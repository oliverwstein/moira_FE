import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';
class Staff extends Component with HasGameReference<MoiraGame>{
  // Event? staffEvent;
  int range;
  int staminaCost;
  Staff(this.range, {this.staminaCost = 1});
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
  bool canUseOn(Unit target) => true;
  void execute(Unit target){
    debugPrint("Use staff on ${target.name}. They feel funny.");
  }
  String effectString(Unit target){
    return "They feel funny.";
  }
}

class Heal extends Staff {
  int baseHealing;
  int expGain;
  Heal(super.range, this.baseHealing, this.expGain, int staminaCost) : super(staminaCost: staminaCost);
  @override
  bool canUseOn(Unit target) => target.hp < target.getStat("hp");

  int healingCalc(Unit target){
    Unit wielder = parent as Unit;
    return baseHealing + wielder.getStat("wis");
  }
  @override
  execute(Unit target){
    debugPrint("Execute Heal on ${target.name}");
    Unit wielder = parent as Unit;
    int healing = healingCalc(target);
    wielder.sta = (wielder.sta - staminaCost).clamp(0, wielder.getStat("sta"));
    game.eventQueue.addEventBatch([UnitHealEvent(target, healing)]);
    game.eventQueue.addEventBatch([UnitExpEvent(wielder, expGain)]);
    game.eventQueue.addEventBatch([UnitExhaustEvent(wielder)]);
  }
  @override
  String effectString(Unit target){
    return "HP:${target.hp}/${target.getStat("hp")} to ${(target.hp+healingCalc(target)).clamp(0, target.getStat("hp"))}";
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

