import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';

mixin UnitBehavior on PositionComponent {
  Point<int> get _tilePosition => (this as Unit).tilePosition;
  MoiraGame get game;
  Unit get unit => (this as Unit);


  List<({List<Event> events, double score})> rankOpenTiles() {
  List<Tile> openTiles = getTilesInMoveRange(unit.movementRange.toDouble());
  var rankedTiles = List.generate(openTiles.length, (_) => (events: <Event>[], score: 0.0));
  debugPrint("${unit.name} can move to ${openTiles.length} tiles because it has ${unit.movementRange} movement.");
  Random rng = Random();
  int count = 0;
  for (Tile tile in openTiles) {
    List<Event> eventList = [];
    double tileScore = getTileDefenseScore(tile) + rng.nextDouble()-.5;

    if (tile.point != unit.tilePosition) {
      eventList.add(UnitMoveEvent(unit, tile.point));
    }

    var bestTarget = bestTargetFrom(tile);
    if (bestTarget != null) {
      debugPrint("Best target from ${tile.point} is ${bestTarget.target.name}, score: ${bestTarget.score}");
      eventList.add(StartCombatEvent(unit, bestTarget.target));
      tileScore += bestTarget.score;
    }

    rankedTiles[count] = (events: eventList, score: tileScore);
    count++;
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
    List<Unit> targets = unit.getTargets(tile.point);
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
    // If the unit is brave, it should consider unit.level + expectedDamageDealt + expectedDamageTaken; it wants a good fight.
    // If the unit is neutral, it should consider unit.level + expectedDamageDealt - expectedDamageTaken; it wants a fight to its advantage.
    // If the unit is cowardly, it should consider unit.level + expectedDamageDealt - expectedDamageTaken**2; it wants a fight where it won't get hurt.
    double expectedDamageDealt = unit.getBestAttackOnTarget(target, getAttacksOnTarget(target, distance));
    double expectedDamageTaken = target.getBestAttackOnTarget(unit, getAttacksOnTarget(unit, distance));
    if(expectedDamageDealt >= target.hp) expectedDamageTaken = 0;
    // For now, just have all the units follow the neutral rules.
    return (unit.level + expectedDamageDealt - expectedDamageTaken);

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
}