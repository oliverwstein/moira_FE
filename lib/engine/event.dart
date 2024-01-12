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

  void executeCurrentBatch() {
    // Execute each event in the current batch
    for (var event in _currentBatch) {
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
      } else if (!_currentBatch.every((event) => event.checkStarted())){ 
        // Checks if the batch has only elements that have not begun.
        // Used for dealing with batches that create new batches. 
        executeCurrentBatch();
      }
    }
    if (!_isProcessing && _eventBatches.isNotEmpty) {
      // Pop the next batch waiting in the queue as the current batch
      _currentBatch = _eventBatches.removeFirst();
      // Execute all events in the current batch simultaneously
      executeCurrentBatch(); 
      _isProcessing = true;
    }
  }
}

abstract class Event {
  String get type => "Generic";
  void execute(){}
  bool checkStarted(){return true;}
  bool checkComplete(){return true;}
  void handleUserInput(RawKeyEvent event){}
}

class TitleCardCreationEvent extends Event {
  @override
  String get type => 'Creation';
  final MyGame game;
  List<Event> nextEventBatch;
  bool _isCompleted = false;
  TitleCardCreationEvent(this.game, [this.nextEventBatch = const []]);

  @override
  void execute() async { // Make this method async
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
  void handleUserInput(RawKeyEvent event) {
    // You can customize this condition based on your specific requirement
    _isCompleted = true;
    game.eventQueue.addEventBatch(nextEventBatch);
  }

  @override
  bool checkComplete() {
    return _isCompleted;
  }
}

class StageCreationEvent extends Event {
  @override
  String get type => 'Creation';
  final MyGame game;
  List<Event> nextEventBatch;
  bool _isCompleted = false;

  StageCreationEvent(this.game, [this.nextEventBatch = const []]);

  @override
  Future<Stage> execute() async { // Make this method async
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

  @override
  bool checkComplete() {
    return _isCompleted;
  }
}

class UnitCreationEvent extends Event {
  @override
  String get type => 'Creation';
  final MyGame game;
  final String name;
  final Point<int> gridCoord;
  final int level;
  bool _isCompleted = false;
  bool _isStarted = false;
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
    game.stage.tilesMap[gridCoord]!.setUnit(unit);

    // Wait for unit's onLoad to complete
    await unit.loadCompleted;

    // Mark as completed once the unit has finished being created.
    _isCompleted = true;
    // Move the unit to its destination
    game.eventQueue.currentBatch().add(UnitMoveEvent(game, unit, destination));
    game.eventQueue.currentBatch().remove(this);
    return unit;
  }
  
  @override
  bool checkComplete() {
    // Check if the unit has finished moving
    return _isCompleted;
  }
  @override
  bool checkStarted() {
    // Check if the unit has finished moving
    return _isStarted;
  }
}

class UnitMoveEvent extends Event {
  @override
  String get type => 'Movement';
  final MyGame game;
  final Point<int> gridCoord;
  final Unit unit;
  bool _isCompleted = false;
  bool _isStarted = false;
  UnitMoveEvent(this.game, this.unit, this.gridCoord);

  @override
  void execute() async { // Make this method async
    _isStarted = true;
    dev.log("Move unit ${unit.name}");
    unit.move(game.stage, gridCoord);
    _isCompleted = true;
  }
  
  @override
  bool checkComplete() {
    return _isCompleted && unit.isMoving == false;
  }
  @override
  bool checkStarted() {
    // Check if the unit has finished moving
    return _isStarted;
  }
}

class CursorMoveEvent extends Event {
  @override
  String get type => 'Movement';
  final MyGame game;
  final Point<int> gridCoord;
  bool _isCompleted = false;
  bool _isStarted = false;
  CursorMoveEvent(this.game, this.gridCoord);

  @override
  void execute() async { // Make this method async
    _isStarted = true;
    dev.log("Move cursor to $gridCoord");
    game.stage.cursor.panToTile(gridCoord);
  }
  
  @override
  bool checkComplete() {
    return _isCompleted && game.stage.cursor.isMoving == false;
  }
  @override
  bool checkStarted() {
    // Check if the unit has finished moving
    return _isStarted;
  }
}
class TurnStartEvent extends Event {
  final UnitTeam activeTeam;
  TurnStartEvent(this.activeTeam);

}



class UnitDeathEvent extends Event {
  final Unit unit;
  UnitDeathEvent(this.unit);
  
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