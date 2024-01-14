import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
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

  MoiraGame() : super(world: Stage(62, 30)) {
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
  late Vector2 playAreaSize;
  Stage(this.mapTileWidth, this.mapTileHeight);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    calculateTileSize();
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
        Tile tile = Tile(point, tileSize);
        tileMap[point] = tile;
        add(tile..position = Vector2(i * tileSize, j * tileSize));
      }
    }
  }


  void resizeStage() {
    tileMap.forEach((point, tile) {
      tile.resize();
    });
    cursor.resize();
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

  Tile(this.point, double size) {
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
    dev.log("$tilePosition");
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
          game.camera.moveBy(positionDelta);
        }
    }
  }

  void resize() {
    Tile tile = game.stage.tileMap[tilePosition]!;
    size = tile.size;
    position = tile.position;
  }
}