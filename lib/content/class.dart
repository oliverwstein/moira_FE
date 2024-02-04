import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:moira/content/content.dart';
class Class extends SpriteAnimationComponent with HasGameReference<MoiraGame>{
  final String name;
  final String description;
  final int movementRange;
  final List<String> skills;
  final List<String> attacks;
  final List<String> proficiencies;
  final List<String> orders;
  final Map<String, int> baseStats;
  final Map<String, int> growths;
  late SpriteSheet spriteSheet;
  late Vector2 spriteSize;
  // Factory constructor
  factory Class.fromJson(String name) {
    Map<String, dynamic> classData;

    // Check if the class exists in the map and retrieve its data
    if (MoiraGame.classMap['classes'].containsKey(name)) {
      classData = MoiraGame.classMap['classes'][name];
    } else {classData = {};}
    String description = classData['description'] ?? "An unknown foe";
    int movementRange = classData['movementRange'] ?? 6;
    List<String> skills = List<String>.from(classData['skills'] ?? []);
    List<String> attacks = List<String>.from(classData['attacks'] ?? []);
    List<String> proficiencies = List<String>.from(classData['proficiencies'] ?? []);
    List<String> orders = List<String>.from(classData['orders'] ?? []);
    Map<String, int> baseStats = Map<String, int>.from(classData['baseStats']);
    Map<String, int> growths = Map<String, int>.from(classData['growths']);
    
    // Return a new Weapon instance
    return Class._internal(name, description, movementRange, skills, attacks, proficiencies, orders, baseStats, growths);
  }
  // Internal constructor for creating instances
  Class._internal(this.name, this.description, this.movementRange, this.skills, this.attacks, this.proficiencies, this.orders, this.baseStats, this.growths);

  set direction(Direction? newDirection) {
    int row;
    double currentStepTime = .15;
    switch (newDirection) {
      case Direction.down:
        row = 0;
        break;
      case Direction.up:
        row = 1;
        break;
      case Direction.right:
        row = 2;
        break;
      case Direction.left:
        row = 3;
        break;
      default:
        row = 4;
        currentStepTime *= 2;
    }
    animation = spriteSheet.createAnimation(row: row, stepTime: currentStepTime);
    size = spriteSize; anchor = Anchor.center;
  }
  @override
  Future<void> onLoad() async {
    debugPrint(name.toLowerCase());
    Image spriteSheetImage = await game.images.load('${name.toLowerCase()}_spritesheet.png');
    spriteSheet = SpriteSheet.fromColumnsAndRows(
      image: spriteSheetImage,
      columns: 4,
      rows: 5,
    );
    spriteSize = Vector2(spriteSheetImage.width/4, spriteSheetImage.height/5);
    size = spriteSize; anchor = Anchor.center;
  }
}