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

  late final SpriteAnimationComponent _moveAnimationComponent;
  late final SpriteAnimationComponent _attackAnimationComponent;
  late final SpriteSheet movementSheet;
  late final SpriteSheet attackSheet;
  late final Point<int> gridCoord;
  Terrain terrain; // e.g., "grass", "water", "mountain"
  String name; // e.g., "grass", "water", "mountain"
  Unit? unit; // Initially null, set when a unit moves into the tile
  TileState state = TileState.blank;
  bool get isOccupied => unit != null;

  Tile(this.gridCoord, this.terrain, this.name);
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
      size: Vector2.all(gameRef.stage.scaling*.9), // Use tileSize for initial size
    );

    _attackAnimationComponent = SpriteAnimationComponent(
      animation: attackSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(gameRef.stage.scaling*.9), // Use tileSize for initial size
    );
    position = Vector2(gridCoord.x * gameRef.stage.scaling, gridCoord.y * gameRef.stage.scaling);
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
}
