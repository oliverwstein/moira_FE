import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:moira/content/content.dart';
class Player extends Component with HasGameReference<MoiraGame>{
  String name;
  FactionType factionType;
  List<Unit> units = [];
  List<String> hostilities = [];
  

  Player(this.name, this.factionType);

  @override
  void update(dt){
  }

  void takeTurn(){
    debugPrint("$name takes their turn");
  }
  bool unitsAllMoved(){
    if (units.every((unit) => unit.canAct == false)) return true;
    return false;
  }

  void startTurn() {
  }
  void endTurn(){
    for(Unit unit in units){
      unit.toggleCanAct(true);
    }
  }

  bool checkHostility(Unit unit){
    if(hostilities.contains(unit.faction)) return true;
    switch (factionType) {
      case FactionType.blue:
        if (game.stage.factionMap[unit.faction]?.factionType == FactionType.red) return true;
        return false;
      case FactionType.yellow:
        if (game.stage.factionMap[unit.faction]?.factionType == FactionType.red) return true;
        return false;
      case FactionType.red:
        if (game.stage.factionMap[unit.faction]?.factionType != FactionType.red) return true;
        return false;
      case FactionType.green:
        return false;
      default:
        debugPrint("checkHostility: faction ${unit.faction} not in factionMap");
        return false;
    }
  }
}

class AIPlayer extends Player{
  AIPlayer(String name, FactionType factionType) : super(name, factionType);
  @override
  void update(dt){
    super.update(dt);
  }
  @override
  void startTurn() {
    super.startTurn();
    debugPrint("AIPlayer: startTurn for $name");
    game.eventQueue.addEventBatch([TakeTurnEvent(name)]);
  }
  @override
  void endTurn() {
    super.endTurn();
  }

  @override
  Future<void> takeTurn() async {
    super.takeTurn();
    for (var unit in game.stage.activeFaction!.units) {
      if (unit.canAct) {
        Vector2 centeredPosition = game.stage.cursor.centerCameraOn(unit.tilePosition);
        game.stage.cursor.moveTo(Point(centeredPosition.x~/Stage.tileSize, centeredPosition.y~/Stage.tileSize));
        await Future.delayed(const Duration(milliseconds: 300));
        var rankedTiles = unit.rankOpenTiles();
        debugPrint("${rankedTiles.firstOrNull}");
        // for(Event event in rankedTiles.first.events){
        //   game.eventQueue.addEventBatch([event]);
        // }
        game.eventQueue.addEventBatch([ExhaustUnitEvent(unit)]);
      }
    }
    game.eventQueue.addEventBatch([EndTurnEvent(name)]);
  }
}

class StartTurnEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  int turn;
  StartTurnEvent(this.factionName, this.turn, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("StartTurnEvent: Start turn $turn for $factionName");
    game.stage.activeFaction = game.stage.factionMap[factionName];
    await Future.delayed(const Duration(milliseconds: 1000));
    game.stage.activeFaction!.startTurn();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}

class TakeTurnEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  TakeTurnEvent(this.factionName, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("TakeTurnEvent: Take ${game.stage.turn} for $factionName");
    game.stage.activeFaction!.takeTurn();
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }

}

class EndTurnEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  EndTurnEvent(this.factionName, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  void execute() {
    super.execute();
    debugPrint("EndTurnEvent execution  $factionName");
    game.stage.activeFaction!.endTurn();
    do {
      if(game.stage.turnOrder[game.stage.turnPhase.$1].length == game.stage.turnPhase.$2){
        game.stage.turnPhase = ((game.stage.turnPhase.$1 + 1) % 4, 0);
        if (game.stage.turnPhase.$1 == 0) game.stage.turn++;
      } else {
        game.stage.turnPhase = ((game.stage.turnPhase.$1), game.stage.turnPhase.$2 + 1);
      }
    } while (game.stage.turnOrder[game.stage.turnPhase.$1].length == game.stage.turnPhase.$2);
    game.stage.activeFaction = game.stage.turnOrder[game.stage.turnPhase.$1][game.stage.turnPhase.$2];
    completeEvent();
    game.eventQueue.dispatchEvent(this);
    StartTurnEvent startTurn = StartTurnEvent(game.stage.activeFaction!.name, game.stage.turn);
    game.eventQueue.addEventBatch([startTurn]);  
  }
}

class FactionCreationEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  bool human;
  FactionType type;
  FactionCreationEvent(this.factionName, this.type, {this.human = false, Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("FactionCreationEvent execution $name");
    Player player;
    if(human){
      player = Player(factionName, type);
      game.stage.add(player);
      game.stage.factionMap[factionName] = player;
    } else {
      player = AIPlayer(factionName, type);
      game.stage.add(player);
      game.stage.factionMap[factionName] = player;
    }
    game.stage.turnOrder[type.order].add(player);
    game.eventQueue.dispatchEvent(this);
    completeEvent();
  }
}