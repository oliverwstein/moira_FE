
import 'package:flame/components.dart';

class Weapon extends Component {
  WeaponType weaponType; // The type of the weapon. 
  final int might; // The base power of the weapon. 
  final int hit; // The base accuracy of the weapon. 
  final int fatigue; // The base fatigue cost of the weapon. 
  final List<CombatEffect>? effects; // The special effects of the weapon. 
  final Attack? specialAttack; // The special attack that can be performed with the weapon, if any. 
}