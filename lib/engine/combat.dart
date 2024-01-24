import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

class Combat extends Component with HasGameReference<MoiraGame>{
  Unit attacker;
  Unit defender;
  Attack attack;
  Combat(this.attacker, this.defender, this.attack); 

  @override
  void onLoad(){
    game.eventQueue.addEventBatch([StartCombatEvent(attacker, defender, attack)]);
  }
}