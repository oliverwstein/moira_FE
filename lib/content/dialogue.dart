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

class Dialogue extends PositionComponent with HasGameReference<MoiraGame>, DialogueView implements InputHandler {
  final String? bgSource;
  String nodeName;
  late CameraComponent camera;
  late SpriteComponent? _bgSprite;
  late TextBoxComponent? _dialogueTextComponent;
  late TextBoxComponent? _nameTextComponent;
  late final SpriteSheet dBoxSheet;
  late final SpriteAnimationComponent dBoxSprite;
  late Vector2 aspectBox;
  Map<String, String> tags = {};
  int speakerSide = 0;
  late SpriteComponent leftPortrait = SpriteComponent();
  late SpriteComponent rightPortrait = SpriteComponent();
  late SpriteFontRenderer fontRenderer;
  final Completer<void> _loadCompleter = Completer<void>();
  Completer<void> _forwardCompleter = Completer();
  bool finished = false;

  Dialogue(this.bgSource, this.nodeName);
  @override
  void update(dt){
    position = game.camera.viewfinder.position;
  }
  @override
  Future<void> onLoad() async {
    tags = game.yarnProject.nodes[nodeName]!.tags;
    debugPrint("tags: ${tags.entries}");
    aspectBox = Vector2(Stage.tileSize*game.stage.tilesInRow, Stage.tileSize*game.stage.tilesInColumn);
    position = game.camera.viewfinder.position;
    size = aspectBox;
    anchor = Anchor.center;
    if(bgSource != null) {
      ui.Image bgImage = await game.images.load(bgSource!);
      _bgSprite = SpriteComponent.fromImage(bgImage,
      size: aspectBox);
      
      add(_bgSprite!);
    }
   
    fontRenderer = SpriteFontRenderer.fromFont(game.dialogueFont);
    dBoxSheet = SpriteSheet.fromColumnsAndRows(
      image: game.images.fromCache("dialogue_box_spritesheet.png"),
      columns: 2,
      rows: 2,
    );
    dBoxSprite = SpriteAnimationComponent(
      animation: dBoxSheet.createAnimation(row: speakerSide, stepTime: 0.2),
      size: Vector2(aspectBox.x, aspectBox.y*.4),
      position: Vector2(aspectBox.x/2, aspectBox.y*.6),
      anchor: Anchor.topCenter
    );
    add(dBoxSprite);
    
    _dialogueTextComponent = getBlankTextComponent("dialogue");
    _nameTextComponent = getBlankTextComponent("name");
    dBoxSprite.add(_dialogueTextComponent!);
    dBoxSprite.add(_nameTextComponent!);
    rightPortrait.flipHorizontally();
    _loadCompleter.complete();
  }

  TextBoxComponent getBlankTextComponent(String type){
    double scaler = 1.2;
    switch (type) {
      case "dialogue":
        double width = .95;
        double xPos = .025;
        double yPos = .1;
        return TextBoxComponent(
            text: "",
            textRenderer: fontRenderer,
            align: Anchor.topLeft,
            position: Vector2(aspectBox.x*xPos, aspectBox.y*yPos),
            scale: Vector2.all(1/scaler),
            boxConfig: TextBoxConfig(
              maxWidth: aspectBox.x*width*scaler,
              timePerChar: 0.02,
              growingBox: false,
              margins: const EdgeInsets.all(5),
            ));
      case "name":
        double xPos = .5;
        double yPos = .035*scaler;
        return TextBoxComponent(
        text: "",
        textRenderer: fontRenderer,
        anchor: Anchor.topCenter,
        align: Anchor.topCenter,
        position: Vector2(aspectBox.x*xPos, aspectBox.y*yPos),
        scale: Vector2.all(1/scaler),
        boxConfig: TextBoxConfig(
          maxWidth: 2*aspectBox.x/scaler,
          margins: const EdgeInsets.all(2),
        ));
      default:
        return TextBoxComponent();
    }
  }

  @override
  Future<void> onDialogueFinish() async {
    super.onDialogueFinish();
    finished = true;
    game.yarnProject.nodes.remove(nodeName);
    game.stage.menuManager.last!.close();
    if(game.stage.menuManager.last is UnitActionMenu){
      (game.stage.menuManager.last as UnitActionMenu).committed = true;
      (game.stage.menuManager.last as UnitActionMenu).options.remove("Talk");
    }
    removeFromParent();
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
    leftPortrait.position = Vector2(aspectBox.x*.2, aspectBox.y*.618);
    leftPortrait.size = Vector2(aspectBox.x*.2, aspectBox.y*.2);
    rightPortrait.anchor = Anchor.center;
    rightPortrait.position = Vector2(aspectBox.x*.8, aspectBox.y*.618);
    rightPortrait.size = Vector2(aspectBox.x*.2, aspectBox.y*.2);
    add(leftPortrait);
    add(rightPortrait);
  }
  @override
  FutureOr<void> onLineFinish(DialogueLine line) async {
    _forwardCompleter = Completer();
    return super.onLineFinish(line);
  }
  Future<void> _advance(DialogueLine line) {
    // var characterName = line.character?.name ?? '';
    // debugPrint('$characterName: ${line.text}');
    return _forwardCompleter.future;
  }
}

class DialogueEvent extends Event{
  static List<Event> observers = [];
  String? bgName;
  String nodeName;
  late DialogueMenu menu;
  DialogueEvent(this.nodeName, {this.bgName, Trigger? trigger, String? name}) : super(trigger: trigger, name: name);

  static void initialize(EventQueue queue) {
    queue.registerClassObserver<UnitDeathEvent>((catalystEvent) {
      if (queue == catalystEvent.game.eventQueue && catalystEvent.game.yarnProject.nodes.keys.contains("${catalystEvent.unit.name}_Death_Quote")) {
        debugPrint("Death Quote found for ${catalystEvent.unit.name}");
        // Trigger UnitDeathEvent
        var deathQuoteEvent = DialogueEvent("${catalystEvent.unit.name}_Death_Quote");
        queue.addEventBatchToHead([deathQuoteEvent]);
      }
    });
    queue.registerClassObserver<StartCombatEvent>((catalystEvent) {
      if (catalystEvent.game.yarnProject.nodes.keys.contains("${catalystEvent.combat.attacker.name}_${catalystEvent.combat.defender.name}_Combat_Quote")) {
        debugPrint("Combat Quote found for ${catalystEvent.combat.attacker.name} against ${catalystEvent.combat.defender.name}");
        var combatQuoteEvent = DialogueEvent("${catalystEvent.combat.attacker.name}_${catalystEvent.combat.defender.name}_Combat_Quote");
        queue.addEventBatchToHead([combatQuoteEvent]);
      }
    });
    queue.registerClassObserver<VisitEvent>((catalystEvent) {
      if (catalystEvent.game.yarnProject.nodes.keys.contains("Town_(${catalystEvent.town.point.x},${catalystEvent.town.point.y})_Visit")) {
        debugPrint("Visit Conversation found for Town ${catalystEvent.town.point}");
        Node node = catalystEvent.game.yarnProject.nodes["Town_(${catalystEvent.town.point.x},${catalystEvent.town.point.y})_Visit"]!;
        debugPrint("Dialogue Tags are: ${node.tags.entries}");
        for(var tag in node.tags.entries){
          debugPrint("Tag: ${tag.key}, ${tag.value}");
          Map<String, String> eventData = {"type": tag.key};
          switch (tag.key) {
            case "AddItemEvent":
              eventData[tag.value.split(".")[0]] = tag.value.split(".")[1].replaceAll("_", " ");
              eventData["unit"] = catalystEvent.unit.name;
              Event event = catalystEvent.game.eventQueue.loadEventfromJson(eventData);
              catalystEvent.game.eventQueue.addEventBatchToHead([event]);
              break;
            default:
          }
          
          
        }
        var dialogueEvent = DialogueEvent("Town_(${catalystEvent.town.point.x},${catalystEvent.town.point.y})_Visit");
        queue.addEventBatchToHead([dialogueEvent]);
      }
    });
  }

  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("DialogueEvent execution $nodeName $bgName");
    menu = DialogueMenu(nodeName, bgName);
    game.stage.menuManager.pushMenu(menu);

  }
  @override
  bool checkComplete() {
    if(checkStarted()) {
      game.eventQueue.dispatchEvent(this);
      return menu.dialogue.finished;}
    return false;
  } 
}