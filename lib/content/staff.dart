import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';
class Staff extends Component with HasGameReference<MoiraGame>{
  // Event? staffEvent;
  int range;
  Staff(this.range);
  factory Staff.fromJson(dynamic staffData, String name) {
    int staffRange = staffData["range"] ?? 1;
    switch (staffData["effect"]){
      case "Heal":
        int baseHealing = staffData["base"] ?? 10;
        return Heal(staffRange, baseHealing);
      default:
        return Staff(staffRange);
    }
  }
  void execute(Unit target){
    debugPrint("Use staff on ${target.name}");
  }
}

class Heal extends Staff {
  int baseHealing;
  Heal(super.range, this.baseHealing);
  @override
  execute(Unit target){
    debugPrint("Execute Heal on ${target.name}");
    // game.eventQueue.addEventBatch();
  }
}

