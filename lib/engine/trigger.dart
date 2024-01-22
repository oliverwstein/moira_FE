import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/content/content.dart';

class Trigger extends Component {
  bool Function(Event) check;
  Trigger(this.check);

  factory Trigger.fromJson(dynamic triggerData, Event event) {
    String? name = triggerData.keys.first["name"];
    switch (triggerData.keys.first) {
      case "StartTurnEvent":
        int turn = triggerData["StartTurnEvent"]["turn"];
        String factionName = triggerData["StartTurnEvent"]["factionName"];
        StartTurnEvent.observers.add(event);
        if (name != null) return Trigger._byName(name);
        return Trigger._startTurn(turn, factionName);
      case "DialogueEvent":
        String nodeName = triggerData["DialogueEvent"]["nodeName"];
        DialogueEvent.observers.add(event);
        if (name != null) return Trigger._byName(name);
        return Trigger._dialogue(nodeName);
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

  Trigger._dialogue(String nodeName) : check = ((Event event) {
    if (event is DialogueEvent) {
      return event.nodeName == nodeName;
    }
    return false;
  });

  Trigger._dummy() : check = ((Event event) => false);
  
  Trigger._byName(String name) : check = ((Event event) {
    if (event.name != null) {
      return event.name == name;
    }
    return false;
  });
}