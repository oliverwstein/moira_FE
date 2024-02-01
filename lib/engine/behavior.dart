import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';

mixin UnitBehavior on PositionComponent {
  Point<int> get _tilePosition => (this as Unit).tilePosition;
  MoiraGame get game;
  Unit get unit => (this as Unit);



  List<({List<Event> events, double score})> getMoveEventsAndScores(List<Tile> openTiles) {
  return List.generate(openTiles.length, (index) {
    var tile = openTiles[index];
    List<Event> eventList = [];
    double tileScore = getTileDefenseScore(tile) + Random().nextDouble() - 0.5;
    if (tile.point != unit.tilePosition) {
      eventList.add(UnitMoveEvent(unit, tile.point));
    }
    return (events: eventList, score: tileScore);
  });
}

  List<({List<Event> events, double score})> getCombatEventsAndScores(List<Tile> openTiles) {
  return List.generate(openTiles.length, (index) {
    var tile = openTiles[index];
    List<Event> eventList = [];
    double combatScore = 0.0;

    var bestTarget = bestTargetFrom(tile);
    if (bestTarget != null) {
      debugPrint("Best target from ${tile.point} is ${bestTarget.target.name}, score: ${bestTarget.score}");
      eventList.add(StartCombatEvent(unit, bestTarget.target));
      combatScore += bestTarget.score;
    }

    return (events: eventList, score: combatScore);
  });
}


  List<({List<Event> events, double score})> rankOpenTiles(List<String> eventTypes) {
  List<Tile> openTiles = getTilesInMoveRange(unit.remainingMovement);
  // debugPrint("${unit.name} can move to ${openTiles.length} tiles because it has ${unit.movementRange} movement.");
  var rankedTiles = List.generate(openTiles.length, (_) => (events: <Event>[], score: 0.0));
  if (eventTypes.contains("Move")) {
    var moveResults = getMoveEventsAndScores(openTiles);
    for (var i = 0; i < rankedTiles.length; i++) {
      rankedTiles[i] = (events: rankedTiles[i].events + moveResults[i].events, score: rankedTiles[i].score+ moveResults[i].score);
    }
  }
  if (eventTypes.contains("Combat")) {
    var combatResults = getCombatEventsAndScores(openTiles);
    for (var i = 0; i < rankedTiles.length; i++) {
      rankedTiles[i] = (events: rankedTiles[i].events + combatResults[i].events, score: rankedTiles[i].score + combatResults[i].score);
    }
  }

  rankedTiles.sort((a, b) => b.score.compareTo(a.score)); // Sort by score in descending order
  return rankedTiles;
}

  double getTileDefenseScore(Tile tile){
    return tile.getTerrainDefense() + tile.getTerrainAvoid()/10;
  }
  
  List<Tile> getTilesInMoveRange(double range){
    return unit.findReachableTiles(range, markTiles: false).toList();
  }

  ({Unit target, double score})? bestTargetFrom(Tile tile){
    List<Unit> targets = unit.getTargetsAt(tile.point);
    Unit? bestTarget;
    double bestCombatScore = 0;
    for(Unit target in targets){
      int distance = Tile.getDistance(tile.point, target.tilePosition);
      double combatScore = judgeCombatAtDistance(target, distance);
      if (combatScore > bestCombatScore) {
        bestCombatScore = combatScore;
        bestTarget = target;
      }
    }
    if(bestTarget != null) return (target: bestTarget, score: bestCombatScore);
    return null;
  }

  double judgeCombatAtDistance(target, distance){
    // behavioral states: brave, neutral, cowardly. 
    // If the unit is brave, it should consider unit.level + expectedDamageDealt*2 + expectedDamageTaken; it wants a good fight.
    // If the unit is neutral, it should consider unit.level + expectedDamageDealt*2 - expectedDamageTaken; it wants a fight to its advantage.
    // If the unit is cowardly, it should consider unit.level + expectedDamageDealt*2 - expectedDamageTaken**2; it wants a fight where it won't get hurt.
    // But for now, just have all the units follow the neutral rules.
    double expectedDamageDealt = unit.getBestAttackOnTarget(target, getAttacksOnTarget(target, distance));
    double expectedDamageTaken = target.getBestAttackOnTarget(unit, getAttacksOnTarget(unit, distance));
    if(expectedDamageDealt >= target.hp) expectedDamageTaken = 0;
    double score = unit.level + expectedDamageDealt*2 - expectedDamageTaken;
    return (score);
  }

  List<Attack> getAttacksOnTarget(Unit target, combatDistance){
    List<Attack> attacks = [];
    for (Attack attack in unit.attackSet.values){
        if(attack.range.$1<=combatDistance && attack.range.$2 >=combatDistance){
          attacks.add(attack);
        }
      }
    return attacks;
  }

  double getBestAttackOnTarget(Unit target, List<Attack> attacks){
    double expectedDamage = 0;
    unit.attack = attacks.firstOrNull;
    for (Attack attack in attacks){
      var attackCalc = unit.attackCalc(target, attack);
      double expectedAttackDamage = (attackCalc.damage*attackCalc.accuracy + attackCalc.damage*attackCalc.accuracy*attackCalc.critRate*.03)/100;
      if(expectedAttackDamage > expectedDamage){
        expectedDamage = expectedAttackDamage;
        unit.attack = attack;
      }
    }
    return expectedDamage;
  }
  void makeBestAttackAt(Tile tile) {
    ({double score, Unit target})? target = unit.bestTargetFrom(tile);
    if(target != null) {
      unit.game.eventQueue.addEventBatch([StartCombatEvent(unit, target.target)]);
    }
  }
}

class UnitOrderEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  final Order order;
  UnitOrderEvent(this.unit, this.order, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
   
  }
}

class UnitActionEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  UnitActionEvent(this.unit, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
   
  }
}
