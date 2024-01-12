// ignore_for_file: unnecessary_overrides
import 'dart:collection';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

import 'engine.dart';
class Cursor extends PositionComponent with HasGameRef<MyGame>, HasVisibility implements CommandHandler {
  /// Cursor represents the player's cursor in the game world. It extends the PositionComponent,
  /// allowing it to have a position in the game world, and implements CommandHandler for handling
  /// keyboard inputs. The Cursor navigates the game's stage, interacting with tiles and units.
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet cursorSheet;
  late final ActionMenu actionMenu;
  Queue<Direction> movementQueue = Queue<Direction>();
  bool isMoving = false;
  Direction? currentDirection;
  Point<int> gridCoord = const Point(32, 25); // The cursor's initial position in terms of tiles, not pixels

  Cursor() {}

  @override
  void update(double dt) {
    super.update(dt);
    isVisible = (gameRef.stage.activeTeam == UnitTeam.blue);
    scale = Vector2.all(gameRef.stage.scaling);
    size = gameRef.stage.tilesize * gameRef.stage.scaling;

    // Handle smooth movement
    if (!isMoving && movementQueue.isNotEmpty) {
      currentDirection = movementQueue.removeFirst();
      isMoving = true;
    }

    if (isMoving && currentDirection != null) {
      // Calculate the pixel position for the target tile position
      Point<int> targetPoint = _getNextPoint(gridCoord, currentDirection!);
      final targetX = targetPoint.x * size.x;
      final targetY = targetPoint.y * size.y;

      // Smoothly move towards the target position
      var moveX = (targetX - x) * 24 * dt; // Adjust speed as needed
      var moveY = (targetY - y) * 24 * dt;

      x += moveX;
      y += moveY;
      if (shouldCameraMove(moveX, moveY)) {
        gameRef.camera.moveBy(Vector2(moveX, moveY)); // Adjust duration as needed
      }

      // Check if the cursor is close enough to the target position to snap it
      if ((x - targetX).abs() < 1 && (y - targetY).abs() < 1) {
        x = targetX;
        y = targetY;
        gridCoord = targetPoint;
        isMoving = false;
        dev.log("Cursor @ $gridCoord");
        currentDirection = null;
      }
    }
  }

  void move(Direction direction) {
  // Calculate the potential new position
  int newX = gridCoord.x;
  int newY = gridCoord.y;

  switch (direction) {
    case Direction.left:
      newX -= 1;
      break;
    case Direction.right:
      newX += 1;
      break;
    case Direction.up:
      newY -= 1;
      break;
    case Direction.down:
      newY += 1;
      break;
  }

  // Clamp the new position to ensure it's within the bounds of the map
  Stage stage = parent as Stage;
  newX = newX.clamp(0, stage.mapTileWidth - 1);
  newY = newY.clamp(0, stage.mapTileHeight - 1);

  // Only enqueue the movement if it's within the bounds
  if (newX != gridCoord.x || newY != gridCoord.y) {
    movementQueue.add(direction);
  }
}

  bool shouldCameraMove(double moveX, double moveY) {
    Rect visibleRect = gameRef.camera.visibleWorldRect;
    Stage stage = gameRef.stage;

    double stageWidth = stage.mapTileWidth * size.x;
    double stageHeight = stage.mapTileHeight * size.y;

    // Calculate the midpoint of the visible rect
    Offset midpoint = Offset(
      visibleRect.left + visibleRect.width / 2,
      visibleRect.top + visibleRect.height / 2
    );

    // Calculate the cursor's world position
    Offset cursorPosition = Offset(gridCoord.x * size.x, gridCoord.y * size.y);

    // Determine if cursor is beyond the midpoint
    bool isBeyondMidpointX = (moveX < 0 && cursorPosition.dx < midpoint.dx) || (moveX > 0 && cursorPosition.dx > midpoint.dx);
    bool isBeyondMidpointY = (moveY < 0 && cursorPosition.dy < midpoint.dy) || (moveY > 0 && cursorPosition.dy > midpoint.dy);

    // Determine if moving the camera would reveal areas outside of the stage
    bool withinStageX = (moveX < 0 && visibleRect.left > 0) || (moveX > 0 && visibleRect.right < stageWidth);
    bool withinStageY = (moveY < 0 && visibleRect.top > 0) || (moveY > 0 && visibleRect.bottom < stageHeight);

    // The camera should move if the cursor is beyond the midpoint and within stage boundaries
    return (isBeyondMidpointX && withinStageX) || (isBeyondMidpointY && withinStageY);
  }


  @override
  Future<void> onLoad() async {
    // Load the cursor image and create the animation component
    ui.Image cursorImage = await gameRef.images.load('cursor.png');
    cursorSheet = SpriteSheet.fromColumnsAndRows(
      image: cursorImage,
      columns: 3,
      rows: 1,
    );

    _animationComponent = SpriteAnimationComponent(
      animation: cursorSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(16), // Use 16 for initial size
    );

    // Add the animation component as a child
    add(_animationComponent);
    actionMenu = ActionMenu();
    add(actionMenu);

    // Set the initial size and position of the cursor
    size = gameRef.stage.tilesize*gameRef.stage.scaling;
    position = Vector2(gridCoord.x * size.x, gridCoord.y * size.y);
    gameRef.camera.moveTo(position);
  }

  Vector2 get worldPosition {
        return Vector2(gridCoord.x * size.x, gridCoord.y * size.y);
    }

  void goToUnit(Unit unit){
    position = Vector2(unit.x, unit.y);
    gridCoord = Point(unit.x ~/ size.x, unit.y ~/ size.y);
  }

  void goToCoord(Point<int> point){
    gridCoord = point;
    position = Vector2(point.x * size.x, point.y * size.y);
  }

  void snapToTile(Point<int> point) {
    if (shouldCameraMove(point.x * size.x - x, point.y * size.y - y)) {
        gameRef.camera.moveBy(Vector2(point.x * size.x - x, point.y * size.y - y)); // Adjust duration as needed
      }
    x = point.x * size.x;
    y = point.y * size.y;
    gridCoord = point;
  }

  void panToTile(Point<int> destination) {
    int deltaX = destination.x - gridCoord.x;
    int deltaY = destination.y - gridCoord.y;
    // Alternate between horizontal and vertical movements
    while (deltaX != 0 || deltaY != 0) {
      if (deltaX > 0) {
        movementQueue.add(Direction.right);
        deltaX--;
      } else if (deltaX < 0) {
        movementQueue.add(Direction.left);
        deltaX++;
      }

      if (deltaY > 0) {
        movementQueue.add(Direction.down);
        deltaY--;
      } else if (deltaY < 0) {
        movementQueue.add(Direction.up);
        deltaY++;
      }
    }
  }


  void select() {
  if (parent is Stage) {
    Stage stage = parent as Stage;
    Tile? tile = stage.tilesMap[gridCoord];

    if (tile != null) {
      // Proceed as normal if tile is not null
      if (tile.isOccupied) { // Chosen tile has a unit on it
        Unit? unit = tile.unit;
        if (unit != null && unit.canAct) { // Unit can act
          if (unit.team == UnitTeam.blue){
            stage.activeComponent = unit;
            dev.log('${unit.idleAnimationName} selected');
            List<Tile> moveSet = unit.findReachableTiles();
            unit.markAttackableTiles(moveSet);
          }
        } else {
          stage.blankAllTiles();
          List<MenuOption> visibleOptions = [MenuOption.endTurn, MenuOption.save];
          stage.cursor.actionMenu.show(visibleOptions);
          stage.activeComponent = stage.cursor.actionMenu;
        }
      } else {
        stage.blankAllTiles();
        List<MenuOption> visibleOptions = [MenuOption.endTurn, MenuOption.save];
        stage.cursor.actionMenu.show(visibleOptions);
        stage.activeComponent = stage.cursor.actionMenu;
      }
    } else {
      // Throw an exception if tile is null
      var x = gridCoord.x;
      var y = gridCoord.y;
      bool inMap = stage.tilesMap.containsKey((x:57.0, y:12.0));
      throw Exception('Attempted to select a null tile at position ($x, $y). Point found = $inMap. $tile');
    }
  } else {
    // Optionally, handle case where parent is not a Stage
    throw Exception('Cursor\'s parent is not of type Stage.');
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
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    Stage stage = parent as Stage;
    if (stage.activeTeam != UnitTeam.blue) return true;

    if (command == LogicalKeyboardKey.arrowLeft || command == LogicalKeyboardKey.arrowRight || command == LogicalKeyboardKey.arrowUp || command == LogicalKeyboardKey.arrowDown) {
      // If the user inputs a move command before reaching the next tile, jump to the next tile
      if (isMoving) {
        Point<int> targetPoint = _getNextPoint(gridCoord, currentDirection!);
        snapToTile(targetPoint);
        dev.log("Cursor @ ${targetPoint}");
        isMoving = false;
        movementQueue.clear();
      }

      // Add new direction to the queue
      if (command == LogicalKeyboardKey.arrowLeft) {
        move(Direction.left);
      } else if (command == LogicalKeyboardKey.arrowRight) {
        move(Direction.right);
      } else if (command == LogicalKeyboardKey.arrowUp) {
        move(Direction.up);
      } else if (command == LogicalKeyboardKey.arrowDown) {
        move(Direction.down);
      }
      handled = true;
    } else if (command == LogicalKeyboardKey.keyA) {
      select();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) {
      stage.blankAllTiles();
      stage.activeComponent = stage.cursor;
      handled = true;
    }
    return handled;
  }

  Point<int> _getNextPoint(Point<int> currentPoint, Direction direction) {
    int newX = currentPoint.x;
    int newY = currentPoint.y;

    switch (direction) {
      case Direction.left:
        newX -= 1;
        break;
      case Direction.right:
        newX += 1;
        break;
      case Direction.up:
        newY -= 1;
        break;
      case Direction.down:
        newY += 1;
        break;
    }

    return Point(newX, newY);
  }
}
