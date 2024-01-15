import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:moira/content/content.dart';

class Unit extends PositionComponent with HasGameReference<MoiraGame>{
  final Completer<void> _loadCompleter = Completer<void>();
  final String name;
  final String className;
  int movementRange;
  UnitTeam team;
  Point<int> gridCoord;
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet unitSheet;
  late final Map<String, dynamic> unitData;

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

  factory Unit.fromJSON(Point<int> gridCoord, String name, {int? level}) {

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
    
    // Create items for inventory
    List<Item> inventory = [];
    for(String itemName in unitData['inventory']){
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
    return Unit._internal(unitData, gridCoord, name, className, givenLevel, movementRange, team, inventory, attackMap, proficiencies, stats);
  }

   // Private constructor for creating instances
  Unit._internal(this.unitData, this.gridCoord, this.name, this.className, this.level, this.movementRange, this.team, this.inventory, this.attackSet, this.proficiencies, this.stats){
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
    // remainingMovement = movementRange.toDouble();
    // oldTile = gridCoord;
  }
  
  @override
  Future<void> onLoad() async {
    // Load the unit image and create the animation component
    ui.Image unitImage = await game.images.load('${name}_idle.png');
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
    size = game.stage.tiles.size;
    position = Vector2(gridCoord.x * size.x, gridCoord.y * size.y);
  
    // Create skills for skillset
    for(String skillName in unitData['skills']){
      Skill skill = Skill.fromJson(skillName, this);
      // skill.attachToUnit(this, game.eventDispatcher);
    }
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
}
