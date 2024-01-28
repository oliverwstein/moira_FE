import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:moira/content/content.dart';

class Tile extends PositionComponent with HasGameReference<MoiraGame>{
  late final SpriteAnimationComponent _moveAnimationComponent;
  late final SpriteAnimationComponent _attackAnimationComponent;
  late final SpriteSheet movementSheet;
  late final SpriteSheet attackSheet;
  final Point<int> point;
  // late final TextComponent textComponent;
  Unit? unit;
  bool get isOccupied => unit != null;
  Terrain terrain; // e.g., "grass", "water", "mountain"
  String name; // Defaults to the terrain name if there is no name.
  TileState state = TileState.blank;
  Tile(this.point, double size, this.terrain, this.name) {
    this.size = Vector2.all(size);
    anchor = Anchor.topLeft;
  }
  static int getDistance(Point<int> a, Point<int> b){
    return (a.x - b.x).abs() + (a.y - b.y).abs();
  }

  @override 
  void update(dt){
    if(unit != null) {
      if (unit?.tilePosition != point){
        removeUnit();
      } 
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    ui.Image moveImage = await game.images.load('movement_highlight.png');
    ui.Image attackImage = await game.images.load('attack_highlight.png');
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
    );
    
    _moveAnimationComponent.anchor = Anchor.center;
    _moveAnimationComponent.position = Vector2(size.x/2, size.y/2);
    _moveAnimationComponent.size = size*.9;
    _attackAnimationComponent = SpriteAnimationComponent(
      animation: attackSheet.createAnimation(row: 0, stepTime: .2),
    );
    _attackAnimationComponent.anchor = Anchor.center;
    _attackAnimationComponent.position = Vector2(size.x/2, size.y/2);
    _attackAnimationComponent.size = size*.9;
  }
  
  void resize() {
    size = Vector2.all(Stage.tileSize);
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


