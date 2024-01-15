import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart' as flame_tiled;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/engine/engine.dart';

class Stage extends World with HasGameReference<MoiraGame> implements InputHandler {
  int tilesInRow = 16;
  int tilesInColumn = 12;
  late double tileSize;
  final int mapTileWidth;
  final int mapTileHeight;
  final Vector2 initialPosition;
  final String mapFileName;
  final Map<Point<int>, Tile> tileMap = {};
  late final Cursor cursor;
  late final Hud hud;
  late Vector2 playAreaSize;
  late final flame_tiled.TiledComponent tiles;
  Stage(this.mapTileWidth, this.mapTileHeight, this.initialPosition, this.mapFileName);

  Stage._internal(this.mapTileWidth, this.mapTileHeight, this.initialPosition, this.mapFileName);

  // Static async method to create an instance from JSON
  static Future<Stage> fromJson(String mapFileName) async {
    // Load the JSON file
    final jsonString = await rootBundle.loadString('assets/data/stages.json');
    final data = json.decode(jsonString)[mapFileName];

    final mapTileWidth = data['mapTileWidth'] as int;
    final mapTileHeight = data['mapTileHeight'] as int;
    final Vector2 initialPosition = Vector2(data['initialPosition'][0].toDouble(), data['initialPosition'][1].toDouble());

    final tmxFile = data['mapFileName'] as String;

    // Create and return a new instance
    return Stage._internal(mapTileWidth, mapTileHeight, initialPosition, tmxFile);
  }
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    calculateTileSize();
    tiles = await flame_tiled.TiledComponent.load(mapFileName, Vector2.all(tileSize));
    add(tiles);
    createTiles();
    cursor = Cursor();
    add(cursor);
    playAreaSize = Vector2(mapTileWidth*tileSize, mapTileHeight*tileSize);
    final gameMidX = playAreaSize.x / 2;
    final gameMidY = playAreaSize.y / 2;

    final camera = game.camera;
    camera.viewport = FixedAspectRatioViewport(aspectRatio: tilesInRow/tilesInColumn);
    camera.viewfinder.visibleGameSize = Vector2(tilesInRow*tileSize, tilesInColumn*tileSize);
    camera.viewfinder.position = Vector2(gameMidX, gameMidY);
    // camera.viewfinder.position = Vector2(initialPosition.x*tileSize, initialPosition.y*tileSize);
    camera.viewfinder.anchor = Anchor.center;
    hud = Hud();
    camera.viewport.add(hud);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    calculateTileSize();
    resizeStage();
  }
  

  void calculateTileSize() {
    // Calculate tile size based on the game's canvas size
    final gameSize = game.size;
    tileSize = min(gameSize.x / mapTileWidth, gameSize.y / mapTileHeight);
  }

  void createTiles() {
    // Create tiles
    for (int i = 0; i < mapTileWidth; i++) {
      for (int j = 0; j < mapTileHeight; j++) {
        Point<int> point = Point(i, j);
        Terrain terrain = determineTerrainType(point);
        String name = getTileName(point);
        Tile tile = Tile(point, tileSize, terrain, name);
        tileMap[point] = tile;
        add(tile..position = Vector2(i * tileSize, j * tileSize));
      }
    }
  }
  String getTileName(Point<int> point){
    int localId = point.y * mapTileWidth + point.x;
    var tile = tiles.tileMap.map.tileByLocalId(mapFileName.split(".")[0], localId.toInt());
    var type = tile?.properties.getProperty("terrain")?.value;
    var name = tile?.properties.getProperty("name")?.value ?? type;
    return name as String;
  }
  
  Terrain determineTerrainType(Point<int> point){
    int localId = point.y * mapTileWidth + point.x;
    var tile = tiles.tileMap.map.tileByLocalId(mapFileName.split(".")[0], localId.toInt());
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


  void resizeStage() {
    tileMap.forEach((point, tile) {
      tile.resize();
    });
    cursor.resize();
    hud.resize();
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    bool handled = false;

    if (key is RawKeyDownEvent && !cursor.isMoving) {
      Point<int> direction = const Point(0, 0);

      // Check each arrow key independently
      if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
        direction = Point(direction.x - 1, direction.y);
        handled = true;
      }
      if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
        direction = Point(direction.x + 1, direction.y);
        handled = true;
      }
      if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
        direction = Point(direction.x, direction.y - 1);
        handled = true;
      }
      if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
        direction = Point(direction.x, direction.y + 1);
        handled = true;
      }

      Point<int> newTilePosition = Point(cursor.tilePosition.x + direction.x, cursor.tilePosition.y + direction.y);
      cursor.moveTo(newTilePosition);
    }
    if(cursor.isMoving) handled = true;
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }
}
