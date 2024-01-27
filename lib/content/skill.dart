import 'package:flame/components.dart';
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
    // Set<Tile> reachableTiles = unit.findReachableTiles(unit.toDouble());
    // tile.unit!.markAttackableTiles(reachableTiles.toList());
    // // if the unit is a part of the active faction, add the MoveMenu to the stack.
    // if (game.stage.factionMap[tile.unit!.faction] == game.stage.activeFaction){
    //   pushMenu(MoveMenu(tile.unit!, tile));
    // }
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}