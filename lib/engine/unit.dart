
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;


import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';

import 'engine.dart';
class Unit extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  /// Unit represents a character or entity in the game with the ability to move and act on the map.
  /// It extends PositionComponent for positional attributes and implements CommandHandler
  /// for handling keyboard commands. It's a central element in the game's mechanics, controlling
  /// movement, actions, and interactions with other units and tiles.
  ///
  /// Attributes:
  /// - `_animationComponent`: Visual representation of the unit using sprite animation.
  /// - `unitSheet`: SpriteSheet containing animation frames for the unit.
  /// - `battleMenu`: A reference to the BattleMenu for triggering actions.
  /// - `idleAnimationName`: The file name of the unit's image, used for loading the sprite.
  /// - `movementRange`: The number of tiles this unit can move in one turn.
  /// - `team`: The team this unit belongs to, used for identifying allies and enemies.
  /// - `data`: The tiered dictionary (Map) of the unit's data: stats, inventory, skills, etc.
  /// - `tilePosition`: The unit's position on the grid map in terms of tiles.
  /// - `targetTilePosition`: A target position the unit is moving towards, if any.
  /// - `tileSize`: Size of the unit in pixels, scaled according to the game's scaleFactor.
  /// - `canAct`: Boolean indicating whether the unit can take actions.
  /// - `movementQueue`: Queue of points representing the unit's movement path.
  /// - `currentTarget`: The current tile target in the unit's movement path.
  /// - `isMoving`: Boolean indicating if the unit is currently moving.
  /// - `paths`: Stores the paths to all reachable tiles based on the unit's movement range.
  ///
  /// Methods:
  /// - `handleCommand(command)`: Handles keyboard commands for unit actions like moving or interacting.
  /// - `onLoad()`: Loads the unit's sprite and sets up the animation component.
  /// - `toggleCanAct()`: Toggles the unit's ability to act and visually indicates its state.
  /// - `enqueueMovement(targetPoint)`: Adds a new target position to the movement queue.
  /// - `update(dt)`: Updates the unit's position and handles movement towards the target tile.
  /// - `onScaleChanged(scaleFactor)`: Updates the unit's size and position based on the game's scale factor.
  /// - `findReachableTiles()`: Calculates and stores paths to all reachable tiles based on movement range.
  /// - `_constructPath(targetPoint, visitedTiles)`: Constructs the path from the unit to a specified tile.
  /// - `getDirection(point, targetPoint)`: Determines the direction from one point to another.
  ///
  /// Constructor:
  /// - Initializes a Unit with a specific position on the grid and an image name for its sprite.
  ///
  /// Usage:
  /// - Units are the primary actors in the game, controlled by the player or AI to move around the map,
  ///   interact with other units, and perform actions like attacking or defending.
  ///
  /// Connects with:
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
  /// - PositionComponent: Inherits position and size attributes and methods.
  /// - CommandHandler: Implements interface to handle keyboard commands.
  /// - Stage: Interacts with Stage for game world context, like tile access and unit positioning.
  /// - Tile: Interacts with Tile to determine movement paths and interactions based on the terrain.

  Map<String, dynamic> data = {};
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet unitSheet;
  late final BattleMenu battleMenu;
  late final String name;
  late final String idleAnimationName;
  late final int movementRange; 
  late UnitTeam team = UnitTeam.blue;
  late Point<int> tilePosition; // The units's position in terms of tiles, not pixels
  Point<int>? targetTilePosition;
  late double tileSize;
  bool canAct = true;
  Queue<Point<int>> movementQueue = Queue<Point<int>>();
  Point<int>? currentTarget;
  bool isMoving = false;
  Map<Point<int>, List<Point<int>>> paths = {};

  Unit(this.tilePosition, this.idleAnimationName) {
    // Initial size, will be updated in onLoad
    tileSize = 16 * MyGame().scaleFactor;
  }

  Unit.fromJSON(this.tilePosition, this.name, String jsonString) {
    tileSize = 16 * MyGame().scaleFactor;
    var unitsJson = jsonDecode(jsonString)['units'] as List;
    Map<String, dynamic> unitData = unitsJson.firstWhere(
        (unit) => unit['name'].toString().toLowerCase() == name.toLowerCase(),
        orElse: () => throw Exception('Unit $name not found in JSON data')
    );

    movementRange = unitData['movementRange'];
    
    final Map<String, UnitTeam> stringToUnitTeam = {
      for (var team in UnitTeam.values) team.toString().split('.').last: team,
      };
    team = stringToUnitTeam[unitData['team']] ?? UnitTeam.blue;
    idleAnimationName = unitData['sprites']['idle'];

    // Store all other data for later use
    data['stats'] = unitData['stats'];
    data['skills'] = unitData['skills'];
    data['inventory'] = unitData['inventory'];
  }

  @override
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    Stage stage = parent as Stage;
    if (command == LogicalKeyboardKey.keyA) {
      if(stage.tilesMap[stage.cursor.tilePosition]!.isOccupied) return false;
      for(Point<int> point in paths[stage.cursor.tilePosition]!){
        enqueueMovement(point);
      }
      stage.updateTileWithUnit(tilePosition, paths[stage.cursor.tilePosition]!.last, this);
      toggleCanAct(false);
      stage.activeComponent = stage.cursor;
      stage.blankAllTiles();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) {
      stage.activeComponent = stage.cursor;
      stage.blankAllTiles();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowLeft) {
      Point<int> newPoint = Point(stage.cursor.tilePosition.x - 1, stage.cursor.tilePosition.y);
      stage.cursor.move(Direction.left);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) {
      Point<int> newPoint = Point(stage.cursor.tilePosition.x + 1, stage.cursor.tilePosition.y);
      stage.cursor.move(Direction.right);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) {
      Point<int> newPoint = Point(stage.cursor.tilePosition.x, stage.cursor.tilePosition.y - 1);
      stage.cursor.move(Direction.up);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      Point<int> newPoint = Point(stage.cursor.tilePosition.x, stage.cursor.tilePosition.y + 1);
      stage.cursor.move(Direction.down);
      handled = true;
    }
    return handled;
  }

  @override
  Future<void> onLoad() async {
    // Load the unit image and create the animation component
    ui.Image unitImage = await gameRef.images.load(idleAnimationName);
    unitSheet = SpriteSheet.fromColumnsAndRows(
      image: unitImage,
      columns: 4,
      rows: 1,
    );

    _animationComponent = SpriteAnimationComponent(
      animation: unitSheet.createAnimation(row: 0, stepTime: .5),
      size: Vector2.all(tileSize), // Use tileSize for initial size
    );
    
    // Add the animation component as a child
    add(_animationComponent);

    // Set the initial size and position of the unit
    size = Vector2.all(tileSize);
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }

  Vector2 get worldPosition {
        return Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
    }

  void toggleCanAct(bool state) {
    canAct = state;
    // Define the grayscale paint
    final grayscalePaint = mat.Paint()
      ..colorFilter = const mat.ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]);

    // Apply or remove the grayscale effect based on canAct
    _animationComponent.paint = canAct ? mat.Paint() : grayscalePaint;
  }

  void enqueueMovement(Point<int> targetPoint) {
    movementQueue.add(targetPoint);
    if (!isMoving) {
      isMoving = true;
      currentTarget = movementQueue.removeFirst();
    }
  }
  
  @override
  void onMount() {
    super.onMount();
    gameRef.addObserver(this);
  }

  @override
  void onRemove() {
    gameRef.removeObserver(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isMoving && currentTarget != null) {
      // Calculate the pixel position for the target tile position
      final targetX = currentTarget!.x * tileSize;
      final targetY = currentTarget!.y * tileSize;

      // Move towards the target position
      // You might want to adjust the step distance depending on your game's needs
      var moveX = (targetX - x)*.6;
      var moveY = (targetY - y)*.6;

      x += moveX;
      y += moveY;

      // Check if the unit is close enough to the target position to snap it
      if ((x - targetX).abs() < 1 && (y - targetY).abs() < 1) {
        x = targetX; // Snap to exact position
        y = targetY;
        tilePosition = currentTarget!; // Update the tilePosition to the new tile
        

        // Move to the next target if any
        if (movementQueue.isNotEmpty) {
          currentTarget = movementQueue.removeFirst();
        } else {
          currentTarget = null;
          isMoving = false; // No more movements left
        }
      }
    }
  }
  
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the unit itself
    _animationComponent.size = Vector2.all(tileSize); // Update animation component size

    // Update position based on new tileSize
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }

  void findReachableTiles() {
    var visitedTiles = <Point<int>, _TileMovement>{}; // Tracks visited tiles and their data
    var queue = Queue<_TileMovement>(); // Queue for BFS

    // Starting point - no parent at the beginning
    queue.add(_TileMovement(tilePosition, movementRange.toDouble(), null));
    while (queue.isNotEmpty) {
      var tileMovement = queue.removeFirst();
      Point<int> currentPoint = tileMovement.point;
      double remainingMovement = tileMovement.remainingMovement;

      // Skip if a better path to this tile has already been found
      if (visitedTiles.containsKey(currentPoint) && visitedTiles[currentPoint]!.remainingMovement >= remainingMovement) continue;
      
      // Record the tile with its movement data
      visitedTiles[Point(currentPoint.x, currentPoint.y)] = tileMovement;
      Tile? tile = gameRef.stage.tilesMap[currentPoint]; // Accessing tiles through stage
      if (tile!.isOccupied && tile.unit?.team != team) continue; // Skip enemy-occupied tiles
      for (var direction in Direction.values) {
        Point<int> nextPoint;
        switch (direction) {
          case Direction.left:
            nextPoint = Point(currentPoint.x - 1, currentPoint.y);
            break;
          case Direction.right:
            nextPoint = Point(currentPoint.x + 1, currentPoint.y);
            break;
          case Direction.up:
            nextPoint = Point(currentPoint.x, currentPoint.y - 1);
            break;
          case Direction.down:
            nextPoint = Point(currentPoint.x, currentPoint.y + 1);
            break;
        }
        Tile? nextTile = gameRef.stage.tilesMap[Point(nextPoint.x, nextPoint.y)];
        if (nextTile != null && !(nextTile.isOccupied  && nextTile.unit?.team != team)) {
          double cost = gameRef.stage.tilesMap[nextTile.gridCoord]!.terrain.cost;
          double nextRemainingMovement = remainingMovement - cost;
          if (nextRemainingMovement > 0) {
            queue.add(_TileMovement(nextPoint, nextRemainingMovement, currentPoint));
          }
        }
      }
    }

    // Construct paths for each tile
    for (Point<int> tilePoint in visitedTiles.keys) {
      paths[tilePoint] = _constructPath(tilePoint, visitedTiles);
      if(team == UnitTeam.blue){
        gameRef.stage.tilesMap[tilePoint]!.state = TileState.move;
      }
    }
  }

  // Helper method to construct a path from a tile back to the unit
  List<Point<int>> _constructPath(Point<int> targetPoint, Map<Point<int>, _TileMovement> visitedTiles) {
    List<Point<int>> path = [];
    Point<int>? current = targetPoint;
    while (current != null) {
      path.insert(0, current); // Insert at the beginning to reverse the path
      current = visitedTiles[current]!.parent; // Move to the parent
    }
    return path; // The path from the start to the target
  }
  
  Direction? getDirection(Point<int>? point, Point<int>? targetPoint){
    if(point == null || targetPoint == null){
      return null;
    }
    if(point.x < targetPoint.x){
      return Direction.right;
    } else if(point.x > targetPoint.x){
      return Direction.left;
    } else if(point.y < targetPoint.y){
      return Direction.down;
    } else if(point.y > targetPoint.y){
      return Direction.up;
    }
    return null;
  }
}

class _TileMovement {
  Point<int> point;
  double remainingMovement;
  Point<int>? parent; // The tile from which this one was reached

  _TileMovement(this.point, this.remainingMovement, this.parent);
}