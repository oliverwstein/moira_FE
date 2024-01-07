import 'dart:developer' as dev;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:moira/engine/engine.dart';


class CombatBox extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  /// Combat Box should take a unit and a target and create three things:
  /// A box that lists the weapon to use
  /// A box that lists the combat art to use
  /// A table that shows the damage and hit chance of the weapon/combat art combo.
  Unit attacker;
  Unit defender;
  List<String> attackList = [];
  int selectedAttackIndex = 0;
  late final SpriteComponent weaponBoxSprite;
  late final SpriteComponent attackBoxSprite;
  CombatBox(this.attacker, this.defender){
    attackList = attacker.attackSet.keys.toList();
  }

  @override
  Future<void> onLoad() async {
    weaponBoxSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('combat_box.png'),
    );
    attackBoxSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('combat_box.png'),
        position: Vector2(0, 32),
        // size: Vector2.all(8)
    );
  }

  int getCombatDistance(){
    return (attacker.gridCoord.x - defender.gridCoord.x).abs() + (attacker.gridCoord.y - defender.gridCoord.y).abs();
  }

  Attack? validAttackCheck(int distance, Attack attack){
    if (attack.range.$1 <= distance && distance <= attack.range.$1){
      return attack;}
    return null;
  }

  List<String> getValidAttacks(Unit attacker){
    int combatDistance = getCombatDistance();
    List<String> attackList = [];
    for (String attack in attacker.attackSet.keys){
      if(validAttackCheck(combatDistance, attacker.attackSet[attack]!) != null){
        attackList.add(attack);
      }
    }
    return attackList;
  }

  ({({int accuracy, int critRate, int damage, int fatigue}) attackerVals, ({int accuracy, int critRate, int damage, int fatigue}) defenderVals}) getCombatValues(Unit attacker, Unit defender, Attack attack){
    ({int accuracy, int critRate, int damage, int fatigue}) attackerVals = attacker.attackCalc(attack, defender);
    ({int accuracy, int critRate, int damage, int fatigue}) defenderVals = (0, 0, 0, 0) as ({int accuracy, int critRate, int damage, int fatigue});
    if(defender.main?.weapon?.specialAttack != null){
      assert(defender.main?.weapon?.specialAttack?.name != null);
      assert(defender.attackSet.containsKey(defender.main?.weapon?.specialAttack?.name));
      Attack? counterAttack = validAttackCheck(getCombatDistance(), defender.attackSet[defender.main!.weapon!.specialAttack!.name]!);
      if(counterAttack != null){
         defenderVals = defender.attackCalc(counterAttack, attacker);
      }
    }
    return (attackerVals: attackerVals, defenderVals: defenderVals);
  }

  void combat(Unit attacker, Unit defender, Attack attack){
    ({({int accuracy, int critRate, int damage, int fatigue}) attackerVals, ({int accuracy, int critRate, int damage, int fatigue}) defenderVals}) vals = getCombatValues(attacker, defender, attack);
  }

  @override
  bool handleCommand(LogicalKeyboardKey command) {
    Stage stage = attacker.parent as Stage;
    bool handled = false;
    if (command == LogicalKeyboardKey.keyA) { // Make the attack.
      dev.log("${attacker.name} attacked ${defender.name}");
      dev.log("${getCombatValues(attacker, defender, attacker.attackSet[attackList[selectedAttackIndex]]!)}");
      attacker.wait();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) { // Cancel the action.
      dev.log("${attacker.name} cancelled it's attack on ${defender.name}");
      stage.cursor.goToUnit(attacker);
      attacker.openActionMenu(stage);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) {
      selectedAttackIndex = (selectedAttackIndex + 1) % attackList.length;
      dev.log("Selected attack is ${attackList[selectedAttackIndex]}");
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      selectedAttackIndex = (selectedAttackIndex - 1) % attackList.length;
      dev.log("Selected attack is ${attackList[selectedAttackIndex]}");
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowLeft) {
      
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) {
      
      handled = true;
    }
    return handled;
  }
}

