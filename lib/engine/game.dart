import 'dart:developer' as dev;

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/engine/engine.dart';
class MoiraGame extends FlameGame with KeyboardEvents {
  late Stage stage;
  late TitleCard titleCard;

  MoiraGame() : super(world: TitleCard()) {
    titleCard = world as TitleCard;
  }
  void switchToWorld(String worldName) async {
    if (worldName == 'Stage') {
      world = stage; // Switch to the Stage world
    }
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (world is InputHandler && world.isLoaded) {
      return (world as InputHandler).handleKeyEvent(event, keysPressed);
    }
    return KeyEventResult.ignored;
  }
}
