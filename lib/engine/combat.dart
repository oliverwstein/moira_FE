import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:moira/engine/engine.dart';
import 'package:flame/text.dart';

TextPaint combatTextRenderer = TextPaint(
        style: const TextStyle(
          color: ui.Color.fromARGB(255, 221, 193, 245),
          fontSize: 20, // Adjust the font size as needed
          fontFamily: 'Courier', // This is just an example, use the actual font that matches your design
          shadows: <ui.Shadow>[
            ui.Shadow(
              offset: ui.Offset(1.0, 1.0),
              blurRadius: 1.0,
              color: ui.Color.fromARGB(255, 20, 11, 48),
            ),
          ],
          // Include any other styles you need
          ),
      );
      
class CombatBox extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  /// Combat Box should take a unit and a target and create three things:
  /// A box that lists the weapon to use
  /// A box that lists the combat art to use
  /// A table that shows the damage and hit chance of the weapon/combat art combo.
  Unit attacker;
  Unit defender;
  List<String> attackList = [];
  List<Item> weaponList = [];
  Map<String, dynamic> combatValMap = {};
  int selectedAttackIndex = 0;
  int equippedWeaponIndex = 0;
  late final SpriteComponent weaponBoxSprite;
  late final SpriteComponent attackBoxSprite;
  late final TextBoxComponent attackTextBox;
  late final TextBoxComponent weaponTextBox;
  CombatBox(this.attacker, this.defender){
    attackList = attacker.attackSet.keys.toList();
    if (attacker.main != null) {weaponList.add(attacker.main!);}
    for (Item item in attacker.inventory) {if (attacker.equipCheck(item, ItemType.main)) weaponList.add(item);}
    getCombatValMap();
    attackTextBox = TextBoxComponent(
      text: '${attackList.first} | ${combatValMap[attackList.first].atk.fatigue}',
      textRenderer: combatTextRenderer,
      position: Vector2(32, 10),
      priority: 20);
    weaponTextBox = TextBoxComponent(
      text: attacker.main?.name ?? "Unarmed",
      textRenderer: combatTextRenderer,
      position: Vector2(32, 10),
      priority: 20);
    }

  void getCombatValMap() {
    for(String attackName in attackList){
      combatValMap[attackName] =  getCombatValues(attacker, defender, attacker.attackSet[attackName]!);
    }
  }

  @override
  bool handleCommand(LogicalKeyboardKey command) {
    Stage stage = attacker.parent as Stage;
    bool handled = false;
    if (command == LogicalKeyboardKey.keyA) { // Make the attack.
      dev.log("${attacker.name} attacked ${defender.name}");
      combat(attacker, defender, attacker.attackSet[attackList[selectedAttackIndex]]!);
      attacker.wait();
      close();
      stage.activeComponent = stage.cursor;
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) { // Cancel the action.
      dev.log("${attacker.name} cancelled it's attack on ${defender.name}");
      close();
      stage.cursor.goToUnit(attacker);
      attacker.openActionMenu(stage);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) { // Change attack option
      selectedAttackIndex = (selectedAttackIndex + 1) % attackList.length;
      attackTextBox.text = '${attackList[selectedAttackIndex]} | ${combatValMap[attackList[selectedAttackIndex]].atk.fatigue}';
      dev.log("Selected attack is ${attackList[selectedAttackIndex]}");
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) { // Change attack option
      selectedAttackIndex = (selectedAttackIndex - 1) % attackList.length;
      attackTextBox.text = '${attackList[selectedAttackIndex]} | ${combatValMap[attackList[selectedAttackIndex]].atk.fatigue}';
      dev.log("Selected attack is ${attackList[selectedAttackIndex]}");
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowLeft) { // Change weapon option
      // Unequip the current weapon, equip the next weapon in ItemList,
      // and update the attackList and combatValMap.
      equippedWeaponIndex = (equippedWeaponIndex + 1) % weaponList.length;
      attacker.equip(weaponList[equippedWeaponIndex]);
      attackList = attacker.attackSet.keys.toList();
      weaponTextBox.text = '${weaponList[equippedWeaponIndex].name}';
      combatValMap = {};
      getCombatValMap();
      selectedAttackIndex = 0;
      attackTextBox.text = '${attackList[selectedAttackIndex]} | ${combatValMap[attackList[selectedAttackIndex]].atk.fatigue}';
      
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) { // change weapon option
      equippedWeaponIndex = (equippedWeaponIndex - 1) % weaponList.length;
      attacker.equip(weaponList[equippedWeaponIndex]);
      attackList = attacker.attackSet.keys.toList();
      weaponTextBox.text = '${weaponList[equippedWeaponIndex].name}';
      combatValMap = {};
      getCombatValMap();
      selectedAttackIndex = 0;
      attackTextBox.text = '${attackList[selectedAttackIndex]} | ${combatValMap[attackList[selectedAttackIndex]].atk.fatigue}';
      
      handled = true;
      handled = true;
    }
    return handled;
  }

  @override
  Future<void> onLoad() async {
    weaponBoxSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('attack_box_trans.png'),
        position: Vector2(128, 0),
    );
    attackBoxSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('attack_box_trans.png'),
        position: Vector2(128, -64),
        // size: Vector2.all(8)
    );
    add(attackBoxSprite);
    attackTextBox.align = Anchor.centerLeft;
    attackBoxSprite.add(attackTextBox);
    add(weaponBoxSprite);
    weaponTextBox.align = Anchor.centerLeft;
    weaponBoxSprite.add(weaponTextBox);
  }
  void close(){
    attacker.remove(this);
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

  ({
  ({int accuracy, int critRate, int damage, int fatigue}) atk, 
  ({int accuracy, int critRate, int damage, int fatigue}) def}) 
  getCombatValues(Unit attacker, Unit defender, Attack attack){
    ({int accuracy, int critRate, int damage, int fatigue}) atk = attacker.attackCalc(attack, defender);
    ({int accuracy, int critRate, int damage, int fatigue}) def = (accuracy: 0, critRate: 0, damage: 0, fatigue: 0);
    if(defender.main?.weapon?.specialAttack != null){
      assert(defender.main?.weapon?.specialAttack?.name != null);
      assert(defender.attackSet.containsKey(defender.main?.weapon?.specialAttack?.name));
      Attack? counterAttack = validAttackCheck(getCombatDistance(), defender.attackSet[defender.main!.weapon!.specialAttack!.name]!);
      if(counterAttack != null){
         def = defender.attackCalc(counterAttack, attacker);
      }
    }
    // dev.log("${attack.name}, ${atk}, ${def}");
    return (atk: atk, def: def);
  }

  void makeAttack(int damage, int accuracy, int critRate, int fatigue, Unit attacker, Unit defender){
    var rng = Random(); // Random number generator
    if (accuracy > 0) {
      if (rng.nextInt(100) + 1 <= accuracy) {
        // Attack hits
        var critical = rng.nextInt(100) + 1 <= critRate; // Check for critical
        var damageDealt = critical ? 3 * damage : damage; // Calculate damage
        defender.hp -= damageDealt; // Apply damage
        attacker.sta -= fatigue; // Reduce stamina
        dev.log('${attacker.name} hit, reducing ${defender.name} to ${defender.hp}');
      } else {
        dev.log('${attacker.name} missed');
      }
    }
  }

  void combat(Unit attacker, Unit defender, Attack attack){
    var rng = Random(); // Random number generator
    ({({int accuracy, int critRate, int damage, int fatigue}) atk, ({int accuracy, int critRate, int damage, int fatigue}) def}) vals = getCombatValues(attacker, defender, attack);
    // Attacker's turn
    makeAttack(vals.atk.damage, vals.atk.accuracy, vals.atk.critRate, vals.atk.fatigue, attacker, defender);
    if (defender.hp <= 0) {
      defender.die();
      return;
    }
    makeAttack(vals.def.damage, vals.def.accuracy, vals.def.critRate, vals.def.fatigue, defender, attacker);
    
    if (attacker.hp <= 0) {
      attacker.die();
      return;
    }
    // Follow-up attacks based on speed
    assert(attacker.stats['spe'] != null);
    assert(defender.stats['spe'] != null);
    if (attacker.stats['spe']! >= defender.stats['spe']! + 4) {
      makeAttack(vals.atk.damage, vals.atk.accuracy, vals.atk.critRate, vals.atk.fatigue, attacker, defender);
    } else if (defender.stats['spe']! >= attacker.stats['spe']! + 4) {
      makeAttack(vals.def.damage, vals.def.accuracy, vals.def.critRate, vals.def.fatigue, defender, attacker);
    }
  }

}

