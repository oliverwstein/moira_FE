import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:moira/content/content.dart';
enum Damage {physical, magical, noncombat}

class Combat extends Component with HasGameReference<MoiraGame>{
  Unit attacker;
  Unit defender;
  int damage = 0;
  bool duel;
  Combat(this.attacker, this.defender, {this.duel = false});

  @override
  void update(dt) {

  }

  static int getCombatDistance(unit, target){
    return (unit.tilePosition.x - target.tilePosition.x).abs() + (unit.tilePosition.y - target.tilePosition.y).abs();
  }

  void addFollowUp() {
    (Unit, Unit)? followUp = (attacker.getStat("spe") >= defender.getStat("spe") + 4) ? (attacker, defender) :
                  (defender.getStat("spe") >= attacker.getStat("spe") + 4) ? (defender, attacker) : null;
    if(followUp == null) {
      return;
    } else {
      game.eventQueue.addEventBatch([AttackEvent(this, followUp.$1, followUp.$2)]);
    }
  }
}

class StartCombatEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  final Unit target;
  final bool duel;
  late final Combat combat;
  StartCombatEvent(this.unit, this.target, {Trigger? trigger, String? name, this.duel = false}) : super(trigger: trigger, name: name ?? "StartCombat_${unit.name}_${target.name}"){
    combat = Combat(unit, target, duel: duel);
  }
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("StartCombatEvent: ${combat.attacker.name} against ${combat.defender.name}");
    if(duel) debugPrint("Duel! $name");
    game.add(combat);
    game.eventQueue.addEventBatch([CombatRoundEvent(combat)]);
    game.eventQueue.addEventBatch([EndCombatEvent(combat)]);
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class CombatRoundEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  CombatRoundEvent(this.combat, {Trigger? trigger, String? name}) 
    : super(trigger: trigger, name: name ?? "CombatRound_${combat.attacker.name}_${combat.defender.name}");

  static void initialize(EventQueue eventQueue) {
    eventQueue.registerClassObserver<EndCombatEvent>((endCombatEvent) {
      if (endCombatEvent.combat.duel && !endCombatEvent.combat.attacker.dead && !endCombatEvent.combat.defender.dead) {
        CombatRoundEvent newCombatRoundEvent = CombatRoundEvent(endCombatEvent.combat);
        EventQueue eventQueue = endCombatEvent.game.eventQueue;
        eventQueue.addEventBatchToHead([newCombatRoundEvent]);
      } else {
        endCombatEvent.combat.removeFromParent();
      }
    });
  }
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("CombatRoundEvent: ${combat.attacker.name} against ${combat.defender.name}");
    game.eventQueue.addEventBatch([AttackEvent(combat, combat.attacker, combat.defender)]);
    game.eventQueue.addEventBatch([AttackEvent(combat, combat.defender, combat.attacker)]);
    combat.addFollowUp();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class EndCombatEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  EndCombatEvent(this.combat, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "EndCombat_${combat.attacker.name}_${combat.defender.name}");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("EndCombatEvent: ${combat.attacker.name} against ${combat.defender.name}");
    game.eventQueue.addEventBatch([UnitExhaustEvent(combat.attacker)]);
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class AttackEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  final Unit unit;
  final Unit target;
  AttackEvent(this.combat, this.unit, this.target, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "Attack_${unit.name}_${target.name}");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    if (combat.attacker.dead || combat.defender.dead) {
      debugPrint("Combat ended due to death.");
      completeEvent();
      return;
    }
    debugPrint("AttackEvent: ${unit.name} against ${target.name}");
    combat.damage = 0;
    Random rng = Random();
    var vals = unit.attackCalc(target, unit.attack);
    if (vals.accuracy > 0) {
      if (rng.nextInt(100) + 1 <= vals.accuracy) {
        // Attack hits
        game.eventQueue.addEventBatchToHead([HitEvent(combat, unit, target, vals)]);
      } else {
        game.eventQueue.addEventBatchToHead([MissEvent(combat, unit, target)]);
      }
    }
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class HitEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  final Unit unit;
  final Unit target;
  final ({int accuracy, int critRate, int damage, int fatigue}) vals;
  
  HitEvent(this.combat, this.unit, this.target, this.vals, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "Hit_${unit.name}_${target.name}");
  
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("HitEvent: ${unit.name} hits ${target.name}");
    combat.damage = vals.damage;
    game.eventQueue.addEventBatchToHead([DamageEvent(combat, target)]);
    game.eventQueue.dispatchEvent(this);
    completeEvent();
  }
}

class MissEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  final Unit unit;
  final Unit target;
  
  MissEvent(this.combat, this.unit, this.target, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "Miss_${unit.name}_${target.name}");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("MissEvent: ${unit.name} misses ${target.name}");
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class CritEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  final Unit unit;
  final Unit target;
  static void initialize(EventQueue eventQueue) {
    eventQueue.registerClassObserver<HitEvent>((hitEvent) {
      debugPrint("Critical hit rate: ${hitEvent.vals.critRate}");
      if (hitEvent.vals.critRate > 0) {
        Random rng = Random();
        if (rng.nextInt(100) + 1 <= hitEvent.vals.critRate) {
          CritEvent critEvent = CritEvent(hitEvent.combat, hitEvent.unit, hitEvent.target);
          EventQueue eventQueue = hitEvent.game.eventQueue;
          eventQueue.addEventBatchToHead([critEvent]);
        }
      }
    });
  }
  
  CritEvent(this.combat, this.unit, this.target, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "Crit_${unit.name}_${target.name}");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("CritEvent: ${unit.name} lands a critical hit on ${target.name}");
    combat.damage *= 3;
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class DamageEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  final Unit unit;
  DamageEvent(this.combat, this.unit, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "Damage_${unit.name}");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("DamageEvent: ${unit.name} takes ${combat.damage} damage.");
    unit.hp = (unit.hp - combat.damage).clamp(0, unit.getStat("hp"));
    debugPrint("DamageEvent: ${unit.name} now has ${unit.hp} hp.");
    game.eventQueue.dispatchEvent(this);
    completeEvent();
  }
}