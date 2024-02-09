
// ignore_for_file: unused_import

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';

import '../engine/engine.dart';
class Unit extends PositionComponent with HasGameRef<MyGame> implements CommandHandler {
  // Identifiers and Descriptive Information
  final String name;
  final String className;
  final String idleAnimationName;
  int movementRange;
  late double remainingMovement;
  UnitTeam team = UnitTeam.blue;

  // Status and State Variables
  Point<int> gridCoord; // The units's position in terms of tiles, not pixels
  bool canAct = true;
  bool isMoving = false;
  late Point<int> oldTile;

  // Collections and Complex Structures
  Queue<Point<int>> movementQueue = Queue<Point<int>>();
  Point<int>? currentTarget;
  double moveCost = 0;
  Map<Point<int>, List<Point<int>>> paths = {};

  // Components and External References
  final Completer<void> _loadCompleter = Completer<void>();
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet unitSheet;
  late final ActionMenu actionMenu;
  late final Map<String, dynamic> unitData;

  // Unit Attributes & Components
  List<MenuOption> actionsAvailable = [MenuOption.wait, MenuOption.attack];
  Item? main;
  Item? treasure;
  Item? gear;
  List<Item> items = [];
  Map<String, Attack> attackSet = {};
  List<Effect> effectSet = [];
  Set<Skill> skillSet = {};
  Set<WeaponType> proficiencies = {};
  Map<String, int> stats = {};
  int level;
  int hp = -1;
  int sta = -1;

  // Factory constructor
  factory Unit.fromJSON(Point<int> gridCoord, String name, {int? level}) {

    // Extract unit data from the static map in MyGame
    var unitsJson = MyGame.unitMap['units'] as List;
    Map<String, dynamic> unitData = unitsJson.firstWhere(
        (unit) => unit['name'].toString() == name,
        orElse: () => throw Exception('Unit $name not found in JSON data')
    );

    String className = unitData['class'];
    int givenLevel = level ?? unitData['level'] ?? 1;
    Class classData = Class.fromJson(className);

    int movementRange = unitData.keys.contains('movementRange') ? unitData['movementRange'] : classData.movementRange;
    unitData['skills'].addAll(classData.skills);
    unitData['attacks'].addAll(classData.attacks);
    unitData['proficiencies'].addAll(classData.proficiencies);

    // Add Unit Team
    final Map<String, UnitTeam> stringToUnitTeam = {
      for (var team in UnitTeam.values) team.toString().split('.').last: team,
    };
    UnitTeam team = stringToUnitTeam[unitData['team']] ?? UnitTeam.blue;

    // Add weapon proficiencies
    Set<WeaponType> proficiencies = {};
    final Map<String, WeaponType> stringToProficiency = {
      for (WeaponType weaponType in WeaponType.values) weaponType.toString().split('.').last: weaponType,
    };
    for (String weaponTypeString in unitData['proficiencies']){
      WeaponType? prof = stringToProficiency[weaponTypeString];
      if (prof != null){proficiencies.add(prof);}
    }
    
    String idleAnimationName = unitData['sprites']['idle'];

    // Create items for items
    List<Item> items = [];
    for(String itemName in unitData['items']){
      items.add(Item.fromJson(itemName));
    }

    Map<String, Attack> attackMap = {};
    for(String attackName in unitData['attacks']){
      attackMap[attackName] = Attack.fromJson(attackName);
    }

    Map<String, int> stats = Map<String, int>.from(classData.baseStats);
    Map<String, int> growths = Map<String, int>.from(classData.growths);
    for (String stat in classData.growths.keys){
      if (unitData['growths']?.keys.contains(stat)){
        growths[stat] = unitData['growths'][stat];
      }
    }
    var rng = Random();
    for (String stat in classData.baseStats.keys){
      if (unitData['baseStats'].keys.contains(stat)){
        stats[stat] = unitData['baseStats'][stat];
      } else {
        int levelUps = Iterable.generate(givenLevel - 1, (_) => rng.nextInt(100) < growths[stat]! ? 1 : 0)
                        .fold(0, (acc, curr) => acc + curr); // Autoleveler
        stats[stat] = classData.baseStats[stat]! + levelUps;

      }
      
    }
    
    // Return a new Unit instance
    return Unit._internal(unitData, gridCoord, name, className, givenLevel, movementRange, team, idleAnimationName, items, attackMap, proficiencies, stats);
  }

   // Private constructor for creating instances
  Unit._internal(this.unitData, this.gridCoord, this.name, this.className, this.level, this.movementRange, this.team, this.idleAnimationName, this.items, this.attackSet, this.proficiencies, this.stats){
    _postConstruction();
  }

  void _postConstruction() {
    for (Item item in items){
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
    hp = getStat('hp');
    sta = getStat('sta');
    remainingMovement = movementRange.toDouble();
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
      size: Vector2.all(16),
    );
    add(_animationComponent);

    // Set the initial size and position of the unit
    size = gameRef.stage.tiles.size;
    position = Vector2(gridCoord.x * size.x, gridCoord.y * size.y);
    gameRef.eventDispatcher.add(Announcer(this));
  
    // Create skills for skillset
    for(String skillName in unitData['skills']){
      Skill skill = Skill.fromJson(skillName, this);
      skill.attachToUnit(this, gameRef.eventDispatcher);
    }
    _loadCompleter.complete();
  }

  Future<void> get loadCompleted => _loadCompleter.future;
  
  @override
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    Stage stage = gameRef.stage;
    if (command == LogicalKeyboardKey.keyA) { // Confirm the move.
      if(!stage.tilesMap[stage.cursor.gridCoord]!.isOccupied || stage.tilesMap[stage.cursor.gridCoord]!.unit == this){
        gameRef.eventQueue.addEventBatch([
          UnitMoveEvent(gameRef, this, stage.cursor.gridCoord),
          ActionMenuEvent(gameRef, this)]);
      }
      
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB) { // Cancel the action.
      stage.activeComponent = stage.cursor;
      stage.blankAllTiles();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowLeft) {
      stage.cursor.handleCommand(command);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowRight) {
      stage.cursor.handleCommand(command);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowUp) {
      stage.cursor.handleCommand(command);
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      stage.cursor.handleCommand(command);
      handled = true;
    }
    return handled;
  }
  void addSkill(Skill skill, EventDispatcher dispatcher) {
    // Add the skill to the unit
    skillSet.add(skill);
    skill.attachToUnit(this, dispatcher);
  }

  void removeSkill(Skill skill, EventDispatcher dispatcher) {
    // Remove the skill from the unit
    skillSet.remove(skill);
    skill.detachFromUnit(dispatcher);
  }

  void die(){
    gameRef.eventDispatcher.dispatch(UnitUnitDeathEvent(this));
    Stage stage = parent as Stage;
    stage.tilesMap[gridCoord]!.removeUnit(); // Remove unit from the tile
    stage.remove(this); // Remove the unit from the stage's children.
    stage.units.remove(this); // Remove the unit from the stage's list of units.
    stage.playerMap[team]!.units.remove(this); // Remove the unit from the player map.
    stage.tilesMap[gridCoord]!.removeUnit();
    removeFromParent();
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
        // dev.log("$name equipped ${item.name} as ${item.type}");
        break;
      case ItemType.gear:
        gear = item;
        // dev.log("$name equipped ${item.name} as ${item.type}");
        break;
      case ItemType.treasure:
        treasure = item;
        // dev.log("$name equipped ${item.name} as ${item.type}");
        break;
      default:
        // dev.log("$name can't equip ${item.name}");
        break;
    }
  }

  void unequip(ItemType? type){
    switch (type) {
      case ItemType.main:
        // dev.log("$name unequipped ${main?.name} as $type");
        if(main?.weapon?.specialAttack != null) {
          attackSet.remove(main!.weapon!.specialAttack!.name);
        }
        main = null;
        break;
      case ItemType.gear:
        // dev.log("$name unequipped ${gear?.name} as $type");
        gear = null;
        break;
      case ItemType.treasure:
        // dev.log("$name unequipped ${treasure?.name} as $type");
        treasure = null;
        break;
      default:
        break;
    }
  }

  int getStat(String stat){
    return stats[stat]!;
  }

  ({int accuracy, int critRate, int damage, int fatigue}) attackCalc(Attack attack, target){
    assert(stats['str'] != null && stats['dex'] != null && stats["wil"] != null && stats['wis'] != null);
    Vector4 combatStats = Vector4(stats['str']!.toDouble(), stats['dex']!.toDouble(), stats["wil"]!.toDouble(), stats['wis']!.toDouble());
    int might = (attack.might + (attack.scaling.dot(combatStats))).toInt();
    int hit = attack.hit + stats['lck']!;
    int crit = attack.crit + stats['lck']!;
    int fatigue = attack.fatigue;
    if(main?.weapon != null) {
      if(attack.magic) {
        hit += getStat('wis')*2;
        crit += getStat('wis')~/2;
      } else {
        hit += getStat('dex')*2;
        crit += getStat('dex')~/2;
      }
      might += main!.weapon!.might;
      hit += main!.weapon!.hit;
      crit += main!.weapon!.crit;
      fatigue += main!.weapon!.fatigue;
      }
    int damage = (might - ((attack.magic ? 1 : 0)*target.getStat('fai') + (1-(attack.magic ? 1 : 0))*target.getStat('def'))).toInt().clamp(0, 100);
    int accuracy = (hit - target.getStat('lck') - ((attack.magic ? 1 : 0)*target.getStat('wis') + (1-(attack.magic ? 1 : 0))*target.getStat('dex'))).toInt().clamp(1, 99);
    int critRate = (crit - target.getStat('lck')).toInt().clamp(1, 99);
    
    return (damage: damage, accuracy: accuracy, critRate: critRate, fatigue: fatigue);

  }
  void openActionMenu(){
    gameRef.eventQueue.addEventBatch([ActionMenuEvent(gameRef, this)]);
    // gameRef.stage.activeComponent = gameRef.stage.cursor.actionMenu;
  }

  void wait(){
    toggleCanAct(false);
    actionsAvailable = [MenuOption.wait];
    gameRef.stage.activeComponent = gameRef.stage.cursor;
    gameRef.stage.blankAllTiles();
    gameRef.stage.updateTileWithUnit(oldTile, gridCoord, this);
    oldTile = gridCoord;
  }

  Vector2 get worldPosition {
        return Vector2(gridCoord.x * size.x, gridCoord.y * size.y);
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
    x = point.x * size.x;
    y = point.x * size.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // I may not need these three lines. 
    size = gameRef.stage.tilesize*gameRef.stage.scaling;
    scale = Vector2.all(gameRef.stage.scaling);
    if(hp <= 0) die();
    if (isMoving && currentTarget != null) {
      // Calculate the pixel position for the target tile position
      final targetX = currentTarget!.x * size.x;
      final targetY = currentTarget!.y * size.y;

      // Move towards the target position
      var moveX = (targetX - x) * 16 * dt;
      var moveY = (targetY - y) * 16 * dt;

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
    final expectedX = gridCoord.x * size.x;
    final expectedY = gridCoord.y * size.y;
    if (x != expectedX || y != expectedY) {
      position = Vector2(expectedX, expectedY); // Snap sprite to the new tile position
    }
  }
  }
  
  void onScaleChanged(double scaleFactor) {}

  
  void move(Stage stage, Point<int> destination){
    oldTile = gridCoord; // Store the position of the unit in case the command gets cancelled
    if(!paths.keys.contains(destination)){
      paths[destination] = getPath(destination);
    }
    for(Point<int> point in paths[destination]!){
      enqueueMovement(point);
      moveCost += stage.tilesMap[point]!.getTerrainCost();
    }
    stage.updateTileWithUnit(gridCoord, destination, this);
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

  void enqueueMovement(Point<int> targetPoint) {
    movementQueue.add(targetPoint);
    if (!isMoving) {
      isMoving = true;
      currentTarget = movementQueue.removeFirst();
    }
  }
  List<Point<int>> getPath(Point<int> destination) {
    var visitedTiles = <Point<int>, _TileMovement>{}; // Tracks visited tiles and their data
    var queue = Queue<_TileMovement>(); // Queue for BFS

    // Starting point - no parent at the beginning
    queue.add(_TileMovement(gridCoord, 100.0, null));
    while (queue.isNotEmpty) {
      var tileMovement = queue.removeFirst();
      Point<int> currentPoint = tileMovement.point;
      double remainingMovement = tileMovement.remainingMovement;

      // Skip if a better path to this tile has already been found
      if (visitedTiles.containsKey(currentPoint) && visitedTiles[currentPoint]!.remainingMovement >= remainingMovement) continue;
      
      // Record the tile with its movement data
      visitedTiles[Point(currentPoint.x, currentPoint.y)] = tileMovement;
      if(currentPoint == destination) {
        return _constructPath(destination, visitedTiles);
      }
      Tile? tile = gameRef.stage.tilesMap[currentPoint]; // Accessing tiles through stage
      if (tile!.isOccupied && tile.unit?.team != team) continue; // Skip enemy-occupied tiles
      for (Direction direction in Direction.values) {
        Point <int> nextPoint = _getNextPoint(currentPoint, direction);
        Tile? nextTile = gameRef.stage.tilesMap[Point(nextPoint.x, nextPoint.y)];
        if (nextTile != null && !(nextTile.isOccupied  && nextTile.unit?.team != team)) {
          double cost = gameRef.stage.tilesMap[nextTile.gridCoord]!.getTerrainCost();
          double nextRemainingMovement = remainingMovement - cost;
            queue.add(_TileMovement(nextPoint, nextRemainingMovement, currentPoint));
        }
      }
    }
    return [];
  }

  List<Tile> findReachableTiles() {
    List<Tile>reachableTiles = [];
    var visitedTiles = <Point<int>, _TileMovement>{}; // Tracks visited tiles and their data
    var queue = Queue<_TileMovement>(); // Queue for BFS

    // Starting point - no parent at the beginning
    queue.add(_TileMovement(gridCoord, remainingMovement.toDouble(), null));
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
      for (Direction direction in Direction.values) {
        Point <int> nextPoint = _getNextPoint(currentPoint, direction);
        Tile? nextTile = gameRef.stage.tilesMap[Point(nextPoint.x, nextPoint.y)];
        if (nextTile != null && !(nextTile.isOccupied  && nextTile.unit?.team != team)) {
          double cost = gameRef.stage.tilesMap[nextTile.gridCoord]!.getTerrainCost();
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
  
  void getActionOptions() {
    (int, int) range = getCombatRange();
    List<Tile> attackTiles = markAttackableEnemies(gameRef.stage.cursor.gridCoord, range.$1, range.$2);
    if(attackTiles.isEmpty){
      if(actionsAvailable.contains(MenuOption.attack)){
        actionsAvailable.remove(MenuOption.attack);}
    }
    if (items.isNotEmpty) if(!actionsAvailable.contains(MenuOption.item)){actionsAvailable.add(MenuOption.item);}
    dev.log("Action options for $name are: $actionsAvailable");
  }
  
  Point<int> _getNextPoint(Point<int> currentPoint, Direction direction) {
    switch (direction) {
      case Direction.left:
        return Point(currentPoint.x - 1, currentPoint.y);
      case Direction.right:
        return Point(currentPoint.x + 1, currentPoint.y);
      case Direction.up:
        return Point(currentPoint.x, currentPoint.y - 1);
      case Direction.down:
        return Point(currentPoint.x, currentPoint.y + 1);
    }
  }
}

class _TileMovement {
  Point<int> point;
  double remainingMovement;
  Point<int>? parent; // The tile from which this one was reached

  _TileMovement(this.point, this.remainingMovement, this.parent);
}