import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';
import 'package:moira/content/jenny_character.dart';

class Dialogue extends PositionComponent with HasGameReference<MoiraGame>, DialogueView implements InputHandler  {
  late final String bgSource;
  late final SpriteComponent _bgSprite;
  late List<CharacterComponent> castList;
  final Completer<void> _loadCompleter = Completer<void>();
  @override
  Future<void> onLoad() async {
    ui.Image bgImage = await game.images.load(bgSource);
    _bgSprite = SpriteComponent.fromImage(bgImage);
    add(_bgSprite);
    _bgSprite.anchor = Anchor.center;
   _loadCompleter.complete();
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