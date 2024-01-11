// ignore_for_file: unnecessary_overrides
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
  Point<int> gridCoord = const Point(32, 25); // The cursor's initial position in terms of tiles, not pixels

  Cursor() {}

  @override
  void update(double dt) {
    super.update(dt);
    isVisible = true;(gameRef.stage.activeTeam == UnitTeam.blue);
    x = gridCoord.x * gameRef.stage.tilesize.x*gameRef.stage.scaling;
    y = gridCoord.y * gameRef.stage.tilesize.y*gameRef.stage.scaling;
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
      size: gameRef.stage.tilesize, // Use tileSize for initial size
    );

    // Add the animation component as a child
    add(_animationComponent);
    actionMenu = ActionMenu();
    add(actionMenu);

    // Set the initial size and position of the cursor
    size = gameRef.stage.tilesize*gameRef.stage.scaling;
    position = Vector2(gridCoord.x * gameRef.stage.tilesize.x*gameRef.stage.scaling, gridCoord.y * gameRef.stage.tilesize.y*gameRef.stage.scaling);
  }

  Vector2 get worldPosition {
        return Vector2(gridCoord.x * gameRef.stage.tilesize.x*gameRef.stage.scaling, gridCoord.y * gameRef.stage.tilesize.y*gameRef.stage.scaling);
    }

  void goToUnit(Unit unit){
    position = Vector2(unit.x, unit.y);
    gridCoord = Point(unit.x ~/ unit.tileSize, unit.y ~/ unit.tileSize);
  }

  void goToCoord(Point<int> point){
    gridCoord = point;
    position = Vector2(point.x * gameRef.stage.tilesize.x, point.y * gameRef.stage.tilesize.y);
  }

  void move(Direction direction) {
    // Assuming parent is always a Stage which is the case in this architecture
    Stage stage = parent as Stage;

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
    newX = newX.clamp(0, stage.mapTileWidth - 1);
    newY = newY.clamp(0, stage.mapTileHeight - 1);

    // Update gridCoord if it's within the map
    gridCoord = Point(newX, newY);
    gameRef.camera.moveTo(worldPosition);
    dev.log("${gameRef.camera.visibleWorldRect}");

    // Update the pixel position of the cursor
    x = gridCoord.x * gameRef.stage.tilesize.x*gameRef.stage.scaling;
    y = gridCoord.y * gameRef.stage.tilesize.y*gameRef.stage.scaling;
    dev.log('Cursor @ $gridCoord, ${stage.tilesMap[gridCoord]!.terrain}, isOccupied = ${stage.tilesMap[gridCoord]!.isOccupied}, ${stage.tilesMap[gridCoord]!.unit?.canAct}');
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
    if (command == LogicalKeyboardKey.arrowLeft) {
      move(Direction.left);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) {
      move(Direction.right);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) {
      move(Direction.up);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      move(Direction.down);
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
  
  void snapToTile(Point<int> point){
    x = point.x * gameRef.stage.tilesize.x;
    y = point.x * gameRef.stage.tilesize.y;
  }
  void onScaleChanged(double scaleFactor) {
    size = gameRef.stage.tilesize; // Update the size of the cursor itself
    _animationComponent.size = gameRef.stage.tilesize; // Update animation component size

    // Update position based on new tileSize
    position = Vector2(gridCoord.x * gameRef.stage.tilesize.x, gridCoord.y * gameRef.stage.tilesize.y);
  }
}
