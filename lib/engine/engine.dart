export 'game.dart';
export 'stage.dart';
export 'event.dart';
export 'trigger.dart';
export 'tile.dart';
export 'cursor.dart';
export 'hud.dart';
export 'movement.dart';
export 'title_card.dart';
export 'player.dart';
export 'menu.dart';
export 'combat.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';



abstract class InputHandler {
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed);
}
enum FactionType {blue, red, green, yellow}
extension FactionOrder on FactionType {
  int get order {
    switch (this) {
      case FactionType.blue:
        return 0;
      case FactionType.yellow:
        return 1;
      case FactionType.red:
        return 2;
      case FactionType.green:
        return 3;
    }
  }
}

enum TileState {blank, move, attack}
enum Terrain {forest, path, cliff, sea, stream, fort, plain}
enum ItemType {main, gear, treasure, basic}
extension TerrainCost on Terrain {
  double get cost {
    switch (this) {
      case Terrain.forest:
        return 2;
      case Terrain.cliff:
        return 10;
      case Terrain.sea:
        return 100;
      case Terrain.stream:
        return 10;
      case Terrain.path:
        return .7;
      default:
        return 1;
    }
  }
}

