import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';

class MenuManager extends PositionComponent with HasGameReference<MoiraGame> implements InputHandler {
  final List<Menu> _menuStack = [];

  bool get isNotEmpty => _menuStack.isNotEmpty;
  Menu? get last => _menuStack.lastOrNull;

  @override
  void onLoad() {
    super.onLoad();
    anchor = Anchor.center;
  }

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
          if(tile.isOccupied) {
            game.stage.blankAllTiles();
            Set<Tile> reachableTiles = tile.unit!.findReachableTiles(tile.unit!.movementRange.toDouble());
            tile.unit!.markAttackableTiles(reachableTiles.toList());
            // if the unit is a part of the active faction, add the MoveMenu to the stack.
            if (tile.unit!.controller == game.stage.activeFaction && tile.unit!.canAct){
              if(reachableTiles.length > 1) {pushMenu(MoveMenu(tile.unit!, tile));}
              else {
                game.stage.blankAllTiles();
                game.stage.menuManager.pushMenu(UnitActionMenu(tile.point, tile.unit!));
              }
            }
            return KeyEventResult.handled;
          } else {
            // add the basic action menu to the stack.
            pushMenu(StageMenu(tile.point));
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

abstract class Menu extends PositionComponent with HasGameReference<MoiraGame> implements InputHandler {
  void open() {}
  void close() {game.stage.menuManager.popMenu();}
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
    unit.setSpriteDirection(unit.direction);
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
    unit.setSpriteDirection(null);
  }
  @override
  void update(dt){
    Cursor cursor = game.stage.cursor;
    game.camera.moveBy(cursor.getCursorEdgeOffset(), speed: 300);
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
          game.stage.menuManager.pushMenu(UnitActionMenu(game.stage.cursor.tilePosition, unit));
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
    unit.setSpriteDirection(unit.direction);
  }
  @override
  void onRemove() {
    super.onRemove();
    unit.setSpriteDirection(null);
  }
  @override
  void update(dt){
    Cursor cursor = game.stage.cursor;
    game.camera.moveBy(cursor.getCursorEdgeOffset(), speed: 300);
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    Point<int> direction = const Point(0, 0);
    debugPrint("CantoMenu given key ${key.logicalKey.keyLabel} to handle.");
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

class UnitActionMenu extends SelectionMenu {
  final Unit unit;

  UnitActionMenu(Point<int> tilePosition, this.unit)
      : super(tilePosition, unit.getActionsAt(tilePosition));

  @override 
  void close() {
    super.close();
    if(game.stage.menuManager._menuStack.lastOrNull != null){
      game.stage.menuManager._menuStack.last.close();
    }
    
  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("ActionMenu given key ${key.logicalKey.keyLabel} to handle.");
    // if(unit != null) || unit!.isMoving) return KeyEventResult.ignored;
      switch (key.logicalKey) {
        case LogicalKeyboardKey.keyA:
            debugPrint("${options[selectedIndex]} Chosen");
            game.stage.blankAllTiles();
            switch (options[selectedIndex]){
              case "Wait":
                game.eventQueue.addEventBatch([UnitExhaustEvent(unit, manual: true)]);
                game.stage.menuManager.clearStack();
                break;
              case "Items":
                game.stage.menuManager.pushMenu(InventoryMenu(game.stage.cursor.tilePosition, unit));
                break;
              case "Staff":
                game.stage.menuManager.pushMenu(StaffMenu(unit));
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
              case "Depart":
                game.eventQueue.addEventBatch([DepartCastleEvent(unit, unit.tile as CastleFort)]);
                game.stage.menuManager.clearStack();
              case "Guard":
                CastleGate gate = unit.tile as CastleGate;
                game.eventQueue.addEventBatch([GuardCastleEvent(unit, gate)]);
                game.stage.menuManager.pushMenu(UnitActionMenu(gate.fort.point, unit));
          } switch (options[selectedIndex]){
              case "End":
                // End the turn, then close.
                game.eventQueue.addEventBatch([EndTurnEvent(game.stage.activeFaction!.name)]);
                // Note: it is not faster to create and execute the event manually.
                close();
                break;
              case "Save":
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

class StageMenu extends SelectionMenu {
  StageMenu(Point<int> tilePosition)
      : super(tilePosition, ["End", "Save"]);
  @override 
  void close() {
    super.close();
    if(game.stage.menuManager._menuStack.lastOrNull != null){
      game.stage.menuManager._menuStack.last.close();
    }
    
  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("ActionMenu given key ${key.logicalKey.keyLabel} to handle.");
    // if(unit != null) || unit!.isMoving) return KeyEventResult.ignored;
      switch (key.logicalKey) {
        case LogicalKeyboardKey.keyA:
            debugPrint("${options[selectedIndex]} Chosen");
            game.stage.blankAllTiles();
            switch (options[selectedIndex]){
              case "End":
                // End the turn, then close.
                game.eventQueue.addEventBatch([EndTurnEvent(game.stage.activeFaction!.name)]);
                // Note: it is not faster to create and execute the event manually.
                close();
                break;
              case "Save":
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

class StaffMenu extends Menu {
  final Unit unit;
  late final List<Unit> targets;
  late final List<Item> staves;
  int selectedTargetIndex = 0;
  int selectedStaffIndex = 0;
  StaffMenu(this.unit);
  @override 
  Future<void> onLoad() async {
    targets = unit.getStaffTargetsAt(unit.tilePosition);
    staves = unit.getStaves();
    game.stage.cursor.snapToTile(targets.first.tilePosition);
  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("StaffMenu given key ${key.logicalKey.keyLabel} to handle.");
    switch (key.logicalKey) {
      case LogicalKeyboardKey.keyA:
        // Use the selected staff on the target.
        unit.equip(staves[selectedStaffIndex]);
        staves[selectedStaffIndex].staff!.execute(targets[selectedTargetIndex]);
        game.stage.menuManager.clearStack();
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
        debugPrint("Target is ${targets[selectedTargetIndex].name}");
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown: // Change target
        selectedTargetIndex = (selectedTargetIndex + 1) % targets.length;
        debugPrint("${targets[selectedTargetIndex].name} Selected");
        game.stage.cursor.snapToTile(targets[selectedTargetIndex].tilePosition);
        debugPrint("Target is ${targets[selectedTargetIndex].name}");
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft: // Change attack
        selectedStaffIndex = (selectedStaffIndex - 1) % staves.length;
        debugPrint("Selected Staff is ${staves[selectedStaffIndex].name}");
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight: // Change attack
        selectedStaffIndex = (selectedStaffIndex + 1) % staves.length;
        debugPrint("Selected Staff is ${staves[selectedStaffIndex].name}");
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }
}

class SelectionMenu extends Menu {
  final Point<int> tilePosition;
  late final List<String> options;
  int selectedIndex = 0;
  late final SpriteFontRenderer fontRenderer;
  SelectionMenu(this.tilePosition, this.options);

  @override 
  void close() {
    super.close();
    if(game.stage.menuManager._menuStack.lastOrNull != null){
      game.stage.menuManager._menuStack.last.close();
    }
    
  }
  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = Vector2(Stage.tileSize * 3, options.length * Stage.tileSize * 0.75 + Stage.tileSize * 0.25); // Dynamic size based on options
    anchor = Anchor.center;
    fontRenderer = SpriteFontRenderer.fromFont(game.hudFont);
    
  }

  @override
  void update(dt){
    position = Vector2(game.stage.cursor.position.x + Stage.tileSize*3, game.stage.cursor.position.y - Stage.tileSize*1);
  }
  @override
  void render(Canvas canvas) {
      super.render(canvas);
      if(game.stage.menuManager._menuStack.last == this){
        final backgroundPaint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white for the background
        final highlightPaint = Paint()..color = Color.fromARGB(141, 203, 16, 203); // Color for highlighting selected action
        canvas.drawRect(size.toRect(), backgroundPaint);
        // Calculate the height of each action entry for positioning and highlighting
        double actionHeight = Stage.tileSize * 0.75;
        // Render each action using the SpriteFontRenderer
        for (int i = 0; i < options.length; i++) {
            double yPos = i * actionHeight; // Adjust yPos as needed for spacing
            // Highlight the background of the selected action
            if (i == selectedIndex) {
                Rect highlightRect = Rect.fromLTWH(0, yPos + Stage.tileSize * 0.1, size.x, actionHeight + Stage.tileSize * 0.10);
                canvas.drawRect(highlightRect, highlightPaint);
            }
            // Use the fontRenderer to draw the text
            fontRenderer.render(
                canvas,
                options[i],
                Vector2(Stage.tileSize * 0.25, yPos), // Adjust text position within the highlighted area
                anchor: Anchor.topLeft,
            );
        }
      }
      
  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("ActionMenu given key ${key.logicalKey.keyLabel} to handle.");
    // if(unit != null) || unit!.isMoving) return KeyEventResult.ignored;
      switch (key.logicalKey) {
        case LogicalKeyboardKey.keyA:
          debugPrint("${options[selectedIndex]} Chosen");
      case LogicalKeyboardKey.keyB:
        close();
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

class InventoryMenu extends SelectionMenu {
  final Unit unit;
  static List<String> getInventoryNames(Unit unit) => unit.inventory.map((item) => item.name).toList();
  InventoryMenu(Point<int> tilePosition, this.unit)
      : super(tilePosition, getInventoryNames(unit));

  @override 
  void close() {
    super.close();
    if(game.stage.menuManager._menuStack.lastOrNull != null){
      game.stage.menuManager._menuStack.last.close();
    }
    
  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("ActionMenu given key ${key.logicalKey.keyLabel} to handle.");
    // if(unit != null) || unit!.isMoving) return KeyEventResult.ignored;
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