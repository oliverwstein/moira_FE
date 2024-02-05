import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';
class Staff extends Component with HasGameReference<MoiraGame>{
  Event? staffEvent;
  Staff();
  factory Staff.fromJson(dynamic staffData, Event event) {
    switch (staffData.keys.first){
      case "Heal":
        int range = staffData["range"] ?? 1;
        int baseHealing = staffData["base"] ?? 10;
        return Heal(range, baseHealing);
      default:
        return Staff.rod();
    }
  }

  Staff.rod();
}

class Heal extends Staff {
  int baseHealing;
  int range;
  Heal(this.range, this.baseHealing);
}

