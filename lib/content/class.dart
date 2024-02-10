// ignore_for_file: prefer_const_constructors

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
  String factionType;
  Direction? _currentDirection;
  // Factory constructor
  factory Class.fromJson(String name, String factionType) {
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
    return Class._internal(name, factionType, description, movementRange, skills, attacks, proficiencies, orders, baseStats, growths);
  }
  // Internal constructor for creating instances
  Class._internal(this.name, this.factionType, this.description, this.movementRange, this.skills, this.attacks, this.proficiencies, this.orders, this.baseStats, this.growths);
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
  debugPrint("Load Class Sprite Sheet ${FactionOrder.fromName(factionType)!.name}.$name");
  Image spriteSheetImage = game.images.fromCache("${FactionOrder.fromName(factionType)!.name}.$name");
  // Image spriteSheetImage = game.images.fromCache(name);
  spriteSheet = SpriteSheet.fromColumnsAndRows(
    image: spriteSheetImage,
    columns: 4,
    rows: 5,
  );

  // Set the sprite size and component size based on the original image dimensions
  spriteSize = Vector2(spriteSheetImage.width / 4, spriteSheetImage.height / 5);
  size = spriteSize;
  anchor = Anchor.center;
  direction = null;
}
}

Map<Color, Map<FactionType, Color>> colorTransformations = {
  Color(0xFF292929): {
    FactionType.red: Color(0xFF290808),
    FactionType.green: Color(0xFF0A2908),
    FactionType.blue: Color(0xFF040029),
  },
  Color(0xFF494949): {
    FactionType.red: Color.fromARGB(255, 91, 26, 26),
    FactionType.green: Color.fromARGB(255, 48, 145, 48),
    FactionType.blue: Color.fromARGB(255, 54, 52, 125),
  },
  Color(0xFF7A7A7A): {
    FactionType.red: Color(0xFF7A1818),
    FactionType.green: Color(0xFF187A18),
    FactionType.blue: Color(0xFF233876),
  },
  Color(0xFF8D8D8D): {
    FactionType.red: Color(0xFF8D3838),
    FactionType.green: Color(0xFF388D38),
    FactionType.blue: Color(0xFF366087),
  },
  Color(0xFFCECECE): {
    FactionType.red: Color(0xFFCE7C7C),
    FactionType.green: Color(0xFF7CCE7C),
    FactionType.blue: Color(0xFF9097CE),
  },
};

Future<Image> applyFactionColorShift(Image image, FactionType faction) async {
  final ByteData? byteData = await image.toByteData(format: ImageByteFormat.rawUnmodified);
  if (byteData == null) return image; // Return original image if byteData is null
  final buffer = byteData.buffer.asUint8List();

  for (int i = 0; i < buffer.length; i += 4) {
    // Convert RGBA to a color value
    int currentColorValue = (buffer[i + 3] << 24) | (buffer[i] << 16) | (buffer[i + 1] << 8) | buffer[i + 2];
    Color currentColor = Color(currentColorValue);

    // Determine the new color based on the transformation or use the original color if no transformation is found
    Color newColor = colorTransformations[currentColor]?[faction] ?? currentColor;

    // Update the buffer with either the transformed color or the original color
    buffer[i + 0] = newColor.red;
    buffer[i + 1] = newColor.green;
    buffer[i + 2] = newColor.blue;
    // Alpha remains unchanged
  }

  // Recreate the image from the modified buffer
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


