import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:moira/content/content.dart';
enum TileState {blank, move, attack}
enum Terrain {forest, path, cliff, sea, stream, fort, gate, rampart, plain}
extension TerrainEffects on Terrain {
  double get cost {
    switch (this) {
      case Terrain.forest:
        return 2;
      case Terrain.cliff:
        return 10;
      case Terrain.sea:
        return 100;
      case Terrain.rampart:
        return 100;
      case Terrain.stream:
        return 20;
      case Terrain.path:
        return .7;
      default:
        return 1;
    }
  }

  int get avoid {
    switch (this) {
      case Terrain.forest:
        return 20;
      case Terrain.fort:
        return 30;
      case Terrain.path:
        return -10;
      default:
        return 0;
    }
  }

  int get defense {
    switch (this) {
      case Terrain.fort:
        return 2;
      case Terrain.forest:
        return 1;
      case Terrain.path:
        return -1;
      default:
        return 0;
    }
  }
}

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
  // Factory constructor
  factory Tile(Point<int> point, double size, Terrain terrain, String name) {
    if (name == "Center") {
      return Town(point, size, terrain, name);
    } else {
      return Tile._internal(point, size, terrain, name);
    }
  }

  // Internal constructor for Tile
  Tile._internal(this.point, double size, this.terrain, this.name) {
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
  double getTerrainCost() {return terrain.cost;}
  int getTerrainAvoid() {return terrain.avoid;}
  int getTerrainDefense() {return terrain.defense;
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

class Town extends Tile {
  bool open;
  int loot;
  // Constructor for the Town class. 
  // Inherits properties and methods from Tile and adds specific properties for Town.
  Town(Point<int> point, double size, Terrain terrain, String name, {this.open = true, this.loot = 10}) 
    : super._internal(point, size, terrain, name);

  void close() {
    open = false;
  }

  void updateLoot(int newLoot) {
    loot = newLoot;
  }
}

class VisitEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  final Town town;
  VisitEvent(this.unit, this.town, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    town.close; 
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}
