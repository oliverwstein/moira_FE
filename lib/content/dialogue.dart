import 'dart:async';
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
  String nodeName;
  late CameraComponent camera;
  late final SpriteComponent _bgSprite;
  late TextBoxComponent? _dialogueTextComponent;
  late TextBoxComponent? _nameTextComponent;
  late final SpriteSheet dBoxSheet;
  late final SpriteAnimationComponent dBoxSprite;
  late Vector2 aspectBox;
  int speakerSide = 0;
  late SpriteComponent leftPortrait = SpriteComponent();
  late SpriteComponent rightPortrait = SpriteComponent();
  late SpriteFontRenderer fontRenderer;
  final Completer<void> _loadCompleter = Completer<void>();
  Completer<void> _forwardCompleter = Completer();
  bool finished = false;

  Dialogue(this.bgSource, this.nodeName);
  
  @override
  Future<void> onLoad() async {
    aspectBox = game.camera.viewfinder.visibleGameSize!;
    ui.Image bgImage = await game.images.load(bgSource);
    _bgSprite = SpriteComponent.fromImage(bgImage,
      position: game.camera.viewfinder.position);
    add(_bgSprite);
    fontRenderer = SpriteFontRenderer.fromFont(game.font);
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
    _bgSprite.add(dBoxSprite);
    _dialogueTextComponent = getBlankTextComponent("dialogue");
    _nameTextComponent = getBlankTextComponent("name");
    dBoxSprite.add(_dialogueTextComponent!);
    dBoxSprite.add(_nameTextComponent!);
    rightPortrait.flipHorizontally();
    getCamera();
    _loadCompleter.complete();
  }

  void getCamera() {
    camera = game.camera;
    game.camera.world = this;
  }

  TextBoxComponent getBlankTextComponent(String type){
    switch (type) {
      case "dialogue":
        double width = 1.9;
        double xPos = .025;
        double yPos = .1;
        return TextBoxComponent(
            text: "",
            textRenderer: fontRenderer,
            align: Anchor.topLeft,
            position: Vector2(aspectBox.x*xPos, aspectBox.y*yPos),
            scale: Vector2(.5, .5),
            boxConfig: TextBoxConfig(
              maxWidth: aspectBox.x*width,
              timePerChar: 0.02,
              growingBox: false,
              margins: const EdgeInsets.all(2),
            ));
      case "name":
        double xPos = .5;
        double yPos = .025;

        return TextBoxComponent(
        text: "",
        textRenderer: fontRenderer,
        anchor: Anchor.topCenter,
        align: Anchor.topCenter,
        position: Vector2(aspectBox.x*xPos, aspectBox.y*yPos),
        scale: Vector2(.5, .5),
        boxConfig: TextBoxConfig(
          maxWidth: 2*aspectBox.x/5,
          margins: const EdgeInsets.all(2),
        ));
      default:
        return TextBoxComponent();
    }
  }

  @override
  Future<void> onDialogueFinish() async {
    super.onDialogueFinish();
    game.switchToWorld(game.stage);
    finished = true;
  }
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    aspectBox = game.camera.viewfinder.visibleGameSize!;
    fontRenderer = SpriteFontRenderer.fromFont(game.font);
    _bgSprite.size = aspectBox;
    dBoxSprite.size = Vector2(aspectBox.x, aspectBox.y/3);
    dBoxSprite.position = Vector2(0, 2*aspectBox.y/3);
    _dialogueTextComponent!.textRenderer = fontRenderer;
    _nameTextComponent!.textRenderer = fontRenderer;
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
    String left = game.yarnProject.nodes[nodeName]!.variables!.getVariable("\$left");
    String right = game.yarnProject.nodes[nodeName]!.variables!.getVariable("\$right");
    getPortraits(line, right, left);
    dBoxSprite.animation = dBoxSheet.createAnimation(row: speakerSide, stepTime: 0.2);
    dBoxSprite.removeAll([_dialogueTextComponent!, _nameTextComponent!]);
    // Create a new dialogue text component with the new line
    aspectBox = game.camera.viewfinder.visibleGameSize!;
    _dialogueTextComponent = getBlankTextComponent("dialogue");
    _dialogueTextComponent!.text = line.text;

    _nameTextComponent = getBlankTextComponent("name");
    if(line.character != null) _nameTextComponent!.text = line.character!.name;
    // Add the new dialogue text component to the bottom box
    dBoxSprite.addAll([_dialogueTextComponent!, _nameTextComponent!]);

    await _advance(line);
    return super.onLineStart(line);
  }

  void getPortraits(DialogueLine line, String right, String left) {
    if(line.character?.name == right) {
      speakerSide = 0;
    } else {
      speakerSide = 1;
    }
    final grayscalePaint = Paint()
      ..colorFilter = const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]);
    
    // Apply or remove the grayscale effect based on canAct
    leftPortrait.paint = speakerSide == 1 ? Paint() : grayscalePaint;
    rightPortrait.paint = speakerSide == 0 ? Paint() : grayscalePaint;
    
    leftPortrait.sprite = game.portraitMap[left]; 
    rightPortrait.sprite = game.portraitMap[right];
    leftPortrait.anchor = Anchor.center;
    leftPortrait.position = Vector2(aspectBox.x*.2, aspectBox.y*(2/3));
    leftPortrait.size = Vector2(aspectBox.x*.2, aspectBox.y*.2);
    rightPortrait.anchor = Anchor.center;
    rightPortrait.position = Vector2(aspectBox.x*.8, aspectBox.y*(2/3));
    rightPortrait.size = Vector2(aspectBox.x*.2, aspectBox.y*.2);
    _bgSprite.add(leftPortrait);
    _bgSprite.add(rightPortrait);
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