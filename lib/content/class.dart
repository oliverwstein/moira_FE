import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:moira/content/content.dart';
class Class extends Component with HasGameReference<MoiraGame>{
  final String name;
  final String description;
  final int movementRange;
  final List<String> skills;
  final List<String> attacks;
  final List<String> proficiencies;
  final List<String> orders;
  final Map<String, int> baseStats;
  final Map<String, int> growths;
  Map<String, SpriteAnimationComponent> animationMap = {};
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

  @override
  Future<void> onLoad() async {
    Image spriteSheetImage = await game.images.load('${name.toLowerCase()}_spritesheet.png');
    SpriteSheet spriteSheet = SpriteSheet.fromColumnsAndRows(
      image: spriteSheetImage,
      columns: 4,
      rows: 5,
    );
     Vector2 spriteSize = Vector2(spriteSheetImage.width/4, spriteSheetImage.height/5);
    double stepTime = .15;
    animationMap['down'] = SpriteAnimationComponent(
                            animation: spriteSheet.createAnimation(row: 0, stepTime: stepTime),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['up'] = SpriteAnimationComponent(
                            animation: spriteSheet.createAnimation(row: 1, stepTime: stepTime),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['right'] = SpriteAnimationComponent(
                            animation: spriteSheet.createAnimation(row: 2, stepTime: stepTime),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['left'] = SpriteAnimationComponent(
                            animation: spriteSheet.createAnimation(row: 3, stepTime: stepTime),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['idle'] = SpriteAnimationComponent(
                            animation: spriteSheet.createAnimation(row: 4, stepTime: stepTime*2),
                            size: spriteSize,
                            anchor: Anchor.center);
  }
}