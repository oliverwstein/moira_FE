// ignore_for_file: unused_import

import 'dart:developer' as dev;
import 'package:flame/components.dart';
import 'engine.dart';
import 'dart:convert';
import 'dart:io';
enum Damage {
  charge(str: 1, dex: 0, mag: 0, wis: 0),
  strike(str: .5, dex: .5, mag: 0, wis: 0),
  slash(str: 1.5, dex: .5, mag: 0, wis: 0),
  stab(str: .5, dex: 1, mag: 0, wis: 0),
  smash(str: 2, dex: 0, mag: 0, wis: 0),
  pierce(str: 2, dex: 2, mag: 0, wis: 0),
  blast(str: 0, dex: 0, mag: 1.5, wis: .5),
  smite(str: 0, dex: 0, mag: .5, wis: 1),
  hex(str: 0, dex: 0, mag: 1, wis: 1);

  const Damage({
    required this.str,
    required this.dex,
    required this.mag,
    required this.wis
  });

  final double str;
  final double dex;
  final double mag;
  final double wis;
}

class Item extends Component {
  String name;
  ItemType? type;
  Equip? equipCond;
  Use? use;
  List<Attack>? attacks;
  List<Effect>? effects;
  
  Item({
      required this.name, 
      this.type, 
      this.equipCond, 
      this.use, 
      this.attacks, 
      this.effects,
    });
  void equip(Unit unit){
    if (equipCond !=null) {
      if(equipCond!.check(unit)){
        switch (type) {
                  case ItemType.main:
                    unit.main = this;
                    dev.log("${unit.name} equipped $name as $type");
                    break;
                  case ItemType.gear:
                    unit.gear = this;
                    dev.log("${unit.name} equipped $name as $type");
                    break;
                  case ItemType.treasure:
                    unit.treasure = this;
                    dev.log("${unit.name} equipped $name as $type");
                    break;
                  default:
                    break;
        }
      }
    }
    dev.log("${unit.name} can't equip $name");
  }
}

// class ItemBank {
//   static final Map<String, Item> _items = {};
//   static Future<void> load(String path) async {
//     final file = File(path);
//     final jsonStr = await file.readAsString();
//     final jsonMap = json.decode(jsonStr);
//     for (var itemData in jsonMap['items']) {
//       var item = Item.fromJson(itemData);
//       _items[item.name] = item;
//     }
//   }
//   static Item get(String itemName) {
//     final item = _items[itemName];
//     if (item != null) {
//       // Return a copy or new instance of the item if needed
//       return item.clone();
//     } else {
//       throw Exception('Item $itemName not found');
//     }
//   }
// }

class Equip extends Component {

  Equip();

  bool check(Unit unit){
    return true;
  }
}

final Item longsword = Item(
  name: 'Longsword',
  type: ItemType.main,
  attacks: [],
);

final Item axe = Item(
  name: 'Axe',
  type: ItemType.main,
  attacks: [],
);

final Item salve = Item(
  name: 'Salve',
  use: null,
);

final Map<String, Item> itemBank = {"longsword": longsword, "axe": axe, "salve": salve};

class Effect extends Component {}
class Skill extends Component {}
class Use extends Component {}
