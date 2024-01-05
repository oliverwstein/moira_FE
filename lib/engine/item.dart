// ignore_for_file: unused_import

import 'dart:developer' as dev;
import 'package:flame/components.dart';
import 'engine.dart';
import 'dart:convert';
import 'dart:io';

class Item extends Component {
  final String name;
  late String description;
  ItemType? type;
  Equip? equipCond;
  Use? use;
  Weapon? weapon;
  List<Effect>? effects;
  
  Item.fromJson(this.name, String jsonString) {
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    var itemData = jsonMap['items'][name];
    description = itemData['description'];
    type = itemData['type'];
    String weaponName = itemData['weapon'];
    weapon = Weapon.fromJson(weaponName, "assets/data/weapons.json");
  }

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

class Equip extends Component {

  Equip();

  bool check(Unit unit){
    return true;
  }
}

class Effect extends Component {}
class Skill extends Component {}
class Use extends Component {}
