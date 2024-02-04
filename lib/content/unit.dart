import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/rendering.dart';
import 'package:flame/sprite.dart';
import 'package:moira/content/content.dart';
import 'package:flutter/material.dart';
final grayscalePaint = Paint()
      ..colorFilter = const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]);
class Unit extends PositionComponent with HasGameReference<MoiraGame>, UnitMovement, UnitBehavior {
  final Completer<void> _loadCompleter = Completer<void>();
  final String name;
  int movementRange;
  double remainingMovement = - 1;
  String faction;
  Point<int> tilePosition;
  
  Tile get tile => game.stage.tileMap[tilePosition]!;
  Player get controller => game.stage.factionMap[faction]!;
  Class unitClass;
  Queue<Movement> movementQueue = Queue<Movement>();
  late final Map<String, dynamic> unitData;
  bool isMoving = false;
  Direction? direction;
  bool _canAct = true;
  bool dead = false;
  bool get canAct => _canAct;
  Queue<Order> orders = Queue<Order>();
  double speed = 2; // Speed of cursor movement in pixels per second

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
  static Unit? getUnitByName(Stage stage, String unitName) {
    debugPrint("getUnitByName: unit $unitName");
    Unit? unit = stage.children.query<Unit>().where((unit) => unit.name == unitName).firstOrNull;
    return unit;
  }
        
  factory Unit.fromJSON(Point<int> tilePosition, String name, String factionName, {int? level, List<String>? itemStrings, List<String>? orderStrings}) {

    // Extract unit data from the static map in MoiraGame
    var unitsJson = MoiraGame.unitMap['units'] as List;
    Map<String, dynamic> unitData = unitsJson.firstWhere(
        (unit) => unit['name'].toString() == name,
        orElse: () => throw Exception('Unit $name not found in JSON data')
    );

    String className = unitData['class'];
    int givenLevel = level ?? unitData['level'] ?? 1;
    Class unitClass = Class.fromJson(className);

    int movementRange = unitData.keys.contains('movementRange') ? unitData['movementRange'] : unitClass.movementRange;
    unitData['skills'].addAll(unitClass.skills);
    unitData['attacks'].addAll(unitClass.attacks);
    unitData['proficiencies'].addAll(unitClass.proficiencies);
    String faction = factionName;
    // Add weapon proficiencies
    Set<WeaponType> proficiencies = getWeaponTypesFromNames(unitData["proficiencies"].cast<String>());
    Set<Skill> skillSet = getSkillsFromNames(unitData["skills"].cast<String>());

    orderStrings = orderStrings ?? [];
    orderStrings.addAll(unitClass.orders);
    Queue<Order> orders = Queue<Order>();
    for (String orderString in orderStrings){
      orders.add(Order.create(orderString));
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

    Map<String, int> stats = Map<String, int>.from(unitClass.baseStats);
    Map<String, int> growths = Map<String, int>.from(unitClass.growths);
    for (String stat in unitClass.growths.keys){
      if (unitData['growths']?.keys.contains(stat)){
        growths[stat] = unitData['growths'][stat];
      }
    }
    var rng = Random();
    for (String stat in unitClass.baseStats.keys){
      if (unitData['baseStats'].keys.contains(stat)){
        stats[stat] = unitData['baseStats'][stat];
      } else {
        int levelUps = Iterable.generate(givenLevel - 1, (_) => rng.nextInt(100) < growths[stat]! ? 1 : 0)
                        .fold(0, (acc, curr) => acc + curr); // Autoleveler
        stats[stat] = unitClass.baseStats[stat]! + levelUps;

      }
      
    }
    
    // Return a new Unit instance
    return Unit._internal(unitData, tilePosition, name, unitClass, givenLevel, movementRange, faction, orders, inventory, attackMap, proficiencies, skillSet, stats);
  }

   // Private constructor for creating instances
  Unit._internal(this.unitData, this.tilePosition, this.name, this.unitClass, this.level, this.movementRange, this.faction, this.orders, this.inventory, this.attackSet, this.proficiencies, this.skillSet, this.stats){
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
  void setSpriteDirection(){
    unitClass.direction = direction;
    if(main?.weapon != null) main?.weapon!.direction = direction;
  }
  @override
  void update(double dt) {
    super.update(dt);
    // unit.toggleCanAct(true);
    if (movementQueue.isNotEmpty) {
      isMoving = true;
      Movement currentMovement = movementQueue.first;
      direction = currentMovement.direction;
      setSpriteDirection();
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
          direction = currentMovement.direction;
          setSpriteDirection();
        } else {//The movement is over.
          direction = null;
          setSpriteDirection();
        }
      } else {
        position.moveToTarget(game.stage.tileMap[targetTilePosition]!.center, moveStep);
      }
    } 
    unit.tile.setUnit(this);
    // if(game.stage.freeCursor){sprite.paint = canAct ? Paint() : grayscalePaint;}
  }

  @override
  Future<void> onLoad() async {
    add(UnitCircle(this));
    children.register<UnitCircle>();
    add(unitClass);
    position = unit.tile.center;
    anchor = Anchor.center;
  
    // Add to faction:
    if(game.stage.factionMap.keys.contains(faction)){
      game.stage.factionMap[faction]!.units.add(this);
    }
    else{ 
      debugPrint("Unit created for faction $faction not in factionMap.");
      debugPrint("factionMap has keys ${game.stage.factionMap.keys}.");
    }
    unit.tile.setUnit(this);
    _loadCompleter.complete();
  }
  @override
  void render(Canvas canvas){
    super.render(canvas);
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
          if(main?.weapon != null) {add(main!.weapon!);}
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
        if(main?.weapon != null) {remove(main!.weapon!);}
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

  List<String> getActionsAt(Point<int> point){
    List<String> actions = [];
    debugPrint("${game.stage.tileMap[point]! is TownCenter}");
    if(game.stage.tileMap[point]! is TownCenter) {
      TownCenter town = game.stage.tileMap[point]! as TownCenter;
      if (town.open) actions.add("Visit");
      if (town.open) actions.add("Ransack");
    }
    if(game.stage.tileMap[point]! is CastleGate) {
      CastleGate gate = game.stage.tileMap[point]! as CastleGate;
      if (gate.factionName != unit.controller.name){
        if(gate.fort.isOccupied && gate.fort.unit!.controller.checkHostility(unit)){
          actions.add("Besiege");
        } else if(!gate.fort.isOccupied && unit.game.stage.factionMap[gate.factionName]!.checkHostility(unit)){
          actions.add("Seize");
        } else if(!gate.fort.isOccupied && gate.factionName == unit.controller.name){
          actions.add("Enter");
        }
      }
    }
    if(unit.getTargetsAt(point).isNotEmpty) actions.add("Attack");
    if(unit.inventory.isNotEmpty) actions.add("Items");
    actions.add("Wait");
    return actions;
  }

  void toggleCanAct(bool state) {
    debugPrint("Toggle canAct to $state");
    _canAct = state;
    debugPrint("_canAct == $_canAct");
    // Apply or remove the grayscale effect based on canAct
    // sprite.paint = canAct ? Paint() : grayscalePaint;
  }

  List<Unit> getTargetsAt(Point<int> tilePosition) {
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
            if (tile != null && tile.isOccupied && controller.checkHostility(tile.unit!)) {
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
    tile.removeUnit();
    controller.units.remove(this);
    removeFromParent();
  }
  void exit() {
    tile.removeUnit();
    controller.units.remove(this);
    removeFromParent();
  }
}

class UnitCircle extends SpriteComponent with HasVisibility{
  Unit unit;
  UnitCircle(this.unit);

  @override
  void onLoad(){
    ui.Image circle = unit.game.images.fromCache("unit_circle.png");
    sprite = Sprite(circle); 
    anchor = Anchor.center;
    size = Vector2.all(Stage.tileSize*1.25);
    paint = Paint()..colorFilter = ColorFilter.mode(unit.controller.factionType.factionColor.withOpacity(.75), BlendMode.srcATop);
  }

  @override
  void render(Canvas canvas){
    super.render(canvas);
  }
  @override
  void update(double dt) {
    super.update(dt);
    if(unit.game.stage.freeCursor && unit.canAct){isVisible = true;} else {isVisible = false;}
    
    }
}

class UnitCreationEvent extends Event{
  static List<Event> observers = [];
  final String unitName;
  final String factionName;
  final Point<int> tilePosition;

  int? level;
  List<String>? items;
  List<String>? orders;
  Point<int>? destination;
  late final Unit unit;
  

  UnitCreationEvent(this.unitName, this.tilePosition, this.factionName, {this.level, this.items, this.orders, this.destination, Trigger? trigger, String? name}) : super(trigger: trigger, name: "UnitCreationEvent: $unitName");
  
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  void execute() {
    super.execute();
    unit = Unit.fromJSON(tilePosition, unitName, factionName, level: level, itemStrings: items, orderStrings: orders);
    game.stage.add(unit);
    if (destination != null) {
      var moveEvent = UnitMoveEvent(unit, destination!);
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
  final Point<int> destination;
  Unit? unit;
  final String unitName;
  double speed;
  bool chainCamera;

  // Constructor for directly passing the Unit
  UnitMoveEvent(this.unit, this.destination, {Trigger? trigger, String? name, this.speed = 2, this.chainCamera = false})
      : unitName = unit!.name, // Set unitName from the Unit
        super(trigger: trigger, name: name ?? "UnitMoveEvent: ${unit.name}_to_$destination");

  // Constructor for when only unitName is known at construction
  UnitMoveEvent.named(this.unitName, this.destination, {this.unit, Trigger? trigger, String? name, this.speed = 2, this.chainCamera = false})
      : super(trigger: trigger, name: name ?? "UnitMoveEvent: ${unitName}_to_$destination");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  void execute() {
    super.execute();
    unit ??= Unit.getUnitByName(game.stage, unitName);
    assert(unit != null);
    unit!.speed = speed;
    unit!.moveTo(destination);
    
  }
  @override
  bool checkComplete() {
    if(chainCamera){
      game.stage.cursor.centerCameraOn(unit!.tilePosition, 100);
    }
    if(checkStarted() && !unit!.isMoving && unit!.movementQueue.isEmpty) {
      game.eventQueue.dispatchEvent(this);
      unit!.speed = 2;
      game.stage.cursor.snapToTile(unit!.tilePosition);
      return true;
    }
    return false;
  } 
}

class UnitRefreshEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  UnitRefreshEvent(this.unit, {Trigger? trigger, String? name}) : super(trigger: trigger, name: "UnitRefreshEvent: ${unit.name}");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    unit.toggleCanAct(true);
    unit.remainingMovement = unit.movementRange.toDouble();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
   
  }
}

class UnitExhaustEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  bool manual;
  UnitExhaustEvent(this.unit, {this.manual = false, Trigger? trigger, String? name}) : super(trigger: trigger, name: "UnitExhaustEvent: $name");
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

class UnitDeathEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  static void initialize(EventQueue queue) {
    queue.registerClassObserver<DamageEvent>((damageEvent) {
      if (damageEvent.unit.hp <= 0) {
        // Trigger UnitDeathEvent
        var unitDeathEvent = UnitDeathEvent(damageEvent.unit);
        damageEvent.game.eventQueue.addEventBatchToHead([unitDeathEvent]);
      }
    });
  }

  UnitDeathEvent(this.unit, {Trigger? trigger, String? name}) : super(trigger: trigger, name: "${unit.name}_Death");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("UnitDeathEvent: ${unit.name} has died.");
    unit.die();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class UnitExitEvent extends Event {
  static List<Event> observers = [];
  Unit? unit;
  final String unitName;

  UnitExitEvent(this.unit, {Trigger? trigger, String? name}) : unitName = unit!.name, super(trigger: trigger, name: "UnitExitEvent: ${unit.name}");
  UnitExitEvent.named(this.unitName, {this.unit, Trigger? trigger, String? name})
      : super(trigger: trigger, name: name ?? "UnitExitEvent: $unitName");

  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    unit ??= Unit.getUnitByName(game.stage, unitName);
    assert(unit != null);
    unit!.exit();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}