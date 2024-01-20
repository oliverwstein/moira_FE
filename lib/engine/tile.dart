import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:moira/content/content.dart';

class Tile extends PositionComponent with HasGameReference<MoiraGame>{
  final Point<int> point;
  // late final TextComponent textComponent;
  Unit? unit;
  bool get isOccupied => unit != null;
  Terrain terrain; // e.g., "grass", "water", "mountain"
  String name; // Defaults to the terrain name if there is no name.

  Tile(this.point, double size, this.terrain, this.name) {
    this.size = Vector2.all(size);
    anchor = Anchor.topLeft;
  }

  @override 
  void update(dt){
    if(unit != null) {
      if (unit?.tilePosition != point){
        debugPrint("removeUnit ${unit?.name} from $point");
        removeUnit();
      } 
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }
  
  void resize() {
    size = Vector2.all(game.stage.tileSize);
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
}


