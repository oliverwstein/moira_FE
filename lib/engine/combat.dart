import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/services.dart';
import 'package:moira/engine/engine.dart';

TextPaint combatTextRenderer = TextPaint(
style: const TextStyle(
  color: ui.Color.fromARGB(255, 255, 255, 255),
  fontSize: 16, // Adjust the font size as needed
  fontFamily: 'Courier', // This is just an example, use the actual font that matches your design
  height: 1.5,
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

TextPaint combatNumberRenderer = TextPaint(
style: const TextStyle(
  color: ui.Color.fromARGB(255, 255, 255, 255),
  fontSize: 22, // Adjust the font size as needed
  fontFamily: 'Courier', // This is just an example, use the actual font that matches your design
  height: 1.5,
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
  late final SpriteComponent combatPaneSprite;
  late final TextBoxComponent attackTextBox;
  late final TextBoxComponent weaponTextBox;
  late final TextBoxComponent defenderTextBox;
  late final (TextBoxComponent, TextBoxComponent) hpRecord;
  late final (TextBoxComponent, TextBoxComponent) damRecord;
  late final (TextBoxComponent, TextBoxComponent) accRecord;
  late final (TextBoxComponent, TextBoxComponent) critRecord;
  late final Combat combat;
  CombatBox(this.attacker, this.defender) {
    // Initialization logic
    attackList = attacker.attackSet.keys.toList();
    weaponList = attacker.inventory
    .where((item) => 
        attacker.equipCheck(item, ItemType.main) && 
        item.equipCond?.check(attacker) == true)
    .toList();
    combat = Combat(attacker, defender);
    add(combat);
    getCombatValMap(); // Assuming this method populates combatValMap

    attackTextBox = createTextBox('${combatValMap[attackList.first].atk.fatigue}|${attackList.first}', 24, 48);
    weaponTextBox = createTextBox('${attacker.name}\n${attacker.main?.name ?? "Unarmed"}', 24, 0);
    defenderTextBox = createTextBox("${defender.name}\n${combatValMap[attackList.first].atk.fatigue}|${defender.main?.name ?? ""}-${defender.attackSet.keys.first}", 24, 212);

    hpRecord = createRecordPair(attacker.hp.toString(), defender.hp.toString(), 80);
    damRecord = createRecordPair(combatValMap[attackList.first].atk.damage.toString(), combatValMap[attackList.first].def.damage.toString(), 110);
    accRecord = createRecordPair(combatValMap[attackList.first].atk.accuracy.toString(), combatValMap[attackList.first].def.accuracy.toString(), 140);
    critRecord = createRecordPair(combatValMap[attackList.first].atk.critRate.toString(), combatValMap[attackList.first].def.critRate.toString(), 170);
    
  }

  TextBoxComponent createTextBox(String text, double x, double y) {
    return TextBoxComponent(
      text: text,
      textRenderer: combatTextRenderer, // Assuming combatTextRenderer is defined
      position: Vector2(x, y),
    );
  }

  (TextBoxComponent, TextBoxComponent) createRecordPair(String atkText, String defText, double y) {
    var atkComp = TextBoxComponent(
      text: atkText,
      textRenderer: combatNumberRenderer, // Assuming combatNumberRenderer is defined
      position: Vector2(110, y),
    );

    var defComp = TextBoxComponent(
      text: defText,
      textRenderer: combatNumberRenderer,
      position: Vector2(10, y),
    );

    return (atkComp, defComp);
  }
  


  void getCombatValMap() {
    for(String attackName in attackList){
      combatValMap[attackName] =  combat.getCombatValues(attacker, defender, attacker.attackSet[attackName]!);
    }
  }

  @override
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    if (command == LogicalKeyboardKey.keyA) { // Make the attack.
      dev.log("${attacker.name} attacked ${defender.name}");
      combat.bout(attacker, defender, attacker.attackSet[attackList[selectedAttackIndex]]!);
      attacker.wait();
      close();
      gameRef.stage.activeComponent = gameRef.stage.cursor;
      attacker.remainingMovement -= attacker.moveCost;
      gameRef.eventDispatcher.dispatch(UnitActionEndEvent(attacker));
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) { // Cancel the action.
      dev.log("${attacker.name} cancelled it's attack on ${defender.name}");
      close();
      gameRef.stage.cursor.goToUnit(attacker);
      attacker.getActionOptions();
      attacker.openActionMenu();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) { // Change attack option
      selectedAttackIndex = (selectedAttackIndex + 1) % attackList.length;
      attackTextBox.text = '${combatValMap[attackList[selectedAttackIndex]].atk.fatigue}|${attackList[selectedAttackIndex]}';
      updateCombatDataUI();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) { // Change attack option
      selectedAttackIndex = (selectedAttackIndex - 1) % attackList.length;
      attackTextBox.text = '${combatValMap[attackList[selectedAttackIndex]].atk.fatigue}|${attackList[selectedAttackIndex]}';
      updateCombatDataUI();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowLeft) { // Change weapon option
      // Unequip the current weapon, equip the next weapon in ItemList,
      // and update the attackList and combatValMap.
      equippedWeaponIndex = (equippedWeaponIndex + 1) % weaponList.length;
      attacker.equip(weaponList[equippedWeaponIndex]);
      attackList = attacker.attackSet.keys.toList();
      weaponTextBox.text = '${attacker.name}\n${attacker.main?.name ?? "Unarmed"}';
      combatValMap = {};
      getCombatValMap();
      selectedAttackIndex = 0;
      attackTextBox.text = '${combatValMap[attackList[selectedAttackIndex]].atk.fatigue}|${attackList[selectedAttackIndex]}';
      updateCombatDataUI();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) { // change weapon option
      equippedWeaponIndex = (equippedWeaponIndex - 1) % weaponList.length;
      attacker.equip(weaponList[equippedWeaponIndex]);
      attackList = attacker.attackSet.keys.toList();
      weaponTextBox.text = '${attacker.name}\n${attacker.main?.name ?? "Unarmed"}';
      combatValMap = {};
      getCombatValMap();
      selectedAttackIndex = 0;
      attackTextBox.text = '${combatValMap[attackList[selectedAttackIndex]].atk.fatigue}|${attackList[selectedAttackIndex]}';
      updateCombatDataUI();
      handled = true;
    }
    return handled;
  }

  void updateCombatDataUI() {
    damRecord.$1.text = '${combatValMap[attackList[selectedAttackIndex]].atk.damage}';
    damRecord.$2.text = '${combatValMap[attackList[selectedAttackIndex]].def.damage}';
    accRecord.$1.text = '${combatValMap[attackList[selectedAttackIndex]].atk.accuracy}';
    accRecord.$2.text = '${combatValMap[attackList[selectedAttackIndex]].def.accuracy}';
    critRecord.$1.text = '${combatValMap[attackList[selectedAttackIndex]].atk.critRate}';
    critRecord.$2.text = '${combatValMap[attackList[selectedAttackIndex]].def.critRate}';
  }

  @override
  Future<void> onLoad() async {
    combatPaneSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('tellius_combat_pane_attack.png'),
        position: Vector2(160, 0),
    );
    combatPaneSprite.add(attackTextBox);
    combatPaneSprite.add(weaponTextBox);
    combatPaneSprite.add(defenderTextBox);
    combatPaneSprite.add(hpRecord.$1);
    combatPaneSprite.add(hpRecord.$2);
    combatPaneSprite.add(damRecord.$1);
    combatPaneSprite.add(damRecord.$2);
    combatPaneSprite.add(accRecord.$1);
    combatPaneSprite.add(accRecord.$2);
    combatPaneSprite.add(critRecord.$1);
    combatPaneSprite.add(critRecord.$2);
    add(combatPaneSprite);
  }
  void close(){
    attacker.remove(this);
  }

}

class Combat extends Component with HasGameRef<MyGame>{
  Unit attacker;
  Unit defender;
  late int damageDealt = 0;
  Combat(this.attacker, this.defender);

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
    return (atk: atk, def: def);
  }

  void makeAttack(int damage, int accuracy, int critRate, int fatigue, Unit attacker, Unit defender){
    var rng = Random(); // Random number generator
    damageDealt = 0;
    if (accuracy > 0) {
      if (rng.nextInt(100) + 1 <= accuracy) {
        // Attack hits
        var critical = rng.nextInt(100) + 1 <= critRate; // Check for critical
        damageDealt = critical ? 3 * damage : damage; // Calculate damage
      } else {
        dev.log('${attacker.name} missed');
      }
    }
    gameRef.eventDispatcher.dispatch(MakeAttackEvent(this, attacker, defender));
    dev.log('${attacker.name} hit, doing ${damageDealt} to ${defender.name}');
    defender.hp -= damageDealt;
    attacker.sta -= fatigue;
  }

  void bout(Unit attacker, Unit defender, Attack attack){
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
    if (attacker.getStat('spe') >= defender.getStat('spe') + 4) {
      makeAttack(vals.atk.damage, vals.atk.accuracy, vals.atk.critRate, vals.atk.fatigue, attacker, defender);
    } else if (defender.getStat('spe') >= attacker.getStat('spe') + 4) {
      makeAttack(vals.def.damage, vals.def.accuracy, vals.def.critRate, vals.def.fatigue, defender, attacker);
    }
  }
}