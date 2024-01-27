// ignore_for_file: constant_identifier_names

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

enum WeaponType {Sword, Axe, Lance, Knife, Staff, Book, Bow}
extension WeaponTypeExtension on WeaponType {
  // Method to get the weapon type name with the first letter capitalized
  String get name => toString().split('.').last;

  // Static method to get a weapon type by its name
  static WeaponType? fromName(String name) {
    try {
      return WeaponType.values.firstWhere((weaponType) => weaponType.toString().split('.').last.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null; // Return null if no matching weapon type is found
    }
  }
}
Set<WeaponType> getWeaponTypesFromNames(List<String> weaponTypeNames) {
  return weaponTypeNames.map((name) => WeaponTypeExtension.fromName(name))
                        .whereType<WeaponType>()
                        .toSet();
}
class Weapon extends Component with HasGameReference<MoiraGame>{
  late WeaponType weaponType; // The type of the weapon. 
  late int might; // The base power of the weapon. 
  late int hit; // The base accuracy of the weapon. 
  late int crit; // The base critical hit chance of the weapon. 
  late int fatigue; // The base fatigue cost of the weapon. 
  bool magic = false; // Whether the weapon does magical or physical damage.
  late List<CombatEffect>? effects; // The special effects of the weapon. 
  late Attack? specialAttack; // The special attack that can be performed with the weapon, if any. 
  
  // Internal constructor for creating instances
  Weapon._internal(this.weaponType, this.might, this.hit, this.crit, this.fatigue, this.effects, this.specialAttack);

  // Factory constructor
  factory Weapon.fromJson(String name) {
    Map<String, dynamic> weaponData;

    // Check if the weapon exists in the map and retrieve its data
    if (MoiraGame.weaponMap['weapons'].containsKey(name)) {
      weaponData = MoiraGame.weaponMap['weapons'][name];
    } else {
      // Define default values for a weapon that doesn't exist in the map
      weaponData = {
        "weaponType": "none",
        "might": 0,
        "hit": 0,
        "crit": 0,
        "fatigue": 0,
        "effects": [],
        "specialAttack": null,
      };
    }

    // Extract values from weaponData or use default values
    String weaponTypeString = weaponData['weaponType'] ?? "none";
    WeaponType weaponType = WeaponType.values.firstWhere((wt) => wt.toString().split('.').last == weaponTypeString);
    int might = weaponData['might'] ?? 0;
    int hit = weaponData['hit'] ?? 0;
    int crit = weaponData['crit'] ?? 0;
    int fatigue = weaponData['fatigue'] ?? 0;
    // List<CombatEffect> effects = weaponData['effects'] ?? []; // Replace with actual type if you have a specific Effect class
    Attack specialAttack = Attack.fromJson(weaponData['specialAttack']); // Replace with actual type

    // Return a new Weapon instance
    return Weapon._internal(weaponType, might, hit, crit, fatigue, null, specialAttack);
  }
}