import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';
class Staff extends Component with HasGameReference<MoiraGame>{
  // Event? staffEvent;
  int range;
  Staff(this.range);
  factory Staff.fromJson(dynamic staffData, String name) {
    int staffRange = staffData["range"] ?? 1;
    int staminaCost = staffData["staminaCost"] ?? 1;
    int expGain = staffData["expGain"] ?? 10;
    switch (staffData["effect"]){
      case "Heal":
        int baseHealing = staffData["base"] ?? 10;
        return Heal(staffRange, baseHealing, staminaCost, expGain);
      default:
        return Staff(staffRange);
    }
  }
  void execute(Unit target){
    debugPrint("Use staff on ${target.name}. They feel funny.");
  }
}

class Heal extends Staff {
  int baseHealing;
  int staminaCost;
  int expGain;
  Heal(super.range, this.baseHealing, this.staminaCost, this.expGain);
  @override
  execute(Unit target){
    debugPrint("Execute Heal on ${target.name}");
    Unit wielder = parent as Unit;
    int healing = baseHealing + wielder.getStat("wis");
    game.eventQueue.addEventBatch([UnitHealEvent(target, healing)]);
    game.eventQueue.addEventBatch([UnitExpEvent(wielder, expGain)]);
    game.eventQueue.addEventBatch([UnitExhaustEvent(wielder)]);
  }
}

class UnitHealEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  final int healing;
  UnitHealEvent(this.unit, this.healing, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "UnitHealEvent: ${unit.name}_$healing");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("$name");
    unit.hp = (unit.hp + healing).clamp(0, unit.getStat("hp"));
    debugPrint("UnitHealEvent: ${unit.name} now has ${unit.hp} hp.");
    game.combatQueue.dispatchEvent(this);
    completeEvent();
  }
}

