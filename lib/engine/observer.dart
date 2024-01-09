import 'dart:developer' as dev;
import 'engine.dart';

abstract class Observer {
  void onEvent(GameEvent event);
}

class Announcer extends Observer {
  final Unit unit;

  Announcer(this.unit);

  @override
  void onEvent(GameEvent event) {
    if (event is UnitCreationEvent && unit == event.unit) {
      dev.log('${unit.name} is announced!');
    } else if (event is UnitDeathEvent && unit == event.unit) {
      dev.log('${unit.name} is dead!');
    }
  }
}

class Canto extends Observer {
  final Unit unit;

  Canto(this.unit);

  @override
  void onEvent(GameEvent event) {
    if (event is UnitActionEndEvent && unit == event.unit) {
      // Stage stage = unit.parent as Stage;
      dev.log('${unit.remainingMovement}');
      unit.toggleCanAct(true);
    }
  }
}