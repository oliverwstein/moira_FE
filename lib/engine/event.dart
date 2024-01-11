// ignore_for_file: unused_import

import 'dart:collection';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/services.dart';

import 'engine.dart';

abstract class Event {
  void execute(){}
  bool checkComplete(){return true;}
  void handleUserInput(RawKeyEvent event){}
}

class EventQueue {
  Queue<List<Event>> _eventBatches = Queue<List<Event>>();
  List<Event> _currentBatch = [];
  bool _isProcessing = false;

  void addEventBatch(List<Event> eventBatch) {
    _eventBatches.add(eventBatch);
  }

  void update(double dt) {
    if (_isProcessing && _currentBatch.every((event) => event.checkComplete())) {
      _isProcessing = false;
      _currentBatch.clear();
    }

    if (!_isProcessing && _eventBatches.isNotEmpty) {
      _currentBatch = _eventBatches.removeFirst();
      for (var event in _currentBatch) {
        event.execute();
      }
      _isProcessing = true;
    }
  }
}

class StageCreationEvent extends Event {
  final MyGame game;
  final List<Event> nextEventBatch;
  bool _isCompleted = false;

  StageCreationEvent(this.game, [this.nextEventBatch = const []]);

  @override
  void execute() async { // Make this method async
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
  }

  @override
  bool checkComplete() {
    return _isCompleted;
  }
}

class UnitCreationEvent extends Event {
  final MyGame game;
  final String name;
  final Point<int> gridCoord;
  final List<Event> nextEventBatch;
  bool _isCompleted = false;
  final int level;
  late final Unit unit;
  UnitCreationEvent(this.game, this.name, this.gridCoord, [this.nextEventBatch = const [], this.level = -1]);

  @override
  void execute() async { // Make this method async
    dev.log("Create unit $name");
    if(this.level>0){unit = Unit.fromJSON(gridCoord, name, level:level);}
    else {unit = Unit.fromJSON(gridCoord, name);}
    game.stage.add(unit); // Add the unit to the stage
    game.stage.units.add(unit);
    game.stage.tilesMap[gridCoord]!.setUnit(unit);

    // Await the completion of unit's onLoad
    await unit.loadCompleted;

    // Once Stage's onLoad is complete, proceed with further actions
    dev.log("Unit loaded");
    _isCompleted = true;
    
    // Add your next event here
    game.eventQueue.addEventBatch(nextEventBatch);
  }
  
  @override
  bool checkComplete() {
    return _isCompleted;
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