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
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    if (isNotEmpty){
      if(key is RawKeyDownEvent) return _menuStack.last.handleKeyEvent(key, keysPressed);
      return KeyEventResult.handled;
    } else {
      switch (key.logicalKey) {
        case LogicalKeyboardKey.keyA:
          Tile tile = game.stage.tileMap[game.stage.cursor.tilePosition]!;
          debugPrint("$tile selected and tile.isOccupied = ${tile.isOccupied}");
          if(tile.isOccupied && tile.unit!.canAct) {
            game.stage.blankAllTiles();
            Set<Tile> reachableTiles = tile.unit!.findReachableTiles(tile.unit!.movementRange.toDouble());
            tile.unit!.markAttackableTiles(reachableTiles.toList());
            // if the unit is a part of the active faction, add the MoveMenu to the stack.
            if (game.stage.factionMap[tile.unit!.faction] == game.stage.activeFaction){
              pushMenu(MoveMenu(tile.unit!, tile.point));
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
}

class MoveMenu extends Menu {
  final Unit unit;
  final Point<int> startPoint;

  MoveMenu(this.unit, this.startPoint);

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
          game.stage.blankAllTiles();
          game.stage.menuManager.pushMenu(ActionMenu(unit));
          close();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        game.stage.blankAllTiles();
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

  ActionMenu(this.unit);

  @override 
  Future<void> onLoad() async {
    SpriteAnimation newAnimation = unit.animationMap["idle"]!.animation!;
    unit.sprite.animation = newAnimation;
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        close();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
    }
    return KeyEventResult.handled;
  }

}

