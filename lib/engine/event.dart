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

class CreateStageEvent extends Event {
  final MyGame game;
  bool _isCompleted = false;

  CreateStageEvent(this.game);

  @override
  void execute() async { // Make this method async
    dev.log("Load the stage");
    game.stage = Stage();
    game.world.add(game.stage); // Add the stage to the game world

    // Await the completion of Stage's onLoad
    await game.stage.loadCompleted;

    // Once Stage's onLoad is complete, proceed with further actions
    dev.log("Stage loaded");
    game.addObserver(game.stage);
    _isCompleted = true;
    dev.log("After _isCompleted check");
    game.screen.removeFromParent();
    game.screen = game.stage;
    
    // Add your next event here
    // game.eventQueue.addEventBatch([YourNextEvent()]);
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

class UnitCreationEvent extends Event {
  final Unit unit;
  UnitCreationEvent(this.unit);
  
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