// ignore_for_file: unnecessary_string_interpolations

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
    if(key.logicalKey == LogicalKeyboardKey.escape){clearStack();}
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
  void close() {
    game.stage.menuManager.popMenu();
    if(game.stage.menuManager._menuStack.lastOrNull is MoveMenu){
      game.stage.menuManager._menuStack.last.close();}}
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

class SelectionMenu extends Menu {
  final Point<int> tilePosition;
  late List<String> options;
  int selectedIndex = 0;
  late final SpriteFontRenderer fontRenderer;
  SelectionMenu(this.tilePosition, this.options);

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
        size = Vector2(Stage.tileSize * 3, options.length * Stage.tileSize * 0.75 + Stage.tileSize * 0.25); // Dynamic size based on options
        final backgroundPaint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white for the background
        final highlightPaint = Paint()..color = const Color.fromARGB(141, 203, 16, 203); // Color for highlighting selected action
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

class UnitActionMenu extends SelectionMenu with HasVisibility {
  final Unit unit;
  bool committed = false;

  UnitActionMenu(Point<int> tilePosition, this.unit)
      : super(tilePosition, unit.getActionsAt(tilePosition));

  @override
  void update(dt){
    super.update(dt);
    if(unit.tilePosition != game.stage.cursor.tilePosition) {isVisible = false;} else {isVisible = true;}

  }
  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("UnitActionMenu given key ${key.logicalKey.keyLabel} to handle.");
    if(!isVisible) return KeyEventResult.ignored;
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
              case "Talk":
                game.stage.menuManager.pushMenu(TalkMenu(game.stage.cursor.tilePosition, unit));
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
        if(committed){
          game.stage.menuManager.clearStack();
          game.eventQueue.addEventBatchToHead([UnitExhaustEvent(unit, manual: false)]);}
        else{close();}
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

class InventoryMenu extends SelectionMenu {
  final Unit unit;
  static List<String> getInventoryNames(Unit unit) => unit.inventory.map((item) => item.name).toList();
  InventoryMenu(Point<int> tilePosition, this.unit)
      : super(tilePosition, getInventoryNames(unit));

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("InventoryMenu given key ${key.logicalKey.keyLabel} to handle.");
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

class StageMenu extends SelectionMenu {
  StageMenu(Point<int> tilePosition)
      : super(tilePosition, ["End", "Save"]);

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

class TalkMenu extends SelectionMenu {
  final Unit unit;
  static List<String> getTalkOptions(Unit unit, Point<int> point) {
    List<String> options = [];
    List<Tile?> adjacentTiles = [
      unit.game.stage.tileMap[Point(point.x+1, point.y)],
      unit.game.stage.tileMap[Point(point.x-1, point.y)],
      unit.game.stage.tileMap[Point(point.x, point.y+1)],
      unit.game.stage.tileMap[Point(point.x, point.y-1)],
      ];
    for (Tile? tile in adjacentTiles){
      if(tile != null){
        if(tile.unit != null && unit.game.yarnProject.nodes.keys.contains("Talk_${unit.name}_${tile.unit!.name}")){
          options.add(tile.unit!.name);
        }
      }
    }
    return options;
  }
  TalkMenu(Point<int> tilePosition, this.unit)
      : super(tilePosition, getTalkOptions(unit, tilePosition));

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("TalkMenu given key ${key.logicalKey.keyLabel} to handle.");
      switch (key.logicalKey) {
        case LogicalKeyboardKey.keyA:
          debugPrint("${options[selectedIndex]} Chosen");
          DialogueMenu menu = DialogueMenu("Talk_${unit.name}_${options[selectedIndex]}", null);
          close();
          game.stage.menuManager.pushMenu(menu);
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

class CombatMenu extends Menu{
  final Unit unit;
  final List<Unit> targets;
  late List<Attack> attacks;
  ({int accuracy, int critRate, int damage, int fatigue}) attackerVals = (accuracy: 0, critRate: 0, damage: 0, fatigue: 0);
  ({int accuracy, int critRate, int damage, int fatigue}) defenderVals = (accuracy: 0, critRate: 0, damage: 0, fatigue: 0);
  int selectedTargetIndex = 0;
  int selectedAttackIndex = 0;
  late final SpriteFontRenderer fontRenderer;
  CombatMenu(this.unit, this.targets);

  @override
  void update(dt){
    position = Vector2(game.stage.cursor.position.x + Stage.tileSize*3, game.stage.cursor.position.y - Stage.tileSize*1);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (game.stage.menuManager._menuStack.last == this) {
      final backgroundPaint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white for the background
      canvas.drawRect(size.toRect(), backgroundPaint);
      double lineHeight = Stage.tileSize * .6;
      double leftColumnX = size.x / 4;
      double rightColumnX = size.x - leftColumnX;
      double centerColumnX = size.x / 2;
      List<(String, double, double, Anchor)> renderTexts = [
        ("${unit.name}", Stage.tileSize*.25, 0, Anchor.topLeft),
        ("${unit.main?.name}", size.x - Stage.tileSize*.25, 0, Anchor.topRight),
        (unit.attack?.name ?? "", size.x - Stage.tileSize*.25, lineHeight, Anchor.topRight),
        ("HP", centerColumnX, lineHeight * 2, Anchor.topCenter),
        ("${targets[selectedTargetIndex].hp}", leftColumnX, lineHeight * 2, Anchor.topRight),
        ("${unit.hp}", rightColumnX, lineHeight * 2, Anchor.topLeft),
        ("STA", centerColumnX, lineHeight * 3, Anchor.topCenter),
        ("${targets[selectedTargetIndex].sta}-${defenderVals.fatigue}", leftColumnX, lineHeight * 3, Anchor.topRight),
        ("${unit.sta}-${attackerVals.fatigue}", rightColumnX, lineHeight * 3, Anchor.topLeft),
        ("Damage", centerColumnX, lineHeight * 4, Anchor.topCenter),
        ("${defenderVals.damage}", leftColumnX, lineHeight * 4, Anchor.topRight),
        ("${attackerVals.damage}", rightColumnX, lineHeight * 4, Anchor.topLeft),
        ("Hit %", centerColumnX, lineHeight * 5, Anchor.topCenter),
        ("${defenderVals.accuracy}", leftColumnX, lineHeight * 5, Anchor.topRight),
        ("${attackerVals.accuracy}", rightColumnX, lineHeight * 5, Anchor.topLeft),
        ("Crit %", centerColumnX, lineHeight * 6, Anchor.topCenter),
        ("${defenderVals.critRate}", leftColumnX, lineHeight * 6, Anchor.topRight),
        ("${attackerVals.critRate}", rightColumnX, lineHeight * 6, Anchor.topLeft),
        ("${targets[selectedTargetIndex].name}", Stage.tileSize*.25, lineHeight * 7, Anchor.topLeft),
        ("${targets[selectedTargetIndex].main?.name}", size.x - Stage.tileSize*.25, lineHeight * 7, Anchor.topRight),
        (targets[selectedTargetIndex].attack?.name ?? "", size.x - Stage.tileSize*.25, lineHeight * 8, Anchor.topRight),
      ];
      if(Combat.addFollowUp(unit, targets[selectedTargetIndex])?.$1 == unit){
        renderTexts.add(("(x2)", size.x, lineHeight, Anchor.topLeft));
      }
      else if(Combat.addFollowUp(unit, targets[selectedTargetIndex])?.$1 == targets[selectedTargetIndex]){
        renderTexts.add(("x2", size.x, lineHeight*8, Anchor.topLeft));
      }

      for (var textInfo in renderTexts) {
        fontRenderer.render(
          canvas,
          textInfo.$1,
          Vector2(textInfo.$2, textInfo.$3),
          anchor: textInfo.$4,
        );
      }
    }
  }

  @override 
  Future<void> onLoad() async {
    size = Vector2(Stage.tileSize * 4, Stage.tileSize * 6);
    anchor = Anchor.center;
    fontRenderer = SpriteFontRenderer.fromFont(game.hudFont, scale: .5);
    attacks = unit.attackSet.values.toList();
    unit.attack = attacks.first;
    // @TODO: attacks should really be generated on a by-target basis. 
    game.stage.cursor.snapToTile(targets.first.tilePosition);
    targets[selectedTargetIndex].getBestAttackOnTarget(unit, targets[selectedTargetIndex].getAttacksOnTarget(unit, Combat.getCombatDistance(unit, targets[selectedTargetIndex])));
    attackerVals = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
    defenderVals = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
  }

  @override
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed) {
    debugPrint("CombatMenu given key ${key.logicalKey.keyLabel} to handle.");
    if(unit.isMoving) return KeyEventResult.handled;
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
        game.stage.cursor.snapToTile(targets[selectedTargetIndex].tilePosition);
        targets[selectedTargetIndex].getBestAttackOnTarget(unit, 
          targets[selectedTargetIndex].getAttacksOnTarget(unit, Combat.getCombatDistance(unit, targets[selectedTargetIndex])));
        attackerVals = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
        defenderVals = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown: // Change target
        selectedTargetIndex = (selectedTargetIndex + 1) % targets.length;
        game.stage.cursor.snapToTile(targets[selectedTargetIndex].tilePosition);
        targets[selectedTargetIndex].getBestAttackOnTarget(unit, 
          targets[selectedTargetIndex].getAttacksOnTarget(unit, Combat.getCombatDistance(unit, targets[selectedTargetIndex])));
        attackerVals = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
        defenderVals = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft: // Change attack
        selectedAttackIndex = (selectedAttackIndex - 1) % attacks.length;
        unit.attack = attacks[selectedAttackIndex];
        attackerVals = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
        defenderVals = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight: // Change attack
        selectedAttackIndex = (selectedAttackIndex + 1) % attacks.length;
        unit.attack = attacks[selectedAttackIndex];
        attackerVals = unit.attackCalc(targets[selectedTargetIndex], unit.attack);
        defenderVals = targets[selectedTargetIndex].attackCalc(unit, targets[selectedTargetIndex].attack);
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
  late final SpriteFontRenderer fontRenderer;
  StaffMenu(this.unit);
  @override 
  Future<void> onLoad() async {
    size = Vector2(Stage.tileSize * 4, Stage.tileSize * 2);
    anchor = Anchor.center;
    fontRenderer = SpriteFontRenderer.fromFont(game.hudFont, scale: .5);
    targets = unit.getStaffTargetsAt(unit.tilePosition);
    staves = unit.getStaves();
    unit.equip(staves[selectedStaffIndex]);
    game.stage.cursor.snapToTile(targets.first.tilePosition);
  }
  @override
  void update(dt){
    position = Vector2(unit.position.x + Stage.tileSize*3, unit.position.y - Stage.tileSize*1);
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (game.stage.menuManager._menuStack.last == this) {
      final backgroundPaint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white for the background
      canvas.drawRect(size.toRect(), backgroundPaint);
      double lineHeight = Stage.tileSize * .6;
      List<(String, double, double, Anchor)> renderTexts = [
        ("${targets[selectedTargetIndex].name}", Stage.tileSize*.25, 0, Anchor.topLeft),
        ("${staves[selectedStaffIndex].staff?.effectString(targets[selectedTargetIndex])}", Stage.tileSize*.25, lineHeight, Anchor.topLeft),
        ("STA Cost: ${staves[selectedStaffIndex].staff?.staminaCost}", Stage.tileSize*.25, lineHeight*2, Anchor.topLeft),
      ];

      for (var textInfo in renderTexts) {
        fontRenderer.render(
          canvas,
          textInfo.$1,
          Vector2(textInfo.$2, textInfo.$3),
          anchor: textInfo.$4,
        );
      }
    }
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
        unit.equip(staves[selectedStaffIndex]);
        debugPrint("Selected Staff is ${staves[selectedStaffIndex].name}");
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight: // Change attack
        selectedStaffIndex = (selectedStaffIndex + 1) % staves.length;
        unit.equip(staves[selectedStaffIndex]);
        debugPrint("Selected Staff is ${staves[selectedStaffIndex].name}");
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
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
    KeyEventResult result = dialogue.handleKeyEvent(key, keysPressed);
    return result;
  }
}