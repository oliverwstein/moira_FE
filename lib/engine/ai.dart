import 'package:flame/components.dart';

import 'engine.dart';

class NPCPlayer extends Component{
  List<Unit> units = [];
  UnitTeam team;
  Stage stage;
  NPCPlayer(this.team, this.stage) {
    for (Unit unit in stage.units) {
      if(unit.team == team) units.add(unit);
    }
  }

  void takeTurn() {
    for (var unit in units) {
      unit.wait(); // Each unit takes its action by waiting
    }
    stage.endTurn(); // End the turn if all units have acted
  }

}