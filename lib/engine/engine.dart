export 'battle_menu.dart';
export 'cursor.dart';
export 'game.dart';
export 'stage.dart';
export 'tile.dart';
export 'unit.dart';
enum Direction {up, down, left, right}
enum UnitTeam {blue, red, green, yellow}
enum TileState {blank, move, attack}
enum Terrain {forest, path, cliff, water, neutral}
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
