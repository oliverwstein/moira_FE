import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
enum Direction {
  up,
  down,
  left,
  right
}

class MyStage extends Component with HasGameRef<FlameGame> {
  MyStage();

  @override
  Future<void> onLoad() async {
    // Load the tiled map and set its anchor to the top-left.
    final tiledMap = await TiledComponent.load('Ch0.tmx', Vector2.all(16));
    tiledMap.anchor = Anchor.topLeft;
    
    // Add the tiled map to the stage.
    add(tiledMap);
  }
}

class MyGame extends FlameGame with KeyboardEvents {
  late Cursor cursor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Your existing onLoad implementation
    await add(MyStage());
    cursor = Cursor();
    add(cursor);
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
      }
    }

    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }
}

void main() {
  // Define the desired size of your game.
  final gameSize = Vector2(1024, 512); // Change this to your desired game size.

  // Create a FixedResolutionViewport with the gameSize.
  final viewport = FixedResolutionViewport(resolution: gameSize);

  // Instantiate your game with the viewport.
  final game = MyGame()
    ..camera.viewport = viewport; // Attach the viewport to the camera as well.

  // Run the app with your game.
  runApp(
    GameWidget(game: game),
  );
}
class Cursor extends PositionComponent {
  // The size of each tile in your map
  static const int tileSize = 16;
  // The cursor's position in terms of tiles, not pixels
  Point tilePosition = Point(x:4, y:15);

  Cursor() {
    // Set the initial size and position of the cursor, perhaps based on the tile size
    width = height = tileSize.toDouble(); // Make the cursor the same size as a tile
    x = tilePosition.x*tileSize;
    y = tilePosition.y*tileSize;
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

  // Override render method to visually represent the cursor
  @override
  void render(Canvas canvas) {
    // Render the cursor with a simple rectangle or your own cursor image
    canvas.drawRect(size.toRect(), Paint()..color = Color(0xFFFFFFFF)); // A white cursor for example
  }
}
