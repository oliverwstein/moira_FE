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
  ///
  /// Attributes:
  /// - `mapTileWidth`: Width of the map in tiles.
  /// - `mapTileHeight`: Height of the map in tiles.
  /// - `mapSize`: Size of the map in vector units.
  /// - `tiles`: The TiledComponent instance that renders the map.
  /// - `cursor`: Cursor object for user interaction and tile selection.
  /// - `units`: List of all units present on the stage.
  /// - `tilesize`: Size of each tile in the game.
  /// - `tilesMap`: Map from tile coordinates to Tile objects.
  /// - `activeComponent`: Currently active component (Cursor or Unit).
  /// - `turn`: Integer that stores the turn.
  ///
  /// Methods:
  /// - `onLoad()`: Asynchronously loads the stage components including tiles,
  ///    units, and sets up the cursor.
  /// - `update(dt)`: Updates the stage state every game tick.
  /// - `onMount()`: Invoked when the stage is mounted to the game, adds itself
  ///    as an observer for scaling.
  /// - `onRemove()`: Cleans up by removing itself from observers upon removal.
  /// - `onScaleChanged(scaleFactor)`: Updates scaling of tiles when game scale changes.
  /// - `updateTileWithUnit(oldPoint, newPoint, unit)`: Moves units between tiles.
  /// - `determineTerrainType(point)`: Determines the type of terrain at a given tile.
  /// - `_stringToTerrain(input)`: Converts a string to a Terrain enum.
  /// - `keyCommandHandler(command)`: Delegates key commands to the active component.
  /// - `blankAllTiles()`: Resets all tiles to the blank state.
  ///
  /// Constructor:
  /// Initializes the stage with default attributes. It sets up tiles, units, and cursor.
  ///
  /// Usage:
  /// The Stage is a central component of MyGame and is typically instantiated and
  /// managed by it. It should be loaded with necessary resources and will handle
  /// most of the gameplay logic, delegating specific actions to other components.
  ///
  /// Connects with:
  /// - MyGame: As part of the Flame game framework, it is managed and updated by MyGame.
  /// - Tile: Manages individual tiles of the game, storing their state and rendering them.
  /// - Unit: Holds and updates units, manages their interaction with tiles.
  /// - Cursor: Manages user interaction with the game through tile selection and commands.
  late final int mapTileWidth;
  late final int mapTileHeight;
  late final Vector2 mapSize;
  late final flame_tiled.TiledComponent tiles;
  late final Cursor cursor;
  List<Unit> units = [];
  final Vector2 tilesize = Vector2.all(16);
  late Map<Point<int>, Tile> tilesMap = {};
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
        Terrain terrain = determineTerrainType(gridCoord); // Implement this based on your Tiled map properties
        Tile tile = Tile(gridCoord, terrain);
        add(tile);
        gameRef.addObserver(tile);
        tilesMap[Point(x, y)] = tile;
      }
    }
    String unitDataJsonString = await loadJsonData('assets/data/units.json');
    units.add(Unit.fromJSON(const Point(59, 10), 'arden', unitDataJsonString));
    units.add(Unit.fromJSON(const Point(60, 12), 'alec', unitDataJsonString));
    units.add(Unit.fromJSON(const Point(58, 12), 'noish', unitDataJsonString));
    units.add(Unit.fromJSON(const Point(59, 13), 'sigurd', unitDataJsonString));

    units.add(Unit.fromJSON(const Point(56, 12), 'brigand', unitDataJsonString));
    units.add(Unit.fromJSON(const Point(55, 13), 'brigand', unitDataJsonString));
    units.add(Unit.fromJSON(const Point(55, 11), 'brigand', unitDataJsonString));
     
    for (Unit unit in units) {
      add(unit);
      tilesMap[unit.tilePosition]?.setUnit(unit);
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
