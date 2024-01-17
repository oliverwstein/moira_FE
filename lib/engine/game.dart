import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';
import 'package:moira/engine/engine.dart';
class MoiraGame extends FlameGame with KeyboardEvents {
  late Stage stage;
  late TitleCard titleCard;
  static late SpriteSheet portraitSheet;
  static late Map<String, dynamic> unitMap;
  static late Map<String, dynamic> itemMap;
  static late Map<String, dynamic> weaponMap;
  static late Map<String, dynamic> attackMap;
  static late Map<String, dynamic> skillMap;
  static late Map<String, dynamic> classMap;
  YarnProject yarnProject = YarnProject();
  // Static methods to load data from JSON
  static Future<Map<String, dynamic>> loadUnitData() async {
    String jsonString = await rootBundle.loadString('assets/data/units.json');
    return jsonDecode(jsonString);
  }

  static Future<Map<String, dynamic>> loadItemsData() async {
    String jsonString = await rootBundle.loadString('assets/data/items.json');
    return jsonDecode(jsonString);
  }

  static Future<Map<String, dynamic>> loadWeaponsData() async {
    String jsonString = await rootBundle.loadString('assets/data/weapons.json');
    return jsonDecode(jsonString);
  }

  static Future<Map<String, dynamic>> loadAttacksData() async {
    String jsonString = await rootBundle.loadString('assets/data/attacks.json');
    return jsonDecode(jsonString);
  }

  static Future<Map<String, dynamic>> loadSkillsData() async {
    String jsonString = await rootBundle.loadString('assets/data/skills.json');
    return jsonDecode(jsonString);
  }
  static Future<Map<String, dynamic>> loadClassesData() async {
    String jsonString = await rootBundle.loadString('assets/data/classes.json');
    return jsonDecode(jsonString);
  }
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.load('title_card.png');
    await images.load('portraits_spritesheet.png');
    await images.load('dialogue_box_spritesheet.png');
    portraitSheet = SpriteSheet(image: images.fromCache("portraits_spritesheet.png"), srcSize: Vector2(48, 64));
    String prologueDialogueData =
        await rootBundle.loadString('assets/yarn/prologue.yarn');
    yarnProject.parse(prologueDialogueData);
    var testDialogue = Dialogue("jungby_interior_dark2.png");
    var dialogueRunner = DialogueRunner(
        yarnProject: yarnProject, dialogueViews: [testDialogue]);
    add(testDialogue);
    dialogueRunner.startDialogue('Opening_Jungby');
    switchToWorld(testDialogue);
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.load('105 - Prologue (Birth of the Holy Knight).mp3');
    await FlameAudio.audioCache.load('101 - Beginning.mp3');
    FlameAudio.bgm.play('101 - Beginning.mp3');
    unitMap = await loadUnitData();
    itemMap = await loadItemsData();
    weaponMap = await loadWeaponsData();
    attackMap = await loadAttacksData();
    skillMap = await loadSkillsData();
    classMap = await loadClassesData();

    
    
  }

  MoiraGame() : super(world: TitleCard()) {
    titleCard = world as TitleCard;
  }
  void switchToWorld(World newWorld) async {
      world = newWorld; // Switch to the Stage world
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (world is InputHandler && world.isLoaded) {
      return (world as InputHandler).handleKeyEvent(event, keysPressed);
    }
    return KeyEventResult.ignored;
  }
}
