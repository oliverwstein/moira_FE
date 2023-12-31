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
  Stage();

  @override
  Future<void> onLoad() async {
    // Load the tiled map and set its anchor to the top-left.
    final tiledMap = await TiledComponent.load('Ch0.tmx', Vector2.all(16));
    tiledMap.anchor = Anchor.topLeft;
    tiledMap.scale = Vector2.all(MyGame().scaleFactor);
    
    // Add the tiled map to the stage.
    add(tiledMap);
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
    for (final child in children) {
      if (child is TiledComponent) {
        child.scale = Vector2.all(scaleFactor);
      }
    }
  }
}
abstract class ScaleObserver {
  void onScaleChanged(double scaleFactor);
}

class MyGame extends FlameGame with KeyboardEvents {
  late FixedAspectRatioViewport viewport;
  late Stage stage;
  late Cursor cursor;
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

  @override
  Future<void> onLoad() async {
    
    await super.onLoad();
    // Your existing onLoad implementation
    viewport = FixedAspectRatioViewport(aspectRatio: canvasSize.x/canvasSize.y);
    camera.viewport = viewport;
    stage = Stage();
    await add(stage);
    addObserver(stage);
    cursor = Cursor();
    add(cursor);
    addObserver(cursor);
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool handled = false;

    // Handling the keyboard events
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        cursor.move(Direction.left);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        cursor.move(Direction.right);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        cursor.move(Direction.up);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        cursor.move(Direction.down);
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

  // A method to move the cursor
  void move(Direction direction) {
    switch (direction) {
      case Direction.left:
        tilePosition = Point(x: tilePosition.x - 1, y: tilePosition.y);
        break;
      case Direction.right:
        tilePosition = Point(x: tilePosition.x + 1, y: tilePosition.y);
        break;
      case Direction.up:
        tilePosition = Point(x: tilePosition.x, y: tilePosition.y - 1);
        break;
      case Direction.down:
        tilePosition = Point(x: tilePosition.x, y: tilePosition.y + 1);
        break;
    }
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
