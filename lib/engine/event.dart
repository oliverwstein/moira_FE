// ignore_for_file: unused_import

import 'dart:collection';
import 'dart:developer' as dev;
import 'engine.dart';

abstract class Event {
  void execute();
  bool checkComplete();
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

class TurnStartEvent extends Event {
  final UnitTeam activeTeam;
  TurnStartEvent(this.activeTeam);
  
  @override
  bool checkComplete() {
    // TODO: implement checkComplete
    throw UnimplementedError();
  }
  
  @override
  void execute() {
    // TODO: implement execute
  }
}

class UnitCreationEvent extends Event {
  final Unit unit;
  UnitCreationEvent(this.unit);
  
  @override
  bool checkComplete() {
    // TODO: implement checkComplete
    throw UnimplementedError();
  }
  
  @override
  void execute() {
    // TODO: implement execute
  }
}

class UnitDeathEvent extends Event {
  final Unit unit;
  UnitDeathEvent(this.unit);
  
  @override
  bool checkComplete() {
    // TODO: implement checkComplete
    throw UnimplementedError();
  }
  
  @override
  void execute() {
    // TODO: implement execute
  }
}

class UnitActionEndEvent extends Event {
  final Unit unit;
  UnitActionEndEvent(this.unit);
  
  @override
  bool checkComplete() {
    // TODO: implement checkComplete
    throw UnimplementedError();
  }
  
  @override
  void execute() {
    // TODO: implement execute
  }
  
}

class MakeAttackEvent extends Event {
  final Combat combat;
  final Unit attacker;
  final Unit defender;
  MakeAttackEvent(this.combat, this.attacker, this.defender);
  
  @override
  bool checkComplete() {
    // TODO: implement checkComplete
    throw UnimplementedError();
  }
  
  @override
  void execute() {
    // TODO: implement execute
  }
}

class MakeDamageEvent extends Event {
  final Unit unit;
  MakeDamageEvent(this.unit);
  
  @override
  bool checkComplete() {
    // TODO: implement checkComplete
    throw UnimplementedError();
  }
  
  @override
  void execute() {
    // TODO: implement execute
  }
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