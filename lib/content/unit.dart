import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:moira/content/content.dart';
import 'package:flutter/material.dart';

class Unit extends PositionComponent with HasGameReference<MoiraGame>, UnitMovement{
  final Completer<void> _loadCompleter = Completer<void>();
  final String name;
  final String className;
  int movementRange;
  String faction;
  Point<int> tilePosition;
  Queue<Movement> movementQueue = Queue<Movement>();
  final Map<String, SpriteAnimationComponent> animationMap = {};
  late SpriteAnimationComponent sprite;
  late final SpriteSheet unitSheet;
  late final Map<String, dynamic> unitData;
  bool isMoving = false;
  bool _canAct = true;
  bool get canAct => _canAct;
  final double speed = 1; // Speed of cursor movement in pixels per second

  // Unit Attributes & Components
  Item? main;
  Item? treasure;
  Item? gear;
  List<Item> inventory = [];
  Map<String, Attack> attackSet = {};
  List<Effect> effectSet = [];
  Set<Skill> skillSet = {};
  Set<WeaponType> proficiencies = {};
  Map<String, int> stats = {};
  int level;
  int hp = -1;
  int sta = -1;
        
  factory Unit.fromJSON(Point<int> tilePosition, String name, String factionName, {int? level, List<String>? itemStrings}) {

    // Extract unit data from the static map in MoiraGame
    var unitsJson = MoiraGame.unitMap['units'] as List;
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

    String faction = factionName;
    // Add weapon proficiencies
    Set<WeaponType> proficiencies = {};
    final Map<String, WeaponType> stringToProficiency = {
      for (WeaponType weaponType in WeaponType.values) weaponType.toString().split('.').last: weaponType,
    };
    for (String weaponTypeString in unitData['proficiencies']){
      WeaponType? prof = stringToProficiency[weaponTypeString];
      if (prof != null){proficiencies.add(prof);}
    }
    
    // Create items for items
    List<Item> inventory = [];
    itemStrings = itemStrings ?? [];

    for(String itemName in itemStrings.isEmpty ? unitData['items'] : itemStrings){
      inventory.add(Item.fromJson(itemName));
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
    return Unit._internal(unitData, tilePosition, name, className, givenLevel, movementRange, faction, inventory, attackMap, proficiencies, stats);
  }

   // Private constructor for creating instances
  Unit._internal(this.unitData, this.tilePosition, this.name, this.className, this.level, this.movementRange, this.faction, this.inventory, this.attackSet, this.proficiencies, this.stats){
    _postConstruction();
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
    hp = getStat('hp');
    sta = getStat('sta');
  }
  
  Point<int> getTilePositionFromPosition(){
    return Point(position.x~/game.stage.tileSize, position.y~/game.stage.tileSize);
  }

  void snapToTile(Tile tile){
    position = tile.center;
    tilePosition = tile.point;
    tile.setUnit(this);
  }
  void wait(){
    unit.toggleCanAct(false);
    game.stage.blankAllTiles();
  }
  @override
  void update(double dt) {
    super.update(dt);
    // tilePosition = getTilePositionFromPosition();
    if (movementQueue.isNotEmpty) {
      isMoving = true;
      Movement currentMovement = movementQueue.first;
      SpriteAnimation newAnimation = animationMap[currentMovement.directionString]!.animation!;
      sprite.animation = newAnimation;
      Point<int> movement = getMovement(currentMovement);
      Point<int> targetTilePosition = tilePosition + movement;
      double distance = position.distanceTo(game.stage.tileMap[targetTilePosition]!.center);
      double moveStep = speed*game.stage.tileSize/16;//game.stage.tileSize / dt;
      if (distance < moveStep) { // Using a small threshold like 1.0 to ensure we reach the target
        tilePosition = targetTilePosition;
        position = game.stage.tileMap[targetTilePosition]!.center;
        if(!game.stage.tileMap[targetTilePosition]!.isOccupied) game.stage.tileMap[targetTilePosition]!.setUnit(this);
        isMoving = false;
        movementQueue.removeFirst(); // Dequeue the completed movement

        if (movementQueue.isNotEmpty) {
          Movement currentMovement = movementQueue.first;
          SpriteAnimation newAnimation = animationMap[currentMovement.directionString]!.animation!;
          sprite.animation = newAnimation;
        } else {//The movement is over.
          SpriteAnimation newAnimation = animationMap["idle"]!.animation!;
          sprite.animation = newAnimation;
        }
      } else {
        position.moveToTarget(game.stage.tileMap[targetTilePosition]!.center, moveStep);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    debugPrint("Load $name");
    // Load the unit image and create the animation component
    ui.Image unitImage = await game.images.load('${name.toLowerCase()}_spritesheet.png');
    unitSheet = SpriteSheet.fromColumnsAndRows(
      image: unitImage,
      columns: 4,
      rows: 5,
    );
    Vector2 spriteSize = Vector2(game.stage.tileSize*1.25, game.stage.tileSize);
    animationMap['down'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 0, stepTime: .25),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['up'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 1, stepTime: .25),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['right'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 2, stepTime: .25),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['left'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 3, stepTime: .25),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['idle'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 4, stepTime: .5),
                            size: spriteSize,
                            anchor: Anchor.center);
    sprite = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 4, stepTime: .5),
                            size: spriteSize,
                            anchor: Anchor.center);
    add(sprite);
    position = game.stage.tileMap[tilePosition]!.center;
    anchor = Anchor.center;
  
    // Create skills for skillset
    for(String skillName in unitData['skills']){
      Skill skill = Skill.fromJson(skillName, this);
      // skill.attachToUnit(this, game.eventDispatcher);
    }
    // Add to faction:
    if(game.stage.factionMap.keys.contains(faction)){
      game.stage.factionMap[faction]!.units.add(this);
    }
    else{ 
      debugPrint("Unit created for faction $faction not in factionMap.");
      debugPrint("factionMap has keys ${game.stage.factionMap.keys}.");
    }
    game.stage.tileMap[tilePosition]?.setUnit(this);
    _loadCompleter.complete();
  }

  Future<void> get loadCompleted => _loadCompleter.future;

  bool equipCheck(Item item, ItemType slot) {
    /// This will be made fancier later, once the Equip component
    /// is implemented. For now it just checks if the item is the right type. 
    if(item.type == slot) return true;
    return false;
  }
  
  void equip(Item item){
    if(item.equipCond != null && !item.equipCond!.check(this)) return;
    unequip(item.type);
      switch (item.type) {
        case ItemType.main:
          main = item;
          if(main?.weapon?.specialAttack != null) {
            attackSet[main!.weapon!.specialAttack!.name] = main!.weapon!.specialAttack!;
          }
          debugPrint("$name equipped ${item.name} as ${item.type}");
          break;
        case ItemType.gear:
          gear = item;
          debugPrint("$name equipped ${item.name} as ${item.type}");
          break;
        case ItemType.treasure:
          treasure = item;
          debugPrint("$name equipped ${item.name} as ${item.type}");
          break;
        default:
          debugPrint("$name can't equip ${item.name}");
          break;
      }
    
  }

  void unequip(ItemType? type){
    switch (type) {
      case ItemType.main:
        // debugPrint("$name unequipped ${main?.name} as $type");
        if(main?.weapon?.specialAttack != null) {
          attackSet.remove(main!.weapon!.specialAttack!.name);
        }
        main = null;
        break;
      case ItemType.gear:
        // debugPrint("$name unequipped ${gear?.name} as $type");
        gear = null;
        break;
      case ItemType.treasure:
        // debugPrint("$name unequipped ${treasure?.name} as $type");
        treasure = null;
        break;
      default:
        break;
    }
  }

  int getStat(String stat){
    return stats[stat]!;
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

  List<String> getActions(){
    List<String> actions = [];
    actions.add("Attack");
    actions.add("Item");
    actions.add("Wait");
    return actions;
  }
  void toggleCanAct(bool state) {
    _canAct = state;
    // Define the grayscale paint
    final grayscalePaint = Paint()
      ..colorFilter = const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]);

    // Apply or remove the grayscale effect based on canAct
    sprite.paint = canAct ? Paint() : grayscalePaint;
  }

  List<Unit> getTargets() {
    List<Unit> targets = [];
    (int, int) combatRange = getCombatRange();
    for (int range = combatRange.$1; range <= combatRange.$2; range++) {
      for (int dx = 0; dx <= range; dx++) {
        int dy = range - dx;
        List<Point<int>> pointsToCheck = [
          Point(tilePosition.x + dx, tilePosition.y + dy),
          Point(tilePosition.x - dx, tilePosition.y + dy),
          Point(tilePosition.x + dx, tilePosition.y - dy),
          Point(tilePosition.x - dx, tilePosition.y - dy)
        ];

        for (var point in pointsToCheck) {
          if (point.x >= 0 && point.x < game.stage.mapTileWidth && point.y >= 0 && point.y < game.stage.mapTileHeight) {
            Tile? tile = game.stage.tileMap[point];
            if (tile != null && tile.isOccupied && game.stage.factionMap[unit.faction]!.checkHostility(tile.unit!)) {
              targets.add(tile.unit!);
              tile.state = TileState.attack;
              debugPrint("${tile.unit!.name} is a target at ${tile.point}");
            }
          }
        }
      }
    }
    return targets;
  }
}
