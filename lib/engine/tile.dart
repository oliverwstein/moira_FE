import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:moira/content/content.dart';
enum TileState {blank, move, attack}
enum Terrain {forest, path, cliff, sea, stream, fort, gate, rampart, town, ruin, plain}
extension TerrainEffects on Terrain {
  double get cost {
    switch (this) {
      case Terrain.forest:
        return 2;
      case Terrain.cliff:
        return 10;
      case Terrain.sea:
        return 100;
      case Terrain.rampart:
        return 100;
      case Terrain.stream:
        return 20;
      case Terrain.path:
        return .7;
      default:
        return 1;
    }
  }

  int get avoid {
    switch (this) {
      case Terrain.forest:
        return 20;
      case Terrain.town:
        return 20;
      case Terrain.ruin:
        return 10;
      case Terrain.fort:
        return 30;
      case Terrain.path:
        return -10;
      default:
        return 0;
    }
  }

  int get defense {
    switch (this) {
      case Terrain.fort:
        return 2;
      case Terrain.forest:
        return 1;
      case Terrain.path:
        return -1;
      default:
        return 0;
    }
  }
}

class Tile extends PositionComponent with HasGameReference<MoiraGame>{
  late final SpriteAnimationComponent _moveAnimationComponent;
  late final SpriteAnimationComponent _attackAnimationComponent;
  late final SpriteSheet movementSheet;
  late final SpriteSheet attackSheet;
  final Point<int> point;
  // late final TextComponent textComponent;
  Unit? unit;
  bool get isOccupied => unit != null;
  Terrain terrain; // e.g., "grass", "water", "mountain"
  String name; // Defaults to the terrain name if there is no name.
  TileState state = TileState.blank;
  // Factory constructor
  factory Tile(Point<int> point, double size, Terrain terrain, String name) {
    if (name == "Center" && terrain == Terrain.town) {
      return TownCenter(point, size, terrain, name);
    } else if (terrain == Terrain.town) {
      return Town(point, size, terrain, name);
    } else if (terrain == Terrain.gate) {
        String castleName = name.split("_")[0];
        String factionName = name.split("_")[1];
        return CastleGate(point, size, terrain, castleName, factionName);
    } else if (terrain == Terrain.fort) {
        return CastleFort(point, size, terrain, name);}
    else{
      return Tile._internal(point, size, terrain, name);
    }
  }

  // Internal constructor for Tile
  Tile._internal(this.point, double size, this.terrain, this.name) {
    this.size = Vector2.all(size);
    anchor = Anchor.topLeft;
  }
  static int getDistance(Point<int> a, Point<int> b){
    return (a.x - b.x).abs() + (a.y - b.y).abs();
  }

  @override 
  void update(dt){
    if(unit != null) {
      if (unit?.tilePosition != point){
        removeUnit();
      } 
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    ui.Image moveImage = await game.images.load('movement_highlight.png');
    ui.Image attackImage = await game.images.load('attack_highlight.png');
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
    );
    
    _moveAnimationComponent.anchor = Anchor.center;
    _moveAnimationComponent.position = Vector2(size.x/2, size.y/2);
    _moveAnimationComponent.size = size*.9;
    _attackAnimationComponent = SpriteAnimationComponent(
      animation: attackSheet.createAnimation(row: 0, stepTime: .2),
    );
    _attackAnimationComponent.anchor = Anchor.center;
    _attackAnimationComponent.position = Vector2(size.x/2, size.y/2);
    _attackAnimationComponent.size = size*.9;
  }
  
  void resize() {
    size = Vector2.all(Stage.tileSize);
  }
  
  void setUnit(Unit newUnit) {
    unit = newUnit;
  }

  void removeUnit() {
    unit = null;
  }
  double getTerrainCost() {return terrain.cost;}
  int getTerrainAvoid() {return terrain.avoid;}
  int getTerrainDefense() {return terrain.defense;
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
}

class TownCenter extends Tile{
  late SpriteComponent closedSprite;
  late final SpriteSheet stateSheet;
  bool open;
  int loot;
  // Constructor for the Town class. 
  // Inherits properties and methods from Tile and adds specific properties for Town.
  TownCenter(Point<int> point, double size, Terrain terrain, String name, {this.open = true, this.loot = 10}) 
    : super._internal(point, size, terrain, name);

  static TownCenter? getNearestTown(Unit unit) {
  var openTowns = unit.game.stage.children.query<TownCenter>().where((town) => town.open && !town.isOccupied);
  return openTowns.isNotEmpty 
    ? openTowns.reduce((nearest, town) => 
        unit.getPathDistance(town.point, unit.tilePosition) < unit.getPathDistance(nearest.point, unit.tilePosition) ? town : nearest) 
    : null;
  }
  void close() {
    open = false;
  }
  @override
  void render(Canvas canvas){
    super.render(canvas);
    if(!open) add(closedSprite);

  }
  @override
  Future<void> onLoad() async {
    super.onLoad();
    ui.Image statesImages = await game.images.load('states_set.png');
    stateSheet = SpriteSheet.fromColumnsAndRows(
      image: statesImages,
      columns: 3,
      rows: 4,
    );
    closedSprite = SpriteComponent(
      sprite: stateSheet.getSprite(2, 0), 
      size: size,
    );
    
    closedSprite.anchor = Anchor.center;
    closedSprite.position = Vector2(size.x/2, size.y/2);
    
  }

  void ransack() {
    if(loot>=9){
      (game.stage.tileMap[Point(point.x-1, point.y-1)]! as Town).degrade();
    }
    else if(loot>=7){
      (game.stage.tileMap[Point(point.x, point.y-1)]! as Town).degrade();
    }
    else if(loot>=5){
      (game.stage.tileMap[Point(point.x+1, point.y-1)]! as Town).degrade();
    }
    else if(loot>=3){
      (game.stage.tileMap[Point(point.x-1, point.y)]! as Town).degrade();
    }
    else if(loot>=1){
      (game.stage.tileMap[Point(point.x+1, point.y)]! as Town).degrade();
    }
    loot--;
    if(loot == 0) close();
  }
}
class Town extends Tile {
  late SpriteComponent ruinSprite;
  late SpriteComponent plainSprite;
  late final SpriteSheet stateSheet;
  late final int col;
  // Constructor for the Village class. 
  // Inherits properties and methods from Tile and adds specific properties for Town.
  Town(Point<int> point, double size, Terrain terrain, String name) 
    : super._internal(point, size, terrain, name);
  @override
  Future<void> onLoad() async {
    super.onLoad();
    ui.Image statesImages = await game.images.load('states_set.png');
    stateSheet = SpriteSheet.fromColumnsAndRows(
      image: statesImages,
      columns: 3,
      rows: 4,
    );
    Random rng = Random();
    col = rng.nextInt(3);
    ruinSprite = SpriteComponent(
      sprite: stateSheet.getSprite(0, col), 
      size: size,
      anchor: Anchor.center,
      position: Vector2(size.x/2, size.y/2),
    );
    plainSprite = SpriteComponent(
      sprite: stateSheet.getSprite(1, col), 
      size: size,
      anchor: Anchor.center,
      position: Vector2(size.x/2, size.y/2),
    );
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas); // Don't forget to call super.render
    switch(terrain) {
      case Terrain.ruin:
        add(ruinSprite);
        break;
      case Terrain.plain:
        if(ruinSprite.isMounted){
          remove(ruinSprite);
        }
        add(plainSprite);
        break;
      default:
        break;
    }
  }
  
  void degrade(){
    if(terrain == Terrain.town){
      terrain = Terrain.ruin;
    } else {terrain = Terrain.plain;}
  }
}

class CastleGate extends Tile {
  late SpriteComponent flagSprite;
  late final SpriteSheet stateSheet;
  String factionName;
  FactionType get factionType => game.stage.factionMap[factionName]?.factionType ?? FactionType.red;
  CastleFort get fort => game.stage.tileMap[Point(point.x, point.y - 2)] as CastleFort;
  CastleGate(Point<int> point, double size, Terrain terrain, String name, this.factionName) 
    : super._internal(point, size, terrain, name);
  static CastleGate? getNearestCastle(Unit unit, String factionName) {
    var castleGates = unit.game.stage.children.query<CastleGate>().where((gate) => gate.factionName == factionName);
    return castleGates.isNotEmpty 
      ? castleGates.reduce((nearest, gate) => 
          unit.getPathDistance(gate.point, unit.tilePosition) < unit.getPathDistance(nearest.point, unit.tilePosition) ? gate : nearest) 
      : null;
  }
  static CastleGate? getCastleByName(MoiraGame game, String castleName) {
    return game.stage.children.query<CastleGate>().where((gate) => gate.name == castleName).firstOrNull;
    // There should only ever be one gate per castleName.
  }
  void cedeTo(String newFactionName){
    factionName = newFactionName;
  }
  @override
  Future<void> onLoad() async {
    super.onLoad();
    ui.Image statesImages = await game.images.load('states_set.png');
    stateSheet = SpriteSheet.fromColumnsAndRows(
      image: statesImages,
      columns: 3,
      rows: 4,
    );
    flagSprite = SpriteComponent(
      sprite: stateSheet.getSprite(3, factionType.order), 
      size: Vector2.all(Stage.tileSize),
      anchor: Anchor.center,
      position: Vector2(size.x*1.5, size.y/2),
    );
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    flagSprite.sprite = stateSheet.getSprite(3, factionType.order);
    add(flagSprite);
  }
}

class CastleFort extends Tile {
  CastleFort(Point<int> point, double size, Terrain terrain, String name) 
    : super._internal(point, size, terrain, name);
}

class VisitEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  final TownCenter town;
  VisitEvent(this.unit, this.town, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    town.close(); 
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class RansackEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  final TownCenter town;
  RansackEvent(this.unit, this.town, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    town.ransack(); 
    debugPrint("RansackEvent: ${unit.name} ransacks town at ${town.point}.");
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class BesiegeEvent extends Event {
  static List<Event> observers = [];
  final CastleGate gate;
  final bool duel;
  BesiegeEvent(this.gate, {Trigger? trigger, String? name, this.duel = false}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    Unit unit = gate.unit!;
    assert(gate.factionName != unit.controller.name);
    if(!gate.fort.isOccupied){
      game.eventQueue.addEventBatch([SeizeEvent(unit, gate)]);
    } else {
      debugPrint("BesiegeEvent: ${unit.name} besieges castle ${gate.name}.");
      // This is for the AI; Player units besieging a fort do so via menus, 
      // though the event should still be involved.
      // Note: besieging lets the unit use any attack in their attackSet.
      unit.getBestAttackOnTarget(gate.fort.unit!, unit.attackSet.values.toList());
      game.eventQueue.addEventBatch([StartCombatEvent(unit, gate.fort.unit!, duel: duel)]);
    }
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class SeizeEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  final CastleGate gate;
  SeizeEvent(this.unit, this.gate, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name ?? "SeizeEvent_${unit.name}_${gate.name}");
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    assert(gate.factionName != unit.controller.name);
    gate.cedeTo(unit.controller.name);
    debugPrint("SeizeEvent: ${unit.name} seizes castle ${gate.name} for ${unit.controller.name}.");
    // game.eventQueue.add(UnitMoveEvent(unit, gate.fort.point));
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

