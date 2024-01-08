import 'dart:developer' as dev;

import 'package:flame/components.dart';

import 'engine.dart';

class Player extends Component {
  List<Unit> units = [];
  UnitTeam team;
  Stage stage;

  Player(this.team, this.stage) {
    for (Unit unit in stage.units) {
      if(unit.team == team) units.add(unit);
    }
  }

  @override
  void update(dt){
    if(team == stage.activeTeam){
      if (units.every((unit) => unit.canAct == false)) {
      dev.log('All $team units have acted.');
    }
    }
    
  }

  void takeTurn(){
    dev.log("$team takes their turn");
  }
}

class NPCPlayer extends Player {
  NPCPlayer(UnitTeam team, Stage stage) : super(team, stage);

  @override
  void update(double dt) {

    super.update(dt);
    // If it's this player's turn and units haven't acted yet, make them wait
    if(team == stage.activeTeam){
      if (units.every((unit) => unit.canAct == false)) stage.endTurn();
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
