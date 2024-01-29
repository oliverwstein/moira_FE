import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:moira/content/content.dart';
import 'package:flutter/material.dart';

class Unit extends PositionComponent with HasGameReference<MoiraGame>, UnitMovement, UnitBehavior{
  final Completer<void> _loadCompleter = Completer<void>();
  final String name;
  final String className;
  int movementRange;
  double remainingMovement = - 1;
  String faction;
  Point<int> tilePosition;
  Queue<Movement> movementQueue = Queue<Movement>();
  final Map<String, SpriteAnimationComponent> animationMap = {};
  late SpriteAnimationComponent sprite;
  late final SpriteSheet unitSheet;
  late final Map<String, dynamic> unitData;
  bool isMoving = false;
  bool _canAct = true;
  bool dead = false;
  bool get canAct => _canAct;
  final double speed = 2; // Speed of cursor movement in pixels per second

  // Unit Attributes & Components
  Attack? attack;
  Item? main;
  Item? treasure;
  Item? gear;
  List<Item> inventory = [];
  Map<String, Attack> attackSet = {};
  List<Effect> effectSet = [];
  Set<Skill> skillSet;
  bool hasSkill(Skill skill) => skillSet.contains(skill);
  Set<WeaponType> proficiencies;
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
    Set<WeaponType> proficiencies = getWeaponTypesFromNames(unitData["proficiencies"].cast<String>());
    Set<Skill> skillSet = getSkillsFromNames(unitData["skills"].cast<String>());

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
    return Unit._internal(unitData, tilePosition, name, className, givenLevel, movementRange, faction, inventory, attackMap, proficiencies, skillSet, stats);
  }

   // Private constructor for creating instances
  Unit._internal(this.unitData, this.tilePosition, this.name, this.className, this.level, this.movementRange, this.faction, this.inventory, this.attackSet, this.proficiencies, this.skillSet, this.stats){
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
    remainingMovement = movementRange.toDouble();
  }
  
  Point<int> getTilePositionFromPosition(){
    return Point(position.x~/Stage.tileSize, position.y~/Stage.tileSize);
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
      double moveStep = speed*Stage.tileSize/16;
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
    } game.stage.tileMap[tilePosition]!.setUnit(this);
  }

  @override
  Future<void> onLoad() async {
    // Load the unit image and create the animation component
    ui.Image unitImage = await game.images.load('${name.toLowerCase()}_spritesheet.png');
    unitSheet = SpriteSheet.fromColumnsAndRows(
      image: unitImage,
      columns: 4,
      rows: 5,
    );
    Vector2 spriteSize = Vector2(unitImage.width/4, unitImage.height/5);
    double stepTime = .15;
    animationMap['down'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 0, stepTime: stepTime),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['up'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 1, stepTime: stepTime),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['right'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 2, stepTime: stepTime),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['left'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 3, stepTime: stepTime),
                            size: spriteSize,
                            anchor: Anchor.center);
    animationMap['idle'] = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 4, stepTime: stepTime*2),
                            size: spriteSize,
                            anchor: Anchor.center);
    sprite = SpriteAnimationComponent(
                            animation: unitSheet.createAnimation(row: 4, stepTime: stepTime*2),
                            size: spriteSize,
                            anchor: Anchor.center);
    add(sprite);
    position = game.stage.tileMap[tilePosition]!.center;
    anchor = Anchor.center;
  
    // Add to faction:
    if(game.stage.factionMap.keys.contains(faction)){
      game.stage.factionMap[faction]!.units.add(this);
    }
    else{ 
      debugPrint("Unit created for faction $faction not in factionMap.");
      debugPrint("factionMap has keys ${game.stage.factionMap.keys}.");
    }
    game.stage.tileMap[tilePosition]?.setUnit(this);
    debugPrint("Unit $name loaded.");
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
          // debugPrint("$name equipped ${item.name} as ${item.type}");
          break;
        case ItemType.gear:
          gear = item;
          // debugPrint("$name equipped ${item.name} as ${item.type}");
          break;
        case ItemType.treasure:
          treasure = item;
          // debugPrint("$name equipped ${item.name} as ${item.type}");
          break;
        default:
          // debugPrint("$name can't equip ${item.name}");
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
    if(game.stage.tileMap[tilePosition]! is Town) {
      Town town = game.stage.tileMap[tilePosition]! as Town;
      if (town.open) actions.add("Visit");
    }
    if(unit.getTargets(game.stage.cursor.tilePosition).isNotEmpty) actions.add("Attack");
    if(unit.inventory.isNotEmpty) actions.add("Items");
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

  List<Unit> getTargets(Point<int> tilePosition) {
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
  ({int accuracy, int critRate, int damage, int fatigue}) attackCalc(Unit target, Attack? attack){
    Vector4 combatStats = Vector4(getStat('str').toDouble(), getStat('dex').toDouble(), getStat('mag').toDouble(), getStat('wis').toDouble());
    
    if(attack == null) {return (damage: 0, accuracy: 0, critRate: 0, fatigue: 0);}
    else {
      Attack atk = attack; // Create local non-nullable atk to avoid having to use null checks everywhere.
      int might = (atk.might + (atk.scaling.dot(combatStats))).toInt();
      int hit = atk.hit + getStat('lck');
      int crit = atk.crit + getStat('lck');
      int fatigue = atk.fatigue;
      if(main?.weapon != null) {
        if(atk.magic) {
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
      int damage = (might - ((atk.magic ? 1 : 0)*target.getStat('res') + (1-(atk.magic ? 1 : 0))*target.getStat('def')) - game.stage.tileMap[target.tilePosition]!.getTerrainDefense()).toInt().clamp(0, 100);
      int accuracy = (hit - target.getStat('lck') - ((atk.magic ? 1 : 0)*target.getStat('wis') + (1-(atk.magic ? 1 : 0))*target.getStat('dex')) - game.stage.tileMap[target.tilePosition]!.getTerrainAvoid()).toInt().clamp(1, 99);
      int critRate = (crit - target.getStat('lck')).toInt().clamp(0, 100);
      return (damage: damage, accuracy: accuracy, critRate: critRate, fatigue: fatigue);
    }
  }

  Attack? getAttack(int combatDistance) {
    // if the unit's current attack is valid for the combatDistance, use that.
    // if not, for now just try to find the first attack they can make. 
    if (attack != null && attack!.range.$1 <= combatDistance && attack!.range.$2 >= combatDistance){
      return attack;
    } else {
      for (Attack attack in attackSet.values){
        if(attack.range.$1<=combatDistance && attack.range.$2 >=combatDistance){
          return attack;
        }
      }
    }
    return null;
  }

  void die() {
    dead = true;
    game.stage.tileMap[tilePosition]!.removeUnit();
    removeFromParent();
  }
}
class UnitCreationEvent extends Event{
  static List<Event> observers = [];
  final String unitName;
  final String factionName;
  final Point<int> tilePosition;
  int? level;
  List<String>? items;
  Point<int>? destination;
  late final Unit unit;
  

  UnitCreationEvent(this.unitName, this.tilePosition, this.factionName, {this.level, this.items, this.destination, Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  void execute() {
    super.execute();
    debugPrint("UnitCreationEvent: unit $name");
    unit = Unit.fromJSON(tilePosition, unitName, factionName, level: level, itemStrings: items);
    game.stage.add(unit);
    if (destination != null) {
      var moveEvent = UnitMoveEvent(unit, destination!, name: name);
      game.eventQueue.add(moveEvent);
    } else {
      destination = tilePosition;
    }
  }
  @override
  bool checkComplete() {
    if(checkStarted()) {
      game.eventQueue.dispatchEvent(this);
      return true;}
    return false;
  } 
}

class UnitMoveEvent extends Event {
  static List<Event> observers = [];
  final Point<int> tilePosition;
  final Unit unit;
  UnitMoveEvent(this.unit, this.tilePosition, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);

  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  void execute() {
    super.execute();
    debugPrint("UnitMoveEvent: Move unit ${unit.name}");
    unit.moveTo(tilePosition);
  }
  @override
  bool checkComplete() {
    if(checkStarted()) {
      game.eventQueue.dispatchEvent(this);
      return (unit.tilePosition == tilePosition);}
    return false;
  } 
}

class ExhaustUnitEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  bool manual;
  ExhaustUnitEvent(this.unit, {this.manual = false, Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    unit.wait();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
   
  }
}

class DeathEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  static void initialize(EventQueue eventQueue) {
    eventQueue.registerClassObserver<DamageEvent>((damageEvent) {
      if (damageEvent.unit.hp <= 0) {
        // Trigger DeathEvent
        var deathEvent = DeathEvent(damageEvent.unit);
        EventQueue eventQueue = damageEvent.game.eventQueue;
        eventQueue.addEventBatchToHead([deathEvent]);
      }
    });
  }

  DeathEvent(this.unit, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("DeathEvent: ${unit.name} has died.");
    unit.die();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}