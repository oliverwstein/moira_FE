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
        // game.camera.moveTo(unit.position, speed: 400);
        game.stage.cursor.centerCameraOn(unit.tilePosition);
        await Future.delayed(const Duration(milliseconds: 100));
        unit.wait();
      }
    }
    game.eventQueue.addEventBatch([EndTurnEvent(name)]);
  }
}