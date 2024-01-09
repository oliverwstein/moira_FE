import 'package:flame/components.dart';

import '../engine/engine.dart';

class Skill extends Component {
  final String name;
  final String description;
  late final Unit unit;
  Observer? observer;

  Skill._internal(this.name, this.description, this.unit){
    switch (name) {
      case "Canto":
        observer = Canto(unit);
        break;
      case "Pavise":
        observer = Pavise(unit);
        break;
      default:
    }
  }

  factory Skill.fromJson(String name, Unit unit) {
    Map<String, dynamic> skillData;
    if (MyGame.skillMap['skills'].containsKey(name)) {
      skillData = MyGame.skillMap['skills'][name];
    } else {
      skillData = {"description": "No such skill"};
      }
    String description = skillData["description"];

    return Skill._internal(name, description, unit);
  }

  void attachToUnit(Unit unit, EventDispatcher dispatcher) {
    if (name == "Canto"){
      observer = Canto(unit); // Or determine the observer based on the skill name
      dispatcher.add(observer!);
    } else if (name == "Pavise"){
      observer = Pavise(unit); // Or determine the observer based on the skill name
      dispatcher.add(observer!);
    }
    unit.skillSet.add(this);
  }

  void detachFromUnit(EventDispatcher dispatcher) {
    if (observer != null) {
      dispatcher.remove(observer!);
      observer = null;
    }
    unit.skillSet.remove(this);
  }
}
