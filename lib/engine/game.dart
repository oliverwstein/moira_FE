import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/engine/engine.dart';
class MoiraGame extends FlameGame with KeyboardEvents {
  late Stage stage;

  MoiraGame() : super(world: Stage(62, 31)) {
    stage = world as Stage;
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    return stage.handleKeyEvent(event, keysPressed);
  }
}
