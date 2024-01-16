import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';

class Dialogue extends World with HasGameReference<MoiraGame>, DialogueView implements InputHandler {
  late final String bgSource;
  late final SpriteComponent _bgSprite;
  late final TextBoxComponent _dialogueTextComponent;
  final Completer<void> _loadCompleter = Completer<void>();
  Completer<void> _forwardCompleter = Completer();
  final TextPaint _dialoguePaint = TextPaint(
    style: const TextStyle(
      backgroundColor: Color.fromARGB(180, 85, 84, 84),
      fontSize: 24,
      color: Colors.white,
    ),
  );

  Dialogue(this.bgSource);

  @override
  Future<void> onDialogueStart() async {
    ui.Image bgImage = await game.images.load(bgSource);
    _bgSprite = SpriteComponent.fromImage(bgImage);
    add(_bgSprite);
    _bgSprite.anchor = Anchor.center;
    _bgSprite.size = game.canvasSize;

    // Initialize the dialogue text component
    _dialogueTextComponent = TextBoxComponent(
      text: 'Test',
      priority: 10,
    );
    add(_dialogueTextComponent);
    _loadCompleter.complete();
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    if (key is RawKeyDownEvent) {
      _forwardCompleter.complete();
    }
    return KeyEventResult.handled;
  }
  @override
  FutureOr<bool> onLineStart(DialogueLine line) async {
    _forwardCompleter = Completer();
    await _advance(line);
    return super.onLineStart(line);
  }
  Future<void> _advance(DialogueLine line) {
    var characterName = line.character?.name ?? '';
    var dialogueLineText = '$characterName: ${line.text}';
    _dialogueTextComponent.text = dialogueLineText;
    debugPrint('debug: $dialogueLineText');
    return _forwardCompleter.future;
  }
}