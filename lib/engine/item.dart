// ignore_for_file: unused_import

import 'dart:developer' as dev;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'engine.dart';
import 'dart:convert';
import 'dart:io';

class Item extends Component with HasGameRef<MyGame>{
  final String name;
  late String description;
  ItemType? type;
  Equip? equipCond;
  Use? use;
  Weapon? weapon;
  List<Effect>? effects;
  
  // Factory constructor
  factory Item.fromJson(String name) {
    var itemData = MyGame.itemMap['items'][name];
    dev.log(itemData.toString());

    if (itemData == null) {
      // Handle the case where itemData does not exist for the given name
      // Perhaps throw an error or return a default item
      throw Exception("Item not found: $name");
    } else {
      // Extract the properties from itemData
      String description = itemData['description'] ?? 'No description provided';
      ItemType type = ItemType.values.firstWhere((e) => e.toString() == 'ItemType.${itemData['type']}', orElse: () => ItemType.basic); // Replace with actual logic to determine ItemType
      
      if (itemData.containsKey("weapon")) {
        Weapon weapon = Weapon.fromJson(itemData['weapon']);
        return Item._internal(name, description, type, weapon);
      } else {
        return Item._internal(name, description, type, null);
      }
    }
  }

  // Internal constructor for creating instances from factory constructor
  Item._internal(this.name, this.description, this.type, this.weapon);

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
