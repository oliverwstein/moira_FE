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
  late InputHandler currentInputHandler;
  int tilesInRow = 16;
  int tilesInColumn = 12;
  late double tileSize;
  final Stage stage = Stage(62, 30);

  @override
  Future<void> onLoad() async {
    calculateTileSize();
    await super.onLoad();
    add(stage);
    currentInputHandler = stage;

  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    calculateTileSize();
    if (children.contains(stage) && stage.isLoaded) {
      stage.resizeTiles();
    }
  }
  void calculateTileSize() {
    tileSize = min(size.x / tilesInRow, size.y / tilesInColumn);
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    return currentInputHandler.handleKeyEvent(key, keysPressed);
  }

  void switchInputHandler(InputHandler newHandler) {
    currentInputHandler = newHandler;
  }
  
}

class Stage extends PositionComponent with HasGameRef<MoiraGame> implements InputHandler {
  final int mapTileWidth;
  final int mapTileHeight;
  final Map<Point<int>, Tile> tileMap = {};
  late final Cursor cursor;

  Stage(this.mapTileWidth, this.mapTileHeight) {
    cursor = Cursor();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    createTiles();
    add(cursor);
  }

  void createTiles() {
    for (int i = 0; i < mapTileHeight; i++) {
      for (int j = 0; j < mapTileWidth; j++) {
        Point<int> point = Point(i, j);
        Tile tile = Tile(point, gameRef.tileSize);
        tileMap[point] = tile;
        add(tile..position = Vector2(i * gameRef.tileSize, j * gameRef.tileSize));
      }
    }
  }

  void resizeTiles() {
    double tileSize = gameRef.tileSize;

    tileMap.forEach((point, tile) {
      tile.size = Vector2.all(tileSize);
      tile.position = Vector2(point.x * tileSize, point.y * tileSize);
      tile.textComponent.position = Vector2(tileSize / 2, tileSize / 2);
      tile.textComponent.textRenderer = TextPaint(style: TextStyle(fontSize: tileSize / 5));
    });

    cursor.resize(tileSize); // Ensure cursor is initialized before calling resize
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

      dev.log('Direction: ${direction.x}, ${direction.y}');
      Point<int> newTilePosition = Point(cursor.tilePosition.x + direction.x, cursor.tilePosition.y + direction.y);
      cursor.moveTo(newTilePosition);
    }
    if(cursor.isMoving) handled = true;
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }
  
}



class Tile extends PositionComponent {
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
}

class Cursor extends PositionComponent with HasGameRef<MoiraGame>, HasVisibility {
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet cursorSheet;
  Point<int> tilePosition = Point<int>(5, 5); // Current tile position
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
      size: Vector2.all(gameRef.tileSize),
    );

    // Set the initial position of the cursor
    position = Vector2(tilePosition.x.toDouble(), tilePosition.y.toDouble()) * gameRef.tileSize;
    targetPosition = position.clone();

    // Add the animation component as a child
    add(_animationComponent);
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
      targetPosition = Vector2(boundedPosition.x.toDouble(), boundedPosition.y.toDouble()) * gameRef.tileSize;
      isMoving = true;
    }
  }

  @override
void update(double dt) {
  super.update(dt);
  if (isMoving) {
    position.lerp(targetPosition, min(1, speed * dt / position.distanceTo(targetPosition)));
    if (position.distanceTo(targetPosition) < 0.5) { // Small threshold
      position = targetPosition;
      isMoving = false;
    }
  }
}

  void resize(double tileSize) {
    size = Vector2.all(tileSize); // Update the cursor's size
    _animationComponent.size = Vector2.all(tileSize); // Update the animation component's size
    position = Vector2(tilePosition.x.toDouble(), tilePosition.y.toDouble()) * tileSize; // Reposition the cursor
  }
}