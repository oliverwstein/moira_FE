import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';

class MenuManager extends Component with HasGameReference<MoiraGame> implements InputHandler {
  final List<Menu> _menuStack = [];

  bool get isNotEmpty => _menuStack.isNotEmpty;
  Menu? get last => _menuStack.lastOrNull;

  void pushMenu(Menu menu) {
    add(menu);
    _menuStack.add(menu);
    debugPrint("push ${_menuStack.lastOrNull} to _menuStack");
    menu.open();
  }

  void popMenu() {
    debugPrint("pop ${_menuStack.lastOrNull} from _menuStack");
    remove(_menuStack.removeLast());
    debugPrint("top of _menuStack is now: ${_menuStack.lastOrNull}");
  }

  void clearStack(){
    _menuStack.clear();
    removeAll(children);
  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    // debugPrint("MenuManager given key ${key.logicalKey.keyLabel} to handle.");
    if (isNotEmpty){
      debugPrint("Active menu is: ${_menuStack.last.runtimeType}");
      if(key is RawKeyDownEvent) return _menuStack.last.handleKeyEvent(key, keysPressed);
      return KeyEventResult.handled;
    } else {
      switch (key.logicalKey) {
        case LogicalKeyboardKey.keyA:
          Tile tile = game.stage.tileMap[game.stage.cursor.tilePosition]!;
          if(tile.isOccupied && tile.unit!.canAct) {
            game.stage.blankAllTiles();
            Set<Tile> reachableTiles = tile.unit!.findReachableTiles(tile.unit!.movementRange.toDouble());
            tile.unit!.markAttackableTiles(reachableTiles.toList());
            // if the unit is a part of the active faction, add the MoveMenu to the stack.
            if (tile.unit!.controller == game.stage.activeFaction){
              pushMenu(MoveMenu(tile.unit!, tile));
            }
            return KeyEventResult.handled;
          } else {
            // add the StageMenu to the stack.
            pushMenu(StageMenu());
            return KeyEventResult.handled;
          }
        case LogicalKeyboardKey.keyB:
          
          if (_menuStack.isEmpty){
            game.stage.blankAllTiles();
          }
          return KeyEventResult.handled;
        default:
          return KeyEventResult.handled;
      }
    }
    
  }
}

abstract class Menu extends Component with HasGameReference<MoiraGame> implements InputHandler {
  void open() {}
  void close() {
    game.stage.menuManager.popMenu();}
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyB:
        close();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
    
  }
}

class MoveMenu extends Menu {
  final Unit unit;
  final Tile startTile;

  MoveMenu(this.unit, this.startTile);

  @override 
  void close() {
    game.stage.blankAllTiles();
    unit.snapToTile(startTile);
    game.stage.cursor.snapToTile(unit.tilePosition);
    super.close();
  }
  @override 
  Future<void> onLoad() async {
    SpriteAnimation newAnimation = unit.animationMap["left"]!.animation!;
    unit.sprite.animation = newAnimation;
  }

  @override
  void open(){
    super.open();
    var rankedTiles = unit.rankOpenTiles(["Move", "Combat"]);
    debugPrint("${rankedTiles.first}");
  }
  @override
  void onRemove() {
    super.onRemove();
    SpriteAnimation newAnimation = unit.animationMap["idle"]!.animation!;
    unit.sprite.animation = newAnimation;
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    Point<int> direction = const Point(0, 0);
    debugPrint("MoveMenu given key ${key.logicalKey.keyLabel} to handle.");
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        if(game.stage.tileMap[game.stage.cursor.tilePosition]!.state == TileState.move){
          // Move the unit to the tile selected by the cursor. 
          game.eventQueue.addEventBatch([UnitMoveEvent(unit, game.stage.cursor.tilePosition)]);
          game.stage.blankAllTiles();
          game.stage.menuManager.pushMenu(ActionMenu(unit));
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        close();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        direction = Point(direction.x - 1, direction.y);
      case LogicalKeyboardKey.arrowRight:
        direction = Point(direction.x + 1, direction.y);
      case LogicalKeyboardKey.arrowUp:
        direction = Point(direction.x, direction.y - 1);
      case LogicalKeyboardKey.arrowDown:
        direction = Point(direction.x, direction.y + 1);
    }
    if (direction != const Point(0,0)){
        Point<int> newTilePosition = Point(game.stage.cursor.tilePosition.x + direction.x, game.stage.cursor.tilePosition.y + direction.y);
        game.stage.cursor.moveTo(newTilePosition);
    }
    return KeyEventResult.handled;
  }
}

class CantoMenu extends Menu {
  final Unit unit;
  final Tile startTile;

  CantoMenu(this.unit, this.startTile);

  @override 
  void close() {
    game.stage.blankAllTiles();
    unit.snapToTile(startTile);
    super.close();
  }
  @override 
  Future<void> onLoad() async {
    SpriteAnimation newAnimation = unit.animationMap["left"]!.animation!;
    unit.sprite.animation = newAnimation;
  }
  @override
  void onRemove() {
    super.onRemove();
    SpriteAnimation newAnimation = unit.animationMap["idle"]!.animation!;
    unit.sprite.animation = newAnimation;
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    Point<int> direction = const Point(0, 0);
    debugPrint("MoveMenu given key ${key.logicalKey.keyLabel} to handle.");
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        if(game.stage.tileMap[game.stage.cursor.tilePosition]!.state == TileState.move){
          // Move the unit to the tile selected by the cursor. 
          game.eventQueue.addEventBatch([UnitMoveEvent(unit, game.stage.cursor.tilePosition)]);
          game.eventQueue.addEventBatch([UnitExhaustEvent(unit, manual: true)]);         
          game.stage.blankAllTiles();
          game.stage.menuManager.clearStack();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        game.stage.blankAllTiles();
        game.stage.menuManager.clearStack();
        game.eventQueue.addEventBatch([UnitExhaustEvent(unit, manual: true)]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        direction = Point(direction.x - 1, direction.y);
      case LogicalKeyboardKey.arrowRight:
        direction = Point(direction.x + 1, direction.y);
      case LogicalKeyboardKey.arrowUp:
        direction = Point(direction.x, direction.y - 1);
      case LogicalKeyboardKey.arrowDown:
        direction = Point(direction.x, direction.y + 1);
    }
    if (direction != const Point(0,0)){
        Point<int> newTilePosition = Point(game.stage.cursor.tilePosition.x + direction.x, game.stage.cursor.tilePosition.y + direction.y);
        game.stage.cursor.moveTo(newTilePosition);
    }
    return KeyEventResult.handled;
  }
}

class ActionMenu extends Menu {
  final Unit unit;
  late final List<String> actions;
  int selectedIndex = 0;
  ActionMenu(this.unit);

  @override 
  void close() {
    super.close();
    game.stage.menuManager._menuStack.last.close();
  }
  @override 
  Future<void> onLoad() async {
    SpriteAnimation newAnimation = unit.animationMap["idle"]!.animation!;
    unit.sprite.animation = newAnimation;
    actions = unit.getActionsAt(game.stage.cursor.tilePosition);
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("ActionMenu given key ${key.logicalKey.keyLabel} to handle.");
    if(unit.isMoving) return KeyEventResult.ignored;
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        debugPrint("${actions[selectedIndex]} Chosen");
        game.stage.blankAllTiles();
        switch (actions[selectedIndex]){
          case "Wait":
            game.eventQueue.addEventBatch([UnitExhaustEvent(unit, manual: true)]);
            game.stage.menuManager.clearStack();
            break;
          case "Items":
            debugPrint("${actions[selectedIndex]} Chosen");
            game.stage.menuManager.pushMenu(InventoryMenu(unit));
            break;
          case "Attack":
            List<Unit> targets = unit.getTargetsAt(unit.tilePosition);
            game.stage.menuManager.pushMenu(CombatMenu(unit, targets));
            break;
          case "Visit":
            game.eventQueue.addEventBatch([VisitEvent(unit, unit.tile as TownCenter)]);
            game.eventQueue.addEventBatch([UnitExhaustEvent(unit, manual: false)]);
            game.stage.menuManager.clearStack();
            break;
          case "Ransack":
            game.eventQueue.addEventBatch([RansackEvent(unit, unit.tile as TownCenter)]);
            game.eventQueue.addEventBatch([UnitExhaustEvent(unit, manual: false)]);
            game.stage.menuManager.clearStack();
            break;
          case "Seize":
            game.eventQueue.addEventBatch([SeizeEvent(unit, unit.tile as CastleGate)]);
          case "Besiege":
            // Create a variant of the CombatMenu called BesiegeMenu. 
            //For now, just trigger a besiege event.
            game.eventQueue.addEventBatch([BesiegeEvent(unit.tile as CastleGate)]);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        close();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        selectedIndex = (selectedIndex - 1) % actions.length;
        debugPrint("${actions[selectedIndex]} Selected");
      case LogicalKeyboardKey.arrowDown:
        selectedIndex = (selectedIndex + 1) % actions.length;
        debugPrint("${actions[selectedIndex]} Selected");
    }
    return KeyEventResult.handled;
  }

}

class CombatMenu extends Menu {
  final Unit unit;
  final List<Unit> targets;
  late List<Attack> attacks;
  int selectedTargetIndex = 0;
  int selectedAttackIndex = 0;
  CombatMenu(this.unit, this.targets);

  @override 
  Future<void> onLoad() async {
    attacks = unit.attackSet.values.toList();
    unit.attack = attacks.first;
    // @TODO: attacks should really be generated on a by-target basis. 
    game.stage.cursor.snapToTile(targets.first.tilePosition);
    targets[selectedTargetIndex].attack = targets[selectedTargetIndex].getAttack(Combat.getCombatDistance(unit, targets[selectedTargetIndex]));
    var unitAttackNumbers = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
    var targetAttackNumbers = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
    debugPrint("Unit attack numbers are $unitAttackNumbers");
    debugPrint("Target attack numbers are $targetAttackNumbers");
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("CombatMenu given key ${key.logicalKey.keyLabel} to handle.");
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        // Make the attack
        game.eventQueue.addEventBatch([StartCombatEvent(unit, targets[selectedTargetIndex])]);
        game.stage.cursor.snapToTile(unit.tilePosition);
        game.stage.menuManager.clearStack();
        game.combatQueue.addEventBatch([UnitExhaustEvent(unit)]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        // Cancel
        close();
        game.stage.cursor.snapToTile(unit.tilePosition);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp: // Change target
        selectedTargetIndex = (selectedTargetIndex - 1) % targets.length;
        debugPrint("${targets[selectedTargetIndex].name} Selected");
        game.stage.cursor.snapToTile(targets[selectedTargetIndex].tilePosition);
        targets[selectedTargetIndex].attack = targets[selectedTargetIndex].getAttack(Combat.getCombatDistance(unit, targets[selectedTargetIndex]));
        var unitAttackNumbers = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
        var targetAttackNumbers = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
        debugPrint("Unit attack numbers are $unitAttackNumbers");
        debugPrint("Target attack numbers are $targetAttackNumbers");
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown: // Change target
        selectedTargetIndex = (selectedTargetIndex + 1) % targets.length;
        debugPrint("${targets[selectedTargetIndex].name} Selected");
        game.stage.cursor.snapToTile(targets[selectedTargetIndex].tilePosition);
        targets[selectedTargetIndex].attack = targets[selectedTargetIndex].getAttack(Combat.getCombatDistance(unit, targets[selectedTargetIndex]));
        var unitAttackNumbers = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
        var targetAttackNumbers = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
        debugPrint("Unit attack numbers are $unitAttackNumbers");
        debugPrint("Target attack numbers are $targetAttackNumbers");
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft: // Change attack
        selectedAttackIndex = (selectedAttackIndex - 1) % attacks.length;
        debugPrint("${attacks[selectedAttackIndex].name} Selected");
        unit.attack = attacks[selectedAttackIndex];
        var unitAttackNumbers = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
        var targetAttackNumbers = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
        debugPrint("Unit attack numbers are $unitAttackNumbers");
        debugPrint("Target attack numbers are $targetAttackNumbers");
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight: // Change attack
        selectedAttackIndex = (selectedAttackIndex + 1) % attacks.length;
        debugPrint("${attacks[selectedAttackIndex].name} Selected");
        unit.attack = attacks[selectedAttackIndex];
        var unitAttackNumbers = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
        var targetAttackNumbers = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
        debugPrint("Unit attack numbers are $unitAttackNumbers");
        debugPrint("Target attack numbers are $targetAttackNumbers");
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }
}

class StageMenu extends Menu {
  final List<String> options = ["Save Game", "End Turn"];
  int selectedIndex = 0;
  StageMenu();
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("StageMenu given key ${key.logicalKey.keyLabel} to handle.");
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        debugPrint("${options[selectedIndex]} Chosen");
        switch (options[selectedIndex]){
          case "End Turn":
            // End the turn, then close.
            game.eventQueue.addEventBatch([EndTurnEvent(game.stage.activeFaction!.name)]);
            // Note: it is not faster to create and execute the event manually.
            close();
            break;
          case "Save Game":
            // @TODO add saving?
            close();
            break;
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        close();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        selectedIndex = (selectedIndex - 1) % options.length;
        debugPrint("${options[selectedIndex]} Selected");
      case LogicalKeyboardKey.arrowDown:
        selectedIndex = (selectedIndex + 1) % options.length;
        debugPrint("${options[selectedIndex]} Selected");
    }
    return KeyEventResult.handled;
  }
}

class InventoryMenu extends Menu {
  final Unit unit;
  late final List<String> options;
  int selectedIndex = 0;
  InventoryMenu(this.unit);

  @override 
  Future<void> onLoad() async {
    SpriteAnimation newAnimation = unit.animationMap["idle"]!.animation!;
    unit.sprite.animation = newAnimation;
    List<String> getInventoryNames() => unit.inventory.map((item) => item.name).toList();
    options = getInventoryNames();
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        debugPrint("${options[selectedIndex]} Chosen");
        if(unit.inventory[selectedIndex].use != null){
          // If the item has a use, prompt if they want to use it.
        } 
        if (unit.inventory[selectedIndex].type != ItemType.basic) {
          unit.equip(unit.inventory[selectedIndex]);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        close();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        selectedIndex = (selectedIndex - 1) % options.length;
        debugPrint("${options[selectedIndex]} Selected");
      case LogicalKeyboardKey.arrowDown:
        selectedIndex = (selectedIndex + 1) % options.length;
        debugPrint("${options[selectedIndex]} Selected");
    }
    return KeyEventResult.handled;
  }

}

class DialogueMenu extends Menu {
  late final Dialogue dialogue;
  late DialogueRunner runner;
  String? bgName;
  String nodeName;
  DialogueMenu(this.nodeName, this.bgName);

  @override
  Future<void> onLoad() async {
    dialogue = Dialogue(bgName, nodeName);
    await add(dialogue);
    runner = DialogueRunner(
        yarnProject: game.yarnProject, dialogueViews: [dialogue]);
    runner.startDialogue(nodeName);
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    if(dialogue.finished){close();}
    return dialogue.handleKeyEvent(key, keysPressed);
  }

}