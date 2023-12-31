// ignore_for_file: unnecessary_overrides, unused_import
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:developer' as dev;

import 'package:flame/components.dart';
import 'package:flame/layout.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/services.dart';
import 'engine.dart';

TextPaint selectedTextRenderer = TextPaint(
        style: const TextStyle(
          color: ui.Color.fromARGB(255, 235, 219, 214),
          fontSize: 10, // Adjust the font size as needed
          fontFamily: 'Courier', // This is just an example, use the actual font that matches your design
          shadows: <ui.Shadow>[
            ui.Shadow(
              offset: ui.Offset(1.0, 1.0),
              blurRadius: 3.0,
              color: ui.Color.fromARGB(255, 18, 5, 49),
            ),
          ],
          // Include any other styles you need
          ),
      );
TextPaint basicTextRenderer = TextPaint(
        style: const TextStyle(
          color: ui.Color.fromARGB(255, 239, 221, 216),
          fontSize: 8, // Adjust the font size as needed
          fontFamily: 'Courier', // This is just an example, use the actual font that matches your design
          shadows: <ui.Shadow>[
            ui.Shadow(
              offset: ui.Offset(1.0, 1.0),
              blurRadius: 1.0,
              color: ui.Color.fromARGB(255, 20, 11, 48),
            ),
          ],
          // Include any other styles you need
          ),
      );
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
    for (var option in MenuOption.values) {
      var boxComponent = PositionComponent(
      );
      boxComponent.add(SpriteComponent(sprite: blankWindowSprite.sprite));
      var textComponent = TextComponent(
        text: option.label,
        textRenderer: basicTextRenderer,
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
      select();
      close();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB || command == LogicalKeyboardKey.keyM) {
      Unit? unit = stage.tilesMap[stage.cursor.gridCoord]!.unit;
      if (unit != null) unit.undoMove();
      close();
      handled = true;
    }
    return handled;
  }

  void select(){
    Stage stage = parent!.parent as Stage;
    switch (visibleOptions[selectedIndex]) {
      case MenuOption.endTurn:
        stage.endTurn();
        stage.activeComponent = stage.cursor;
      case MenuOption.unitList:
        break;
      case MenuOption.save:
        stage.activeComponent = stage.cursor;
        break;
      case MenuOption.attack:
        Unit? unit = stage.tilesMap[stage.cursor.gridCoord]!.unit;
        assert(unit != null);
        TargetSelector selector = TargetSelector(stage.getTargets());
        stage.cursor.goToUnit(selector.targets[0]);
        unit!.add(selector);
        stage.activeComponent = selector;
        break;
      case MenuOption.item:
        // On selecting item, pull up the item menu.
        Unit? unit = stage.tilesMap[stage.cursor.gridCoord]!.unit;
        assert(unit != null);
        ItemMenu itemMenu = ItemMenu(unit!);
        stage.cursor.add(itemMenu);
        stage.activeComponent = itemMenu;
        break;
      case MenuOption.wait:
        Unit? unit = stage.tilesMap[stage.cursor.gridCoord]!.unit;
        unit!.wait();
      default:
        stage.activeComponent = stage.cursor;
        break;
    }
    close();
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
          menu.selectedIndex = (menu.selectedIndex - 1) % menu.visibleOptions.length;
      } else if (dir == Direction.down) {
          menu.selectedIndex = (menu.selectedIndex + 1) % menu.visibleOptions.length;
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

class ItemMenu extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  Unit unit;
  late final SpriteComponent menuSprite;
  late final SpriteComponent mainEquipSprite;
  late final SpriteComponent gearEquipSprite;
  late final SpriteComponent treasureEquipSprite;
  late List<Item> inventory;
  Map<int, TextComponent> indexMap = {};
  int selectedIndex = 0;
  int mainEquippedIndex = -1;
  int gearEquippedIndex = -1;
  int treasureEquippedIndex = -1;
  static const double scaleFactor = 2;

  ItemMenu(this.unit){
    inventory = unit.inventory;
    for (int i = 0; i < inventory.length; i++){
      var textComponent = TextComponent(
        text: inventory[i].name,
        textRenderer: basicTextRenderer,
        position: Vector2(20, 16*(i+1)),
        priority: 20,
      );
      add(textComponent);
      if(unit.main != null){
        if (inventory[i] == unit.main){
          mainEquippedIndex = i;
        }
      }
      indexMap[i] = textComponent;
      
    }
    indexMap[0]!.textRenderer = selectedTextRenderer;
  }

  @override
  Future<void> onLoad() async {
    menuSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('item_table_titled.png'),
    );
    mainEquipSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('main_icon.png'),
        position: Vector2(-12, 2),
        size: Vector2.all(8)
    );
     gearEquipSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('gear_icon.png'),
        position: Vector2(-12, 2),
        size: Vector2.all(8)
    );
    treasureEquipSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('treasure_icon.png'),
        position: Vector2(-12, 2),
        size: Vector2.all(8)
    );
    add(menuSprite);
    if(indexMap[mainEquippedIndex]!= null) indexMap[mainEquippedIndex]!.add(mainEquipSprite);
    if(indexMap[gearEquippedIndex]!= null) indexMap[gearEquippedIndex]!.add(gearEquipSprite);
    if(indexMap[treasureEquippedIndex]!= null) indexMap[treasureEquippedIndex]!.add(treasureEquipSprite);
    
  }
  
  @override
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    if (command == LogicalKeyboardKey.arrowUp) {
      indexMap[selectedIndex]!.textRenderer = basicTextRenderer;
      selectedIndex = (selectedIndex - 1) % inventory.length;
      indexMap[selectedIndex]!.textRenderer = selectedTextRenderer;

      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      indexMap[selectedIndex]!.textRenderer = basicTextRenderer;
      selectedIndex = (selectedIndex + 1) % inventory.length;
      indexMap[selectedIndex]!.textRenderer = selectedTextRenderer;
      handled = true;
    } else if (command == LogicalKeyboardKey.keyA) {
      select();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB || command == LogicalKeyboardKey.keyM) {
      close();
      handled = true;
    }
    return handled;
  }

  void equipItem(){
    
    switch (inventory[selectedIndex].type) {
      case ItemType.main:
        if (unit.main == inventory[selectedIndex]){
          mainEquipSprite.removeFromParent();
          unit.unequip(ItemType.main);
        } else{
          mainEquipSprite.removeFromParent();
          unit.equip(inventory[selectedIndex]);
          indexMap[selectedIndex]!.add(mainEquipSprite);
          mainEquippedIndex = selectedIndex;
        }
        
        break;
      case ItemType.gear:
        if (unit.gear == inventory[selectedIndex]){
          gearEquipSprite.removeFromParent();
          unit.unequip(ItemType.gear);
        } else{
          gearEquipSprite.removeFromParent();
          unit.equip(inventory[selectedIndex]);
          indexMap[selectedIndex]!.add(gearEquipSprite);
          gearEquippedIndex = selectedIndex;
        }
        break;
      case ItemType.treasure:
      if (unit.treasure == inventory[selectedIndex]){
          treasureEquipSprite.removeFromParent();
          unit.unequip(ItemType.treasure);
        } else{
          treasureEquipSprite.removeFromParent();
          unit.equip(inventory[selectedIndex]);
          indexMap[selectedIndex]!.add(treasureEquipSprite);
          treasureEquippedIndex = selectedIndex;
          }
        break;
      default:
        break;
    }
    
  }

  void select(){
    if (inventory[selectedIndex].equipCond?.check(unit) ?? true){equipItem();}
    close();
  }

  void close(){
    Stage stage = unit.parent as Stage;
    removeAll(children);
    unit.getActionOptions();
    unit.openActionMenu(stage);

  }
}

class TargetSelector extends Component implements CommandHandler {
  List<Unit> targets;
  TargetSelector(this.targets);
  int targetIndex = 0;
  @override
  bool handleCommand(LogicalKeyboardKey command) {
    Unit unit = parent! as Unit;
    Stage stage = unit.parent as Stage;
    bool handled = false;
    if (command == LogicalKeyboardKey.keyA) { // Confirm the selection.
      if(stage.tilesMap[stage.cursor.gridCoord]!.isOccupied){
        if(stage.tilesMap[stage.cursor.gridCoord]!.unit!.team == UnitTeam.red){
          Unit target = stage.tilesMap[stage.cursor.gridCoord]!.unit!;
          CombatBox combatBox = CombatBox(unit, target);
          unit.add(combatBox);
          dev.log("${unit.name} has the attacks: ${combatBox.combat.getValidAttacks(unit)}");
          stage.activeComponent = combatBox;
        }

      }
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) { // Cancel the action.
      stage.cursor.goToUnit(unit);
      unit.getActionOptions();
      unit.openActionMenu(stage);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) {
      targetIndex = (targetIndex + 1) % targets.length;
      stage.cursor.goToUnit(targets[targetIndex]);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      targetIndex = (targetIndex - 1) % targets.length;
      stage.cursor.goToUnit(targets[targetIndex]);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowLeft) {
      targetIndex = (targetIndex + 1) % targets.length;
      stage.cursor.goToUnit(targets[targetIndex]);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) {
      targetIndex = (targetIndex - 1) % targets.length;
      stage.cursor.goToUnit(targets[targetIndex]);
      handled = true;
    }
    return handled;
  }
}
