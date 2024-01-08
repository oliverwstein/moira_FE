import 'dart:developer' as dev;

import 'package:flame/components.dart';

import 'engine.dart';

class Player extends Component {
  List<Unit> units = [];
  UnitTeam team;
  Stage stage;
  bool active = false;

  Player(this.team, this.stage) {
    for (Unit unit in stage.units) {
      if(unit.team == team) units.add(unit);
    }
  }

  @override
  void update(dt){
    if(active){
      if (units.every((unit) => unit.canAct == false)) {
      dev.log('All $team units have acted.');
    }
    }
    
  }

  void takeTurn(){
    active = true;
    dev.log("$team takes their turn");
  }
}

class NPCPlayer extends Player {
  NPCPlayer(UnitTeam team, Stage stage) : super(team, stage);

  @override
  void update(double dt) {

    super.update(dt);
    // If it's this player's turn and units haven't acted yet, make them wait
    if(active){
      if (units.every((unit) => unit.canAct == false)) stage.endTurn();
      dev.log("NPCPlayer update: Time to end $team's turn");
      dev.log("NPCPlayer update: Active team is ${stage.activeTeam}");
    }
  }

  @override
  void takeTurn(){
    super.takeTurn();
    for (var unit in units) {
      if(unit.canAct) {
        unit.wait();
      }
    }
  }
}
