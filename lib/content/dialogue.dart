import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';

class Dialogue extends World with HasGameReference<MoiraGame>, DialogueView implements InputHandler {
  late final String bgSource;
  late final SpriteComponent _bgSprite;
  late final TextBoxComponent _dialogueTextComponent;
  late final SpriteComponent bottomBox;
  late final SpriteComponent topBox;
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
    var aspectBox = Vector2(min(game.size.x, game.size.y*(4/3)), min(game.size.y, game.size.x*(3/4)));
    _bgSprite.size = aspectBox;
    _bgSprite.anchor = Anchor.center;

    SpriteSheet dialogueBoxes = SpriteSheet(image: game.images.fromCache("dialogue_boxes.png"), srcSize: Vector2(648, 164));
    bottomBox = SpriteComponent(
      sprite:dialogueBoxes.getSpriteById(0), 
      anchor: Anchor.topLeft,
      size: Vector2(aspectBox.x, aspectBox.y/3),
      position: Vector2(0, 2*aspectBox.y/3));
    topBox = SpriteComponent(
      sprite:dialogueBoxes.getSpriteById(1), 
      anchor: Anchor.topLeft,
      size: Vector2(aspectBox.x, aspectBox.y/3));
    _dialogueTextComponent = TextBoxComponent(
      text: "Midir: My lady, the castle is surrounded and they will overrun us soon. I'm sorry.",
      textRenderer: TextPaint(style: TextStyle(fontSize: aspectBox.x / 25)),
      size: Vector2(aspectBox.x*(.72), aspectBox.y*(.2)),
      boxConfig: TextBoxConfig(
        maxWidth: aspectBox.x*(2/3),
        timePerChar: 0.05,
        growingBox: true,
        margins: EdgeInsets.all(5),
      ));

    bottomBox.add(_dialogueTextComponent);
    _bgSprite.add(bottomBox);
    _bgSprite.add(topBox);

    _loadCompleter.complete();
  }
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    var aspectBox = Vector2(min(size.x, size.y*(4/3)), min(size.y, size.x*(3/4)));
    _bgSprite.size = aspectBox;
    bottomBox.size = Vector2(aspectBox.x, aspectBox.y/3);
    bottomBox.position = Vector2(0, 2*aspectBox.y/3);
    topBox.size = Vector2(aspectBox.x, aspectBox.y/3);
    _dialogueTextComponent.size = Vector2(aspectBox.x*(.72), aspectBox.y*(.2));
    _dialogueTextComponent.position = Vector2(aspectBox.x*(1/4), bottomBox.y*(.15));
    _dialogueTextComponent.textRenderer =  TextPaint(style: TextStyle(fontSize: aspectBox.x / 25));
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