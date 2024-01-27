import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

enum Skill {canto, pavise, vantage}

abstract class SkillHandler {
  void execute(Unit unit);
}

class Canto extends SkillHandler {
  @override
  void execute(Unit unit) {
    // Implementation for Canto
  }
}