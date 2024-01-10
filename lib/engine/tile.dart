// ignore_for_file: unnecessary_overrides
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/widgets.dart';

import 'engine.dart';

class Tile extends PositionComponent with HasGameRef<MyGame>{
  /// Tile represents a single tile on the game's map. It is a positional component that
  /// can hold a unit and has different states to represent various terrains and actions,
  /// such as movement or attack animations. The Tile class is crucial in the rendering
  /// and logic of the game's map.
  ///
  /// Attributes:
  /// - `_moveAnimationComponent`: Component for rendering movement animations.
  /// - `_attackAnimationComponent`: Component for rendering attack animations.
  /// - `movementSheet`: SpriteSheet for movement animations.
  /// - `attackSheet`: SpriteSheet for attack animations.
  /// - `gridCoord`: Coordinates of the tile on the grid.
  /// - `tileSize`: Size of the tile in pixels, adjusted by the game's scale factor.
  /// - `terrain`: Type of terrain represented by the tile.
  /// - `unit`: The unit currently occupying the tile, if any.
  /// - `state`: Current state of the tile, can be blank, move, or attack.
  /// - `isOccupied`: Read-only property indicating whether the tile is occupied by a unit.
  ///
  /// Methods:
  /// - `onLoad()`: Asynchronously loads resources necessary for the tile, such as animations.
  /// - `setUnit(newUnit)`: Assigns a unit to the tile.
  /// - `removeUnit()`: Removes the unit from the tile.
  /// - `render(canvas)`: Renders the tile and its current state to the canvas.
  /// - `onScaleChanged(scaleFactor)`: Updates the tile's size and position based on the game's scale factor.
  ///
  /// Constructor:
  /// Takes the grid coordinates and terrain type and initializes the tile. The constructor also sets the tile size based on the game's scale factor.
  ///
  /// Usage:
  /// Tiles are used to compose the game's map and are managed by the Stage class. Each tile holds its position, terrain type, and potentially a unit. The Tile class also manages animations and rendering based on its state.
  ///
  /// Connects with:
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
  /// - Unit: May hold a reference to a Unit object representing a unit on the tile.
  /// - Stage: Managed by and interacts with the Stage class, which holds all tiles.

  late final SpriteAnimationComponent _moveAnimationComponent;
  late final SpriteAnimationComponent _attackAnimationComponent;
  late final SpriteSheet movementSheet;
  late final SpriteSheet attackSheet;
  late final Point<int> gridCoord;
  late double tileSize;
  Terrain terrain; // e.g., "grass", "water", "mountain"
  Unit? unit; // Initially null, set when a unit moves into the tile
  TileState state = TileState.blank;
  bool get isOccupied => unit != null;

  Tile(this.gridCoord, this.terrain){
    tileSize = 16 * MyGame().scaleFactor;
  }
  @override
  Future<void> onLoad() async {
    // Load the cursor image and create the animation component
    ui.Image moveImage = await gameRef.images.load('movement_highlight.png');
    ui.Image attackImage = await gameRef.images.load('attack_highlight.png');
    movementSheet = SpriteSheet.fromColumnsAndRows(
      image: moveImage,
      columns: 2,
      rows: 1,
    );
    attackSheet = SpriteSheet.fromColumnsAndRows(
      image: attackImage,
      columns: 2,
      rows: 1,
    );

    _moveAnimationComponent = SpriteAnimationComponent(
      animation: movementSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(tileSize*.9), // Use tileSize for initial size
    );

    _attackAnimationComponent = SpriteAnimationComponent(
      animation: attackSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(tileSize*.9), // Use tileSize for initial size
    );
    position = Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
  }

  void setUnit(Unit newUnit) {
    unit = newUnit;
  }

  void removeUnit() {
    unit = null;
  }

   double getTerrainCost() {
    return terrain.cost;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas); // Don't forget to call super.render
    switch(state) {
      case TileState.blank:
        // Do nothing
        if(_moveAnimationComponent.isMounted){
          remove(_moveAnimationComponent);
        }
        if(_attackAnimationComponent.isMounted){
          remove(_attackAnimationComponent);
        }
        break;
      case TileState.move:
        // Render move animation component
        if(_attackAnimationComponent.isMounted){
          remove(_attackAnimationComponent);
        }
        add(_moveAnimationComponent);
        break;
      case TileState.attack:
        // Render attack animation component
        if(_moveAnimationComponent.isMounted){
          remove(_moveAnimationComponent);
        }
        add(_attackAnimationComponent);
        break;
    }
  }
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the tile itself
    _moveAnimationComponent.size = Vector2.all(tileSize*.9);
    _attackAnimationComponent.size = Vector2.all(tileSize*.9);

    // Update position based on new tileSize
    position = Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
  }
}
