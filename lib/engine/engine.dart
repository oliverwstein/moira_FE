export 'game.dart';
export 'stage.dart';
export 'tile.dart';
export 'cursor.dart';
export 'hud.dart';
export 'title_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';



abstract class InputHandler {
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed);
}
enum TileState {blank, move, attack}
enum Terrain {forest, path, cliff, sea, stream, fort, plain}
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

