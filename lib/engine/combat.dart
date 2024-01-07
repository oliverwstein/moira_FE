import 'dart:developer' as dev;
import 'dart:math';
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

  ({({int accuracy, int critRate, int damage, int fatigue}) atk, ({int accuracy, int critRate, int damage, int fatigue}) def}) getCombatValues(Unit attacker, Unit defender, Attack attack){
    ({int accuracy, int critRate, int damage, int fatigue}) atk = attacker.attackCalc(attack, defender);
    ({int accuracy, int critRate, int damage, int fatigue}) def = (0, 0, 0, 0) as ({int accuracy, int critRate, int damage, int fatigue});
    if(defender.main?.weapon?.specialAttack != null){
      assert(defender.main?.weapon?.specialAttack?.name != null);
      assert(defender.attackSet.containsKey(defender.main?.weapon?.specialAttack?.name));
      Attack? counterAttack = validAttackCheck(getCombatDistance(), defender.attackSet[defender.main!.weapon!.specialAttack!.name]!);
      if(counterAttack != null){
         def = defender.attackCalc(counterAttack, attacker);
      }
    }
    return (atk: atk, def: def);
  }

  void combat(Unit attacker, Unit defender, Attack attack){
    /// Start with the attacker. Roll a random integer between 1-100 (inclusive) .
      /// If the random integer is <= vals.atk.accuracy, the attack succeeds.
    /// If the attack succeeds, roll another random integer between 1-100 (inclusive).
      /// If the random integer is <= vals.atk.critRate, the attack is critical.
    /// If the attack succeeds, defender.hp -= vals.atk.damage. 
      /// If the attack is a critical, defender.hp -= 3*vals.atk.damage. 
    // If defender.hp <= 0, they die and the combat ends. 
    // Otherwise, if vals.def.accuracy > 0, calculate their counterattack.
    // Once both attacker and defender have made attacks 
      /// (whether they landed or not), if both units are alive,
      /// if attacker.stats['spe'] >= defender.stats['spe'] + 4, 
      /// the attacker gets another chance to attack. 
      /// If defender.stats['spe'] >= attacker.stats['spe'] + 4 ,
      /// the defender gets another chance to attack.
    /// Each time a unit attacks, that unit's sta attribute -= fatigue.
    
    var rng = Random(); // Random number generator
    ({({int accuracy, int critRate, int damage, int fatigue}) atk, ({int accuracy, int critRate, int damage, int fatigue}) def}) vals = getCombatValues(attacker, defender, attack);
    // Attacker's turn
    if (rng.nextInt(100) + 1 <= vals.atk.accuracy) {
      // Attack hits
      var critical = rng.nextInt(100) + 1 <= vals.atk.critRate; // Check for critical
      var damageDealt = critical ? 3 * vals.atk.damage : vals.atk.damage; // Calculate damage
      defender.hp -= damageDealt; // Apply damage
      attacker.sta -= vals.atk.fatigue; // Reduce stamina
    }
    if (defender.hp <= 0) {
      defender.die();
    return;
  }
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

