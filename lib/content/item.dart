import 'package:flame/components.dart';
import 'package:moira/content/content.dart';
class Item extends Component with HasGameReference<MoiraGame>{
  final String name;
  String description;
  ItemType type;
  Equip? equipCond;
  Use? use;
  Weapon? weapon;
  List<Effect>? effects;
  
  // Factory constructor
  factory Item.fromJson(String name) {
    var itemData = MoiraGame.itemMap['items'][name];

    if (itemData == null) {
      // Handle the case where itemData does not exist for the given name
      // Perhaps throw an error or return a default item
      throw Exception("Item not found: $name");
    } else {
      // Extract the properties from itemData
      String description = itemData['description'] ?? 'No description provided';
      ItemType type = ItemType.values.firstWhere((e) => e.toString() == 'ItemType.${itemData['type']}', orElse: () => ItemType.basic);
      
      if (itemData.containsKey("weapon")) {
        Weapon weapon = Weapon.fromJson(itemData['weapon']);
        return Item._internal(name, description, type, weapon);
      } else {
        return Item._internal(name, description, type, null);
      }
    }
  }

  // Internal constructor for creating instances from factory constructor
  Item._internal(this.name, this.description, this.type, this.weapon) {
    equipCond = Equip(this);
  }

}

class Equip extends Component {
  final Item item;
  Equip(this.item);

  bool check(Unit unit){
    bool canEquip = false;
    if(item.weapon != null){
      if(unit.proficiencies.contains(item.weapon!.weaponType)){canEquip = true;}
    } else {canEquip = true;}
    return canEquip;
  }
}

class Effect extends Component {}
class Use extends Component {}