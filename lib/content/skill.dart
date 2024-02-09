import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';

enum Skill {canto, pavise, vantage}
extension SkillExtension on Skill {
  // Method to get the skill name with the first letter capitalized
  String get name => toString().split('.').last.replaceFirstMapped(RegExp(r'[a-zA-Z]'), (match) => match.group(0)!.toUpperCase());

  // Static method to get a skill by its name
  static Skill? fromName(String name) {
    try {
      return Skill.values.firstWhere((skill) => skill.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null; // Return null if no matching skill is found
    }
  }
}
Set<Skill> getSkillsFromNames(List<String> skillNames) {
  return skillNames.map((name) => SkillExtension.fromName(name))
                   .whereType<Skill>()
                   .toSet();
}

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
    eventQueue.registerClassObserver<UnitExhaustEvent>((unitExhaustEvent) {
      if (unitExhaustEvent.unit.hasSkill(Skill.canto) && unitExhaustEvent.unit.remainingMovement >= .7 && unitExhaustEvent.manual == false) {
        debugPrint("Canto Activates");
        unitExhaustEvent.unit.toggleCanAct(true);
        CantoEvent cantoEvent = CantoEvent(unitExhaustEvent.unit);
        EventQueue eventQueue = unitExhaustEvent.game.eventQueue;
        eventQueue.addEventBatch([cantoEvent]);
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
    if (unit.controller.takingTurn && game.stage.activeFaction is! AIPlayer){
      if(unit.findReachableTiles(unit.remainingMovement).length > 1){
        game.stage.menuManager.pushMenu(CantoMenu(unit, game.stage.tileMap[unit.tilePosition]!));
      } else {game.eventQueue.addEventBatch([UnitExhaustEvent(unit, manual: true)]);}
      
    } else if (unit.controller.takingTurn && game.stage.activeFaction is AIPlayer){
      var rankedTiles = unit.rankOpenTiles(["Move"]);
      if (rankedTiles.length > 1) {
        var bestTileEvent = rankedTiles.first;
        game.eventQueue.addEventBatchToHead(bestTileEvent.events);
      } 
      game.eventQueue.addEventBatch([UnitExhaustEvent(unit, manual: true)]);
    }
    

    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}