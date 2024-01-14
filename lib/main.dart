import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart' as flame_tiled;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';


void main() {
  final game = MoiraGame();
  runApp(
    GameWidget(game: game),
  );
}

abstract class InputHandler {
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed);
}

class MoiraGame extends FlameGame with KeyboardEvents {
  late Stage stage;

  MoiraGame() : super(world: Stage(62, 31)) {
    stage = world as Stage;
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    return stage.handleKeyEvent(key, keysPressed);
  }

}

class Stage extends World with HasGameReference<MoiraGame> implements InputHandler {
  int tilesInRow = 16;
  int tilesInColumn = 12;
  late double tileSize;
  final int mapTileWidth;
  final int mapTileHeight;
  final Map<Point<int>, Tile> tileMap = {};
  late final Cursor cursor;
  late final Hud hud;
  late Vector2 playAreaSize;
  late final flame_tiled.TiledComponent tiles;
  Stage(this.mapTileWidth, this.mapTileHeight);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    calculateTileSize();
    tiles = await flame_tiled.TiledComponent.load('Ch0.tmx', Vector2.all(tileSize));
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
      Point<int> direction = Point(0, 0);

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

class Tile extends PositionComponent with HasGameRef<MoiraGame>{
  final Point<int> point;
  late final TextComponent textComponent;
  Terrain terrain; // e.g., "grass", "water", "mountain"
  String name; // Defaults to the terrain name if there is no name.

  Tile(this.point, double size, this.terrain, this.name) {
    this.size = Vector2.all(size);
    anchor = Anchor.topLeft;

    textComponent = TextComponent(
      text: '(${point.x}, ${point.y})',
      position: Vector2(size / 2, size / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(fontSize: size / 5)),
    );
    add(textComponent);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(textComponent);
  }
  
  void resize() {
    size = Vector2.all(game.stage.tileSize);
  }
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
class Cursor extends PositionComponent with HasGameRef<MoiraGame>, HasVisibility {
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet cursorSheet;
  Point<int> tilePosition = Point<int>(31, 15); // Current tile position
  Vector2 targetPosition; // Target position in pixels
  bool isMoving = false;
  final double speed = 300; // Speed of cursor movement in pixels per second

  Cursor() : targetPosition = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the cursor image and create the animation component
    ui.Image cursorImage = await gameRef.images.load('cursor.png');
    cursorSheet = SpriteSheet.fromColumnsAndRows(
      image: cursorImage,
      columns: 3,
      rows: 1,
    );

    _animationComponent = SpriteAnimationComponent(
      animation: cursorSheet.createAnimation(row: 0, stepTime: 0.2),
      size: Vector2.all(game.stage.tileSize),
    );

    // Set the initial position of the cursor
    
    position = game.stage.tileMap[tilePosition]!.position;
    targetPosition = position.clone();

    // Add the animation component as a child
    add(_animationComponent);
    anchor = Anchor.topLeft;
  }

  void moveTo(Point<int> newTilePosition) {
    // Calculate the bounded position within the full stage size
    Point<int> boundedPosition = Point(
      max(0, min(newTilePosition.x, gameRef.stage.mapTileWidth - 1)),
      max(0, min(newTilePosition.y, gameRef.stage.mapTileHeight - 1))
    );

    // Update only if the position has changed
    if (tilePosition != boundedPosition) {
      tilePosition = boundedPosition;
      targetPosition = game.stage.tileMap[boundedPosition]!.position;
      isMoving = true;
    }
    dev.log("$tilePosition, ${game.stage.tileMap[tilePosition]!.name}, ${game.stage.tileMap[tilePosition]!.terrain}");
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isMoving) {
      Vector2 positionDelta = Vector2.all(0);
      if (position.distanceTo(targetPosition) < 0.1) { // Small threshold
        
        positionDelta = targetPosition - position;
        position = targetPosition;
        isMoving = false;
      } else {
        Vector2 currentPosition = position.clone();
        position.lerp(targetPosition, min(1, speed * dt / position.distanceTo(targetPosition)));
        positionDelta = position - currentPosition;
      }
      Rect boundingBox = game.camera.visibleWorldRect.deflate(game.stage.tileSize);
      if (!boundingBox.contains(position.toOffset())) {
        Rect playArea = Rect.fromPoints(const Offset(0, 0), game.stage.playAreaSize.toOffset());
          if(playArea.contains((position).toOffset())){
            game.camera.moveBy(positionDelta);
          }
          
        }
    }
  }

  void resize() {
    Tile tile = game.stage.tileMap[tilePosition]!;
    size = tile.size;
    position = tile.position;
  }
}

class Hud extends PositionComponent with HasGameReference<MoiraGame>{
  late final TextComponent point;
  late final TextComponent terrain;

  Hud(){
  }
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = Vector2(game.stage.tileSize*12, game.stage.tileSize*9);
    position = Vector2(5, 5);
    anchor = Anchor.topLeft;
    point = TextComponent(
        text: '(${game.stage.cursor.tilePosition.x}, ${game.stage.cursor.tilePosition.y})',
        position: Vector2(size.x / 2, size.y / 3),
        anchor: Anchor.center,
        textRenderer: TextPaint(style: TextStyle(fontSize: size.x / 5)),
      );
    terrain = TextComponent(
        text: '(${game.stage.tileMap[game.stage.cursor.tilePosition]!.name})',
        position: Vector2(size.x / 2, size.y*2 / 3),
        anchor: Anchor.center,
        textRenderer: TextPaint(style: TextStyle(fontSize: size.x / 5)),
      );
      add(point);
      add(terrain);
  }

  @override
  void update(double dt) {
    super.update(dt);
    point.text = '(${game.stage.cursor.tilePosition.x}, ${game.stage.cursor.tilePosition.y})';
    terrain.text = game.stage.tileMap[game.stage.cursor.tilePosition]!.name;
  }

  void resize(){
    size = Vector2(game.stage.tileSize*12, game.stage.tileSize*9);
    point.textRenderer = TextPaint(style: TextStyle(fontSize: size.x / 5));
    point.position = Vector2(size.x / 2, size.y*1 / 3);
    terrain.textRenderer = TextPaint(style: TextStyle(fontSize: size.x / 5));
    terrain.position = Vector2(size.x / 2, size.y*2 / 3);
  }

  @override
  void render(Canvas canvas) {
  super.render(canvas);
  // Draw the HUD box
  final paint = Paint()..color = Color(0xAAFFFFFF); // Semi-transparent white
  canvas.drawRect(size.toRect(), paint);
  // Add more rendering logic here as needed
  }
}