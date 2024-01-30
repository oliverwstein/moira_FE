import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';
class Movement {
  Direction direction;
  int tileDistance;
  String get directionString => direction.name.toString();
  Movement(this.direction, this.tileDistance);
}
enum Direction {up, down, left, right}

mixin UnitMovement on PositionComponent {
  Queue<Movement> get _movementQueue => (this as Unit).movementQueue;
  Point<int> get _tilePosition => (this as Unit).tilePosition;
  MoiraGame get game;
  Unit get unit => (this as Unit);

  void moveTo(Point<int> destination, [List<Movement>? path]) {
    path ??= getPath(destination);
    _movementQueue.addAll(path);
  }
  Set<Tile> findReachableTiles(double range, {bool markTiles = true}) {
    Set<Tile>reachableTiles = {game.stage.tileMap[unit.tilePosition]!};
    var visitedTiles = <Point<int>, _TileMovement>{}; // Tracks visited tiles and their data
    var queue = Queue<_TileMovement>(); // Queue for BFS
    queue.add(_TileMovement(unit.tilePosition, range, null)); // enqueue the initial position
    while (queue.isNotEmpty) {
      var tileMovement = queue.removeFirst();
      Point<int> currentPoint = tileMovement.point;
      double remainingMovement = tileMovement.remainingMovement;
      // Skip if a better path to this tile has already been found
      if (visitedTiles.containsKey(currentPoint) && visitedTiles[currentPoint]!.remainingMovement >= remainingMovement) continue;

      visitedTiles[Point(currentPoint.x, currentPoint.y)] = tileMovement;
      Tile? tile = game.stage.tileMap[currentPoint];
      if (tile!.isOccupied) { // Skip enemy-occupied tiles
        if(game.stage.factionMap[unit.faction]!.checkHostility(tile.unit!)) continue;
      }

      for (Direction direction in Direction.values) {
        Point <int> nextPoint = currentPoint + getMovement(Movement(direction, 1));
        Tile? nextTile = game.stage.tileMap[Point(nextPoint.x, nextPoint.y)];
        if (nextTile != null && !(nextTile.isOccupied && game.stage.factionMap[unit.faction]!.checkHostility(nextTile.unit!))) {
          double cost = game.stage.tileMap[nextTile.point]!.getTerrainCost();
          double nextRemainingMovement = remainingMovement - cost;
          if (nextRemainingMovement > 0) {
            queue.add(_TileMovement(nextPoint, nextRemainingMovement, currentPoint));
            if (!game.stage.tileMap[currentPoint]!.isOccupied || game.stage.tileMap[currentPoint]!.unit == unit){
              reachableTiles.add(game.stage.tileMap[currentPoint]!);
              if (markTiles) game.stage.tileMap[currentPoint]!.state = TileState.move;
            }
          }
        }
      }
    }
    return reachableTiles;
  }
  List<Tile> markAttackableTiles(List<Tile> reachableTiles) {
    List<Tile> targets = [];
    // Mark tiles attackable from the unit's current position
    (int, int) range = unit.getCombatRange();
    targets.addAll(markTilesInRange(unit.tilePosition, range.$1, range.$2, TileState.attack));
    // Mark tiles attackable from each reachable tile
    for (var tile in reachableTiles) {
      targets.addAll(markTilesInRange(tile.point, range.$1, range.$2,  TileState.attack));
    }
    return targets;
  }
  List<Tile> markTilesInRange(Point<int> centerTile, int minRange, int maxRange, TileState newState) {
    List<Tile> tilesInRange = [];
    for (int x = centerTile.x - maxRange.toInt(); x <= centerTile.x + maxRange.toInt(); x++) {
      for (int y = centerTile.y - maxRange.toInt(); y <= centerTile.y + maxRange.toInt(); y++) {
        var tilePoint = Point<int>(x, y);
        var distance = centerTile.distanceTo(tilePoint);
        if (distance >= minRange && distance <= maxRange) {
          // Check if the tile is within the game bounds
          if (x >= 0 && x < game.stage.mapTileWidth && y >= 0 && y < game.stage.mapTileHeight) {
            var tile = game.stage.tileMap[tilePoint];
            // Mark the tile as attackable if it's not a movement tile
            if (tile != null && tile.state != TileState.move) {
              if (newState == TileState.attack && tile.isOccupied && !game.stage.factionMap[unit.faction]!.checkHostility(tile.unit!)){
                continue;
              }
              tile.state = newState;
              tilesInRange.add(tile);
            }
          }
        }
      }
    }
    return tilesInRange;
  }
  

  Point<int> getMovement(Movement movement) {
    switch (movement.direction) {
      case Direction.up:
        return const Point(0, -1);
      case Direction.down:
        return const Point(0, 1);
      case Direction.left:
        return const Point(-1, 0);
      case Direction.right:
        return const Point(1, 0);
      default:
        return const Point(0,0);
    }
  }

  ({List<Movement> path, Map<Point<int>, double> gScores}) _aStar(Point<int> destination, {Point<int>? source}){
    Map<Point<int>, Point<int>> cameFrom = {};
    source ??= _tilePosition;
    Map<Point<int>, double> gScore = {source: 0};
    Map<Point<int>, double> fScore = {source: _heuristicCost(source, destination)};

    var openSet = {source};

    while (openSet.isNotEmpty) {
      Point<int> current = openSet.reduce((a, b) => fScore[a]! < fScore[b]! ? a : b);

      openSet.remove(current);

      for (var neighbor in _getNeighbors(current)) {
        double tentativeGScore = gScore[current]! + game.stage.tileMap[neighbor]!.terrain.cost;

        if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] = gScore[neighbor]! + _heuristicCost(neighbor, destination);
          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    if (current == destination) {
        unit.remainingMovement = (unit.movementRange - gScore[destination]!).clamp(0, unit.movementRange.toDouble());
        return (path: _reconstructPath(cameFrom, current), gScores: gScore);
      }
    }
    return (path: [], gScores: {});
  }

  List<Movement> getPath(Point<int> destination) {
    return _aStar(destination).path;
  }

  Map<Point<int>, double> getGScores(Point<int> destination, Point<int> source) {
    return _aStar(destination, source: source).gScores;
  }

  List<Movement> _reconstructPath(Map<Point<int>, Point<int>> cameFrom, Point<int> current) {
    List<Movement> totalPath = [];

    while (cameFrom.containsKey(current)) {
      Point<int> previous = cameFrom[current]!;
      Movement movement = _getMovementFromPoints(previous, current);
      totalPath.add(movement);
      current = previous;
    }

    return totalPath.reversed.toList();
  }

  Movement _getMovementFromPoints(Point<int> from, Point<int> to) {
  if (to.x > from.x) return Movement(Direction.right, to.x - from.x);
  if (to.x < from.x) return Movement(Direction.left, from.x - to.x);
  if (to.y > from.y) return Movement(Direction.down, to.y - from.y);
  if (to.y < from.y) return Movement(Direction.up, from.y - to.y);
  throw Exception('Invalid movement from $from to $to');
}

List<Point<int>> _getNeighbors(Point<int> point) {
  List<Point<int>> neighbors = [];

  // Assuming game.stage.tileMap contains all valid tiles
  // Check bounds and add neighboring tiles
  if (game.stage.tileMap.containsKey(Point(point.x - 1, point.y))) {
    neighbors.add(Point(point.x - 1, point.y));
  }
  if (game.stage.tileMap.containsKey(Point(point.x + 1, point.y))) {
    neighbors.add(Point(point.x + 1, point.y));
  }
  if (game.stage.tileMap.containsKey(Point(point.x, point.y - 1))) {
    neighbors.add(Point(point.x, point.y - 1));
  }
  if (game.stage.tileMap.containsKey(Point(point.x, point.y + 1))) {
    neighbors.add(Point(point.x, point.y + 1));
  }

  return neighbors;
}

  double _heuristicCost(Point<int> a, Point<int> b) {
  // Using Manhattan distance as the heuristic
  return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
  }
}

class _TileMovement {
  Point<int> point;
  double remainingMovement;
  Point<int>? parent; // The tile from which this one was reached

  _TileMovement(this.point, this.remainingMovement, this.parent);
}