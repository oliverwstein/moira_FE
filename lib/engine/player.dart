import 'dart:developer' as dev;

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';
class Player extends Component with HasGameReference<MoiraGame>{
  String name;
  FactionType factionType;
  List<Unit> units = [];
  

  Player(this.name, this.factionType) {
    List<Unit> stageUnits = game.stage.children.query<Unit>();
    for (Unit unit in stageUnits) {
      if(unit.faction == name) units.add(unit);
    }
  }

  @override
  void update(dt){
  }

  void takeTurn(){
    dev.log("$name takes their turn");
  }
}