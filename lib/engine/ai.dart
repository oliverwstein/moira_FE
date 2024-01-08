import 'package:flame/components.dart';

import 'engine.dart';

class NPCPlayer extends Component{
  List<Unit> units;
  NPCPlayer(this.units);

  void takeTurn() {
    Stage stage = parent as Stage;
    for (var unit in units) {
      unit.wait(); // Each unit takes its action by waiting
    }
    // Check if all units have acted
    if (units.every((unit) => unit.canAct = false)) {
      stage.endTurn(); // End the turn if all units have acted
    }
  }

}