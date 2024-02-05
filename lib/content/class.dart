import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/rendering.dart';
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
  Direction? _currentDirection;
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
  Direction? get direction => _currentDirection;
  set direction(Direction? newDirection) {
    _currentDirection = newDirection;
    int row;
    double currentStepTime = .1;
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
    Image spriteSheetImage = await game.images.load('class_sprites/${name.toLowerCase()}_spritesheet.png');
    Image recoloredSpriteImage = await replaceShades(spriteSheetImage, redShades);
    spriteSheet = SpriteSheet.fromColumnsAndRows(
      image: recoloredSpriteImage,
      columns: 4,
      rows: 5,
    );
    spriteSize = Vector2(spriteSheetImage.width/4, spriteSheetImage.height/5);
    size = spriteSize; anchor = Anchor.center;
  }
}

Map<int, int> grays = {
  0xFF292929: 0, // Placeholder for dynamic replacement
  0xFF494949: 0,
  0xFF7A7A7A: 0,
  0xFF8D8D8D: 0,
  0xFFCECECE: 0,
};

// Replacement shades for red
Map<int, int> redShades = {
  0xFF292929: 0xFF290808,
  0xFF494949: 0xFF490F0F,
  0xFF7A7A7A: 0xFF7A1818,
  0xFF8D8D8D: 0xFF8D3838,
  0xFFCECECE: 0xFFCE7C7C,
};

// Replacement shades for blue
Map<int, int> blueShades = {
  0xFF292929: 0xFF040029,
  0xFF494949: 0xFF1B1649,
  0xFF7A7A7A: 0xFF233876,
  0xFF8D8D8D: 0xFF366087,
  0xFFCECECE: 0xFF9097CE,
};

Map<int, int> greenShades = {
  0xFF292929: 0xFF0A2908,
  0xFF494949: 0xFF0F490F,
  0xFF7A7A7A: 0xFF187A18,
  0xFF8D8D8D: 0xFF388D38,
  0xFFCECECE: 0xFF7CCE7C,
};

Future<Image> replaceShades(Image image, Map<int, int> replacementShades) async {
  final ByteData? byteData = await image.toByteData(format: ImageByteFormat.rawUnmodified);
  final buffer = byteData!.buffer.asUint8List();

  for (int i = 0; i < buffer.length; i += 4) {
    // Extract the current pixel color (in ARGB format)
    int currentColor = (buffer[i+3] << 24) | (buffer[i] << 16) | (buffer[i+1] << 8) | buffer[i+2];

    // Check if the current color is one of the grays to replace
    if (replacementShades.containsKey(currentColor)) {
      // Replace with the corresponding color
      int newColor = replacementShades[currentColor]!;
      buffer[i] = (newColor >> 16) & 0xFF; // Red component
      buffer[i + 1] = (newColor >> 8) & 0xFF; // Green component
      buffer[i + 2] = newColor & 0xFF; // Blue component
      // Alpha remains unchanged
    }
  }

  final ImmutableBuffer immutableBuffer = await ImmutableBuffer.fromUint8List(buffer);
  final ImageDescriptor imageDescriptor = ImageDescriptor.raw(
    immutableBuffer,
    width: image.width,
    height: image.height,
    pixelFormat: PixelFormat.rgba8888,
  );

  final Codec codec = await imageDescriptor.instantiateCodec();
  final FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

