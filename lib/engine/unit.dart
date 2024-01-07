
// ignore_for_file: unused_import

import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;


import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';

import 'engine.dart';
class Unit extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  // Identifiers and Descriptive Information
  final String name;
  final String idleAnimationName;
  int movementRange;
  UnitTeam team = UnitTeam.blue;
  double tileSize;

  // Status and State Variables
  Point<int> gridCoord; // The units's position in terms of tiles, not pixels
  bool canAct = true;
  bool isMoving = false;
  Point<int> oldTile;

  // Collections and Complex Structures
  Queue<Point<int>> movementQueue = Queue<Point<int>>();
  Point<int>? currentTarget;
  Map<Point<int>, List<Point<int>>> paths = {};

  // Components and External References
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet unitSheet;
  late final ActionMenu actionMenu;

  // Unit Attributes & Components
  Item? main;
  Item? treasure;
  Item? gear;
  List<Item> inventory = [];
  Map<String, Attack> attackSet = {};
  List<Effect> effects = [];
  List<Skill> skills = [];
  Map<String, int> stats = {};
  int hp = -1;
  int sta = -1;

  // Private constructor for creating instances
  Unit._internal(this.gridCoord, this.name, this.oldTile, this.tileSize, this.movementRange, this.team, this.idleAnimationName, this.inventory, this.attackSet, this.stats){
    _postConstruction();
  }

  // Factory constructor
  factory Unit.fromJSON(Point<int> gridCoord, String name) {
    // Use gridCoord and scaleFactor to set oldTile and tileSize
    Point<int> oldTile = gridCoord;
    double tileSize = 16 * MyGame().scaleFactor; // This assumes scaleFactor is available from an instance of MyGame. If not, adjust accordingly.

    // Extract unit data from the static map in MyGame
    var unitsJson = MyGame.unitMap['units'] as List;
    Map<String, dynamic> unitData = unitsJson.firstWhere(
        (unit) => unit['name'].toString().toLowerCase() == name.toLowerCase(),
        orElse: () => throw Exception('Unit $name not found in JSON data')
    );

    // Extract other properties from unitData
    int movementRange = unitData['movementRange'];
    final Map<String, UnitTeam> stringToUnitTeam = {
      for (var team in UnitTeam.values) team.toString().split('.').last: team,
    };
    UnitTeam team = stringToUnitTeam[unitData['team']] ?? UnitTeam.blue;
    String idleAnimationName = unitData['sprites']['idle'];

    // Create items for inventory
    List<Item> inventory = [];
    for(String itemName in unitData['inventory']){
      inventory.add(Item.fromJson(itemName));
    }

    Map<String, Attack> attackMap = {};
    for(String attackName in unitData['attacks']){
      attackMap[attackName] = Attack.fromJson(attackName);
    }

    Map<String, int> stats = {};
    for (String stat in unitData['stats'].keys){
      stats[stat] = unitData['stats'][stat];
    }
    // Return a new Unit instance
    return Unit._internal(gridCoord, name, oldTile, tileSize, movementRange, team, idleAnimationName, inventory, attackMap, stats);
  }

  void die(){
    Stage stage = parent as Stage;
    stage.tilesMap[gridCoord]!.removeUnit();
    removeFromParent();
  }
  void _postConstruction() {
    for (Item item in inventory){
      switch (item.type) {
        case ItemType.main:
          if (main == null) equip(item);
          break;
        case ItemType.gear:
          if (gear == null) equip(item);
          break;
        case ItemType.treasure:
        if (treasure == null) equip(item);
          treasure ??= item;
          break;
        default:
          break;
      }
    }
    hp = stats['hp']!;
    sta = stats['sta']!;
  }

  @override
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    Stage stage = parent as Stage;
    if (command == LogicalKeyboardKey.keyA) { // Confirm the move.
      if(!stage.tilesMap[stage.cursor.gridCoord]!.isOccupied){
        move(stage);
        openActionMenu(stage);
      }
      
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) { // Cancel the action.
      stage.activeComponent = stage.cursor;
      stage.blankAllTiles();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowLeft) {
      stage.cursor.move(Direction.left);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) {
      stage.cursor.move(Direction.right);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) {
      stage.cursor.move(Direction.up);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      stage.cursor.move(Direction.down);
      handled = true;
    }
    return handled;
  }

  bool equipCheck(Item item, ItemType slot) {
    /// This will be made fancier later, once the Equip component
    /// is implemented. For now it just checks if the item is the right type. 
    if(item.type == slot) return true;
    return false;
  }
  void equip(Item item){
    unequip(item.type);
    switch (item.type) {
      case ItemType.main:
        
        main = item;
        if(main?.weapon?.specialAttack != null) {
          attackSet[main!.weapon!.specialAttack!.name] = main!.weapon!.specialAttack!;
        }
        dev.log("$name equipped ${item.name} as ${item.type}");
        break;
      case ItemType.gear:
        gear = item;
        dev.log("$name equipped ${item.name} as ${item.type}");
        break;
      case ItemType.treasure:
        treasure = item;
        dev.log("$name equipped ${item.name} as ${item.type}");
        break;
      default:
        dev.log("$name can't equip ${item.name}");
        break;
    }
  }

  void unequip(ItemType? type){
    switch (type) {
      case ItemType.main:
        dev.log("$name unequipped ${main?.name} as $type");
        if(main?.weapon?.specialAttack != null) {
          attackSet.remove(main!.weapon!.specialAttack!.name);
        }
        main = null;
        break;
      case ItemType.gear:
        dev.log("$name unequipped ${gear?.name} as $type");
        gear = null;
        break;
      case ItemType.treasure:
        dev.log("$name unequipped ${treasure?.name} as $type");
        treasure = null;
        break;
      default:
        break;
    }
  }

  void move(Stage stage){
    oldTile = gridCoord; // Store the position of the unit in case the command gets cancelled
    for(Point<int> point in paths[stage.cursor.gridCoord]!){
      enqueueMovement(point);
    }
    Point<int> newTile = paths[stage.cursor.gridCoord]!.last;
    stage.updateTileWithUnit(gridCoord, newTile, this);
    stage.blankAllTiles();
  }

  void undoMove(){
    Stage stage = parent as Stage;
    snapToTile(oldTile);
    stage.updateTileWithUnit(gridCoord, oldTile, this);
    gridCoord = oldTile;
    stage.activeComponent = stage.cursor;
    stage.blankAllTiles();
  }

  ({int accuracy, int critRate, int damage, int fatigue}) attackCalc(Attack attack, target){
    ///In combat, the relevant stats for *damage* calculations are are:
    /// the attacker’s might, hit, attack.magic, and (attack) type against the defender’s stats.
    /// damage = weapon.might + attack.might + sum((unit.atk, unit.dex, unit.int, unit.wis)*attack.type.values) - (attack.magic*targ.res + (1-attack.magic)*targ.def)
    /// accuracy is weapon.hit + attack.hit + unit.hit - (attack.magic*targ.magAvo + (1-attack.magic)*targ.phyAvo)
    assert(stats['str'] != null && stats['dex'] != null && stats["mag"] != null && stats['wis'] != null);
    Vector4 combatStats = Vector4(stats['str']!.toDouble(), stats['dex']!.toDouble(), stats["mag"]!.toDouble(), stats['wis']!.toDouble());
    int might = (attack.might + (attack.scaling.dot(combatStats))).toInt();
    int hit = attack.hit + stats['lck']!;
    int crit = attack.crit + stats['lck']!;
    int fatigue = attack.fatigue;
    if(main?.weapon != null) {
      if(attack.magic) {
        hit += stats['wis']!*2;
        crit += stats['wis']!~/2;
      } else {
        hit += stats['dex']!*2;
        crit += stats['dex']!~/2;
      }
      might += main!.weapon!.might;
      hit += main!.weapon!.hit;
      crit += main!.weapon!.crit;
      fatigue += main!.weapon!.fatigue;
      }
    int damage = (might - ((attack.magic ? 1 : 0)*target.stats['res'] + (1-(attack.magic ? 1 : 0))*target.stats['def'])).toInt().clamp(0, 100);
    int accuracy = (hit - target.stats['lck'] - ((attack.magic ? 1 : 0)*target.stats['wis'] + (1-(attack.magic ? 1 : 0))*target.stats['dex'])).toInt().clamp(1, 99);
    int critRate = (crit - target.stats['lck']).toInt().clamp(1, 99);
    
    return (damage: damage, accuracy: accuracy, critRate: critRate, fatigue: fatigue);

  }
  void openActionMenu(Stage stage){
    (int, int) range = getCombatRange();
    List<Tile> attackTiles = markAttackableEnemies(stage.cursor.gridCoord, range.$1, range.$2);
    List<MenuOption> visibleOptions = [MenuOption.wait];
    if(attackTiles.isNotEmpty){
      visibleOptions.add(MenuOption.attack);
    }
    if (inventory.isNotEmpty) visibleOptions.add(MenuOption.item);
    stage.cursor.actionMenu.show(visibleOptions);
    stage.activeComponent = stage.cursor.actionMenu;
  }

  void wait(){
    Stage stage = parent as Stage;
    toggleCanAct(false);
    stage.activeComponent = stage.cursor;
    stage.blankAllTiles();
    stage.updateTileWithUnit(oldTile, gridCoord, this);
    oldTile = gridCoord;
  }

  @override
  Future<void> onLoad() async {
    // Load the unit image and create the animation component
    ui.Image unitImage = await gameRef.images.load(idleAnimationName);
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
    position = Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
  }

  Vector2 get worldPosition {
        return Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
    }

  void toggleCanAct(bool state) {
    canAct = state;
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

  void enqueueMovement(Point<int> targetPoint) {
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

  void snapToTile(Point<int> point){
    x = point.x * tileSize;
    y = point.x * tileSize;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if(hp <= 0) die;

    if (isMoving && currentTarget != null) {
      // Calculate the pixel position for the target tile position
      final targetX = currentTarget!.x * tileSize;
      final targetY = currentTarget!.y * tileSize;

      // Move towards the target position
      var moveX = (targetX - x)*.6;
      var moveY = (targetY - y)*.6;

      x += moveX;
      y += moveY;

      // Check if the unit is close enough to the target position to snap it
      if ((x - targetX).abs() < 1 && (y - targetY).abs() < 1) {
        x = targetX; // Snap to exact position
        y = targetY;
        gridCoord = currentTarget!; // Update the gridCoord to the new tile
        

        // Move to the next target if any
        if (movementQueue.isNotEmpty) {
          currentTarget = movementQueue.removeFirst();
        } else {
          currentTarget = null;
          isMoving = false;
        }
      }
    } else {
    // Check if the gridCoord has changed without the animation
    // and update the sprite's position accordingly
    final expectedX = gridCoord.x * tileSize;
    final expectedY = gridCoord.y * tileSize;
    if (x != expectedX || y != expectedY) {
      position = Vector2(expectedX, expectedY); // Snap sprite to the new tile position
    }
  }
  }
  
  void onScaleChanged(double scaleFactor) {
    tileSize = 16 * scaleFactor; // Update tileSize
    size = Vector2.all(tileSize); // Update the size of the unit itself
    _animationComponent.size = Vector2.all(tileSize); // Update animation component size

    // Update position based on new tileSize
    position = Vector2(gridCoord.x * tileSize, gridCoord.y * tileSize);
  }

  List<Tile> findReachableTiles() {
    List<Tile>reachableTiles = [];
    var visitedTiles = <Point<int>, _TileMovement>{}; // Tracks visited tiles and their data
    var queue = Queue<_TileMovement>(); // Queue for BFS

    // Starting point - no parent at the beginning
    queue.add(_TileMovement(gridCoord, movementRange.toDouble(), null));
    while (queue.isNotEmpty) {
      var tileMovement = queue.removeFirst();
      Point<int> currentPoint = tileMovement.point;
      double remainingMovement = tileMovement.remainingMovement;

      // Skip if a better path to this tile has already been found
      if (visitedTiles.containsKey(currentPoint) && visitedTiles[currentPoint]!.remainingMovement >= remainingMovement) continue;
      
      // Record the tile with its movement data
      visitedTiles[Point(currentPoint.x, currentPoint.y)] = tileMovement;
      Tile? tile = gameRef.stage.tilesMap[currentPoint]; // Accessing tiles through stage
      if (tile!.isOccupied && tile.unit?.team != team) continue; // Skip enemy-occupied tiles
      for (var direction in Direction.values) {
        Point<int> nextPoint;
        switch (direction) {
          case Direction.left:
            nextPoint = Point(currentPoint.x - 1, currentPoint.y);
            break;
          case Direction.right:
            nextPoint = Point(currentPoint.x + 1, currentPoint.y);
            break;
          case Direction.up:
            nextPoint = Point(currentPoint.x, currentPoint.y - 1);
            break;
          case Direction.down:
            nextPoint = Point(currentPoint.x, currentPoint.y + 1);
            break;
        }
        Tile? nextTile = gameRef.stage.tilesMap[Point(nextPoint.x, nextPoint.y)];
        if (nextTile != null && !(nextTile.isOccupied  && nextTile.unit?.team != team)) {
          double cost = gameRef.stage.tilesMap[nextTile.gridCoord]!.terrain.cost;
          double nextRemainingMovement = remainingMovement - cost;
          if (nextRemainingMovement > 0) {
            queue.add(_TileMovement(nextPoint, nextRemainingMovement, currentPoint));
          }
        }
      }

    }

    // Construct paths for each tile
    for (Point<int> tilePoint in visitedTiles.keys) {
      paths[tilePoint] = _constructPath(tilePoint, visitedTiles);
      if(team == UnitTeam.blue){
        gameRef.stage.tilesMap[tilePoint]!.state = TileState.move;
        reachableTiles.add(gameRef.stage.tilesMap[tilePoint]!);
      }
    }
    return reachableTiles;
  }

  // Helper method to construct a path from a tile back to the unit
  List<Point<int>> _constructPath(Point<int> targetPoint, Map<Point<int>, _TileMovement> visitedTiles) {
    List<Point<int>> path = [];
    Point<int>? current = targetPoint;
    while (current != null) {
      path.insert(0, current); // Insert at the beginning to reverse the path
      current = visitedTiles[current]!.parent; // Move to the parent
    }
    return path; // The path from the start to the target
  }
  
  (int, int) getCombatRange() {
    int minCombatRange = 0;
    int maxCombatRange = 0;
    for(String attackName in attackSet.keys){
      minCombatRange = min(minCombatRange, attackSet[attackName]!.range.$1);
      maxCombatRange = max(maxCombatRange, attackSet[attackName]!.range.$2);
    }
    return (minCombatRange, maxCombatRange);
  } 
  void markAttackableTiles(List<Tile> reachableTiles) {
    // Mark tiles attackable from the unit's current position
    (int, int) range = getCombatRange();
    markTilesInRange(gridCoord, range.$1, range.$2, TileState.attack);
    // Mark tiles attackable from each reachable tile
    for (var tile in reachableTiles) {
      markTilesInRange(tile.gridCoord, range.$1, range.$2,  TileState.attack);
    }
  }

  List<Tile> markAttackableEnemies(Point<int> centerTile, int minRange, int maxRange){
    List<Tile> tilesInRange = markTilesInRange(centerTile, minRange, maxRange, TileState.attack);
    List<Tile> attackTiles = [];
    for (Tile tile in tilesInRange){
      if (tile.unit?.team != UnitTeam.red){
        tile.state = TileState.blank;
      } else {
        attackTiles.add(tile);
      }
    }
    return attackTiles;
  }

  List<Tile> markTilesInRange(Point<int> centerTile, int minRange, int maxRange, TileState newState) {
    List<Tile> tilesInRange = [];
    for (int x = centerTile.x - maxRange.toInt(); x <= centerTile.x + maxRange.toInt(); x++) {
      for (int y = centerTile.y - maxRange.toInt(); y <= centerTile.y + maxRange.toInt(); y++) {
        var tilePoint = Point<int>(x, y);
        var distance = centerTile.distanceTo(tilePoint);
        if (distance >= minRange && distance <= maxRange) {
          // Check if the tile is within the game bounds
          if (x >= 0 && x < gameRef.stage.mapTileWidth && y >= 0 && y < gameRef.stage.mapTileHeight) {
            var tile = gameRef.stage.tilesMap[tilePoint];
            // Mark the tile as attackable if it's not a movement tile
            if (tile != null && tile.state != TileState.move) {
              tile.state = newState;
              tilesInRange.add(tile);
            }
          }
        }
      }
    }
    return tilesInRange;
  }

  Direction? getDirection(Point<int>? point, Point<int>? targetPoint){
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
  Point<int> point;
  double remainingMovement;
  Point<int>? parent; // The tile from which this one was reached

  _TileMovement(this.point, this.remainingMovement, this.parent);
}