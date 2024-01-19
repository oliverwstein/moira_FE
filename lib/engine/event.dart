import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:async/async.dart';
import 'package:flame/components.dart';
import 'package:jenny/jenny.dart';
import 'package:moira/content/content.dart';

abstract class Event extends Component with HasGameReference<MoiraGame>{
  void execute(){
    _isStarted = true;
  }
  bool _isStarted = false;
  bool _isCompleted = false;
  bool checkStarted(){return _isStarted;}
  bool checkComplete(){return _isCompleted;}
  @override 
  void update(dt){
    if(!_isStarted) execute();
    if(checkComplete()) removeFromParent();
  }
}

mixin Observer {
    void onEvent(Event event);
}

class EventQueue extends Component with HasGameReference<MoiraGame>{
  Queue<List<Event>> _eventBatches = Queue<List<Event>>();

  @override
  void onLoad() {
    children.register<Event>();
  }

  void addEventBatch(List<Event> eventBatch) {
    _eventBatches.add(eventBatch);
  }

  List<Event> currentBatch(){
    return children.query<Event>();
  }

  void mountBatch(List<Event> batch) {
    // Execute each event in the current batch
    for (var event in batch) {
      add(event);
    }
  }

  @override
  void update(double dt) {
    if(currentBatch().isEmpty){
      if(_eventBatches.isNotEmpty){
        mountBatch(_eventBatches.removeFirst());
      }
    }
  }

  void loadEventsFromJson(dynamic jsonData) {
    for (List<dynamic> eventBatch in jsonData) {
      List<Event> batch = [];
      for (Map eventData in eventBatch){
        switch (eventData['type']) {
            case 'UnitCreationEvent':
              String name = eventData['name'];
              String faction = eventData['faction'];
              Point<int> tilePosition = Point(eventData['tilePosition'][0], eventData['tilePosition'][1]);
              int? level = eventData['level'];
              List<String>? itemStrings;
              if (eventData['items'] != null) {
                itemStrings = List<String>.from(eventData['items']);
              }
              Point<int>? destination;
              if (eventData['destination'] != null) {
                destination = Point(eventData['destination'][0], eventData['destination'][1]);
              }
              batch.add(UnitCreationEvent(name, tilePosition, level:level, teamString: faction, items:itemStrings, destination: destination));
              break;
            case 'DialogueEvent':
              String bgName = eventData['bgName'];
              String nodeName = eventData['nodeName'];
              batch.add(DialogueEvent(bgName, nodeName));
              break;
            case 'PanEvent':
              Point<int> destination = Point(eventData['destination'][0], eventData['destination'][1]);
              batch.add(PanEvent(destination));
              break;
            case 'StartTurnEvent':
              String factionName = eventData['factionName'];
              batch.add(StartTurnEvent(factionName));
            case 'FactionCreationEvent':
              final Map<String, FactionType> stringToFactionType = {
                for (var type in FactionType.values) type.toString().split('.').last: type,
              };
              FactionType factionType = stringToFactionType[eventData['factionType']] ?? FactionType.blue;
              String factionName = eventData["factionName"];
              bool human = eventData["human"] ?? false;
              batch.add(FactionCreationEvent(factionName, factionType, human:human));

        }
      } addEventBatch(batch);
    }
  }
}

class UnitCreationEvent extends Event{
  final String name;
  final String? teamString;
  final Point<int> tilePosition;
  int? level;
  List<String>? items;
  Point<int>? destination;
  late final Unit unit;
  

  UnitCreationEvent(this.name, this.tilePosition, {this.level, this.teamString, this.items, this.destination});

  @override
  void execute() {
    super.execute();
    dev.log("Create unit $name");
    unit = Unit.fromJSON(tilePosition, name, level: level, teamString: teamString, itemStrings: items);
    game.stage.add(unit);
    _isCompleted = true;
    if (destination != null) {
      var moveEvent = UnitMoveEvent(unit, destination!);
      game.stage.eventQueue.add(moveEvent);
    } else {
      destination = tilePosition;
    }
    dev.log("Unit $name Created");
    
  }
}

class UnitMoveEvent extends Event {
  final Point<int> tilePosition;
  final Unit unit;
  UnitMoveEvent(this.unit, this.tilePosition);

  @override
  void execute() {
    super.execute();
    dev.log("Event: Move unit ${unit.name}");
    unit.moveTo(tilePosition);
  }
  @override
  bool checkComplete() {
    return (unit.tilePosition == tilePosition);
  } 
}

class DialogueEvent extends Event{
  String bgName;
  String nodeName;
  late Dialogue dialogue;
  late DialogueRunner runner;
  DialogueEvent(this.bgName, this.nodeName);

  @override
  Future<void> execute() async {
    super.execute();
    dev.log("DialogueEvent execution");
    dialogue = Dialogue(bgName, nodeName);
    await game.add(dialogue);
    runner = DialogueRunner(
        yarnProject: game.yarnProject, dialogueViews: [dialogue]);
    runner.startDialogue(nodeName);
    game.switchToWorld(dialogue);
  }
  @override
  bool checkComplete() {
    return dialogue.finished;
  } 
}

class PanEvent extends Event{
  final Point<int> destination;
  PanEvent(this.destination);
  @override
  void execute() {
    super.execute();
    game.stage.cursor.speed = 50;
    dev.log("Event: Pan to $destination");
    game.stage.cursor.moveTo(destination);
  }
  @override
  bool checkComplete() {
    if(!game.stage.cursor.isMoving){
      game.stage.cursor.speed = 300;
      return true;
    }
    return false;
  } 
}

class StartTurnEvent extends Event{
  String factionName;
  StartTurnEvent(this.factionName);
  @override
  Future<void> execute() async {
    super.execute();
    dev.log("StartTurnEvent execution");
    game.stage.activeFaction = game.stage.factionMap[factionName];
    game.stage.activeFaction!.startTurn();
    _isCompleted = true;
  }
}

class FactionCreationEvent extends Event{
  String name;
  bool human;
  FactionType type;
  FactionCreationEvent(this.name, this.type, {this.human = false});
  @override
  Future<void> execute() async {
    super.execute();
    dev.log("FactionCreationEvent execution");
    if(human){
      game.stage.add(Player(name, type));
    } else {
      game.stage.add(AIPlayer(name, type));
    }
    _isCompleted = true;
  }
}