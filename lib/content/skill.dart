import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';

enum Skill {canto, pavise, vantage}

class VantageEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  static void initialize(EventQueue eventQueue) {
    eventQueue.registerClassObserver<StartCombatEvent>((combatEvent) {
      if (combatEvent.combat.defender.hasSkill(Skill.vantage)) {
        VantageEvent vantageEvent = VantageEvent(combatEvent.combat);
        EventQueue eventQueue = combatEvent.game.eventQueue;
        eventQueue.addEventBatchToHead([vantageEvent]);
      }
    });
  }
  
  VantageEvent(this.combat, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    Unit temp = combat.attacker;
    combat.attacker = combat.defender;
    combat.defender = temp;
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class CantoEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  static void initialize(EventQueue eventQueue) {
    eventQueue.registerClassObserver<ExhaustUnitEvent>((exhaustUnitEvent) {
      if (exhaustUnitEvent.unit.hasSkill(Skill.canto)) {
        CantoEvent cantoEvent = CantoEvent(exhaustUnitEvent.unit);
        EventQueue eventQueue = exhaustUnitEvent.game.eventQueue;
        eventQueue.addEventBatchToHead([cantoEvent]);
      }
    });
  }
  
  CantoEvent(this.unit, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    game.stage.blankAllTiles();
    debugPrint("Canto: unit's remaining movement is: ${unit.remainingMovement}");
    unit.findReachableTiles(unit.remainingMovement);
    if (game.stage.factionMap[unit.faction] == game.stage.activeFaction){
      game.stage.menuManager.pushMenu(CantoMenu(unit, game.stage.tileMap[unit.tilePosition]!));
    }
    // @TODO: I'll need to set something up that allows the AI to use Canto too.
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}