// ignore_for_file: unnecessary_overrides
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/engine/engine.dart';

class Cursor extends PositionComponent with HasGameReference<MoiraGame>, HasVisibility {
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet cursorSheet;
  Point<int> tilePosition; // Current tile position
  Vector2 targetPosition; // Target position in pixels
  bool isMoving = false;
  double speed = 300;

  Cursor(this.tilePosition) : targetPosition = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the cursor image and create the animation component
    ui.Image cursorImage = await game.images.load('cursor.png');
    cursorSheet = SpriteSheet.fromColumnsAndRows(
      image: cursorImage,
      columns: 3,
      rows: 1,
    );
    _animationComponent = SpriteAnimationComponent(
      animation: cursorSheet.createAnimation(row: 0, stepTime: 0.2),
      size: Vector2.all(Stage.tileSize),
    );

    // Set the initial position of the cursor
    
    position = game.stage.tileMap[tilePosition]!.position;
    targetPosition = position.clone();

    // Add the animation component as a child
    add(_animationComponent);
    anchor = Anchor.topLeft;
  }

  void moveTo(Point<int> newTilePosition) {
    // Calculate the bounded position within the full stage size
    Point<int> boundedPosition = Point(
      max(0, min(newTilePosition.x, game.stage.mapTileWidth - 1)),
      max(0, min(newTilePosition.y, game.stage.mapTileHeight - 1))
    );

    // Update only if the position has changed
    if (tilePosition != boundedPosition) {
      tilePosition = boundedPosition;
      targetPosition = game.stage.tileMap[boundedPosition]!.position;
      isMoving = true;
    }
  }
  void snapToTile(Point<int> newTilePosition){
    tilePosition = newTilePosition;
    x = newTilePosition.x * Stage.tileSize;
    y = newTilePosition.y * Stage.tileSize;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.world == game.stage && game.stage.activeFaction?.factionType == FactionType.blue && game.eventQueue.currentBatch().isEmpty){isVisible = true;} else {isVisible = false;}
    if (isMoving) {
      Vector2 positionDelta = Vector2.all(0);
      if (position.distanceTo(targetPosition) < 0.1) { // Small threshold
        positionDelta = targetPosition - position;
        position = targetPosition;
        isMoving = false;
      } else {
        Vector2 currentPosition = position.clone();
        position.lerp(targetPosition, min(1, speed * dt / position.distanceTo(targetPosition)));
        positionDelta = position - currentPosition;
      }
      Rect boundingBox = game.camera.visibleWorldRect.deflate(Stage.tileSize);
      if (!boundingBox.contains(position.toOffset())) {
        Rect playArea = Rect.fromPoints(const Offset(0, 0), game.stage.playAreaSize.toOffset());
          if(playArea.contains((position).toOffset())){
            game.camera.moveBy(positionDelta);
          }
      }
    }
  }
  Vector2 centerCamera() {
  // Calculate the centered position
  Vector2 centeredPosition = Vector2(tilePosition.x.toDouble(), tilePosition.y.toDouble()) * Stage.tileSize;
  centeredPosition.add(Vector2(Stage.tileSize / 2, Stage.tileSize / 2)); // Center on the tile

  // Adjust for camera view size
  centeredPosition.sub(game.camera.viewport.size / 2);

  // Ensure the camera does not go outside the bounding box of the stage
  Rect stageBounds = Rect.fromLTWH(0, 0, game.stage.mapTileWidth * Stage.tileSize, game.stage.mapTileHeight * Stage.tileSize);
  Rect cameraBounds = Rect.fromCenter(center: centeredPosition.toOffset(), width: game.camera.viewport.size.x, height: game.camera.viewport.size.y);

  // Adjust if camera bounds exceed stage bounds
  if (!stageBounds.contains(cameraBounds.topLeft)) {
    centeredPosition.x = max(centeredPosition.x, stageBounds.left + game.camera.viewport.size.x / 2);
    centeredPosition.y = max(centeredPosition.y, stageBounds.top + game.camera.viewport.size.y / 2);
  }
  if (!stageBounds.contains(cameraBounds.bottomRight)) {
    centeredPosition.x = min(centeredPosition.x, stageBounds.right - game.camera.viewport.size.x / 2);
    centeredPosition.y = min(centeredPosition.y, stageBounds.bottom - game.camera.viewport.size.y / 2);
  }
  return centeredPosition;
}

}