import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../engine/engine.dart';

class TitleCard extends Component with HasGameRef<MyGame>, HasVisibility implements CommandHandler {
  /// Cursor represents the player's cursor in the game world. It extends the PositionComponent,
  /// allowing it to have a position in the game world, and implements CommandHandler for handling
  /// keyboard inputs. The Cursor navigates the game's stage, interacting with tiles and units.
  late final SpriteComponent _spriteComponent;
  
  TitleCard();

  @override
  void update(double dt) {
    super.update(dt);
     _spriteComponent.scale = Vector2.all(1/max(_spriteComponent.size.x / gameRef.canvasSize.x,
                        _spriteComponent.size.y / gameRef.canvasSize.y));
  }

  @override
  Future<void> onLoad() async {
    final imagesLoader = Images();
    ui.Image titleCardImage = await imagesLoader.load('title_card.png');
    _spriteComponent = SpriteComponent.fromImage(titleCardImage);
    add(_spriteComponent);
    _spriteComponent.anchor = Anchor.center;
  }

  @override
  void onMount() {
    super.onMount();
    gameRef.addObserver(this);
  }

  @override
  void onRemove() {
    gameRef.removeObserver(this);
    super.onRemove();
  }
  
  @override
  bool handleCommand(LogicalKeyboardKey command) {
   bool handled = false;
    if (command == LogicalKeyboardKey.enter) {
      gameRef.eventQueue.addEventBatch([CreateStageEvent(gameRef)]);
      handled = true;
    }
    return handled;
  }
}