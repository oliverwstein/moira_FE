import 'dart:developer' as dev;
import 'dart:math';
import 'engine.dart';

abstract class Observer {
  Type? listensTo;
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

class Mover extends Observer {
  final Unit unit;
  final Point<int> destination;

  Mover(this.unit, this.destination);
  
  @override
  void onEvent(GameEvent event) {
    if (event is UnitCreationEvent && unit == event.unit) {
    }
  }

}

class Canto extends Observer {
  final Unit unit;
  Canto(this.unit) {
    listensTo = UnitActionEndEvent;
  }

  @override
  void onEvent(GameEvent event) {
    if (event.runtimeType == UnitActionEndEvent && event is UnitActionEndEvent && unit == event.unit) {
      // Stage stage = unit.parent as Stage;
      dev.log('${unit.remainingMovement}');
      unit.toggleCanAct(true);
      dev.log("${unit.actionsAvailable}");
    }
  }
}

class Pavise extends Observer {
  final Unit unit;
  Pavise(this.unit) {
    listensTo = MakeAttackEvent;
  }

  @override
  void onEvent(GameEvent event) {
    if (event.runtimeType == MakeAttackEvent && event is MakeAttackEvent && unit == event.defender) {
      // Stage stage = unit.parent as Stage;
      dev.log('${unit.name} has pavise');
      var rng = Random();
      int activationRate = event.defender.getStat('dex');
      if (rng.nextInt(100) + 1 <= activationRate) {
        event.combat.damageDealt = 0;
        dev.log('Pavise nullified the blow!');
      }
    }
  }
}