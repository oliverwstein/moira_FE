// ignore_for_file: unnecessary_overrides
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'engine.dart';
class MyGame extends FlameGame with KeyboardEvents {
  
  EventQueue eventQueue = EventQueue();
  late Component screen;
  late MaxViewport viewport;
  late Stage stage;
  late TitleCard titleCard;
  double _scaleFactor = 1;
  final List _observers = [];
  double get scaleFactor => _scaleFactor;
  static late Map<String, dynamic> unitMap;
  static late Map<String, dynamic> itemMap;
  static late Map<String, dynamic> weaponMap;
  static late Map<String, dynamic> attackMap;
  static late Map<String, dynamic> skillMap;
  static late Map<String, dynamic> classMap;
  final EventDispatcher eventDispatcher = EventDispatcher();
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

  set scaleFactor(double value) {
    if (_scaleFactor != value) {
      _scaleFactor = value;
      for (var observer in _observers) {
        observer.onScaleChanged(_scaleFactor);
      }
    }
  }

  void addObserver(observer) {
    _observers.add(observer);
  }

  void removeObserver(observer) {
    _observers.remove(observer);
  }

  @override
    void update(double dt) {
        super.update(dt);
        eventQueue.update(dt);
    }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unitMap = await loadUnitData();
    itemMap = await loadItemsData();
    weaponMap = await loadWeaponsData();
    attackMap = await loadAttacksData();
    skillMap = await loadSkillsData();
    classMap = await loadClassesData();
    eventQueue.addEventBatch([TitleCardCreationEvent(this, [])]);
    eventQueue.addEventBatch([StageCreationEvent(this, [])]);

    eventQueue.addEventBatch([
      UnitCreationEvent(this, "Brigand", const Point(24, 22), 1, Point(33, 25)),
      UnitCreationEvent(this, "Brigand", const Point(23, 22), 5, Point(32, 26)),
      UnitCreationEvent(this, "Brigand", const Point(22, 20), 1, Point(31, 25)),
      UnitCreationEvent(this, "Brigand", const Point(21, 19), 1, Point(30, 28)),]);
    eventQueue.addEventBatch([
      UnitCreationEvent(this, "Brigand", const Point(37, 15), 1, Point(37, 26)),
      UnitCreationEvent(this, "Brigand", const Point(35, 15), 5, Point(35, 25)),
      UnitCreationEvent(this, "Brigand", const Point(36, 16), 1, Point(35, 26)),
      UnitCreationEvent(this, "Brigand", const Point(21, 19), 1, Point(27, 27)),]);
    eventQueue.addEventBatch([
      UnitCreationEvent(this, "Brigand", const Point(37, 15), 1, Point(36, 21)),
      UnitCreationEvent(this, "Brigand", const Point(35, 15), 5, Point(35, 20)),
      UnitCreationEvent(this, "Brigand", const Point(36, 16), 1, Point(36, 19)),
      UnitCreationEvent(this, "Brigand", const Point(20, 22), 1, Point(32, 24)),
      UnitCreationEvent(this, "Brigand", const Point(20, 22), 5, Point(33, 26)),]);
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    bool handled = false;
    // First, handle any game-wide key events (like zooming)
    // Check if there is an event being processed and if it handles the user input
    if (eventQueue.isProcessing() && key is RawKeyDownEvent) {
      for (var event in eventQueue.currentBatch()) {
        event.handleUserInput(key);
        if (event.checkComplete()) {
          handled = true;
          break;
        }
      }
    }
    // Handle game-wide key events if not handled by an event
    if (!handled) {
      if (key is RawKeyDownEvent) {
          handled = stage.keyCommandHandler(key.logicalKey);
      }
    }
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }
}

abstract class ScaleObserver {
  void onScaleChanged(double scaleFactor);
}
abstract class CommandHandler {
  bool handleCommand(LogicalKeyboardKey command);
}
