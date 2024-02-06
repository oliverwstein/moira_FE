import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
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
    //  debugPrint("move to $boundedPosition");
    tilePosition = boundedPosition;
    targetPosition = Vector2(tilePosition.x*Stage.tileSize, tilePosition.y*Stage.tileSize);
    
  }
  
  void snapToTile(Point<int> newTilePosition){
    tilePosition = newTilePosition;
    x = newTilePosition.x * Stage.tileSize;
    y = newTilePosition.y * Stage.tileSize;
    targetPosition = Vector2(x, y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if(game.stage.freeCursor){isVisible = true;} else {isVisible = false;}
    if(position != targetPosition) {
      if(!game.stage.menuManager.isNotEmpty){
        Vector2 shift = getCursorEdgeOffset();
        if(shift.length != 0) game.camera.moveBy(shift, speed: 10*shift.length.abs());
      }
      position.lerp(targetPosition, 1/8);
    }
  }

  Vector2 centerCameraOn(Point<int> newTilePosition, double speed) {
    Vector2 crudePosition = Vector2(newTilePosition.x*Stage.tileSize, newTilePosition.y*Stage.tileSize);
    Rect playBox = Rect.fromPoints(const Offset(0, 0), game.stage.playAreaSize.toOffset());
    Rect centeredRect = Rect.fromCenter(
      center: crudePosition.toOffset(),
      width: game.camera.visibleWorldRect.width,
      height: game.camera.visibleWorldRect.height
    );
    double dx = 0;
    if (centeredRect.left < playBox.left) {
      dx = (playBox.left - centeredRect.left);
    } else if (centeredRect.right > playBox.right) {
      dx = (playBox.right - centeredRect.right);
    }
    double dy = 0;
    if (centeredRect.top < playBox.top) {
      dy = (playBox.top - centeredRect.top);
    } else if (centeredRect.bottom > playBox.bottom) {
      dy = (playBox.bottom - centeredRect.bottom);
    }
    Vector2 centeredPosition = crudePosition + Vector2(dx, dy);
    game.camera.moveTo(centeredPosition, speed: speed);
    return centeredPosition;
  }

  Vector2 getCursorEdgeOffset() {
    Rect playBox = Rect.fromPoints(const Offset(0, 0), game.stage.playAreaSize.toOffset());
    Rect centeredRect = game.camera.visibleWorldRect;

    // Set distance to check from edge
    double edgeDistance = Stage.tileSize * 2;

    // Calculate potential dx and dy
    double dx = _calculateOffset(position.x, centeredRect.left, centeredRect.right, playBox.left, playBox.right, edgeDistance);
    double dy = _calculateOffset(position.y, centeredRect.top, centeredRect.bottom, playBox.top, playBox.bottom, edgeDistance);

    // Clamp dx and dy to ensure centeredRect does not go outside playBox
    double clampedDx = _clampOffset(dx, centeredRect.left, centeredRect.right, playBox.left, playBox.right);
    double clampedDy = _clampOffset(dy, centeredRect.top, centeredRect.bottom, playBox.top, playBox.bottom);

    return Vector2(clampedDx, clampedDy);
}

double _calculateOffset(double pos, double rectStart, double rectEnd, double boxStart, double boxEnd, double edgeDistance) {
    double distStart = (pos - rectStart < edgeDistance && boxStart < rectStart) ? edgeDistance - (pos - rectStart) : 0;
    double distEnd = (rectEnd - pos < edgeDistance && boxEnd > rectEnd) ? edgeDistance - (rectEnd - pos) : 0;
    return distEnd - distStart;
}

double _clampOffset(double offset, double rectStart, double rectEnd, double boxStart, double boxEnd) {
    if (offset > 0) { // Moving right or down
        return min(offset, boxEnd - rectEnd);
    } else { // Moving left or up
        return max(offset, boxStart - rectStart);
    }
}

}