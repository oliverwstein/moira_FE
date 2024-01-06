// ignore_for_file: unnecessary_overrides
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

import 'engine.dart';
class Cursor extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  /// Cursor represents the player's cursor in the game world. It extends the PositionComponent,
  /// allowing it to have a position in the game world, and implements CommandHandler for handling
  /// keyboard inputs. The Cursor navigates the game's stage, interacting with tiles and units.
  ///
  /// Attributes:
  /// - `_animationComponent`: Component for rendering cursor animations.
  /// - `cursorSheet`: SpriteSheet for cursor animations.
  /// - `ActionMenu`: ActionMenu component associated with the cursor for in-game actions.
  /// - `gridCoord`: The cursor's position in terms of tiles, not pixels.
  /// - `tileSize`: Size of the cursor in pixels, adjusted by the game's scale factor.
  ///
  /// Methods:
  /// - `onLoad()`: Asynchronously loads resources necessary for the cursor, such as animations.
  /// - `move(direction)`: Moves the cursor in the given direction, updating both tile and pixel positions.
  /// - `select()`: Interacts with the tile at the cursor's current position, handling unit selection and battle menu toggling.
  /// - `handleCommand(command)`: Implements the CommandHandler interface to handle keyboard commands.
  /// - `onMount()`: Observes lifecycle changes, adds itself to game observers on mounting.
  /// - `onRemove()`: Cleans up by removing itself from game observers on removal.
  /// - `onScaleChanged(scaleFactor)`: Updates the cursor's size and position based on the game's scale factor.
  ///
  /// Constructor:
  /// Initializes the cursor with a default tile position and sets up its size based on the game's scale factor.
  ///
  /// Usage:
  /// The Cursor is the main interface for the player to interact with the game world, allowing them to move around the map, select units, and access menus. It is a crucial component for game navigation and interaction.
  ///
  /// Connects with:
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
  /// - Stage: Interacts with and navigates within the Stage class, which holds all tiles and units.
  /// - Tile: Interacts with tiles to select units or display menus.
  /// - Unit: May select units on the tiles to activate them or show their possible movements.

  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet cursorSheet;
  late final ActionMenu actionMenu;
  Point<int> gridCoord = const Point(59, 12); // The cursor's position in terms of tiles, not pixels
  late double tileSize;

  Cursor() {
    // Initial size, will be updated in onLoad
    tileSize = 16 * MyGame().scaleFactor;
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
      size: Vector2.all(tileSize), // Use tileSize for initial size
    );

    // Add the animation component as a child
    add(_animationComponent);
    actionMenu = ActionMenu();
    add(actionMenu);

    // Set the initial size and position of the cursor
    size = Vector2.all(tileSize);
    position = Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
  }

  Vector2 get worldPosition {
        return Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
    }

  void goToUnit(Unit unit){
    position = Vector2(unit.x, unit.y);
    gridCoord = Point(unit.x ~/ unit.tileSize, unit.y ~/ unit.tileSize);
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

    // Update the pixel position of the cursor
    x = gridCoord.x * tileSize;
    y = gridCoord.y * tileSize;
    dev.log('Cursor @ $gridCoord, ${stage.tilesMap[gridCoord]!.terrain}, isOccupied = ${stage.tilesMap[gridCoord]!.isOccupied}, ${stage.tilesMap[gridCoord]!.unit}');
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
          stage.activeComponent = unit;
          dev.log('${unit.idleAnimationName} selected');
          List<Tile> moveSet = unit.findReachableTiles();
          unit.markAttackableTiles(moveSet);
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
      Stage stage = parent as Stage;
      stage.blankAllTiles();
      stage.activeComponent = stage.cursor;
      handled = true;
    }
    return handled;
  }
  
  void snapToTile(Point<int> point){
    x = point.x * tileSize;
    y = point.x * tileSize;
  }
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the cursor itself
    _animationComponent.size = Vector2.all(tileSize); // Update animation component size

    // Update position based on new tileSize
    position = Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
  }
}
