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
    menu.open();
  }

  void popMenu() {
    remove(_menuStack.removeLast());
  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("top of _menuStack is: ${_menuStack.firstOrNull}");
    if (isNotEmpty){
      if(key is RawKeyDownEvent) return _menuStack.last.handleKeyEvent(key, keysPressed);
      return KeyEventResult.handled;
    } else {
      switch (key.logicalKey) {
        case LogicalKeyboardKey.keyA:
          Tile tile = game.stage.tileMap[game.stage.cursor.tilePosition]!;
          debugPrint("$tile selected and tile.isOccupied = ${tile.isOccupied}");
          if(tile.isOccupied) {
            tile.unit!.findReachableTiles(tile.unit!.movementRange.toDouble());
            // add the MoveMenu to the stack.
            pushMenu(MoveMenu());
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

  @override 
  Future<void> onLoad() async {

  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyB:
        game.stage.blankAllTiles();
        close();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.handled;
    }
  }

}

