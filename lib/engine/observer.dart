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
    if (event is UnitCreationEvent) {
      dev.log('${unit.name} is announced!');
    }
  }
}