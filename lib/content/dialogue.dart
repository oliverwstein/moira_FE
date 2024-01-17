import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';

class Dialogue extends World with HasGameReference<MoiraGame>, DialogueView implements InputHandler {
  late final String bgSource;
  late final SpriteComponent _bgSprite;
  late TextBoxComponent? _dialogueTextComponent;
  late TextBoxComponent? _nameTextComponent;
  late final SpriteSheet dBoxSheet;
  late final SpriteAnimationComponent dBoxSprite;
  late Vector2 aspectBox;
  int speakerSide = 0;
  final Completer<void> _loadCompleter = Completer<void>();
  Completer<void> _forwardCompleter = Completer();

  Dialogue(this.bgSource);

  TextBoxComponent getBlankTextComponent(String type){
    switch (type) {
      case "dialogue":
        double width = .95;
        double xPos = .025;
        double yPos = .1;
        return TextBoxComponent(
            text: "",
            textRenderer: SpriteFontRenderer.fromFont(game.font),
            align: Anchor.topLeft,
            position: Vector2(aspectBox.x*xPos, aspectBox.y*yPos),
            boxConfig: TextBoxConfig(
              maxWidth: aspectBox.x*width,
              timePerChar: 0.05,
              growingBox: true,
              margins: EdgeInsets.all(5),
            ));
      case "name":
        double xPos = .5;
        double yPos = .05;

        return TextBoxComponent(
        text: "",
        textRenderer: SpriteFontRenderer.fromFont(game.font),
        anchor: Anchor.topCenter,
        align: Anchor.topCenter,
        position: Vector2(aspectBox.x*xPos, aspectBox.y*yPos),
        boxConfig: TextBoxConfig(
          maxWidth: 100,
          margins: EdgeInsets.all(5),
        ));
      default:
        return TextBoxComponent();
    }
  }
  @override
  Future<void> onDialogueStart() async {
    ui.Image bgImage = await game.images.load(bgSource);
    _bgSprite = SpriteComponent.fromImage(bgImage);
    add(_bgSprite);
    aspectBox = Vector2(min(game.size.x, game.size.y*(4/3)), min(game.size.y, game.size.x*(3/4)));
    _bgSprite.size = aspectBox;
    _bgSprite.anchor = Anchor.center;
    dBoxSheet = SpriteSheet.fromColumnsAndRows(
      image: game.images.fromCache("dialogue_box_spritesheet.png"),
      columns: 2,
      rows: 2,
    );
    dBoxSprite = SpriteAnimationComponent(
      animation: dBoxSheet.createAnimation(row: speakerSide, stepTime: 0.2),
      size: Vector2(aspectBox.x, aspectBox.y*.4),
    );

    _dialogueTextComponent = getBlankTextComponent("dialogue");
    _nameTextComponent = getBlankTextComponent("name");
    dBoxSprite.add(_dialogueTextComponent!);
    dBoxSprite.add(_nameTextComponent!);
    _bgSprite.add(dBoxSprite);

    _loadCompleter.complete();
  }
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    aspectBox = Vector2(min(size.x, size.y*(4/3)), min(size.y, size.x*(3/4)));
    _bgSprite.size = aspectBox;
    dBoxSprite.size = Vector2(aspectBox.x, aspectBox.y/3);
    dBoxSprite.position = Vector2(0, 2*aspectBox.y/3);
    // _dialogueTextComponent!.size = Vector2(aspectBox.x*(.90), aspectBox.y*(.2));
    // _dialogueTextComponent!.position = Vector2(aspectBox.x*(.05), dBoxSprite.y*(.13));
    // _dialogueTextComponent!.textRenderer = TextPaint(style: TextStyle(
    //     fontSize: aspectBox.x / 25,
    //     color: ui.Color.fromARGB(255, 18, 1, 1)));

    // _nameTextComponent!.size = Vector2(aspectBox.x*(.35), aspectBox.y*(.2));
    // _nameTextComponent!.position = Vector2(aspectBox.x*(.5), aspectBox.y*(.03));
    // _nameTextComponent!.textRenderer = TextPaint(style: TextStyle(
    //     fontSize: aspectBox.x / 25,
    //     color: ui.Color.fromARGB(255, 18, 1, 1)));
  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    if (key is RawKeyDownEvent) {
      if (!_forwardCompleter.isCompleted){
        _forwardCompleter.complete();
      }
    }
    return KeyEventResult.handled;
  }
  @override
  FutureOr<bool> onLineStart(DialogueLine line) async {
    dBoxSprite.removeAll([_dialogueTextComponent!, _nameTextComponent!]);
    // Create a new dialogue text component with the new line
    aspectBox = Vector2(min(game.size.x, game.size.y*(4/3)), min(game.size.y, game.size.x*(3/4)));
    _dialogueTextComponent = getBlankTextComponent("dialogue");
    _dialogueTextComponent!.text = line.text;

    _nameTextComponent = getBlankTextComponent("name");
    if(line.character != null) _nameTextComponent!.text = line.character!.name;
    // Add the new dialogue text component to the bottom box
    dBoxSprite.addAll([_dialogueTextComponent!, _nameTextComponent!]);

    await _advance(line);
    return super.onLineStart(line);
  }
  @override
  FutureOr<void> onLineFinish(DialogueLine line) async {
    _forwardCompleter = Completer();
    return super.onLineFinish(line);
  }
  Future<void> _advance(DialogueLine line) {
    var characterName = line.character?.name ?? '';
    debugPrint('$characterName: ${line.text}');
    return _forwardCompleter.future;
  }
}