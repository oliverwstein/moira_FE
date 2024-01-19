import 'dart:developer' as dev;

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';
class Player extends Component with HasGameReference<MoiraGame>{
  String name;
  FactionType factionType;
  List<Unit> units = [];
  

  Player(this.name, this.factionType);

  @override
  void update(dt){
  }

  void takeTurn(){
    dev.log("$name takes their turn");
  }

  void startTurn() {}
}

class AIPlayer extends Player{

  AIPlayer(String name, FactionType factionType) : super(name, factionType);
  @override
  void update(dt){}

  void takeTurn(){
    dev.log("$name takes their turn");
  }
}