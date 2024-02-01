// ignore_for_file: unused_import, prefer_final_fields

import 'dart:collection';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/services.dart';

import 'engine.dart';

class EventQueue {
  Queue<List<Event>> _eventBatches = Queue<List<Event>>();
  List<Event> _currentBatch = [];
  bool _isProcessing = false;
  // ignore: unused_field
  String? _currentType;

  void addEventBatch(List<Event> eventBatch) {
    _eventBatches.add(eventBatch);
  }

  bool isProcessing(){
    return _isProcessing;
  }

  List<Event> currentBatch(){
    return _currentBatch;
  }

  void executeBatch(List<Event> batch) {
    // Execute each event in the current batch
    for (var event in batch) {
      event.execute();
    }
  }

  void update(double dt) {
    if (_isProcessing) {
      if (_currentBatch.every((event) => event.checkComplete())){
        // If the batch elements have all been completed, clear the batch
        // and allow EventQueue to go on to the next batch.
        _isProcessing = false;
        _currentBatch.clear();
      } else {
        List<Event> batch = [];
        for (Event event in _currentBatch){if (!event.checkStarted()) batch.add(event);}
        executeBatch(batch);}
    }
    if (!_isProcessing && _eventBatches.isNotEmpty) {
      // Pop the next batch waiting in the queue as the current batch
      _currentBatch = _eventBatches.removeFirst();
      // Execute all events in the current batch simultaneously
      executeBatch(_currentBatch); 
      _isProcessing = true;
    }
  }
}

abstract class Event {
  String get type => "Generic";
  void execute(){}
  bool _isStarted = false;
  bool _isCompleted = false;
  bool handled = true;
  bool checkStarted(){return _isStarted;}
  bool checkComplete(){return _isCompleted;}
  bool handleUserInput(RawKeyEvent event){return handled;}
}

class TitleCardCreationEvent extends Event {
  @override
  String get type => 'Creation';
  final MyGame game;
  List<Event> nextEventBatch;
  TitleCardCreationEvent(this.game, [this.nextEventBatch = const []]);

  @override
  void execute() async { // Make this method async
    _isStarted = true;
    dev.log("Load the title card");
    game.titleCard = TitleCard();
    game.world.add(game.titleCard);
    game.screen = game.titleCard;

    // Await the completion of Stage's onLoad
    await game.titleCard.loadCompleted;

    // Once Stage's onLoad is complete, proceed with further actions
    dev.log("Title Card loaded");
  }

  @override
  bool handleUserInput(RawKeyEvent event) {
    // You can customize this condition based on your specific requirement
    _isCompleted = true;
    game.eventQueue.addEventBatch(nextEventBatch);
    return true;
  }  
}

class StageCreationEvent extends Event {
  @override
  String get type => 'Creation';
  final MyGame game;
  List<Event> nextEventBatch;
  StageCreationEvent(this.game, [this.nextEventBatch = const []]);

  @override
  Future<Stage> execute() async { // Make this method async
    _isStarted = true;
    dev.log("Load the stage");
    game.stage = Stage();
    game.world.add(game.stage); // Add the stage to the game world

    // Await the completion of Stage's onLoad
    await game.stage.loadCompleted;

    // Once Stage's onLoad is complete, proceed with further actions
    dev.log("Stage loaded");
    _isCompleted = true;
    game.screen.removeFromParent();
    game.screen = game.stage;
    
    // Add your next event here
    game.eventQueue.addEventBatch(nextEventBatch);
    return game.stage;
  }
}

class UnitCreationEvent extends Event {
  @override
  String get type => 'Creation';
  final MyGame game;
  final String name;
  final Point<int> gridCoord;
  final int level;
  late final Unit unit;
  final Point<int> destination;

  UnitCreationEvent(this.game, this.name, this.gridCoord, this.level, this.destination);

  @override
  Future<Unit> execute() async {
    _isStarted = true;
    dev.log("Create unit $name");
    unit = level > 0 ? Unit.fromJSON(gridCoord, name, level: level) : Unit.fromJSON(gridCoord, name);
    game.stage.add(unit); // Add the unit to the stage
    game.stage.units.add(unit);

    // Wait for unit's onLoad to complete
    await unit.loadCompleted;

    // Mark as completed once the unit has finished being created.
    _isCompleted = true;
    // Move the unit to its destination
    if(destination != gridCoord) {
      game.eventQueue.currentBatch().add(UnitMoveEvent(game, unit, destination));
      game.eventQueue.currentBatch().remove(this);
    }
    
    return unit;
  }
}

class UnitMoveEvent extends Event {
  @override
  String get type => 'Movement';
  final MyGame game;
  final Point<int> gridCoord;
  final Unit unit;
  List<Event>? nextEventBatch;
  UnitMoveEvent(this.game, this.unit, this.gridCoord, [this.nextEventBatch]);

  @override
  void execute() async { // Make this method async
    _isStarted = true;
    dev.log("Event: Move unit ${unit.name}");
    unit.move(game.stage, gridCoord);
    if(nextEventBatch != null) game.eventQueue.addEventBatch(nextEventBatch!);
    
  }
  @override
  bool checkComplete() {
    return (unit.gridCoord == gridCoord && _isStarted);
  }
}

class ItemMenuEvent extends Event {
  @override
  String get type => 'Menu';
  final MyGame game;
  final Unit unit;
  List<Event>? nextEventBatch;
  late ItemMenu itemMenu;
  ItemMenuEvent(this.game, this.unit, [this.nextEventBatch]);

  @override
  void execute() async { // Make this method async
    _isStarted = true;
    dev.log("Event: Open item menu for ${unit.name}");
    itemMenu = ItemMenu(unit);
    unit.add(itemMenu);
    dev.log("${unit.name} has ${itemMenu.items.map((item) => item.name).join(", ")}");
  }

  @override
  bool checkComplete() {
    return (_isCompleted);
  }

  @override
  bool handleUserInput(RawKeyEvent event) {
    LogicalKeyboardKey command = event.logicalKey;
    bool handled = false;
    itemMenu.handleCommand(command);
    if (command == LogicalKeyboardKey.arrowUp) {
      dev.log("Item Menu ArrowUp to ${itemMenu.items[itemMenu.selectedIndex].name}");
      handled = true;
    } else 
    if (command == LogicalKeyboardKey.arrowDown) {
      dev.log("Item Menu ArrowDown to ${itemMenu.items[itemMenu.selectedIndex].name}");
      handled = true;
    } else 
    if (command == LogicalKeyboardKey.keyA) {
      dev.log("Item Menu Select ${itemMenu.items[itemMenu.selectedIndex]}");
      // @TODO: once the option to use an item exists, using an item should complete the event.
      // It should also complete the event differently than cancellation should, 
      // because equipping is a free action and using an item is not.
      itemMenu.close();
      _isCompleted = true;
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB || command == LogicalKeyboardKey.keyM) {
      dev.log("Item Menu Cancelled");
      itemMenu.close();
      _isCompleted = true;
      handled = true;
    }
    return handled;
  }  
}

class ActionMenuEvent extends Event {
  @override
  String get type => 'Menu';
  final MyGame game;
  final Unit? unit;
  List<Event>? nextEventBatch;
  late ActionMenu actionMenu;
  ActionMenuEvent(this.game, this.unit, [this.nextEventBatch]);

  @override
  void execute() async { // Make this method async
    _isStarted = true;
    if(unit != null){
      dev.log("Event: Open action menu for ${unit!.name}");
      unit!.getActionOptions();
      actionMenu = ActionMenu(unit!.actionsAvailable, unit);
      unit!.add(actionMenu);
    } else {
      List<MenuOption> actionsAvailable = [MenuOption.unitList, MenuOption.save, MenuOption.endTurn];
      actionMenu = ActionMenu(actionsAvailable);
      game.stage.cursor.add(actionMenu);
    }
  }

  @override
  bool checkComplete() {
    return (_isCompleted);
  }

  @override
  bool handleUserInput(RawKeyEvent event) {
    LogicalKeyboardKey command = event.logicalKey;
    bool handled = false;
    if (command == LogicalKeyboardKey.arrowUp) {
      actionMenu.move(Direction.up);
      dev.log("Action Menu ArrowUp to ${actionMenu.options[actionMenu.selectedIndex]}");
      handled = true;
    } else 
    if (command == LogicalKeyboardKey.arrowDown) {
      actionMenu.move(Direction.down);
      dev.log("Action Menu ArrowDown to ${actionMenu.options[actionMenu.selectedIndex]}");
      handled = true;
    } else 
    if (command == LogicalKeyboardKey.keyA) {
      dev.log("Action Menu Select ${actionMenu.options[actionMenu.selectedIndex]}");
      game.eventQueue.addEventBatch(actionMenu.select());
      _isCompleted = true;
      actionMenu.close();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB || command == LogicalKeyboardKey.keyM) {
      dev.log("Action Menu Cancelled");
      if (unit != null) unit!.undoMove();
      _isCompleted = true;
      actionMenu.close();
      handled = true;
    }
    return handled;
  }  
}

class CursorMoveEvent extends Event {
  @override
  String get type => 'Movement';
  final MyGame game;
  final Point<int> gridCoord;
  CursorMoveEvent(this.game, this.gridCoord);

  @override
  void execute() async { // Make this method async
    _isStarted = true;
    dev.log("Move cursor to $gridCoord from ${game.stage.cursor.gridCoord}");
    game.stage.cursor.panToTile(gridCoord);
  }
  
  @override
  bool checkComplete() {
    return (game.stage.cursor.gridCoord == gridCoord && _isStarted);
  }
}

class TurnStartEvent extends Event {
  final MyGame game;
  final UnitTeam activeTeam;
  TurnStartEvent(this.game, this.activeTeam);
  @override
  void execute() async { // Make this method async
    dev.log("Start turn ${game.stage.turn} for $activeTeam");
    _isStarted = true;
    game.stage.activeTeam = activeTeam;
    _isCompleted = true;
  }
}

class TurnEndEvent extends Event {
  final MyGame game;
  TurnEndEvent(this.game);
  @override
  void execute() async {
    dev.log("End turn ${game.stage.turn} for ${game.stage.activeTeam}");
    _isStarted = true;
    game.stage.endTurn();
    _isCompleted = true;
  }
}

class UnitWaitEvent extends Event {
  final Unit unit;
  UnitWaitEvent(this.unit){
    dev.log("UnitWaitEvent created for $unit");
  }
  @override
  void execute() async {
    dev.log("${unit.name} waits.");
    _isStarted = true;
    unit.wait();
    _isCompleted = true;
  }
}

class UnitUnitDeathEvent extends Event {
  final Unit unit;
  UnitUnitDeathEvent(this.unit);
}

class UnitActionEndEvent extends Event {
  final Unit unit;
  UnitActionEndEvent(this.unit);
  
}

class MakeAttackEvent extends Event {
  final Combat combat;
  final Unit attacker;
  final Unit defender;
  MakeAttackEvent(this.combat, this.attacker, this.defender);

}

class MakeDamageEvent extends Event {
  final Unit unit;
  MakeDamageEvent(this.unit);
  
}

class EventDispatcher {
  final List<Observer> _observers = [];

  void add(Observer observer) {
    _observers.add(observer);
  }

  void remove(Observer observer) {
    _observers.remove(observer);
  }

  void dispatch(Event event) {
    for (var observer in _observers) {
      observer.onEvent(event);
    }
  }
}