import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

class Trigger extends Component {
  bool Function(Event) check;
  Trigger(this.check);

  factory Trigger.fromJson(dynamic triggerData, Event event) {
    switch (triggerData.keys.first) {
      case "StartTurnEvent":
        int turn = triggerData["StartTurnEvent"]["turn"] ?? -1;
        String factionName = triggerData["StartTurnEvent"]["factionName"];
        StartTurnEvent.observers.add(event);
        String? name = triggerData["StartTurnEvent"]["name"];
        if (name != null) return Trigger.byName(name);
        return Trigger._startTurn(turn, factionName);
      case "DialogueEvent":
        String name = triggerData["DialogueEvent"]["nodeName"] ?? triggerData["DialogueEvent"]["name"];
        DialogueEvent.observers.add(event);
        return Trigger.byName(name);
      case "PanEvent":
        PanEvent.observers.add(event);
        String name = triggerData["PanEvent"]["name"];
        return Trigger.byName(name);
      case "UnitCreationEvent":
        UnitCreationEvent.observers.add(event);
        String name = triggerData["UnitCreationEvent"]["name"];
        return Trigger.byName(name);
      case "UnitMoveEvent":
        UnitMoveEvent.observers.add(event);
        String name = triggerData["UnitMoveEvent"]["name"];
        return Trigger.byName(name);
      case "UnitExitEvent":
        UnitExitEvent.observers.add(event);
        String name = triggerData["UnitExitEvent"]["name"];
        return Trigger.byName(name);
      default:
        String name = triggerData[triggerData.keys.first]["name"];
        Event.getObserversByClassName(triggerData.keys.first).add(event);
        return Trigger.byName(name);
    }
  }

  Trigger._startTurn(int turn, String factionName) : check = ((Event event) {
    // debugPrint("Check StartTurnEvent");
    if (event is StartTurnEvent) {
      return event.factionName == factionName && (event.turn == turn || turn == -1);
    }
    return false;
  });

  Trigger.byName(String name) : check = ((Event event) {
    // debugPrint("Check Event by name $name");
    if (event.name != null) {
      return event.name == name;
    }
    return false;
  });

  Trigger.death(Unit unit) : check = ((Event event) {
    if (event is CombatDamageEvent && unit.hp <= 0) {
      return true;
    }
    return false;
  }) {
    CombatDamageEvent.observers.add(UnitDeathEvent(unit, trigger: this));
  }
}