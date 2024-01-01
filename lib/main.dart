// ignore_for_file: unnecessary_overrides

import 'dart:ui' as ui;
import 'package:flutter/material.dart' as mat;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
enum Direction {
  up,
  down,
  left,
  right
}

class Tile {
  final Point position;
  String terrainType; // e.g., "grass", "water", "mountain"
  Unit? unit; // Initially null, set when a unit moves into the tile

  Tile(this.position, this.terrainType);

  bool get isOccupied => unit != null;

  void setUnit(Unit newUnit) {
    unit = newUnit;
  }

  void removeUnit() {
    unit = null;
  }
}

class Stage extends Component with HasGameRef<MyGame> {
  late final int mapTileWidth;
  late final int mapTileHeight;
  late final Vector2 mapSize;
  late final TiledComponent tiles;
  late final Cursor cursor;
  List<Unit> units = [];
  final Vector2 tilesize = Vector2.all(16);
  late Map<Point, Tile> tilesMap = {};
  Stage();

  @override
  Future<void> onLoad() async {
    tiles = await TiledComponent.load('Ch0.tmx', tilesize);
    tiles.anchor = Anchor.topLeft;
    tiles.scale = Vector2.all(gameRef.scaleFactor);

    mapTileHeight = tiles.tileMap.map.height;
    mapTileWidth = tiles.tileMap.map.width;
    for (double x = 0; x < mapTileWidth; x++) {
      for (double y = 0; y < mapTileHeight; y++) {
        Point point = Point(x:x, y:y);
        String terrainType = determineTerrainType(point); // Implement this based on your Tiled map properties
        tilesMap[point] = Tile(point, terrainType);
      }
    }
    add(tiles);

    units.add(Unit(Point(x:59, y:10), 'arden.png'));
    units.add(Unit(Point(x:60, y:12), 'alec.png'));
    units.add(Unit(Point(x:58, y:12), 'noish.png'));
    units.add(Unit(Point(x:59, y:13), 'sigurd.png'));

    for (Unit unit in units) {
      add(unit);
      gameRef.addObserver(unit);
    }

    cursor = Cursor();
    add(cursor);
    gameRef.addObserver(cursor);
    
  }
  @override
  void update(double dt) {
    super.update(dt);
  }

  @override
  void onMount() {
    gameRef.addObserver(this);
    super.onMount();
  }

  @override
  void onRemove() {
    gameRef.removeObserver(this);
    super.onRemove();
  }

  void onScaleChanged(double scaleFactor) {
    for (final child in children) {
      if (child is TiledComponent) {
        child.scale = Vector2.all(scaleFactor);
      }
    }
  }

  void updateTileWithUnit(Point oldPoint, Point newPoint, Unit unit) {
    getTileAt(oldPoint)?.removeUnit();
    getTileAt(newPoint)?.setUnit(unit);
  }

  Tile? getTileAt(Point point) {
    return tilesMap[point];
  }
  String determineTerrainType(Point point){
    double localId = point.y * mapTileWidth + point.x;
    var tile = tiles.tileMap.map.tileByLocalId('Ch0', localId.toInt());
    var type = tile?.properties.firstOrNull?.value ?? 'plain';
    return type as String;
  }
}

class Cursor extends PositionComponent with HasGameRef<MyGame> {
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet cursorSheet;
  late final BattleMenu battleMenu;

  
  Point tilePosition = Point(x:59, y:12); // The cursor's position in terms of tiles, not pixels
  late double tileSize;

  Cursor() {
    // Initial size, will be updated in onLoad
    tileSize = 16 * MyGame().scaleFactor;
  }

  @override
  Future<void> onLoad() async {
    // Load the cursor image and create the animation component
    ui.Image cursorImage = await gameRef.images.load('cursor.png');
    cursorSheet = SpriteSheet.fromColumnsAndRows(
      image: cursorImage,
      columns: 3,
      rows: 1,
    );

    _animationComponent = SpriteAnimationComponent(
      animation: cursorSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(tileSize), // Use tileSize for initial size
    );

    // Add the animation component as a child
    add(_animationComponent);
    battleMenu = BattleMenu();
    add(battleMenu);

    // Set the initial size and position of the cursor
    size = Vector2.all(tileSize);
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }

  Vector2 get worldPosition {
        return Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
    }

  void move(Direction direction) {
    // Assuming parent is always a Stage which is the case in this architecture
    Stage stage = parent as Stage;

    double newX = tilePosition.x;
    double newY = tilePosition.y;

    switch (direction) {
      case Direction.left:
        newX -= 1;
        break;
      case Direction.right:
        newX += 1;
        break;
      case Direction.up:
        newY -= 1;
        break;
      case Direction.down:
        newY += 1;
        break;
    }

    // Clamp the new position to ensure it's within the bounds of the map
    newX = newX.clamp(0, stage.mapTileWidth - 1);
    newY = newY.clamp(0, stage.mapTileHeight - 1);

    // Update tilePosition if it's within the map
    tilePosition = Point(x: newX, y: newY);

    // Update the pixel position of the cursor
    x = tilePosition.x * tileSize;
    y = tilePosition.y * tileSize;
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
  
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the cursor itself
    _animationComponent.size = Vector2.all(tileSize); // Update animation component size

    // Update position based on new tileSize
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }

}

class BattleMenu extends PositionComponent with HasGameRef<MyGame>, HasVisibility {
  late final SpriteComponent menuSprite;
  late final AnimatedPointer pointer;
  @override
  Future<void> onLoad() async {
    // Load and position the menu sprite
    menuSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('action_menu.png'),
        // size: Vector2(71, 122),
    );
    add(menuSprite);

    // Create and position the pointer
    pointer = AnimatedPointer();
    add(pointer);
    isVisible = false;
  }

  void toggleVisibility() {
    isVisible = !isVisible;
    // Additional logic to show/hide or enable/disable
  }

  @override
  void render(Canvas canvas) {
    if (isVisible) {
      
      super.render(canvas);  // Render only if menu is visible
    }
  }
}

class AnimatedPointer extends PositionComponent with HasGameRef<MyGame> {
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet pointerSheet;

  // Adjust these based on your menu layout
  final double stepY = 16; // The vertical distance between menu items
  int currentIndex = 0;   // The index of the current menu item

  late double tileSize;

  AnimatedPointer() {
    // Initial size, will be updated in onLoad
    tileSize = 16;
  }
  @override
  Future<void> onLoad() async {
    // Load the cursor image and create the animation component
    ui.Image pointerImage = await gameRef.images.load('selection_pointer.png');
    pointerSheet = SpriteSheet.fromColumnsAndRows(
      image: pointerImage,
      columns: 3,
      rows: 1,
    );

    _animationComponent = SpriteAnimationComponent(
      animation: pointerSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(tileSize), // Use tileSize for initial size
    );

    add(_animationComponent);

    // Set the initial size and position of the cursor
    size = Vector2.all(tileSize);
  }

  void moveUp() {
    if (currentIndex > 0) {
      currentIndex--;
      updatePosition();
    }
  }

  void moveDown() {
    if (currentIndex < 7) {
      currentIndex++;
      updatePosition();
    }
  }

  void updatePosition() {
    // Update the position of the pointer based on the current index
    y = 5 + stepY * currentIndex;
  }
}

class Unit extends PositionComponent with HasGameRef<MyGame> {
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet unitSheet;
  late final BattleMenu battleMenu;
  late final String unitImageName;
  bool canAct = true;
  
  late final Point tilePosition; // The units's position in terms of tiles, not pixels
  late double tileSize;

  Unit(this.tilePosition, this.unitImageName) {
    // Initial size, will be updated in onLoad
    tileSize = 16 * MyGame().scaleFactor;
  }

  @override
  Future<void> onLoad() async {
    // Load the unit image and create the animation component
    ui.Image unitImage = await gameRef.images.load(unitImageName);
    unitSheet = SpriteSheet.fromColumnsAndRows(
      image: unitImage,
      columns: 4,
      rows: 1,
    );

    _animationComponent = SpriteAnimationComponent(
      animation: unitSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(tileSize), // Use tileSize for initial size
    );
    
    // Add the animation component as a child
    add(_animationComponent);

    // Set the initial size and position of the unit
    size = Vector2.all(tileSize);
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }

  Vector2 get worldPosition {
        return Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
    }

  void toggleCanAct() {
    canAct = !canAct;
    // Define the grayscale paint
    final grayscalePaint = mat.Paint()
      ..colorFilter = const mat.ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]);

    // Apply or remove the grayscale effect based on canAct
    _animationComponent.paint = canAct ? mat.Paint() : grayscalePaint;
  }

  void move(Direction direction) {
    Stage stage = parent as Stage;

    double newX = tilePosition.x;
    double newY = tilePosition.y;

    switch (direction) {
      case Direction.left:
        newX -= 1;
        break;
      case Direction.right:
        newX += 1;
        break;
      case Direction.up:
        newY -= 1;
        break;
      case Direction.down:
        newY += 1;
        break;
    }

    // Clamp the new position to ensure it's within the bounds of the map
    newX = newX.clamp(0, stage.mapTileWidth - 1);
    newY = newY.clamp(0, stage.mapTileHeight - 1);

    // Update tilePosition if it's within the map
    tilePosition = Point(x: newX, y: newY);

    // Update the pixel position of the unit
    x = tilePosition.x * tileSize;
    y = tilePosition.y * tileSize;
    
    Point oldPosition = tilePosition;
    stage.updateTileWithUnit(oldPosition, tilePosition, this);
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
  
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the unit itself
    _animationComponent.size = Vector2.all(tileSize); // Update animation component size

    // Update position based on new tileSize
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }

}

abstract class ScaleObserver {
  void onScaleChanged(double scaleFactor);
}

class MyGame extends FlameGame with KeyboardEvents {
  late MaxViewport viewport;
  late Stage stage;
  double _scaleFactor = 1;
  final List _observers = [];
  double get scaleFactor => _scaleFactor;

  set scaleFactor(double value) {
    if (_scaleFactor != value) {
      _scaleFactor = value;
      for (var observer in _observers) {
        observer.onScaleChanged(_scaleFactor);
      }
    }
  }

  void addObserver(observer) {
    _observers.add(observer);
  }

  void removeObserver(observer) {
    _observers.remove(observer);
  }

  @override
    void update(double dt) {
        super.update(dt);
    }

  @override
  Future<void> onLoad() async {
    
    await super.onLoad();
    // Your existing onLoad implementation
    viewport = MaxViewport();
    camera.viewport = viewport;
    stage = Stage();
    await world.add(stage);
    addObserver(stage);
    camera.follow(stage.cursor);

    // battleMenu = BattleMenu();
    // world.add(battleMenu);
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool handled = false;

    // Handling the keyboard events
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        stage.cursor.battleMenu.toggleVisibility();
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
        if (stage.cursor.battleMenu.isVisible) {stage.cursor.battleMenu.toggleVisibility();}
        handled = true;
      } 
      if (stage.cursor.battleMenu.isVisible) {
        // Handle menu navigation
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          stage.cursor.battleMenu.pointer.moveUp();
          handled = true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          stage.cursor.battleMenu.pointer.moveDown(); // Assuming 7 menu items, max index is 6
          handled = true;
        }
      } else {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          stage.cursor.move(Direction.left);
          handled = true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          stage.cursor.move(Direction.right);
          handled = true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          stage.cursor.move(Direction.up);
          handled = true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          stage.cursor.move(Direction.down);
          handled = true;
        } else if (event.logicalKey == LogicalKeyboardKey.equal) { // "+" key for zooming in
          scaleFactor *= 1.1;//.clamp(0.5, 2.0); // Zoom in and clamp between 0.5x and 2x
          handled = true;
        } else if (event.logicalKey == LogicalKeyboardKey.minus) { // "-" key for zooming out
          scaleFactor *= 0.9;//.clamp(0.5, 2.0); // Zoom out and clamp
          handled = true;
        }
      }
    }
  return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }
}

void main() {
  final game = MyGame();
  runApp(
    GameWidget(game: game),
  );
}
