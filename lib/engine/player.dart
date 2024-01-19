import 'dart:developer' as dev;

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';
class Player extends Component with HasGameReference<MoiraGame>{
  List<Unit> units = [];
  UnitTeam team;

  Player(this.team) {
    List<Unit> stageUnits = game.stage.children.query<Unit>();
    for (Unit unit in stageUnits) {
      if(unit.team == team) units.add(unit);
    }
  }

  @override
  void update(dt){
  }

  void takeTurn(){
    dev.log("$team takes their turn");
  }
}