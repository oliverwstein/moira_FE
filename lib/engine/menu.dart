// ignore_for_file: unnecessary_overrides
import 'dart:ui' as ui;
import 'dart:developer' as dev;

import 'package:flame/components.dart';
import 'package:flame/layout.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/services.dart';

import 'engine.dart';

class ActionMenu extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  Map<MenuOption, PositionComponent> options = {};
  late int selectedIndex;
  List visibleOptions = [];
  late AnimatedPointer pointer; 
  late SpriteComponent blankWindowSprite;
  static const double scaleFactor = 2;

  ActionMenu();

  @override
  Future<void> onLoad() async {
    blankWindowSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('action_menu_narrow.png'),
    );
    dev.log('${MenuOption.values}');
    for (var option in MenuOption.values) {
      var boxComponent = PositionComponent(
      );
      boxComponent.add(SpriteComponent(sprite: blankWindowSprite.sprite));
      var textComponent = TextComponent(
        text: option.label,
        textRenderer: TextPaint(style: menuTextStyle),
        position: Vector2(8, 2)
      );
      boxComponent.add(textComponent);
      boxComponent.scale = Vector2.all(scaleFactor);
      options[option] = boxComponent;
    }
    pointer = AnimatedPointer();
  }

  @override
  bool handleCommand(LogicalKeyboardKey command) {
    Stage stage = parent!.parent as Stage;
    bool handled = false;
    if (command == LogicalKeyboardKey.arrowUp) {
      pointer.move(Direction.up);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      pointer.move(Direction.down);
      handled = true;
    } else if (command == LogicalKeyboardKey.keyA) {
      dev.log('${visibleOptions}');
      select();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB || command == LogicalKeyboardKey.keyM) {
      Unit? unit = stage.tilesMap[stage.cursor.tilePosition]!.unit;
      if (unit != null){
        unit.snapToTile(unit.oldTile);
        stage.updateTileWithUnit(unit.tilePosition, unit.oldTile, unit);
        unit.tilePosition = unit.oldTile;
        
        stage.activeComponent = stage.cursor;
        stage.blankAllTiles();
      }
      close();
      handled = true;
    }
    return handled;
  }

  void select(){
    Stage stage = parent!.parent as Stage;
    dev.log('${visibleOptions[selectedIndex]}');
    switch (visibleOptions[selectedIndex]) {
      case MenuOption.endTurn:
        stage.endTurn();
      case MenuOption.unitList:
        break;
      case MenuOption.save:
        break;
      case MenuOption.attack:
        break;
      case MenuOption.item:
        break;
      case MenuOption.wait:
        Unit? unit = stage.tilesMap[stage.cursor.tilePosition]!.unit;
        unit!.toggleCanAct(false);
        stage.activeComponent = stage.cursor;
        stage.blankAllTiles();
        stage.updateTileWithUnit(unit.oldTile, unit.tilePosition, unit);
        unit.oldTile = unit.tilePosition;
        
      default:
        stage.activeComponent = stage.cursor;
        break;
    }
    close();
    stage.activeComponent = stage.cursor;
  }
  void show(List<MenuOption> shownOptions) {
    visibleOptions = shownOptions;
    visibleOptions.sort((a, b) => a.priority.compareTo(b.priority));

    double i = 1;
    for (var option in visibleOptions) {
      var component = options[option];
      if (component != null) {
        component.position = Vector2(64, 32*i);
        add(component);
      }
      i++;
    }
    selectedIndex = 0;
    add(pointer);
    pointer.updatePosition();
  }

  void close(){
    removeAll(children);
  }

}

class AnimatedPointer extends PositionComponent with HasGameRef<MyGame> {
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet pointerSheet;
  final double stepY = 32;
  late double tileSize;

  AnimatedPointer() {
    tileSize = 16;
  }

  @override
  Future<void> onLoad() async {
    // Load the cursor image and create the animation component
    ui.Image pointerImage = await gameRef.images.load('dancing_selector.png');
    pointerSheet = SpriteSheet.fromColumnsAndRows(
      image: pointerImage,
      columns: 3,
      rows: 1,
    );

    _animationComponent = SpriteAnimationComponent(
      animation: pointerSheet.createAnimation(row: 0, stepTime: .2),
      position: Vector2(64, 32),
    );
    _animationComponent.scale = Vector2.all(ActionMenu.scaleFactor);
    add(_animationComponent);

    // Set the initial size and position of the cursor
  }


  // You might want methods to update the pointer's position based on the current selection
  void move(Direction dir) {
    ActionMenu menu = parent as ActionMenu;
    if (menu.visibleOptions.isNotEmpty){
      if (dir == Direction.up) {
          menu.selectedIndex = (menu.selectedIndex + 1) % menu.visibleOptions.length;
      } else if (dir == Direction.down) {
          menu.selectedIndex = (menu.selectedIndex - 1) % menu.visibleOptions.length;
      }
      updatePosition();
    }
  }
    
  void updatePosition() {
    ActionMenu menu = parent as ActionMenu;
    y = stepY * menu.selectedIndex;
  }
}

enum MenuOption {
  unitList('Units', 1),
  save('Save Game', 2),
  endTurn('End Turn', 3),
  attack('Attack', 10),
  item('Items', 20),
  wait('Wait', 100);


  const MenuOption(this.label, this.priority);
  final String label;
  final int priority;
}

TextStyle menuTextStyle = const TextStyle(
  color: ui.Color(0xFFF3E5AB), // Gold-like color
  fontSize: 8, // Adjust the font size as needed
  fontFamily: 'Courier', // This is just an example, use the actual font that matches your design
  shadows: <ui.Shadow>[
    ui.Shadow(
      offset: ui.Offset(1.0, 1.0),
      blurRadius: 3.0,
      color: ui.Color(0xFF000000),
    ),
  ],
);