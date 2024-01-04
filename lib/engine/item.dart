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

class Attack extends Component {
  String name;
  int might;
  int hit;
  (int, int) combatRange = (1,1);
  bool magic = false;
  List<Damage> damages;
  late Item? item;

  Attack(this.name, this.might, this.hit, this.combatRange, this.magic, this.damages);
  Attack.melee(this.name, this.might, this.hit, this.damages, {combatRange = (1, 1), magic = false});
  Attack.magic(this.name, this.might, this.hit, this.damages, {combatRange = (1, 3), magic = true});
}

final Attack longswordAttack = Attack.melee(
  'Slash',
  6, // might
  75, // hit
  [Damage.slash], // damages
);

final Attack axeAttack = Attack.melee(
  'Smash',
  8, // might
  60, // hit
  [Damage.smash], // damages
);

final Attack magicFireAttack = Attack.magic(
  'Fireball',
  5, // might
  80, // hit
  [Damage.blast], // damages
);

final Item longsword = Item(
  name: 'Longsword',
  type: ItemType.main,
  attacks: [longswordAttack],
);

final Item axe = Item(
  name: 'Axe',
  type: ItemType.main,
  attacks: [axeAttack],
);

final Item salve = Item(
  name: 'Salve',
  use: null,
);

final Map<String, Item> itemBank = {"longsword": longsword, "axe": axe, "salve": salve};

class Effect extends Component {}
class Skill extends Component {}
class Use extends Component {}
