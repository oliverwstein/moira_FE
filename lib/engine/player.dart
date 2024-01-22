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
  bool startedTurn = false;
  AIPlayer(String name, FactionType factionType) : super(name, factionType);
  @override
  void update(dt){
    super.update(dt);
    if (startedTurn && game.stage.eventQueue.eventBatches.isEmpty) game.stage.eventQueue.addEventBatch([EndTurnEvent(name)]);
  }
  @override
  void startTurn() {
    startedTurn = true;
    takeTurn();
  }
  @override
  void endTurn() {
    startedTurn = false;
  }
  @override
  Future<void> takeTurn() async {
    debugPrint("$name takes their turn");
  }
}