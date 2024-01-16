import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';

class Dialogue extends World with HasGameReference<MoiraGame>, DialogueView implements InputHandler  {
  late final String bgSource;
  late final SpriteComponent _bgSprite;
  final Completer<void> _loadCompleter = Completer<void>();

  Dialogue(this.bgSource);
  @override
  Future<void> onLoad() async {
    ui.Image bgImage = await game.images.load(bgSource);
    _bgSprite = SpriteComponent.fromImage(bgImage);
    add(_bgSprite);
    _bgSprite.anchor = Anchor.center;
    _bgSprite.size = game.canvasSize;
   _loadCompleter.complete();
  }
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
  }
  Future<void> get loadCompleted => _loadCompleter.future;

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
   if (key is RawKeyDownEvent) {
      // @TODO Advance the text.
    }
    return KeyEventResult.handled;
  }
}