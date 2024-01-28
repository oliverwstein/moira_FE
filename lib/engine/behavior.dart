import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';

mixin UnitBehavior on PositionComponent {
  Point<int> get _tilePosition => (this as Unit).tilePosition;
  MoiraGame get game;
  Unit get unit => (this as Unit);

  void getCombatEventOptions(){
    List<Tile> openTiles = getTilesInMoveRange(unit.remainingMovement.toDouble());
    for(Tile tile in openTiles){
      var bestTarget = bestTargetFrom(tile);
      if(bestTarget != null) {
        debugPrint("Best target from ${tile.point} is ${bestTarget.target.name}, score: ${bestTarget.score}");
      }
    }
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
    double expectedDamageTaken = target.getBestAttack(unit, getAttacksOnTarget(unit, distance));
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
    unit.attack = attacks.first;
    for (Attack attack in attacks){
      var attackCalc = unit.attackCalc(target, attack);
      double expectedAttackDamage = attackCalc.damage*attackCalc.accuracy + attackCalc.damage*attackCalc.accuracy*attackCalc.critRate*3;
      if(expectedDamage < expectedAttackDamage){
        expectedDamage = expectedAttackDamage;
        unit.attack = attack;
      }
    }
    return expectedDamage;
  }
}