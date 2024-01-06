// ignore_for_file: unnecessary_overrides
import 'dart:convert';

import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'engine.dart';
class MyGame extends FlameGame with KeyboardEvents {
  /// MyGame is the core class for the tactical RPG game, extending FlameGame for 
  /// game loop management and integrating KeyboardEvents for user interaction.
  /// It manages the game's viewport, stage, and global state like scaling.
  /// 
  /// Attributes:
  /// - `viewport`: Manages the game's viewport size and scaling.
  /// - `stage`: The main container for all game elements, including tiles and units.
  /// - `_scaleFactor`: A private variable managing the zoom level of the game view.
  /// - `_observers`: A list of observers (like Stage) that listen to scale changes.
  /// 
  /// Methods:
  /// - `scaleFactor`: Getter and setter for _scaleFactor, updates observers on change.
  /// - `addObserver(observer)`: Adds an observer to be notified of scale changes.
  /// - `removeObserver(observer)`: Removes an observer from the notification list.
  /// - `update(dt)`: Updates the game state every tick, part of the game loop.
  /// - `onLoad()`: Asynchronously loads game resources and initializes components.
  /// - `onKeyEvent(event, keysPressed)`: Handles keyboard events globally.
  /// 
  /// Constructor:
  /// Initializes game components, sets up the viewport, and loads the stage.
  /// It ensures the game scales properly and the camera follows the cursor.
  /// 
  /// Connects with:
  /// - Stage: Stage acts as the main interactive area of the game, containing all tiles,
  ///   units, and managing the cursor.
  /// - Tile, Unit: Managed by Stage, but their scaling and updates are propagated
  ///   by MyGame through observers.
  /// - MaxViewport: Manages how the game's view is scaled and presented.
  /// 
  /// Usage:
  /// This class should be instantiated to start the game. It sets up necessary
  /// game components and starts the game loop. User interactions are primarily
  /// managed here and delegated to other components like Stage and Unit.

  late MaxViewport viewport;
  late Stage stage;
  double _scaleFactor = 2;
  final List _observers = [];
  double get scaleFactor => _scaleFactor;
  static late Map<String, dynamic> unitMap;
  static late Map<String, dynamic> itemMap;
  static late Map<String, dynamic> weaponMap;
  static late Map<String, dynamic> attackMap;

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
    }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unitMap = await loadUnitData();
    itemMap = await loadItemsData();
    weaponMap = await loadWeaponsData();
    attackMap = await loadAttacksData();
    viewport = MaxViewport();
    camera.viewport = viewport;
    stage = Stage();
    await world.add(stage);
    addObserver(stage);
    camera.follow(stage.cursor);
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool handled = false;
    // First, handle any game-wide key events (like zooming)
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.equal) { // Zoom in
        scaleFactor *= 1.1;
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.minus) { // Zoom out
        scaleFactor *= 0.9;
        handled = true;
      } else {
        handled = stage.keyCommandHandler(event.logicalKey);
      }
    }
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }
}

enum UnitTeam {blue, red, green, yellow}
abstract class ScaleObserver {
  void onScaleChanged(double scaleFactor);
}
abstract class CommandHandler {
  bool handleCommand(LogicalKeyboardKey command);
}
