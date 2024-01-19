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

  void moveTo(Point<int> destination, [List<Movement>? path]) {
    path ??= getPath(destination);
    _movementQueue.addAll(path);
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
  List<Movement> getPath(Point<int> destination) {
    Map<Point<int>, Point<int>> cameFrom = {};
    Map<Point<int>, double> gScore = {_tilePosition: 0};
    Map<Point<int>, double> fScore = {_tilePosition: _heuristicCost(_tilePosition, destination)};

    var openSet = {_tilePosition};

    while (openSet.isNotEmpty) {
      Point<int> current = openSet.reduce((a, b) => fScore[a]! < fScore[b]! ? a : b);

      if (current == destination) {
        return _reconstructPath(cameFrom, current);
      }

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
    }

    return []; // return empty path if destination is not reachable
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