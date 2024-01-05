import 'dart:convert';

import 'package:flame/components.dart';
import 'engine.dart';

enum WeaponType {sword, axe, lance, knife, staff, book, none}

class Attack extends Component {
  final String name; // The Attack name
  late String description; // A description of the attack
  late Vector4 scaling; // The stat scaling of the attack
  late List<WeaponType> weaponTypes; // The types of weapons which can be used with this attack. 
  late int might; // The base power of the attack.
  late int hit; // The base accuracy of the attack
  late int fatigue; // The base fatigue cost of the attack
  bool magic = false; // Whether the attack does magical or physical damage.
  late (int, int) range; // The min and max range of the attack. 
  late List<CombatEffect>? effects; // The special effects of the attack. 

  // Constructor
  Attack.fromJson(this.name, String jsonString) {
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    var attackData = jsonMap['attacks'][name];

    description = attackData['description'];
    scaling = Vector4(attackData['scaling'][0], attackData['scaling'][1], attackData['scaling'][2], attackData['scaling'][3]);
    weaponTypes = (attackData['weaponType'] as List<dynamic>)
        .map((e) => WeaponType.values.firstWhere((wt) => wt.toString().split('.').last == e))
        .toList();
    might = attackData['might'];
    hit = attackData['hit'];
    fatigue = attackData['fatigue'];
    magic = attackData['magic'];
    range = (attackData['range'][0], attackData['range'][1]);
    effects = attackData['effects'];
  }
}

class CombatEffect {}