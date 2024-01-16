import 'package:flame/components.dart';
import 'package:moira/content/content.dart';
class Skill extends Component {
  final String name;
  final String description;
  late final Unit unit;

  Skill._internal(this.name, this.description, this.unit){
    switch (name) {
      case "Canto":
        // observer = Canto(unit);
        break;
      case "Pavise":
        // observer = Pavise(unit);
        break;
      default:
    }
  }

  factory Skill.fromJson(String name, Unit unit) {
    Map<String, dynamic> skillData;
    if (MoiraGame.skillMap['skills'].containsKey(name)) {
      skillData = MoiraGame.skillMap['skills'][name];
    } else {
      skillData = {"description": "No such skill"};
      }
    String description = skillData["description"];

    return Skill._internal(name, description, unit);
  }
}
