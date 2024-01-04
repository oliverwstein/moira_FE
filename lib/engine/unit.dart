
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
  Map<String, dynamic> data = {};
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet unitSheet;
  late final ActionMenu actionMenu;
  late final String name;
  late final String idleAnimationName;
  late int movementRange; 
  late List<Item> inventory;
  Map<ItemType, Item> equippedItems = {};
  late UnitTeam team = UnitTeam.blue;
  late (int, int) combatRange;
  late Point<int> tilePosition; // The units's position in terms of tiles, not pixels
  Point<int>? targetTilePosition;
  late double tileSize;
  bool canAct = true;
  Queue<Point<int>> movementQueue = Queue<Point<int>>();
  Point<int>? currentTarget;
  bool isMoving = false;
  Map<Point<int>, List<Point<int>>> paths = {};
  late Point<int> oldTile;
  

  Unit(this.tilePosition, this.idleAnimationName) {
    // Initial size, will be updated in onLoad
    tileSize = 16 * MyGame().scaleFactor;
    oldTile = tilePosition;
  }

  Unit.fromJSON(this.tilePosition, this.name, String jsonString) {
    oldTile = tilePosition;
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

  void equipItem(Item item) {
    equippedItems[item.type] = item;  // Equips the item, replacing any item of the same type.
  }

  void unequipItem(ItemType itemType) {
    equippedItems.remove(itemType);  // Removes the item of the specified type.
  }

  Item? getEquippedItem(ItemType itemType) {
    return equippedItems[itemType];  // Retrieves the equipped item of the specified type, if any.
  }
  @override
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    Stage stage = parent as Stage;
    if (command == LogicalKeyboardKey.keyA) {
      oldTile = tilePosition;
      for(Point<int> point in paths[stage.cursor.tilePosition]!){
        enqueueMovement(point);
      }
      var newTile = paths[stage.cursor.tilePosition]!.last;
      stage.updateTileWithUnit(tilePosition, newTile, this);
      stage.blankAllTiles();

      List<Tile> attackTiles = markAttackableEnemies(newTile, combatRange.$1, combatRange.$2);
      List<MenuOption> visibleOptions = [MenuOption.item, MenuOption.wait];
      if(attackTiles.isNotEmpty){
        visibleOptions.add(MenuOption.attack);
      }
      stage.cursor.actionMenu.show(visibleOptions);
      stage.activeComponent = stage.cursor.actionMenu;
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) {
      stage.activeComponent = stage.cursor;
      stage.blankAllTiles();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowLeft) {
      stage.cursor.move(Direction.left);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) {
      stage.cursor.move(Direction.right);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) {
      stage.cursor.move(Direction.up);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
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

  void snapToTile(Point<int> point){
    x = point.x * tileSize;
    y = point.x * tileSize;
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
    } else {
    // Check if the tilePosition has changed without the animation
    // and update the sprite's position accordingly
    final expectedX = tilePosition.x * tileSize;
    final expectedY = tilePosition.y * tileSize;
    if (x != expectedX || y != expectedY) {
      position = Vector2(expectedX, expectedY); // Snap sprite to the new tile position
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

  List<Tile> findReachableTiles() {
    List<Tile>reachableTiles = [];
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
        reachableTiles.add(gameRef.stage.tilesMap[tilePoint]!);
      }
    }
    return reachableTiles;
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
  
  void markAttackableTiles(List<Tile> reachableTiles) {
    // Mark tiles attackable from the unit's current position
    markTilesInRange(tilePosition, combatRange.$1, combatRange.$2, TileState.attack);
    // Mark tiles attackable from each reachable tile
    for (var tile in reachableTiles) {
      markTilesInRange(tile.gridCoord, combatRange.$1, combatRange.$2,  TileState.attack);
    }
  }

  List<Tile> markAttackableEnemies(Point<int> centerTile, int minRange, int maxRange){
    List<Tile> tilesInRange = markTilesInRange(centerTile, minRange, maxRange, TileState.attack);
    List<Tile> attackTiles = [];
    for (Tile tile in tilesInRange){
      if (tile.unit?.team != UnitTeam.red){
        tile.state = TileState.blank;
      } else {
        attackTiles.add(tile);
      }
    }
    return attackTiles;
  }

  List<Tile> markTilesInRange(Point<int> centerTile, int minRange, int maxRange, TileState newState) {
    List<Tile> tilesInRange = [];
    for (int x = centerTile.x - maxRange.toInt(); x <= centerTile.x + maxRange.toInt(); x++) {
      for (int y = centerTile.y - maxRange.toInt(); y <= centerTile.y + maxRange.toInt(); y++) {
        var tilePoint = Point<int>(x, y);
        var distance = centerTile.distanceTo(tilePoint);
        if (distance >= minRange && distance <= maxRange) {
          // Check if the tile is within the game bounds
          if (x >= 0 && x < gameRef.stage.mapTileWidth && y >= 0 && y < gameRef.stage.mapTileHeight) {
            var tile = gameRef.stage.tilesMap[tilePoint];
            // Mark the tile as attackable if it's not a movement tile
            if (tile != null && tile.state == TileState.blank) {
              tile.state = newState;
              tilesInRange.add(tile);
            }
          }
        }
      }
    }
    return tilesInRange;
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