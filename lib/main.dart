import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/engine/engine.dart';


void main() {
  final game = MoiraGame();
  runApp(
    GameWidget(game: game),
  );
}