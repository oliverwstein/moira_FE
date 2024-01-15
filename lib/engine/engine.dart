export 'game.dart';
export 'stage.dart';
export 'event.dart';
export 'tile.dart';
export 'cursor.dart';
export 'hud.dart';
export 'title_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';



abstract class InputHandler {
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed);
}
enum UnitTeam {blue, red, green, yellow}
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

