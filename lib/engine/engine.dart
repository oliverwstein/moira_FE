// ignore_for_file: unused_import

import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:moira/main.dart';

export '../content/content.dart';
export 'combat.dart';
export 'cursor.dart';
export 'event.dart';
export 'game.dart';
export 'menu.dart';
export 'observer.dart';
export 'player.dart';
export 'stage.dart';
export 'tile.dart';

enum Direction {up, down, left, right}
enum UnitTeam {blue, red, green, yellow}
enum TileState {blank, move, attack}
enum Terrain {forest, path, cliff, sea, stream, plain}
enum ItemType {main, gear, treasure, basic}
extension TerrainCost on Terrain {
  double get cost {
    switch (this) {
      case Terrain.forest:
        return 2;
      case Terrain.cliff:
        return 100;
      case Terrain.sea:
        return 100;
      case Terrain.stream:
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