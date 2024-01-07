import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'engine.dart';

class Attack extends Component with HasGameRef<MyGame>{
  final String name; // The Attack name
  late String description; // A description of the attack
  late Vector4 scaling; // The stat scaling of the attack
  late List<WeaponType> weaponTypes; // The types of weapons which can be used with this attack. 
  late int might; // The base power of the attack.
  late int hit; // The base accuracy of the attack
  late int crit; // The base critical hit rate of the attack
  late int fatigue; // The base fatigue cost of the attack
  bool magic = false; // Whether the attack does magical or physical damage.
  late (int, int) range; // The min and max range of the attack. 
  late List<CombatEffect>? effects; // The special effects of the attack. 

  // Private constructor for creating instances
  Attack._internal(this.name, this.description, this.scaling, this.weaponTypes, this.might, this.hit, this.crit, this.fatigue, this.magic, this.range, this.effects);

  // Factory constructor
  factory Attack.fromJson(String name) {
    // Check if the attack exists in the map and retrieve its data
    var attackData = MyGame.attackMap['attacks'][name];
    if (attackData == null) {
      // Handle the case where attackData does not exist for the given name
      // Perhaps throw an error or return a default attack
      throw Exception("Attack not found: $name");
    }

    // Extract values from attackData or use default values
    String description = attackData['description'] ?? 'No description provided';
    Vector4 scaling = Vector4(
      attackData['scaling'][0], 
      attackData['scaling'][1], 
      attackData['scaling'][2], 
      attackData['scaling'][3]
    ); // Replace with actual logic for Vector4
    List<WeaponType> weaponTypes = (attackData['weaponType'] as List<dynamic>)
        .map((e) => WeaponType.values.firstWhere((wt) => wt.toString().split('.').last == e))
        .toList(); // Handle possible missing or incorrect data
    int might = attackData['might'] ?? 0;
    int hit = attackData['hit'] ?? 0;
    int crit = attackData['crit'] ?? 0;
    int fatigue = attackData['fatigue'] ?? 0;
    bool magic = attackData['magic'] ?? false;
    (int, int) range = (attackData['range'][0], attackData['range'][1]); // Handle possible missing or incorrect data
    // List<CombatEffect> effects = attackData['effects'] ?? []; // Replace with the actual type if you have a specific Effect class

    // Return a new Attack instance
    return Attack._internal(name, description, scaling, weaponTypes, might, hit, crit, fatigue, magic, range, null);
  }
}

class CombatEffect {}