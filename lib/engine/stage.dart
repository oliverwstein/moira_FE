import 'dart:convert';
import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_tiled/flame_tiled.dart' as flame_tiled;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/content/content.dart';

class Stage extends World with HasGameReference<MoiraGame> implements InputHandler {
  int tilesInRow = 16;
  int tilesInColumn = 14;
  static double tileSize = 16;
  final int mapTileWidth;
  final int mapTileHeight;
  final Point<int> initialPoint;
  final String mapFileName;
  final Map<Point<int>, Tile> tileMap = {};
  Player? activeFaction;
  final Map<String, Player> factionMap = {};
  List<List<Player>> turnOrder = [[],[],[],[]];
  int turn = 1;
  (int, int) turnPhase = (0,0);
  late final Cursor cursor;
  late final MenuManager menuManager;
  late final Hud hud;
  late final UnitHud unitHud;
  late Vector2 playAreaSize;
  late final flame_tiled.TiledComponent tiles;
  dynamic data;
  Stage(this.mapTileWidth, this.mapTileHeight, this.initialPoint, this.mapFileName, this.data);

  Stage._internal(this.mapTileWidth, this.mapTileHeight, this.initialPoint, this.mapFileName, this.data);
  
  bool get freeCursor => activeFaction is HumanPlayer && activeFaction!.takingTurn && !game.eventQueue.processing;

  // Static async method to create an instance from JSON
  static Future<Stage> fromJson(String mapFileName) async {
    // Load the JSON file
    final jsonString = await rootBundle.loadString('assets/data/stages.json');
    final data = json.decode(jsonString)[mapFileName];

    final mapTileWidth = data['mapTileWidth'] as int;
    final mapTileHeight = data['mapTileHeight'] as int;
    final Point<int> initialPoint = Point(data['initialPoint'][0], data['initialPoint'][1]);

    final tmxFile = data['mapFileName'] as String;

    // Create and return a new instance
    return Stage._internal(mapTileWidth, mapTileHeight, initialPoint, tmxFile, data);
  }

  @override
  void update(dt){
    super.update(dt);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    FlameAudio.bgm.stop();
    FlameAudio.bgm.play('105 - Prologue (Birth of the Holy Knight).mp3');
    playAreaSize = Vector2(mapTileWidth*tileSize, mapTileHeight*tileSize);
    tiles = await flame_tiled.TiledComponent.load(mapFileName, Vector2.all(tileSize));
    add(tiles);
    createTiles();
    cursor = Cursor(initialPoint);
    cursor.priority = 10;
    add(cursor);
    hud = Hud();
    unitHud = UnitHud();
    unitHud.priority = 20;
    game.eventQueue.loadEventsFromJson(data['events']);
    menuManager = MenuManager();
    menuManager.priority = 20;
    add(menuManager);
    getCamera();
    children.register<Unit>();
    children.register<Player>();
    children.register<TownCenter>();
    children.register<CastleGate>();
    children.register<CastleFort>();
  }
  void getCamera() {
    debugPrint("Get stage camera");
    game.camera.world = this;
    game.camera.viewport = FixedAspectRatioViewport(aspectRatio: tilesInRow/tilesInColumn); //Vital
    game.camera.viewfinder.visibleGameSize = Vector2(tilesInRow*tileSize, tilesInColumn*tileSize);
    game.camera.viewfinder.position = Vector2(initialPoint.x*tileSize, initialPoint.y*tileSize);
    game.camera.viewfinder.anchor = Anchor.center;
    game.stage.add(hud);
    game.stage.add(unitHud);
    
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
  void blankAllTiles(){
    for (Tile tile in tileMap.values) {
      tile.state = TileState.blank;
    }
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    bool handled = false;
    if(menuManager.isNotEmpty && key is RawKeyDownEvent){
      return menuManager.handleKeyEvent(key, keysPressed);
    }
    if (key is RawKeyDownEvent && !cursor.isMoving && freeCursor) {
      // debugPrint("Stage given key ${key.logicalKey.keyLabel} to handle.");
      switch (key.logicalKey) {
        case (LogicalKeyboardKey.keyA || LogicalKeyboardKey.keyB):
          return menuManager.handleKeyEvent(key, keysPressed);
        default:
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

      }
    if(cursor.isMoving) handled = true;
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }
}
