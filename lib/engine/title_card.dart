import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'engine.dart';

class TitleCard extends World with HasGameReference<MoiraGame> implements InputHandler  {
  late final SpriteComponent _spriteComponent;
  final Completer<void> _loadCompleter = Completer<void>();
  @override
  Future<void> onLoad() async {
    final imagesLoader = Images();
    ui.Image titleCardImage = await imagesLoader.load('title_card.png');
    _spriteComponent = SpriteComponent.fromImage(titleCardImage);
    add(_spriteComponent);
    _spriteComponent.anchor = Anchor.center;
    dev.log("Await Stage!");
    game.stage = await Stage.fromJson('Prologue'); // Load the Stage asynchronously
    dev.log("Stage is initialized!");
   _loadCompleter.complete();
  }

  Future<void> get loadCompleted => _loadCompleter.future;

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
   game.switchToWorld("Stage");
   return KeyEventResult.handled;
  }
}