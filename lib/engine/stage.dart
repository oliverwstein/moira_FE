// ignore_for_file: unnecessary_overrides
import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;
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
  final Completer<void> _loadCompleter = Completer<void>();
  late final int mapTileWidth;
  late final int mapTileHeight;
  late final Vector2 mapSize;
  late final flame_tiled.TiledComponent tiles;
  late final Cursor cursor;
  List<Unit> units = [];
  List<UnitTeam> teams = UnitTeam.values;
  Map<UnitTeam, Player> playerMap = {};
  UnitTeam? activeTeam;
  late Vector2 tilesize;
  Map<Point<int>, Tile> tilesMap = {};
  late Component activeComponent;
  int turn = 1;
  Stage();

  @override
  Future<void> onLoad() async {
    tilesize = Vector2.all(16*gameRef.scaleFactor);
    tiles = await flame_tiled.TiledComponent.load('Ch0.tmx', tilesize);
    tiles.scale = Vector2.all(gameRef.scaleFactor);
    add(tiles);
    mapTileHeight = tiles.tileMap.map.height;
    mapTileWidth = tiles.tileMap.map.width;
    mapSize = Vector2(mapTileWidth*16, mapTileHeight*16);
    for (int x = 0; x < mapTileWidth; x++) {
      for (int y = 0; y < mapTileHeight; y++) {
        Point<int> gridCoord = Point(x, y);
        Terrain terrain = determineTerrainType(gridCoord);
        String name = getTileName(gridCoord);
        Tile tile = Tile(gridCoord, terrain, name);
        add(tile);
        gameRef.addObserver(tile);
        tilesMap[Point(x, y)] = tile;
      }
    }
    activeTeam = UnitTeam.blue;
    cursor = Cursor();
    activeComponent = cursor;
    add(cursor);
    gameRef.addObserver(cursor);
    
    // THIS IS HOW YOU SET THE SIZE OF THE MAXIMUM VISIBLE AREA
    gameRef.camera.viewport.size = Vector2(16*16, 12*16);
    gameRef.camera.moveTo(cursor.worldPosition);
    gameRef.camera.viewfinder;
    // gameRef.camera.follow(cursor);
    dev.log("Test");
    _loadCompleter.complete();
  }

  Future<void> get loadCompleted => _loadCompleter.future;
  
  @override
  void update(double dt) {
    super.update(dt);
    // dev.log("stage ${mapSize}");
    // gameRef.scaleFactor = max(mapSize.x / gameRef.canvasSize.x,
    //                     mapSize.y / gameRef.canvasSize.y);
    // dev.log("stage ${gameRef.scaleFactor}");

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

  List<Unit> getTargets(){
    List<Unit> targetList = [];
    for (Tile tile in tilesMap.values){
      if(tile.state == TileState.attack){
        assert(tile.isOccupied);
        targetList.add(tile.unit!);
      }
    }
    return targetList;
  }

  void startStage(){
    activeTeam = UnitTeam.blue;
    dev.log('Start the stage!');

  }
  void startTurn() {
    dev.log('Turn $turn');
    dev.log('Start turn for $activeTeam');
    Player? player = playerMap[activeTeam];
    player?.takeTurn();
  }

  void endTurn() {
    dev.log('End turn for $activeTeam');

    if(activeTeam == UnitTeam.blue) turn++;
    int index = teams.indexOf(activeTeam!);
    activeTeam = teams[(index + 1) % teams.length];
    for (var unit in units) {
      unit.toggleCanAct(true);
      if(!unit.actionsAvailable.contains(MenuOption.attack)){
        unit.actionsAvailable.add(MenuOption.attack);
      }
      unit.remainingMovement = unit.movementRange.toDouble();
    }
    startTurn();
  }

  String getTileName(Point<int> point){
    int localId = point.y * mapTileWidth + point.x;
    var tile = tiles.tileMap.map.tileByLocalId('Ch0', localId.toInt());
    var type = tile?.properties.getProperty("terrain")?.value;
    var name = tile?.properties.getProperty("name")?.value ?? type;
    return name as String;
  }
  

  Terrain determineTerrainType(Point<int> point){
    int localId = point.y * mapTileWidth + point.x;
    var tile = tiles.tileMap.map.tileByLocalId('Ch0', localId.toInt());
    var terrain = tile?.properties.getProperty("terrain")?.value;
    return _stringToTerrain(terrain as String);
  }
  
  Terrain _stringToTerrain(String input) {
    // Create and initialize the map within the method
    final Map<String, Terrain> stringToTerrain = {
      for (var terrain in Terrain.values) terrain.toString().split('.').last: terrain,
    };
    // Perform the lookup and return
    return stringToTerrain[input.toLowerCase()] ?? Terrain.plain;
  }

  Point<int>? findTilePoint(String name, Terrain terrain) {
  try {
    return tilesMap.entries
        .firstWhere(
            (entry) => entry.value.name == name && entry.value.terrain == terrain)
        .key;
  } on StateError {
    // No tile found that matches the criteria
    return null;
  }
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
