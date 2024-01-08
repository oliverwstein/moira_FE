import 'dart:developer' as dev;
import 'engine.dart';

abstract class GameEvent {}

class TurnStartEvent extends GameEvent {
  final UnitTeam activeTeam;
  TurnStartEvent(this.activeTeam);
}

class UnitCreationEvent extends GameEvent {
  final Unit unit;
  UnitCreationEvent(this.unit);
}

class UnitDeathEvent extends GameEvent {
  final Unit unit;
  UnitDeathEvent(this.unit);
}

class EventDispatcher {
  final List<Observer> _observers = [];

  void add(Observer observer) {
    _observers.add(observer);
  }

  void remove(Observer observer) {
    _observers.remove(observer);
  }

  void dispatch(GameEvent event) {
    for (var observer in _observers) {
      observer.onEvent(event);
    }
  }
}