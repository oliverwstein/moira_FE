import 'dart:ui' as ui;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
enum Direction {
  up,
  down,
  left,
  right
}

class Stage extends Component with HasGameRef<MyGame> {
  late final int mapTileWidth;
  late final int mapTileHeight;
  late final Cursor cursor;  // Declare Cursor here

  Stage();

  @override
  Future<void> onLoad() async {
    final tiledMap = await TiledComponent.load('Ch0.tmx', Vector2.all(16));
    tiledMap.anchor = Anchor.topLeft;
    tiledMap.scale = Vector2.all(gameRef.scaleFactor);

    mapTileHeight = tiledMap.tileMap.map.height;
    mapTileWidth = tiledMap.tileMap.map.width;

    add(tiledMap);

    cursor = Cursor();
    add(cursor);
    gameRef.addObserver(cursor);
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
      if (child is TiledComponent) {
        child.scale = Vector2.all(scaleFactor);
      }
    }
  }
}

class Cursor extends PositionComponent with HasGameRef<MyGame> {
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet cursorSheet;
  // The size of each tile in your map
  // The cursor's position in terms of tiles, not pixels
  Point tilePosition = Point(x:4, y:15);
  late double tileSize;

  Cursor() {
    // Initial size, will be updated in onLoad
    tileSize = 16 * MyGame().scaleFactor;
  }

  @override
  Future<void> onLoad() async {
    // Load the cursor image and create the animation component
    ui.Image cursorImage = await gameRef.images.load('cursor.png');
    cursorSheet = SpriteSheet.fromColumnsAndRows(
      image: cursorImage,
      columns: 3,
      rows: 1,
    );

    _animationComponent = SpriteAnimationComponent(
      animation: cursorSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(tileSize), // Use tileSize for initial size
    );

    // Add the animation component as a child
    add(_animationComponent);

    // Set the initial size and position of the cursor
    size = Vector2.all(tileSize);
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }

  Vector2 get worldPosition {
        return Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
    }

  void move(Direction direction) {
    // Assuming parent is always a Stage which is the case in this architecture
    Stage stage = parent as Stage;

    double newX = tilePosition.x;
    double newY = tilePosition.y;

    switch (direction) {
      case Direction.left:
        newX -= 1;
        break;
      case Direction.right:
        newX += 1;
        break;
      case Direction.up:
        newY -= 1;
        break;
      case Direction.down:
        newY += 1;
        break;
    }

    // Clamp the new position to ensure it's within the bounds of the map
    newX = newX.clamp(0, stage.mapTileWidth - 1);
    newY = newY.clamp(0, stage.mapTileHeight - 1);

    // Update tilePosition if it's within the map
    tilePosition = Point(x: newX, y: newY);

    // Update the pixel position of the cursor
    x = tilePosition.x * tileSize;
    y = tilePosition.y * tileSize;
  }
  @override
  void onMount() {
    super.onMount();
    gameRef.addObserver(this);
  }

  @override
  void onRemove() {
    gameRef.removeObserver(this);
    super.onRemove();
  }
  
  @override
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the cursor itself
    _animationComponent.size = Vector2.all(tileSize); // Update animation component size

    // Update position based on new tileSize
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }

}

abstract class ScaleObserver {
  void onScaleChanged(double scaleFactor);
}

class MyGame extends FlameGame with KeyboardEvents {
  late MaxViewport viewport;
  late Stage stage;
  // late Cursor cursor;
  double _scaleFactor = 1;
  final List _observers = [];
  double get scaleFactor => _scaleFactor;

  set scaleFactor(double value) {
    if (_scaleFactor != value) {
      _scaleFactor = value;
      for (var observer in _observers) {
        observer.onScaleChanged(_scaleFactor);
      }
    }
  }

  void addObserver(observer) {
    _observers.add(observer);
  }

  void removeObserver(observer) {
    _observers.remove(observer);
  }
  void centerCameraOnCursor() {
        if (stage.cursor.parent != null) { // Ensure cursor is loaded and has a parent
            Vector2 cursorPosition = stage.cursor.worldPosition;
            camera.viewfinder.position = cursorPosition; // Center viewfinder on cursor
        }
    }

  @override
    void update(double dt) {
        super.update(dt);
        centerCameraOnCursor(); // Keep the camera centered on the cursor
    }

  @override
  Future<void> onLoad() async {
    
    await super.onLoad();
    // Your existing onLoad implementation
    viewport = MaxViewport();
    camera.viewport = viewport;
    stage = Stage();
    await add(stage);
    addObserver(stage);
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool handled = false;

    // Handling the keyboard events
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        stage.cursor.move(Direction.left);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        stage.cursor.move(Direction.right);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        stage.cursor.move(Direction.up);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        stage.cursor.move(Direction.down);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.equal) { // "+" key for zooming in
        scaleFactor *= 1.1;//.clamp(0.5, 2.0); // Zoom in and clamp between 0.5x and 2x
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.minus) { // "-" key for zooming out
        scaleFactor *= 0.9;//.clamp(0.5, 2.0); // Zoom out and clamp
        handled = true;
      }
    }

    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }
}

void main() {
  final game = MyGame();
  runApp(
    GameWidget(game: game),
  );
}
