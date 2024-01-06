// ignore_for_file: unnecessary_overrides
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart' as flame_tiled;
import 'package:flutter/services.dart';

import 'engine.dart';
class Stage extends Component with HasGameRef<MyGame>{
  /// Stage is a primary component in the game that manages the layout of the 
  /// game map, including tiles, units, and the cursor. It interfaces with the 
  /// game's TiledComponent to render the map and holds the logic for the game's 
  /// terrain, unit positioning, and active components like cursor or units.
  late final int mapTileWidth;
  late final int mapTileHeight;
  late final Vector2 mapSize;
  late final flame_tiled.TiledComponent tiles;
  late final Cursor cursor;
  List<Unit> units = [];
  final Vector2 tilesize = Vector2.all(16);
  Map<Point<int>, Tile> tilesMap = {};
  late Component activeComponent;
  int turn = 1;
  Stage();

  @override
  Future<void> onLoad() async {
    tiles = await flame_tiled.TiledComponent.load('Ch0.tmx', tilesize);
    tiles.anchor = Anchor.topLeft;
    tiles.scale = Vector2.all(gameRef.scaleFactor);
    add(tiles);
    mapTileHeight = tiles.tileMap.map.height;
    mapTileWidth = tiles.tileMap.map.width;
    for (int x = 0; x < mapTileWidth; x++) {
      for (int y = 0; y < mapTileHeight; y++) {
        Point<int> gridCoord = Point(x, y);
        Terrain terrain = determineTerrainType(gridCoord);
        Tile tile = Tile(gridCoord, terrain);
        add(tile);
        gameRef.addObserver(tile);
        tilesMap[Point(x, y)] = tile;
      }
    }
    units.add(Unit.fromJSON(const Point(59, 10), 'arden'));
    units.add(Unit.fromJSON(const Point(60, 12), 'alec'));
    units.add(Unit.fromJSON(const Point(58, 12), 'noish'));
    units.add(Unit.fromJSON(const Point(59, 13), 'sigurd'));

    units.add(Unit.fromJSON(const Point(56, 12), 'brigand'));
    units.add(Unit.fromJSON(const Point(55, 13), 'brigand'));
    units.add(Unit.fromJSON(const Point(55, 11), 'brigand'));
     
    for (Unit unit in units) {
      add(unit);
      tilesMap[unit.gridCoord]?.setUnit(unit);
      gameRef.addObserver(unit);
    }

    cursor = Cursor();
    activeComponent = cursor;
    add(cursor);
    gameRef.addObserver(cursor);
    
  }
  @override
  void update(double dt) {
    super.update(dt);
  }

  @override
  void onMount() {
    gameRef.addObserver(this);
    super.onMount();
  }

  @override
  void onRemove() {
    gameRef.removeObserver(this);
    super.onRemove();
  }

  void onScaleChanged(double scaleFactor) {
    for (final child in children) {
      if (child is flame_tiled.TiledComponent) {
        child.scale = Vector2.all(scaleFactor);
      }
    }
  }

  void updateTileWithUnit(Point<int> oldPoint, Point<int> newPoint, Unit unit) {
    tilesMap[oldPoint]?.removeUnit();
    tilesMap[newPoint]?.setUnit(unit);
  }

  void endTurn() {
    for (var unit in units) {
      unit.toggleCanAct(true);
    }
    turn++;
  }
  
  Terrain determineTerrainType(Point<int> point){
    int localId = point.y * mapTileWidth + point.x;
    var tile = tiles.tileMap.map.tileByLocalId('Ch0', localId.toInt());
    var type = tile?.properties.firstOrNull?.value ?? 'neutral';
    return _stringToTerrain(type as String);
  }
  
  Terrain _stringToTerrain(String input) {
    // Create and initialize the map within the method
    final Map<String, Terrain> stringToTerrain = {
      for (var terrain in Terrain.values) terrain.toString().split('.').last: terrain,
    };
    // Perform the lookup and return
    return stringToTerrain[input] ?? Terrain.neutral;
  }

  bool keyCommandHandler(LogicalKeyboardKey command) {
    if (activeComponent is CommandHandler) {
      return (activeComponent as CommandHandler).handleCommand(command);
    }
    return false;
  }
  
  void blankAllTiles(){
    for (Tile tile in tilesMap.values) {
      tile.state = TileState.blank;
    }
  }
}
