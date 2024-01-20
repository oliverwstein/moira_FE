import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moira/content/content.dart';

class MenuManager extends Component with HasGameReference<MoiraGame> implements InputHandler {
  final List<Menu> _menuStack = [];

  bool get isNotEmpty => _menuStack.isNotEmpty;

  void pushMenu(Menu menu) {
    _menuStack.add(menu);
    menu.open();
  }

  void popMenuState() {
    _menuStack.removeLast().close();
  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    if (isNotEmpty){
      return _menuStack.last.handleKeyEvent(key, keysPressed);
    } else {
      switch (key.logicalKey) {
        case LogicalKeyboardKey.keyA:
          Tile tile = game.stage.tileMap[game.stage.cursor.tilePosition]!;
          if(tile.isOccupied && tile.unit!.canAct) {
            // add the MoveMenu to the stack.
            return KeyEventResult.handled;
          } else {
            // add the GameMenu to the stack.
            return KeyEventResult.handled;
          }
        default:
          return KeyEventResult.handled;
      }
    }
    
  }
}

abstract class Menu extends Component with HasGameReference<MoiraGame> implements InputHandler {
  void open() {}
  void close() {}
}


