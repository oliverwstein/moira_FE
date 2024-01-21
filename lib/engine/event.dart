import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/content/content.dart';

abstract class Event extends Component with HasGameReference<MoiraGame>{
  Trigger? trigger;
  bool _isStarted = false;
  bool _isCompleted = false;
  bool checkStarted(){return _isStarted;}
  bool checkComplete(){return _isCompleted;}
  Event({this.trigger});
  void execute(){
    _isStarted = true;
    if (trigger != null) debugPrint("Trigger found!");
  }

  List<Event> getObservers();

  @override 
  void update(dt){
    if(!_isStarted) execute();
    if(checkComplete()) removeFromParent();
    
    
  }

  void dispatch() {
    for (var observer in getObservers()) {
      observer.trigger?.check(this);
    }
  }
}

class DummyEvent extends Event {
  @override
  List<Event> getObservers() {
    // TODO: implement getObservers
    throw UnimplementedError();
  }

}

class EventQueue extends Component with HasGameReference<MoiraGame>{
  final Queue<List<Event>> _eventBatches = Queue<List<Event>>();
  final List<Event> triggerEvents = [];

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
    for (var event in batch) {
      if(event.trigger == null){
        event.dispatch();
        add(event);
      } else {
        triggerEvents.add(event);
      }
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
        Event event;
        switch (eventData['type']) {
          case 'UnitCreationEvent':
            String name = eventData['unitName'];
            String factionName = eventData['faction'];
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
            event = UnitCreationEvent(name, tilePosition, factionName, level:level, items:itemStrings, destination: destination);
            break;
          case 'DialogueEvent':
            String bgName = eventData['bgName'];
            String nodeName = eventData['nodeName'];
            event = DialogueEvent(nodeName, bgName: bgName);
            break;
          case 'PanEvent':
            Point<int> destination = Point(eventData['destination'][0], eventData['destination'][1]);
            event = PanEvent(destination);
            break;
          case 'StartTurnEvent':
            String factionName = eventData['factionName'];
            int turn = eventData['turn'];
            event = StartTurnEvent(factionName, turn);
            break;
          case 'FactionCreationEvent':
            final Map<String, FactionType> stringToFactionType = {
              for (var type in FactionType.values) type.toString().split('.').last: type,
            };
            FactionType factionType = stringToFactionType[eventData['factionType']] ?? FactionType.blue;
            String factionName = eventData["factionName"];
            bool human = eventData["human"] ?? false;
            event = FactionCreationEvent(factionName, factionType, human:human);
            break;
          default:
            // Add a dummy event.
            event = DummyEvent();
        }
        List<dynamic> triggerList = eventData['triggers'] ?? [];
        Trigger? eventTrigger;
        if (triggerList.isNotEmpty) {
          eventTrigger = Trigger.fromJson(triggerList.first, event);
          event.trigger = eventTrigger;
          }
        batch.add(event);
        addEventBatch(batch);
      }
    }
  }
}

class UnitCreationEvent extends Event{
  static List<Event> observers = [];
  final String name;
  final String factionName;
  final Point<int> tilePosition;
  int? level;
  List<String>? items;
  Point<int>? destination;
  late final Unit unit;
  

  UnitCreationEvent(this.name, this.tilePosition, this.factionName, {this.level, this.items, this.destination, Trigger? trigger}) : super(trigger: trigger);
  
  @override
  List<Event> getObservers() => observers;

  @override
  void execute() {
    super.execute();
    debugPrint("UnitCreationEvent: unit $name");
    unit = Unit.fromJSON(tilePosition, name, factionName, level: level, itemStrings: items);
    game.stage.add(unit);
    _isCompleted = true;
    if (destination != null) {
      var moveEvent = UnitMoveEvent(unit, destination!);
      game.stage.eventQueue.add(moveEvent);
    } else {
      destination = tilePosition;
    }
    
  }
}

class UnitMoveEvent extends Event {
  static List<Event> observers = [];
  final Point<int> tilePosition;
  final Unit unit;
  UnitMoveEvent(this.unit, this.tilePosition, {Trigger? trigger}) : super(trigger: trigger);

  @override
  List<Event> getObservers() => observers;

  @override
  void execute() {
    super.execute();
    debugPrint("Event: Move unit ${unit.name}");
    unit.moveTo(tilePosition);
  }
  @override
  bool checkComplete() {
    return (unit.tilePosition == tilePosition);
  } 
}

class DialogueEvent extends Event{
  static List<Event> observers = [];
  String? bgName;
  String nodeName;
  late DialogueMenu menu;
  DialogueEvent(this.nodeName, {this.bgName, Trigger? trigger}) : super(trigger: trigger);
  @override
  List<Event> getObservers() => observers;
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("DialogueEvent execution");
    menu = DialogueMenu(nodeName, bgName);
    game.stage.menuManager.pushMenu(menu);

  }
  @override
  bool checkComplete() {
    return menu.dialogue.finished;
  } 
}

class PanEvent extends Event{
  static List<Event> observers = [];
  final Point<int> destination;
  PanEvent(this.destination, {Trigger? trigger}) : super(trigger: trigger);
  @override
  List<Event> getObservers() => observers;
  @override
  void execute() {
    super.execute();
    game.stage.cursor.speed = 100;
    debugPrint("Event: Pan to $destination");
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
  static List<Event> observers = [];
  String factionName;
  int turn;
  StartTurnEvent(this.factionName, this.turn, {Trigger? trigger}) : super(trigger: trigger);
  @override
  List<Event> getObservers() => observers;
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("StartTurnEvent execution  $factionName");
    game.stage.activeFaction = game.stage.factionMap[factionName];
    game.stage.activeFaction!.startTurn();
    _isCompleted = true;
  }
}

class EndTurnEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  EndTurnEvent(this.factionName, {Trigger? trigger}) : super(trigger: trigger);
  @override
  List<Event> getObservers() => observers;
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("EndTurnEvent execution  $factionName");
    game.stage.activeFaction!.endTurn();
    do {
      debugPrint("Try to get the next faction after ${game.stage.turnPhase}");
      if(game.stage.turnOrder[game.stage.turnPhase.$1].length == game.stage.turnPhase.$2){
        game.stage.turnPhase = ((game.stage.turnPhase.$1 + 1) % 4, 0);
        if (game.stage.turnPhase.$1 == 0) game.stage.turn++;
      } else {
        game.stage.turnPhase = ((game.stage.turnPhase.$1), game.stage.turnPhase.$2 + 1);
      }
    } while (game.stage.turnOrder[game.stage.turnPhase.$1].length == game.stage.turnPhase.$2);
    game.stage.activeFaction = game.stage.turnOrder[game.stage.turnPhase.$1][game.stage.turnPhase.$2];
    game.stage.eventQueue.add(StartTurnEvent(game.stage.activeFaction!.name, game.stage.turn));
    _isCompleted = true;
  }
}

class FactionCreationEvent extends Event{
  static List<Event> observers = [];
  String name;
  bool human;
  FactionType type;
  FactionCreationEvent(this.name, this.type, {this.human = false, Trigger? trigger}) : super(trigger: trigger);
  @override
  List<Event> getObservers() => observers;
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("FactionCreationEvent execution $name");
    Player player;
    if(human){
      player = Player(name, type);
      game.stage.add(player);
      game.stage.factionMap[name] = player;
    } else {
      player = AIPlayer(name, type);
      game.stage.add(player);
      game.stage.factionMap[name] = player;
    }
    game.stage.turnOrder[type.order].add(player);
    _isCompleted = true;
  }
}