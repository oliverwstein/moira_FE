import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame/text.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';
class MoiraGame extends FlameGame with KeyboardEvents {
  late Stage stage;
  late TitleCard titleCard;
  late SpriteFont dialogueFont;
  late SpriteFont hudFont;
  final EventQueue eventQueue = EventQueue();
  final EventQueue combatQueue = EventQueue();
  Map<String, Sprite> portraitMap = {};
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
    await images.load('unit_circle.png');
    await images.load('portraits_spritesheet.png');
    await images.load('dialogue_box_spritesheet.png');
    await images.load('alphabet_spritesheet.png');
    String alphabetOrder = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,?!'-\"º:;()0123456789\$%&×+/“”=[♪]~ ";
    Map<String, int> widths = {
      "A": 9, "B": 8, "C": 8, "D": 8, "E": 7, "F": 7, "G": 8, "H": 8,
      "I": 4, "J": 7, "K": 9, "L": 7, "M": 10, "N": 8, "O": 8, "P": 8, 
      "Q": 8, "R": 8, "S": 8, "T": 8, "U": 8, "V": 9, "W": 10, "X": 8,
      "Y": 8, "Z": 7,
      "a": 8, "b": 7, "c": 7, "d": 7, "e": 7, "f": 6, 
      "g": 7, "h": 6, "i": 4, "j": 5, "k": 7, "l": 4, "m": 10, "n": 8, 
      "o": 7, "p": 7, "q": 7, "r": 6, "s": 7, "t": 6, "u": 7, "v": 8, 
      "w": 10, "x": 7, "y": 7, "z": 7,
      ".": 5, ",": 5, "?": 7, "!": 5, "'": 5, "-": 6, "\"": 6, "º": 6, ":": 5, ";": 5, "(": 6, ")": 6, 
      "0": 8, "1": 5, "2": 7, "3": 7, "4": 8, "5": 7, "6": 7, "7": 7, "8": 7, "9": 7, 
      "\$": 8, "%": 10, "&": 10, "×": 6, "+": 8, "/": 7, "“": 6, "”": 6,
      "=": 9, "[": 5, "♪": 9, "]": 5, "~": 9, " ": 6
    };
    SpriteSheet alphabetSpriteSheet = SpriteSheet.fromColumnsAndRows(image: images.fromCache("alphabet_spritesheet.png"), columns: 8, rows: 19);
    List<Glyph> glyphList = [];
    for (int i = 0; i < alphabetOrder.length; i++) {
      final char = alphabetOrder[i];
      Sprite charSprite = alphabetSpriteSheet.getSpriteById(i);
      glyphList.add(Glyph(char, left: charSprite.srcPosition.x, top: charSprite.srcPosition.y, width: widths[char]!.toDouble()));
    }
    dialogueFont = SpriteFont(source: images.fromCache("alphabet_spritesheet.png"), size: 16, ascent: 16, glyphs: glyphList);
    hudFont = SpriteFont(source: images.fromCache("alphabet_spritesheet.png"), size: 16, ascent: 16, glyphs: glyphList);
    SpriteSheet portraitSheet = SpriteSheet(image: images.fromCache("portraits_spritesheet.png"), srcSize: Vector2(48, 64));
    List<String> portraitNames = ["", "Gerrard", "DiMaggio", "Lex", "Azel", "Gandolf", "Aideen", "Midir", "Arden", "Noish", "Alec", "Sigurd", "Oifey", "Quan", "Ethlyn", "Finn"];
    for(var i = 0; i < portraitNames.length; i++){
      portraitMap[portraitNames[i]] = portraitSheet.getSpriteById(i);
    }
    String prologueDialogueData = await rootBundle.loadString('assets/yarn/prologue.yarn');
    yarnProject.parse(prologueDialogueData);
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.load('105 - Prologue (Birth of the Holy Knight).mp3');
    await FlameAudio.audioCache.load('101 - Beginning.mp3');
    // FlameAudio.bgm.play('101 - Beginning.mp3');
    unitMap = await loadUnitData();
    itemMap = await loadItemsData();
    weaponMap = await loadWeaponsData();
    attackMap = await loadAttacksData();
    skillMap = await loadSkillsData();
    classMap = await loadClassesData();
    add(eventQueue);
    add(combatQueue);
    
    UnitDeathEvent.initialize(eventQueue);
    UnitDeathEvent.initialize(combatQueue);
    UnitExpEvent.initialize(eventQueue);
    CombatRoundEvent.initialize(combatQueue);
    CritEvent.initialize(combatQueue);
    CantoEvent.initialize(eventQueue);
    DialogueEvent.initialize(eventQueue);
    DialogueEvent.initialize(combatQueue);

    
    
  }

  MoiraGame() : super(world: TitleCard()) {
    titleCard = world as TitleCard;
  }
  
  void switchToWorld(World newWorld) async {
      world = newWorld;
      camera.world = newWorld;
  }


  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (world is InputHandler && world.isLoaded) {
      return (world as InputHandler).handleKeyEvent(event, keysPressed);
    }
    return KeyEventResult.ignored;
  }
}
