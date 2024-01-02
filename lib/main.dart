// ignore_for_file: unnecessary_overrides
import 'dart:collection';
import 'dart:developer';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart' as mat;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
enum Direction {up, down, left, right}
enum TileState {blank, move, attack}
enum UnitTeam {blue, red, green, yellow}
enum Terrain {forest, path, cliff, water, neutral}
extension TerrainCost on Terrain {
  double get cost {
    switch (this) {
      case Terrain.forest:
        return 2;
      case Terrain.cliff:
        return 3;
      case Terrain.water:
        return 100;
      case Terrain.path:
        return .5;
      default:
        return 1;
    }
  }
}

class Tile extends PositionComponent with HasGameRef<MyGame>{
  /// Tile represents a single tile on the game's map. It is a positional component that
  /// can hold a unit and has different states to represent various terrains and actions,
  /// such as movement or attack animations. The Tile class is crucial in the rendering
  /// and logic of the game's map.
  ///
  /// Attributes:
  /// - `_moveAnimationComponent`: Component for rendering movement animations.
  /// - `_attackAnimationComponent`: Component for rendering attack animations.
  /// - `movementSheet`: SpriteSheet for movement animations.
  /// - `attackSheet`: SpriteSheet for attack animations.
  /// - `gridCoord`: Coordinates of the tile on the grid.
  /// - `tileSize`: Size of the tile in pixels, adjusted by the game's scale factor.
  /// - `terrain`: Type of terrain represented by the tile.
  /// - `unit`: The unit currently occupying the tile, if any.
  /// - `state`: Current state of the tile, can be blank, move, or attack.
  /// - `isOccupied`: Read-only property indicating whether the tile is occupied by a unit.
  ///
  /// Methods:
  /// - `onLoad()`: Asynchronously loads resources necessary for the tile, such as animations.
  /// - `setUnit(newUnit)`: Assigns a unit to the tile.
  /// - `removeUnit()`: Removes the unit from the tile.
  /// - `render(canvas)`: Renders the tile and its current state to the canvas.
  /// - `onScaleChanged(scaleFactor)`: Updates the tile's size and position based on the game's scale factor.
  ///
  /// Constructor:
  /// Takes the grid coordinates and terrain type and initializes the tile. The constructor also sets the tile size based on the game's scale factor.
  ///
  /// Usage:
  /// Tiles are used to compose the game's map and are managed by the Stage class. Each tile holds its position, terrain type, and potentially a unit. The Tile class also manages animations and rendering based on its state.
  ///
  /// Connects with:
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
  /// - Unit: May hold a reference to a Unit object representing a unit on the tile.
  /// - Stage: Managed by and interacts with the Stage class, which holds all tiles.

  late final SpriteAnimationComponent _moveAnimationComponent;
  late final SpriteAnimationComponent _attackAnimationComponent;
  late final SpriteSheet movementSheet;
  late final SpriteSheet attackSheet;
  late final math.Point<int> gridCoord;
  late double tileSize;
  Terrain terrain; // e.g., "grass", "water", "mountain"
  Unit? unit; // Initially null, set when a unit moves into the tile
  TileState state = TileState.blank;
  bool get isOccupied => unit != null;

  Tile(this.gridCoord, this.terrain){
    tileSize = 16 * MyGame().scaleFactor;
  }
  @override
  Future<void> onLoad() async {
    // Load the cursor image and create the animation component
    ui.Image moveImage = await gameRef.images.load('movement_highlight.png');
    ui.Image attackImage = await gameRef.images.load('attack_highlight.png');
    movementSheet = SpriteSheet.fromColumnsAndRows(
      image: moveImage,
      columns: 2,
      rows: 1,
    );
    attackSheet = SpriteSheet.fromColumnsAndRows(
      image: attackImage,
      columns: 2,
      rows: 1,
    );

    _moveAnimationComponent = SpriteAnimationComponent(
      animation: movementSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(tileSize*.9), // Use tileSize for initial size
    );

    _attackAnimationComponent = SpriteAnimationComponent(
      animation: attackSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(tileSize*.9), // Use tileSize for initial size
    );
    position = Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
  }

  void setUnit(Unit newUnit) {
    unit = newUnit;
  }

  void removeUnit() {
    unit = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas); // Don't forget to call super.render
    switch(state) {
      case TileState.blank:
        // Do nothing
        if(_moveAnimationComponent.isMounted){
          remove(_moveAnimationComponent);
        }
        if(_attackAnimationComponent.isMounted){
          remove(_attackAnimationComponent);
        }
        break;
      case TileState.move:
        // Render move animation component
        if(_attackAnimationComponent.isMounted){
          remove(_attackAnimationComponent);
        }
        add(_moveAnimationComponent);
        break;
      case TileState.attack:
        // Render attack animation component
        if(_moveAnimationComponent.isMounted){
          remove(_moveAnimationComponent);
        }
        add(_attackAnimationComponent);
        break;
    }
  }
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the tile itself
    _moveAnimationComponent.size = Vector2.all(tileSize*.9);
    _attackAnimationComponent.size = Vector2.all(tileSize*.9);

    // Update position based on new tileSize
    position = Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
  }
}

class Stage extends Component with HasGameRef<MyGame>{
  /// Stage is a primary component in the game that manages the layout of the 
  /// game map, including tiles, units, and the cursor. It interfaces with the 
  /// game's TiledComponent to render the map and holds the logic for the game's 
  /// terrain, unit positioning, and active components like cursor or units.
  ///
  /// Attributes:
  /// - `mapTileWidth`: Width of the map in tiles.
  /// - `mapTileHeight`: Height of the map in tiles.
  /// - `mapSize`: Size of the map in vector units.
  /// - `tiles`: The TiledComponent instance that renders the map.
  /// - `cursor`: Cursor object for user interaction and tile selection.
  /// - `units`: List of all units present on the stage.
  /// - `tilesize`: Size of each tile in the game.
  /// - `tilesMap`: Map from tile coordinates to Tile objects.
  /// - `activeComponent`: Currently active component (Cursor or Unit).
  ///
  /// Methods:
  /// - `onLoad()`: Asynchronously loads the stage components including tiles,
  ///    units, and sets up the cursor.
  /// - `update(dt)`: Updates the stage state every game tick.
  /// - `onMount()`: Invoked when the stage is mounted to the game, adds itself
  ///    as an observer for scaling.
  /// - `onRemove()`: Cleans up by removing itself from observers upon removal.
  /// - `onScaleChanged(scaleFactor)`: Updates scaling of tiles when game scale changes.
  /// - `updateTileWithUnit(oldPoint, newPoint, unit)`: Moves units between tiles.
  /// - `determineTerrainType(point)`: Determines the type of terrain at a given tile.
  /// - `_stringToTerrain(input)`: Converts a string to a Terrain enum.
  /// - `keyCommandHandler(command)`: Delegates key commands to the active component.
  /// - `blankAllTiles()`: Resets all tiles to the blank state.
  ///
  /// Constructor:
  /// Initializes the stage with default attributes. It sets up tiles, units, and cursor.
  ///
  /// Usage:
  /// The Stage is a central component of MyGame and is typically instantiated and
  /// managed by it. It should be loaded with necessary resources and will handle
  /// most of the gameplay logic, delegating specific actions to other components.
  ///
  /// Connects with:
  /// - MyGame: As part of the Flame game framework, it is managed and updated by MyGame.
  /// - Tile: Manages individual tiles of the game, storing their state and rendering them.
  /// - Unit: Holds and updates units, manages their interaction with tiles.
  /// - Cursor: Manages user interaction with the game through tile selection and commands.
  late final int mapTileWidth;
  late final int mapTileHeight;
  late final Vector2 mapSize;
  late final TiledComponent tiles;
  late final Cursor cursor;
  List<Unit> units = [];
  final Vector2 tilesize = Vector2.all(16);
  late Map<math.Point<int>, Tile> tilesMap = {};
  late Component activeComponent;
  Stage();

  @override
  Future<void> onLoad() async {
    tiles = await TiledComponent.load('Ch0.tmx', tilesize);
    tiles.anchor = Anchor.topLeft;
    tiles.scale = Vector2.all(gameRef.scaleFactor);
    add(tiles);
    mapTileHeight = tiles.tileMap.map.height;
    mapTileWidth = tiles.tileMap.map.width;
    for (int x = 0; x < mapTileWidth; x++) {
      for (int y = 0; y < mapTileHeight; y++) {
        math.Point<int> gridCoord = math.Point(x, y);
        Terrain terrain = determineTerrainType(gridCoord); // Implement this based on your Tiled map properties
        Tile tile = Tile(gridCoord, terrain);
        add(tile);
        gameRef.addObserver(tile);
        tilesMap[math.Point(x, y)] = tile;
      }
    }
    

    units.add(Unit(const math.Point(59, 10), 'arden.png'));
    units.add(Unit(const math.Point(60, 12), 'alec.png'));
    units.add(Unit(const math.Point(58, 12), 'noish.png'));
    units.add(Unit(const math.Point(59, 13), 'sigurd.png'));
    for (Unit unit in units) {
      add(unit);
      tilesMap[unit.tilePosition]?.setUnit(unit);
      gameRef.addObserver(unit);
    }

    cursor = Cursor();
    activeComponent = cursor;
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

  void updateTileWithUnit(math.Point<int> oldPoint, math.Point<int> newPoint, Unit unit) {
    tilesMap[oldPoint]?.removeUnit();
    tilesMap[newPoint]?.setUnit(unit);
  }
  
  Terrain determineTerrainType(math.Point<int> point){
    int localId = point.y * mapTileWidth + point.x;
    var tile = tiles.tileMap.map.tileByLocalId('Ch0', localId.toInt());
    var type = tile?.properties.firstOrNull?.value ?? 'neutral';
    return _stringToTerrain(type as String);
  }
  
  Terrain _stringToTerrain(String input) {
    // Create and initialize the map within the method
    final Map<String, Terrain> stringToTerrain = {
      for (var terrain in Terrain.values) terrain.toString().split('.').last: terrain,
    };
    // Perform the lookup and return
    return stringToTerrain[input] ?? Terrain.neutral;
  }

  bool keyCommandHandler(LogicalKeyboardKey command) {
    if (activeComponent is CommandHandler) {
      return (activeComponent as CommandHandler).handleCommand(command);
    }
    return false;
  }
  void blankAllTiles(){
    for (Tile tile in tilesMap.values) {
      tile.state = TileState.blank;
    }
  }
}

class Cursor extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  /// Cursor represents the player's cursor in the game world. It extends the PositionComponent,
  /// allowing it to have a position in the game world, and implements CommandHandler for handling
  /// keyboard inputs. The Cursor navigates the game's stage, interacting with tiles and units.
  ///
  /// Attributes:
  /// - `_animationComponent`: Component for rendering cursor animations.
  /// - `cursorSheet`: SpriteSheet for cursor animations.
  /// - `battleMenu`: BattleMenu component associated with the cursor for in-game actions.
  /// - `tilePosition`: The cursor's position in terms of tiles, not pixels.
  /// - `tileSize`: Size of the cursor in pixels, adjusted by the game's scale factor.
  ///
  /// Methods:
  /// - `onLoad()`: Asynchronously loads resources necessary for the cursor, such as animations.
  /// - `move(direction)`: Moves the cursor in the given direction, updating both tile and pixel positions.
  /// - `select()`: Interacts with the tile at the cursor's current position, handling unit selection and battle menu toggling.
  /// - `handleCommand(command)`: Implements the CommandHandler interface to handle keyboard commands.
  /// - `onMount()`: Observes lifecycle changes, adds itself to game observers on mounting.
  /// - `onRemove()`: Cleans up by removing itself from game observers on removal.
  /// - `onScaleChanged(scaleFactor)`: Updates the cursor's size and position based on the game's scale factor.
  ///
  /// Constructor:
  /// Initializes the cursor with a default tile position and sets up its size based on the game's scale factor.
  ///
  /// Usage:
  /// The Cursor is the main interface for the player to interact with the game world, allowing them to move around the map, select units, and access menus. It is a crucial component for game navigation and interaction.
  ///
  /// Connects with:
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
  /// - Stage: Interacts with and navigates within the Stage class, which holds all tiles and units.
  /// - Tile: Interacts with tiles to select units or display menus.
  /// - Unit: May select units on the tiles to activate them or show their possible movements.

  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet cursorSheet;
  late final BattleMenu battleMenu;
  math.Point<int> tilePosition = const math.Point(59, 12); // The cursor's position in terms of tiles, not pixels
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

    int newX = tilePosition.x;
    int newY = tilePosition.y;

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
    tilePosition = math.Point(newX, newY);

    // Update the pixel position of the cursor
    x = tilePosition.x * tileSize;
    y = tilePosition.y * tileSize;
    log('Cursor position $tilePosition, terrain type ${stage.tilesMap[tilePosition]!.terrain}');
  }
  
  void select() {
  if (parent is Stage) {
    Stage stage = parent as Stage;
    Tile? tile = stage.tilesMap[tilePosition];

    if (tile != null) {
      // Proceed as normal if tile is not null
      if (tile.isOccupied) {
        Unit? unit = tile.unit;
        if (unit != null && unit.canAct) {
          stage.activeComponent = unit;
          log('${unit.unitImageName} selected');
          unit.findReachableTiles();
        }
      } else {
        stage.blankAllTiles();
        stage.cursor.battleMenu.toggleVisibility();
        stage.activeComponent = stage.cursor.battleMenu;
      }
    } else {
      // Throw an exception if tile is null
      var x = tilePosition.x;
      var y = tilePosition.y;
      bool inMap = stage.tilesMap.containsKey((x:57.0, y:12.0));
      throw Exception('Attempted to select a null tile at position ($x, $y). Point found = $inMap. $tile');
    }
  } else {
    // Optionally, handle case where parent is not a Stage
    throw Exception('Cursor\'s parent is not of type Stage.');
  }
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
    if (command == LogicalKeyboardKey.arrowLeft) {
      move(Direction.left);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) {
      move(Direction.right);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) {
      move(Direction.up);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      move(Direction.down);
      handled = true;
    } else if (command == LogicalKeyboardKey.keyA) {
      select();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) {
      Stage stage = parent as Stage;
      stage.blankAllTiles();
      stage.activeComponent = stage.cursor;
      handled = true;
    }
    return handled;
  }
  
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the cursor itself
    _animationComponent.size = Vector2.all(tileSize); // Update animation component size

    // Update position based on new tileSize
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }
}

class BattleMenu extends PositionComponent with HasGameRef<MyGame>, HasVisibility implements CommandHandler {
  /// BattleMenu is a component that represents the in-game menu for actions such as attack, move, etc.
  /// It extends PositionComponent and implements CommandHandler for handling keyboard inputs,
  /// along with HasVisibility for managing its visibility state.
  ///
  /// Attributes:
  /// - `menuSprite`: The visual representation of the menu.
  /// - `pointer`: AnimatedPointer object that indicates the current selection in the menu.
  ///
  /// Methods:
  /// - `handleCommand(command)`: Handles command inputs to navigate the menu or trigger actions.
  /// - `select()`: Handles the action of selecting a menu item, toggling menu visibility, and setting the active component.
  /// - `onLoad()`: Asynchronously loads resources necessary for the BattleMenu and initializes its components.
  /// - `toggleVisibility()`: Toggles the visibility of the BattleMenu.
  /// - `render(canvas)`: Renders the BattleMenu to the provided canvas, only if it's visible.
  ///
  /// Constructor:
  /// Initializes the BattleMenu component, setting up its visibility and subcomponents.
  ///
  /// Usage:
  /// The BattleMenu is used to display a list of actions that a player can take during their turn,
  /// such as moving units or attacking. It's typically brought up when a unit is selected and provides
  /// the means to choose what action to take next.
  ///
  /// Connects with:
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
  /// - AnimatedPointer: Utilizes AnimatedPointer to indicate the current selection within the menu.
  /// - Stage: Interacts with Stage to control game flow, toggling active components based on menu selection.

  late final SpriteComponent menuSprite;
  late final AnimatedPointer pointer;

  @override
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    if (command == LogicalKeyboardKey.arrowUp) {
      pointer.moveUp();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      pointer.moveDown();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyA) {
      select();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB || command == LogicalKeyboardKey.keyM) {
      select();
      handled = true;
    }
    return handled;
  }

  void select(){
    Stage stage = parent!.parent as Stage;
    stage.activeComponent = stage.cursor;
    toggleVisibility();
  }

  @override
  Future<void> onLoad() async {
    // Load and position the menu sprite
    menuSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('action_menu.png'),
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
  /// AnimatedPointer is a component that represents the selection pointer in the BattleMenu,
  /// highlighting the current option selected by the player. It extends PositionComponent
  /// and is used within the BattleMenu to navigate between different options.
  ///
  /// Attributes:
  /// - `_animationComponent`: Component for rendering pointer animations.
  /// - `pointerSheet`: SpriteSheet for pointer animations.
  /// - `stepY`: The vertical distance between menu items, used to move the pointer up and down.
  /// - `currentIndex`: The index of the current menu item selected.
  /// - `tileSize`: Size of the pointer in pixels, can be adjusted with the game's scale factor.
  ///
  /// Methods:
  /// - `onLoad()`: Asynchronously loads resources necessary for the AnimatedPointer, such as animations.
  /// - `moveUp()`: Moves the pointer up in the menu, decreasing the currentIndex.
  /// - `moveDown()`: Moves the pointer down in the menu, increasing the currentIndex.
  /// - `updatePosition()`: Updates the position of the pointer based on the currentIndex.
  ///
  /// Constructor:
  /// Initializes the AnimatedPointer with a default size and index.
  ///
  /// Usage:
  /// The AnimatedPointer is used within the BattleMenu to visually indicate the current selection.
  /// It moves up and down as the player navigates the menu options, providing feedback on the current choice.
  ///
  /// Connects with:
  /// - BattleMenu: AnimatedPointer is a subcomponent of BattleMenu, indicating the current menu selection.
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
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

class Unit extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  /// Unit represents a character or entity in the game with the ability to move and act on the map.
  /// It extends PositionComponent for positional attributes and implements CommandHandler
  /// for handling keyboard commands. It's a central element in the game's mechanics, controlling
  /// movement, actions, and interactions with other units and tiles.
  ///
  /// Attributes:
  /// - `_animationComponent`: Visual representation of the unit using sprite animation.
  /// - `unitSheet`: SpriteSheet containing animation frames for the unit.
  /// - `battleMenu`: A reference to the BattleMenu for triggering actions.
  /// - `unitImageName`: The file name of the unit's image, used for loading the sprite.
  /// - `movementRange`: The number of tiles this unit can move in one turn.
  /// - `team`: The team this unit belongs to, used for identifying allies and enemies.
  /// - `tilePosition`: The unit's position on the grid map in terms of tiles.
  /// - `targetTilePosition`: A target position the unit is moving towards, if any.
  /// - `tileSize`: Size of the unit in pixels, scaled according to the game's scaleFactor.
  /// - `canAct`: Boolean indicating whether the unit can take actions.
  /// - `movementQueue`: Queue of points representing the unit's movement path.
  /// - `currentTarget`: The current tile target in the unit's movement path.
  /// - `isMoving`: Boolean indicating if the unit is currently moving.
  /// - `paths`: Stores the paths to all reachable tiles based on the unit's movement range.
  ///
  /// Methods:
  /// - `handleCommand(command)`: Handles keyboard commands for unit actions like moving or interacting.
  /// - `onLoad()`: Loads the unit's sprite and sets up the animation component.
  /// - `toggleCanAct()`: Toggles the unit's ability to act and visually indicates its state.
  /// - `enqueueMovement(targetPoint)`: Adds a new target position to the movement queue.
  /// - `update(dt)`: Updates the unit's position and handles movement towards the target tile.
  /// - `onScaleChanged(scaleFactor)`: Updates the unit's size and position based on the game's scale factor.
  /// - `findReachableTiles()`: Calculates and stores paths to all reachable tiles based on movement range.
  /// - `_constructPath(targetPoint, visitedTiles)`: Constructs the path from the unit to a specified tile.
  /// - `getDirection(point, targetPoint)`: Determines the direction from one point to another.
  ///
  /// Constructor:
  /// - Initializes a Unit with a specific position on the grid and an image name for its sprite.
  ///
  /// Usage:
  /// - Units are the primary actors in the game, controlled by the player or AI to move around the map,
  ///   interact with other units, and perform actions like attacking or defending.
  ///
  /// Connects with:
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
  /// - PositionComponent: Inherits position and size attributes and methods.
  /// - CommandHandler: Implements interface to handle keyboard commands.
  /// - Stage: Interacts with Stage for game world context, like tile access and unit positioning.
  /// - Tile: Interacts with Tile to determine movement paths and interactions based on the terrain.

  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet unitSheet;
  late final BattleMenu battleMenu;
  late final String unitImageName;
  final int movementRange = 6; 
  late UnitTeam team = UnitTeam.blue;
  late math.Point<int> tilePosition; // The units's position in terms of tiles, not pixels
  math.Point<int>? targetTilePosition;
  late double tileSize;
  bool canAct = true;
  Queue<math.Point<int>> movementQueue = Queue<math.Point<int>>();
  math.Point<int>? currentTarget;
  bool isMoving = false;
  Map<math.Point<int>, List<math.Point<int>>> paths = {};

  Unit(this.tilePosition, this.unitImageName) {
    // Initial size, will be updated in onLoad
    tileSize = 16 * MyGame().scaleFactor;
  }

  @override
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    Stage stage = parent as Stage;
    if (command == LogicalKeyboardKey.keyA) {
      for(math.Point<int> point in paths[stage.cursor.tilePosition]!){
        enqueueMovement(point);
      }
      toggleCanAct();
      stage.activeComponent = stage.cursor;
      stage.blankAllTiles();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) {
      stage.activeComponent = stage.cursor;
      stage.blankAllTiles();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowLeft) {
      math.Point<int> newPoint = math.Point(stage.cursor.tilePosition.x - 1, stage.cursor.tilePosition.y);
      if(stage.tilesMap[newPoint]?.state != TileState.blank){
        stage.cursor.move(Direction.left);
      }
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) {
      math.Point<int> newPoint = math.Point(stage.cursor.tilePosition.x + 1, stage.cursor.tilePosition.y);
      if(stage.tilesMap[newPoint]?.state != TileState.blank){
        stage.cursor.move(Direction.right);
      }
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) {
      math.Point<int> newPoint = math.Point(stage.cursor.tilePosition.x, stage.cursor.tilePosition.y - 1);
      if(stage.tilesMap[newPoint]?.state != TileState.blank){
        stage.cursor.move(Direction.up);
      }
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      math.Point<int> newPoint = math.Point(stage.cursor.tilePosition.x, stage.cursor.tilePosition.y + 1);
      if(stage.tilesMap[newPoint]?.state != TileState.blank){
        stage.cursor.move(Direction.down);
      }
      handled = true;
    }
    return handled;
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
      animation: unitSheet.createAnimation(row: 0, stepTime: .5),
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

  void enqueueMovement(math.Point<int> targetPoint) {
    movementQueue.add(targetPoint);
    if (!isMoving) {
      isMoving = true;
      currentTarget = movementQueue.removeFirst();
    }
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
  void update(double dt) {
    super.update(dt);

    if (isMoving && currentTarget != null) {
      // Calculate the pixel position for the target tile position
      final targetX = currentTarget!.x * tileSize;
      final targetY = currentTarget!.y * tileSize;

      // Move towards the target position
      // You might want to adjust the step distance depending on your game's needs
      var moveX = (targetX - x)*.6;
      var moveY = (targetY - y)*.6;

      x += moveX;
      y += moveY;

      // Check if the unit is close enough to the target position to snap it
      if ((x - targetX).abs() < 1 && (y - targetY).abs() < 1) {
        x = targetX; // Snap to exact position
        y = targetY;
        tilePosition = currentTarget!; // Update the tilePosition to the new tile
        

        // Move to the next target if any
        if (movementQueue.isNotEmpty) {
          currentTarget = movementQueue.removeFirst();
        } else {
          currentTarget = null;
          isMoving = false; // No more movements left
        }
      }
    }
  }
  
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the unit itself
    _animationComponent.size = Vector2.all(tileSize); // Update animation component size

    // Update position based on new tileSize
    position = Vector2(tilePosition.x * tileSize, tilePosition.y * tileSize);
  }

  void findReachableTiles() {
    var visitedTiles = <math.Point<int>, _TileMovement>{}; // Tracks visited tiles and their data
    var queue = Queue<_TileMovement>(); // Queue for BFS

    // Starting point - no parent at the beginning
    queue.add(_TileMovement(tilePosition, movementRange.toDouble(), null));
    while (queue.isNotEmpty) {
      var tileMovement = queue.removeFirst();
      math.Point<int> currentPoint = tileMovement.point;
      double remainingMovement = tileMovement.remainingMovement;

      // Skip if a better path to this tile has already been found
      if (visitedTiles.containsKey(currentPoint) && visitedTiles[currentPoint]!.remainingMovement >= remainingMovement) continue;
      
      // Record the tile with its movement data
      visitedTiles[math.Point(currentPoint.x, currentPoint.y)] = tileMovement;
      Tile? tile = gameRef.stage.tilesMap[currentPoint]; // Accessing tiles through stage
      if (tile!.isOccupied && tile.unit?.team != team) continue; // Skip enemy-occupied tiles

      for (var direction in Direction.values) {
        math.Point<int> nextPoint;
        switch (direction) {
          case Direction.left:
            nextPoint = math.Point(currentPoint.x - 1, currentPoint.y);
            break;
          case Direction.right:
            nextPoint = math.Point(currentPoint.x + 1, currentPoint.y);
            break;
          case Direction.up:
            nextPoint = math.Point(currentPoint.x, currentPoint.y - 1);
            break;
          case Direction.down:
            nextPoint = math.Point(currentPoint.x, currentPoint.y + 1);
            break;
        }
        Tile? nextTile = gameRef.stage.tilesMap[math.Point(nextPoint.x, nextPoint.y)];
        if (nextTile != null) {
          double cost = gameRef.stage.tilesMap[nextTile.gridCoord]!.terrain.cost;
          double nextRemainingMovement = remainingMovement - cost;
          if (nextRemainingMovement > 0) {
            queue.add(_TileMovement(nextPoint, nextRemainingMovement, currentPoint));
          }
        }
      }
    }

    // Construct paths for each tile
    for (math.Point<int> tilePoint in visitedTiles.keys) {
      paths[tilePoint] = _constructPath(tilePoint, visitedTiles);
      if(team == UnitTeam.blue){
        gameRef.stage.tilesMap[tilePoint]!.state = TileState.move;
      }
    }
  }

  // Helper method to construct a path from a tile back to the unit
  List<math.Point<int>> _constructPath(math.Point<int> targetPoint, Map<math.Point<int>, _TileMovement> visitedTiles) {
    List<math.Point<int>> path = [];
    math.Point<int>? current = targetPoint;
    while (current != null) {
      path.insert(0, current); // Insert at the beginning to reverse the path
      current = visitedTiles[current]!.parent; // Move to the parent
    }
    return path; // The path from the start to the target
  }
  
  Direction? getDirection(math.Point<int>? point, math.Point<int>? targetPoint){
    if(point == null || targetPoint == null){
      return null;
    }
    if(point.x < targetPoint.x){
      return Direction.right;
    } else if(point.x > targetPoint.x){
      return Direction.left;
    } else if(point.y < targetPoint.y){
      return Direction.down;
    } else if(point.y > targetPoint.y){
      return Direction.up;
    }
    return null;
  }
}

class _TileMovement {
  math.Point<int> point;
  double remainingMovement;
  math.Point<int>? parent; // The tile from which this one was reached

  _TileMovement(this.point, this.remainingMovement, this.parent);
}

abstract class ScaleObserver {
  void onScaleChanged(double scaleFactor);
}

abstract class CommandHandler {
  bool handleCommand(LogicalKeyboardKey command);
}

class MyGame extends FlameGame with KeyboardEvents {
  /// MyGame is the core class for the tactical RPG game, extending FlameGame for 
  /// game loop management and integrating KeyboardEvents for user interaction.
  /// It manages the game's viewport, stage, and global state like scaling.
  /// 
  /// Attributes:
  /// - `viewport`: Manages the game's viewport size and scaling.
  /// - `stage`: The main container for all game elements, including tiles and units.
  /// - `_scaleFactor`: A private variable managing the zoom level of the game view.
  /// - `_observers`: A list of observers (like Stage) that listen to scale changes.
  /// 
  /// Methods:
  /// - `scaleFactor`: Getter and setter for _scaleFactor, updates observers on change.
  /// - `addObserver(observer)`: Adds an observer to be notified of scale changes.
  /// - `removeObserver(observer)`: Removes an observer from the notification list.
  /// - `update(dt)`: Updates the game state every tick, part of the game loop.
  /// - `onLoad()`: Asynchronously loads game resources and initializes components.
  /// - `onKeyEvent(event, keysPressed)`: Handles keyboard events globally.
  /// 
  /// Constructor:
  /// Initializes game components, sets up the viewport, and loads the stage.
  /// It ensures the game scales properly and the camera follows the cursor.
  /// 
  /// Connects with:
  /// - Stage: Stage acts as the main interactive area of the game, containing all tiles,
  ///   units, and managing the cursor.
  /// - Tile, Unit: Managed by Stage, but their scaling and updates are propagated
  ///   by MyGame through observers.
  /// - MaxViewport: Manages how the game's view is scaled and presented.
  /// 
  /// Usage:
  /// This class should be instantiated to start the game. It sets up necessary
  /// game components and starts the game loop. User interactions are primarily
  /// managed here and delegated to other components like Stage and Unit.

  late MaxViewport viewport;
  late Stage stage;
  double _scaleFactor = 2;
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
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool handled = false;
    // First, handle any game-wide key events (like zooming)
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.equal) { // Zoom in
        scaleFactor *= 1.1;
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.minus) { // Zoom out
        scaleFactor *= 0.9;
        handled = true;
      } else {
        handled = stage.keyCommandHandler(event.logicalKey);
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
