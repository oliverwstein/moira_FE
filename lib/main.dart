import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'engine/engine.dart';
void main() {
  final game = MyGame();
  runApp(
    GameWidget(game: game),
  );
}
