import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';
class Staff extends Component with HasGameReference<MoiraGame>{
  // Event? staffEvent;
  int range;
  Staff(this.range);
  factory Staff.fromJson(dynamic staffData, Event event) {
    switch (staffData.keys.first){
      case "Heal":
        int staffRange = staffData["range"] ?? 1;
        int baseHealing = staffData["base"] ?? 10;
        return Heal(staffRange, baseHealing);
      default:
        int staffRange = staffData["range"] ?? 1;
        return Staff(staffRange);
    }
  }

}

class Heal extends Staff {
  int baseHealing;
  Heal(super.range, this.baseHealing);
}

