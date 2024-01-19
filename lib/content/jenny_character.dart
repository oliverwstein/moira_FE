import 'dart:async';

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

enum CharacterDirection { left, right }

enum CharacterStartLocation { left, right }

class CharacterComponent extends SpriteComponent with HasGameReference<MoiraGame> {
  SpriteComponent spriteComponent;

  double leftBorder = 0.0;
  late double rightBorder;
  final CharacterStartLocation startLocation;
  late CharacterDirection direction;
  bool move = false;

  CharacterComponent({required this.spriteComponent, required this.startLocation})
      : super(anchor: Anchor.topCenter);

  @override
  FutureOr<void> onLoad() {
    sprite = sprite;
    if (startLocation == CharacterStartLocation.left) {
      position = Vector2(size.x / 2, 0);
      leftBorder = 0.0;
      rightBorder = game.size.x / 3;
      direction = CharacterDirection.left;
    } else {
      rightBorder = game.size.x - size.x / 2;
      leftBorder = game.size.x * .6;
      position = Vector2(game.size.x - size.x / 2, 0);
      direction = CharacterDirection.right;
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    switch (direction) {
      case CharacterDirection.left:
        if (x - size.x / 2 > leftBorder) {
          if (move) {
            x -= 50 * dt;
          }
        } else {
          direction = CharacterDirection.right;
          move = false;
        }
        break;
      case CharacterDirection.right:
        if (x < rightBorder) {
          if (move) {
            x += 50 * dt;
          }
        } else {
          direction = CharacterDirection.left;
          move = false;
        }
        break;
    }
    super.update(dt);
  }
}