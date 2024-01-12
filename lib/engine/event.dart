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

  void executeBatch(List<Event> batch) {
    // Execute each event in the current batch
    for (var event in batch) {
      event.execute();
    }
  }

  void update(double dt) {
    if (_isProcessing) {
      if (_currentBatch.every((event) => event.checkComplete())){
        dev.log("Current batch is $_currentBatch, _isProcessing && all batch events completed.");
        // If the batch elements have all been completed, clear the batch
        // and allow EventQueue to go on to the next batch.
        _isProcessing = false;
        _currentBatch.clear();
      } else {
        dev.log("Current batch is $_currentBatch, _isProcessing && some batch events still in progress.");
        List<Event> batch = [];
        for (Event event in _currentBatch){if (!event.checkStarted()) batch.add(event);}
        executeBatch(batch);}
    }
    if (!_isProcessing && _eventBatches.isNotEmpty) {
      dev.log("Current batch is $_currentBatch, !_isProcessing && _eventBatches.isNotEmpty");
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
  bool checkStarted(){return _isStarted;}
  bool checkComplete(){return _isCompleted;}
  void handleUserInput(RawKeyEvent event){}
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
  void handleUserInput(RawKeyEvent event) {
    // You can customize this condition based on your specific requirement
    _isCompleted = true;
    game.eventQueue.addEventBatch(nextEventBatch);
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
    game.stage.tilesMap[gridCoord]!.setUnit(unit);

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
  UnitMoveEvent(this.game, this.unit, this.gridCoord);

  @override
  void execute() async { // Make this method async
    _isStarted = true;
    dev.log("Move unit ${unit.name}");
    unit.move(game.stage, gridCoord);
  }
  @override
  bool checkComplete() {
    return (unit.gridCoord == gridCoord && _isStarted);
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