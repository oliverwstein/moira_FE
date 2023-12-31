import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/widgets.dart';

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

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Add your world or stage to the game.
    await add(MyStage());
  }
}

void main() {
  // Define the desired size of your game.
  final gameSize = Vector2(800, 600); // Change this to your desired game size.

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
