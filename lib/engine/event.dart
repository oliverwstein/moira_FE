// ignore_for_file: unused_import

import 'dart:collection';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/services.dart';

import 'engine.dart';

class EventQueue {
  Queue<List<Event>> _eventBatches = Queue<List<Event>>();
  List<Event> _currentBatch = [];
  bool _isProcessing = false;

  void addEventBatch(List<Event> eventBatch) {
    _eventBatches.add(eventBatch);
  }

  bool isProcessing(){
    return _isProcessing;
  }

  List<Event> currentBatch(){
    return _currentBatch;
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

abstract class Event {
  void execute(){}
  bool checkComplete(){return true;}
  void handleUserInput(RawKeyEvent event){}
}

class TitleCardCreationEvent extends Event {
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
  final MyGame game;
  List<Event> nextEventBatch;
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
  Point<int>? destination;
  bool _isCompleted = false;
  final int level;
  late final Unit unit;
  UnitCreationEvent(this.game, this.name, this.gridCoord, [this.level = -1, this.destination]);

  @override
  void execute() async { // Make this method async
    dev.log("Create unit $name");
    if(level>0){unit = Unit.fromJSON(gridCoord, name, level:level);}
    else {unit = Unit.fromJSON(gridCoord, name);}
    game.stage.add(unit); // Add the unit to the stage
    game.stage.units.add(unit);
    game.stage.tilesMap[gridCoord]!.setUnit(unit);

    // Await the completion of unit's onLoad
    await unit.loadCompleted;

    // Once Stage's onLoad is complete, proceed with further actions
    dev.log("Unit loaded");
    _isCompleted = true;
    List<Event> nextEventBatch = [];
    if(destination != null){
      nextEventBatch = [UnitMoveEvent(game, unit, destination!)];
    } 
    // Add your next event here
    game.eventQueue.addEventBatch(nextEventBatch);
    
  }
  
  @override
  bool checkComplete() {
    return _isCompleted;
  }
}

class UnitMoveEvent extends Event {
  final MyGame game;
  final Point<int> gridCoord;
  bool _isCompleted = false;
  final Unit unit;
  UnitMoveEvent(this.game, this.unit, this.gridCoord);

  @override
  void execute() async { // Make this method async
    dev.log("Move unit ${unit.name}");
    // unit.move(game.stage, gridCoord);
    _isCompleted = true;
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