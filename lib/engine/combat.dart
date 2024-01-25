import 'dart:math';

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';
enum Damage {physical, magical, noncombat}

class Combat extends Component with HasGameReference<MoiraGame>{
  Unit attacker;
  Unit defender;
  Attack attack;
  Attack? counterAttack;
  int damage = 0;
  Combat(this.attacker, this.defender, this.attack){
    counterAttack = defender.getCounter(getCombatDistance());
  }

  @override
  void onLoad(){
    game.eventQueue.addEventBatch([StartCombatEvent(this)]);
  }
  int getCombatDistance(){
    return (attacker.tilePosition.x - defender.tilePosition.x).abs() + (attacker.tilePosition.y - defender.tilePosition.y).abs();
  }

  void addFollowUp() {
    if (attacker.getStat("spe")>= defender.getStat("spe") + 4){
      game.eventQueue.addEventBatch([AttackEvent(this, attacker, defender, attack)]);
    } else if (attacker.getStat("spe")<= defender.getStat("spe") - 4){
      if (counterAttack != null) game.eventQueue.addEventBatch([AttackEvent(this, defender, attacker, counterAttack!)]);
    }
  }
}