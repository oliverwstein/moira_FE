import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/src/experimental/geometry/shapes/shape.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/content/content.dart';

abstract class Event extends Component with HasGameReference<MoiraGame>{
  Trigger? trigger;
  String? name;
  bool _isTriggered = false;
  bool _isStarted = false;
  bool _isCompleted = false;
  bool checkStarted(){return _isStarted;}
  bool checkComplete(){return _isCompleted;}
  Event({this.trigger, this.name});
  void execute(){
    _isStarted = true;
    if (trigger != null) debugPrint("Trigger found!");
  }

  List<Event> getObservers();

  @override 
  void update(dt){
    if(!_isStarted) {
      execute();
      debugPrint("Dispatch $runtimeType");
      }
    if(checkComplete()) {
      removeFromParent();
      dispatch();}
    
    
  }

  void dispatch() {
    List<Event> batch = [];
    for (var observer in getObservers()) {
      debugPrint("Dispatch $this to ${observer.runtimeType}");
      if(observer.trigger!.check(this)){
        observer._isTriggered = true;
        observer._isStarted = false;
        observer._isCompleted = false;
        batch.add(observer);
      }
    }
  game.stage.eventQueue.addEventBatch(batch);
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
  final Queue<List<Event>> eventBatches = Queue<List<Event>>();
  final List<Event> triggerEvents = [];

  @override
  void onLoad() {
    children.register<Event>();
  }

  void addEventBatch(List<Event> eventBatch) {
    eventBatches.add(eventBatch);
  }

  List<Event> currentBatch(){
    return children.query<Event>();
  }

  void mountBatch(List<Event> batch) {
    for (var event in batch) {
      if(event.trigger == null){add(event);}
      else {
        if(event._isTriggered){ add(event);}
        else {triggerEvents.add(event);} 
      }
    }
  }

  @override
  void update(double dt) {
    if(currentBatch().isEmpty){
      if(eventBatches.isNotEmpty){
        mountBatch(eventBatches.removeFirst());
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
            String? eventName = eventData['name'] ?? name;
            event = UnitCreationEvent(name, tilePosition, factionName, level:level, items:itemStrings, destination: destination, name: eventName);
            break;
          case 'DialogueEvent':
            String? bgName = eventData['bgName'];
            String nodeName = eventData['nodeName'];
            String? eventName = eventData['name'] ?? nodeName;
            event = DialogueEvent(nodeName, bgName: bgName, name: eventName);
            break;
          case 'PanEvent':
            Point<int> destination = Point(eventData['destination'][0], eventData['destination'][1]);
            String? eventName = eventData['name'];
            event = PanEvent(destination, name: eventName);
            break;
          case 'StartTurnEvent':
            String factionName = eventData['factionName'];
            int turn = eventData['turn'];
            String? eventName = eventData['name'];
            event = StartTurnEvent(factionName, turn, name: eventName);
            break;
          case 'FactionCreationEvent':
            final Map<String, FactionType> stringToFactionType = {
              for (var type in FactionType.values) type.toString().split('.').last: type,
            };
            FactionType factionType = stringToFactionType[eventData['factionType']] ?? FactionType.blue;
            String factionName = eventData["factionName"];
            bool human = eventData["human"] ?? false;
            String? eventName = eventData['name'] ?? factionName;
            event = FactionCreationEvent(factionName, factionType, human:human, name: eventName);
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
  final String unitName;
  final String factionName;
  final Point<int> tilePosition;
  int? level;
  List<String>? items;
  Point<int>? destination;
  late final Unit unit;
  

  UnitCreationEvent(this.unitName, this.tilePosition, this.factionName, {this.level, this.items, this.destination, Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  
  @override
  List<Event> getObservers() => observers;

  @override
  void execute() {
    super.execute();
    debugPrint("UnitCreationEvent: unit $name");
    unit = Unit.fromJSON(tilePosition, unitName, factionName, level: level, itemStrings: items);
    game.stage.add(unit);
    _isCompleted = true;
    if (destination != null) {
      var moveEvent = UnitMoveEvent(unit, destination!, name: name);
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
  UnitMoveEvent(this.unit, this.tilePosition, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);

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
  DialogueEvent(this.nodeName, {this.bgName, Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() => observers;
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("DialogueEvent execution $nodeName $bgName");
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
  PanEvent(this.destination, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() => observers;
  @override
  void execute() {
    super.execute();
    game.stage.cursor.speed = 100;
    debugPrint("Event: Pan to $destination");
    game.camera.follow(game.stage.cursor, snap: false, maxSpeed: 100);
    game.stage.cursor.moveTo(destination);
  }
  @override
  bool checkComplete() {
    if(!game.stage.cursor.isMoving){
      game.stage.cursor.speed = 300;
      game.camera.stop();
      return true;
    }
    return false;
  } 
}

class StartTurnEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  int turn;
  StartTurnEvent(this.factionName, this.turn, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() => observers;
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("StartTurnEvent: Start $turn for $factionName");
    game.stage.activeFaction = game.stage.factionMap[factionName];
    game.stage.activeFaction!.startTurn();
    _isCompleted = true;
  }
}

class EndTurnEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  EndTurnEvent(this.factionName, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() => observers;
  @override
  Future<void> execute() async {
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
    game.stage.eventQueue.add(StartTurnEvent(game.stage.activeFaction!.name, game.stage.turn));
    _isCompleted = true;
  }
}

class FactionCreationEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  bool human;
  FactionType type;
  FactionCreationEvent(this.factionName, this.type, {this.human = false, Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() => observers;
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
    _isCompleted = true;
  }
}