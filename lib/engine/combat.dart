import 'dart:collection';
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
  final Map<Unit, int> expGain = {};
  Combat(this.attacker, this.defender, {this.duel = false}){
    expGain[attacker] = 1; expGain[defender] = 1;
  }

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
      game.combatQueue.addEventBatch([AttackEvent(this, followUp.$1, followUp.$2)]);
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
    game.combatQueue.addEventBatch([CombatRoundEvent(combat)]);
    game.combatQueue.dispatchEvent(this);
  }

  @override
  bool checkComplete(){
    return (!game.combatQueue.processing && game.combatQueue.eventBatches.isEmpty);
  }
}

class CombatRoundEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  CombatRoundEvent(this.combat, {Trigger? trigger, String? name}) 
    : super(trigger: trigger, name: name ?? "CombatRound_${combat.attacker.name}_${combat.defender.name}");

  static void initialize(EventQueue queue) {}
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("CombatRoundEvent: ${combat.attacker.name} against ${combat.defender.name}");
    game.combatQueue.addEventBatch([AttackEvent(combat, combat.attacker, combat.defender)]);
    game.combatQueue.addEventBatch([AttackEvent(combat, combat.defender, combat.attacker)]);
    combat.addFollowUp();
    completeEvent();
    game.combatQueue.dispatchEvent(this);
    if (combat.attacker.hp == 0 || combat.defender.hp == 0 || !combat.duel) {
      game.combatQueue.addEventBatch([EndCombatEvent(combat)]);
      return;
    } else {
      debugPrint("Add duel round: ${combat.attacker.name} against ${combat.defender.name}");
      game.combatQueue.addEventBatch([CombatRoundEvent(combat)]);
    }
  }
}

class EndCombatEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  EndCombatEvent(this.combat, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "EndCombatEvent_${combat.attacker.name}_${combat.defender.name}");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("$name");
    completeEvent();
    game.eventQueue.dispatchEvent(this);
    combat.removeFromParent();
    
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
    if (combat.attacker.hp == 0 || combat.defender.hp == 0) {
      debugPrint("Combat ended due to fatal damage.");
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
        game.combatQueue.addEventBatchToHead([HitEvent(combat, unit, target, vals)]);
      } else {
        game.combatQueue.addEventBatchToHead([MissEvent(combat, unit, target)]);
      }
    }
    completeEvent();
    game.combatQueue.dispatchEvent(this);
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
    if(combat.damage > 0) game.combatQueue.addEventBatchToHead([CombatDamageEvent(combat, unit, target)]);
    game.combatQueue.dispatchEvent(this);
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
    game.combatQueue.dispatchEvent(this);
  }
}

class CritEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  final Unit unit;
  final Unit target;
  static void initialize(EventQueue queue) {
    queue.registerClassObserver<HitEvent>((hitEvent) {
      debugPrint("Critical hit rate: ${hitEvent.vals.critRate}");
      if (hitEvent.vals.critRate > 0) {
        Random rng = Random();
        if (rng.nextInt(100) + 1 <= hitEvent.vals.critRate) {
          CritEvent critEvent = CritEvent(hitEvent.combat, hitEvent.unit, hitEvent.target);
          queue.addEventBatchToHead([critEvent]);
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
    game.combatQueue.dispatchEvent(this);
  }
}

class CombatDamageEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  final Unit unit;
  final Unit target;
  CombatDamageEvent(this.combat, this.unit, this.target, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "CombatDamageEvent: ${target.name}_${combat.damage}");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("$name");
    target.hp = (target.hp - combat.damage).clamp(0, target.getStat("hp"));
    if(target.hp == 0) {combat.expGain[unit] = (30 + (target.level - unit.level)*2).clamp(2, 100);}
    else {combat.expGain[unit] = (10 + target.level - unit.level).clamp(1, 100);}
    debugPrint("CombatDamageEvent: ${target.name} now has ${target.hp} hp.");
    game.combatQueue.dispatchEvent(this);
    completeEvent();
  }
}