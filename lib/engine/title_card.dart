import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'engine.dart';

class TitleCard extends World with HasGameReference<MoiraGame> implements InputHandler  {
  late final SpriteComponent _spriteComponent;
  final Completer<void> _loadCompleter = Completer<void>();
  @override
  Future<void> onLoad() async {
    _spriteComponent = SpriteComponent.fromImage(game.images.fromCache('title_card.png'));
    add(_spriteComponent);
    _spriteComponent.anchor = Anchor.center;
    _spriteComponent.size = game.canvasSize;
    dev.log("Await Stage!");
    game.stage = await Stage.fromJson('Prologue'); // Load the Stage asynchronously
    dev.log("Stage is initialized!");
   _loadCompleter.complete();
  }

  Future<void> get loadCompleted => _loadCompleter.future;

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
   game.switchToWorld(game.stage);
   return KeyEventResult.handled;
  }
}