import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/content/content.dart';

class Trigger extends Component {
  bool Function(Event) check;
  Trigger(this.check);

  factory Trigger.fromJson(dynamic triggerData, Event event) {
    switch (triggerData.keys.first) {
      case "StartTurnEvent":
        int turn = triggerData["StartTurnEvent"]["turn"];
        String factionName = triggerData["StartTurnEvent"]["factionName"];
        StartTurnEvent.observers.add(event);
        String? name = triggerData["StartTurnEvent"]["name"];
        if (name != null) return Trigger._byName(name);
        return Trigger._startTurn(turn, factionName);
      case "DialogueEvent":
        String name = triggerData["DialogueEvent"]["nodeName"] ?? triggerData["DialogueEvent"]["name"];
        DialogueEvent.observers.add(event);
        return Trigger._byName(name);
      case "PanEvent":
        Point<int>? destination = Point(triggerData["PanEvent"]["destination"][0], triggerData["PanEvent"]["destination"][1]);
        PanEvent.observers.add(event);
        String? name = triggerData["PanEvent"]["name"];
        if (name != null) return Trigger._byName(name);
        return Trigger._pan(destination);
      case "UnitCreationEvent":
        UnitCreationEvent.observers.add(event);
        String name = triggerData["UnitCreationEvent"]["name"];
        return Trigger._byName(name);
      case "UnitMoveEvent":
        UnitMoveEvent.observers.add(event);
        String name = triggerData["UnitMoveEvent"]["name"];
        return Trigger._byName(name);
      default:
        return Trigger._dummy();
    }
  }

  Trigger._startTurn(int turn, String factionName) : check = ((Event event) {
    debugPrint("Check StartTurnEvent");
    if (event is StartTurnEvent) {
      return event.factionName == factionName && event.turn == turn;
    }
    return false;
  });

  Trigger._pan(Point<int> destination) : check = ((Event event) {
    debugPrint("Check PanEvent");
    if (event is PanEvent) {
      return event.destination == destination;
    }
    return false;
  });

  Trigger._dummy() : check = ((Event event) => false);
  
  Trigger._byName(String name) : check = ((Event event) {
    debugPrint("Check Event by name $name");
    if (event.name != null) {
      return event.name == name;
    }
    return false;
  });

  Trigger.death(Unit unit) : check = ((Event event) {
    if (event is DamageEvent && unit.hp <= 0) {
      return true;
    }
    return false;
  }) {
    DamageEvent.observers.add(DeathEvent(unit, trigger: this));
  }
}