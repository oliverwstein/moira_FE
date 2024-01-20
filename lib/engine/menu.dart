import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moira/content/content.dart';

class MenuManager extends Component with HasGameReference<MoiraGame> implements InputHandler {
  final List<Menu> _menuStack = [];

  bool get isNotEmpty => _menuStack.isNotEmpty;

  void pushMenu(Menu menu) {
    _menuStack.add(menu);
    add(menu);
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
    if (isNotEmpty){
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
            if (game.stage.factionMap[tile.unit!.faction] == game.stage.activeFaction){
              pushMenu(MoveMenu(tile.unit!, tile));
            }
            return KeyEventResult.handled;
          } else {
            // add the GameMenu to the stack.
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
  void close() {game.stage.menuManager.popMenu();}
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    close();
    return KeyEventResult.handled;
  }
}

class MoveMenu extends Menu {
  final Unit unit;
  final Tile startTile;

  MoveMenu(this.unit, this.startTile);

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
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        if(game.stage.tileMap[game.stage.cursor.tilePosition]!.state == TileState.move){
          // Move the unit to the tile selected by the cursor. 
          game.stage.eventQueue.addEventBatch([UnitMoveEvent(unit, game.stage.cursor.tilePosition)]);
          // game.stage.blankAllTiles();
          game.stage.menuManager.pushMenu(ActionMenu(unit));
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        game.stage.blankAllTiles();
        unit.snapToTile(startTile);
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

class ActionMenu extends Menu {
  final Unit unit;
  late final List<String> actions;
  int selectedIndex = 0;
  ActionMenu(this.unit);

  @override 
  Future<void> onLoad() async {
    SpriteAnimation newAnimation = unit.animationMap["idle"]!.animation!;
    unit.sprite.animation = newAnimation;
    actions = unit.getActions();
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    if(unit.isMoving) return KeyEventResult.ignored;
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        debugPrint("${actions[selectedIndex]} Chosen");
        switch (actions[selectedIndex]){
          case "Wait":
            unit.wait();
            game.stage.menuManager.clearStack();
            break;
          case "Item":
            game.stage.blankAllTiles();
            game.stage.menuManager.pushMenu(InventoryMenu(unit));
            break;
          case "Attack":
            game.stage.blankAllTiles();
            List<Unit> targets = unit.getTargets();
            game.stage.menuManager.pushMenu(CombatMenu(unit, targets));
            

            break;
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
    game.stage.cursor.snapToTile(targets.first.tilePosition);
  }

  // @override
  // KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
  //   return KeyEventResult.handled;
  // }
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