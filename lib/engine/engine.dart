export 'game.dart';
export 'stage.dart';
export 'event.dart';
export 'trigger.dart';
export 'tile.dart';
export 'cursor.dart';
export 'hud.dart';
export 'movement.dart';
export 'behavior.dart';
export 'title_card.dart';
export 'player.dart';
export 'menu.dart';
export 'combat.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';



abstract class InputHandler {
  KeyEventResult handleKeyEvent(RawKeyEvent key, Set<LogicalKeyboardKey> keysPressed);
}
enum FactionType {blue, red, green}
extension FactionOrder on FactionType {
  int get order {
    switch (this) {
      case FactionType.blue:
        return 0;
      case FactionType.red:
        return 1;
      case FactionType.green:
        return 2;
    }
  }
  Color get factionColor {
    switch (this) {
      case FactionType.blue:
        return Color.fromARGB(255, 0, 0, 255); // RGB for blue
      case FactionType.red:
        return const Color.fromARGB(255, 255, 0, 0); // RGB for red
      case FactionType.green:
        return const Color.fromARGB(255, 0, 255, 0); // RGB for green
      default:
        return const Color.fromARGB(128, 255, 255, 255);
    }
  }
  String get name => toString().split('.').last.replaceFirstMapped(RegExp(r'[a-zA-Z]'), (match) => match.group(0)!.toUpperCase());

  // Static method to get a skill by its name
  static FactionType? fromName(String name) {
    try {
      return FactionType.values.firstWhere((factionType) => factionType.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null; // Return null if no matching faction is found
    }
  }
}


enum ItemType {main, gear, treasure, basic}

