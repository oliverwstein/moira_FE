
import 'dart:convert';

import 'package:flame/components.dart';
import 'engine.dart';
// ignore: constant_identifier_names
enum WeaponType {Sword, Axe, Lance, Knife, Staff, Book, None}

class Weapon extends Component {
  late WeaponType weaponType; // The type of the weapon. 
  late int might; // The base power of the weapon. 
  late int hit; // The base accuracy of the weapon. 
  late int fatigue; // The base fatigue cost of the weapon. 
  bool magic = false; // Whether the weapon does magical or physical damage.
  late List<CombatEffect>? effects; // The special effects of the weapon. 
  late Attack? specialAttack; // The special attack that can be performed with the weapon, if any. 

  Weapon.fromJson(String name, String jsonString) {
    // Define default values
    Map<String, dynamic> weaponData = {
      "might": 0,
      "hit": 0,
      "fatigue": 0,
      "magic": false,
      "effects": [],
      "specialAttack": null,
    };
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    if (jsonMap['weapons'].contains_key(name)){
      weaponData = jsonMap['weapons'][name];
    } else {
      weaponData['weaponType'] = "none";
    }

    // Get the weapon type first
    var weaponTypeString = weaponData['weaponType']; // Ensure this key exists or have error handling
    weaponType = WeaponType.values.firstWhere((wt) => wt.toString().split('.').last == weaponTypeString);

    // Use the weapon type to retrieve the default values for this weapon type
    var defaults = weaponData[weaponTypeString] ?? {};

    // Assign values from JSON or use defaults
    might = jsonMap['might'] ?? defaults['might'] ?? 0;
    hit = jsonMap['hit'] ?? defaults['hit'] ?? 0;
    fatigue = jsonMap['fatigue'] ?? defaults['fatigue'] ?? 0;
    magic = jsonMap['magic'] ?? defaults['magic'] ?? false;
    effects = jsonMap['effects'] ?? defaults['effects'] ?? [];
    String specialAttackName = jsonMap['specialAttack'] ?? defaults['specialAttack'];
    specialAttack = Attack.fromJson(specialAttackName, 'assets/data/attacks.json');

  }
}