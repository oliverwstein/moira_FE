// ignore_for_file: unused_import

import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:moira/main.dart';
export 'menu.dart';
export 'cursor.dart';
export 'game.dart';
export 'stage.dart';
export 'tile.dart';
export 'unit.dart';
export 'item.dart';
export 'attack.dart';
export 'weapon.dart';
export 'combat.dart';
export 'ai.dart';

enum Direction {up, down, left, right}
enum UnitTeam {blue, red, green, yellow}
enum TileState {blank, move, attack}
enum Terrain {forest, path, cliff, water, neutral}
enum ItemType {main, gear, treasure, basic}
extension TerrainCost on Terrain {
  double get cost {
    switch (this) {
      case Terrain.forest:
        return 2;
      case Terrain.cliff:
        return 3;
      case Terrain.water:
        return 100;
      case Terrain.path:
        return .7;
      default:
        return 1;
    }
  }
}



Future<String> loadJsonData(String jsonPath) async {
  var jsonText = await rootBundle.loadString(jsonPath);
  return jsonText;
}