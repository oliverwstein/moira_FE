import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/content/content.dart';

abstract class Event extends Component with HasGameReference<MoiraGame>{
  Trigger? trigger;
  String? name;
  bool _isStarted = false;
  bool _isCompleted = false;
  triggerEvent() {trigger = null;}
  startEvent() {_isStarted = true;}
  completeEvent() {_isCompleted = true;}
  bool checkTriggered(){return (trigger == null);}
  bool checkStarted(){return _isStarted;}
  bool checkComplete(){return _isCompleted;}
  Event({this.trigger, this.name});
  void execute(){
    _isStarted = true;
    if (trigger != null) debugPrint("Trigger found!");
  }

  List<Event> getObservers();

  @override 
  Future<void> update(double dt) async {
    if(!checkTriggered()) return;
    if(!_isStarted) {
      execute();
      return;
      }
    if(checkComplete()) {
      game.eventQueue.addEventBatch(dispatch());
      game.eventQueue.dispatchEvent(this);
      removeFromParent();
      }
  }

  List<Event> dispatch() {
    List<Event> batch = [];
    for (var observer in getObservers()) {
      debugPrint("Dispatch $name to ${observer.runtimeType}");
      if(observer.trigger != null) {
        if(observer.trigger!.check(this)){
          observer.triggerEvent();
          observer._isStarted = false;
          observer._isCompleted = false;
          batch.add(observer);
        }
      }
    }
  return batch;
  }
}

class DummyEvent extends Event {
  @override
  List<Event> getObservers() {
    // Ignore
    throw UnimplementedError();
  }

}

class EventQueue extends Component with HasGameReference<MoiraGame>{
  final Queue<List<Event>> eventBatches = Queue<List<Event>>();

  final Map<Type, List<dynamic>> _classObservers = {};

  void registerClassObserver<T extends Event>(void Function(T) observer) {
    final observersOfType = _classObservers[T] as List<void Function(T)>? ?? [];
    observersOfType.add(observer);
    _classObservers[T] = observersOfType;
  }

  void dispatchEvent<T extends Event>(T event) {
    final observersOfType = _classObservers[T] as List<void Function(T)>?;
    observersOfType?.forEach((observer) => observer(event));
  }

  @override
  void onLoad() {
    children.register<Event>();
  }

  void addEventBatch(List<Event> eventBatch) {
    eventBatches.add(eventBatch);
  }
  void addEventBatchToHead(List<Event> eventBatch) {
    eventBatches.addFirst(eventBatch);
  }

  List<Event> currentBatch(){
    List<Event> batch = children.query<Event>();
    List<Event> currentBatch = [];
    for (Event event in batch){
      if(event.checkTriggered()) currentBatch.add(event);
    }
    return currentBatch;
  }

  void mountBatch(List<Event> batch) {
    for (var event in batch) {
      add(event);
    }
  }

  @override
  Future<void> update(double dt) async {
    if(currentBatch().isEmpty){
      if(eventBatches.isNotEmpty){
        mountBatch(eventBatches.removeFirst());
      }
    } else {
      // debugPrint("Current batch length is: ${currentBatch().length}, starts with: ${currentBatch().first}");
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
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered() && event.checkComplete()));
    return observers;
  }

  @override
  void execute() {
    super.execute();
    debugPrint("UnitCreationEvent: unit $name");
    unit = Unit.fromJSON(tilePosition, unitName, factionName, level: level, itemStrings: items);
    game.stage.add(unit);
    if (destination != null) {
      var moveEvent = UnitMoveEvent(unit, destination!, name: name);
      game.eventQueue.add(moveEvent);
    } else {
      destination = tilePosition;
    }
  }
  @override
  bool checkComplete() {
    if(checkStarted()) return true;
    return false;
  } 
}

class UnitMoveEvent extends Event {
  static List<Event> observers = [];
  final Point<int> tilePosition;
  final Unit unit;
  UnitMoveEvent(this.unit, this.tilePosition, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);

  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered() && event.checkComplete()));
    return observers;
  }

  @override
  void execute() {
    super.execute();
    debugPrint("UnitMoveEvent: Move unit ${unit.name}");
    unit.moveTo(tilePosition);
  }
  @override
  bool checkComplete() {
    if(checkStarted()) return (unit.tilePosition == tilePosition);
    return false;
  } 
}

class DialogueEvent extends Event{
  static List<Event> observers = [];
  String? bgName;
  String nodeName;
  late DialogueMenu menu;
  DialogueEvent(this.nodeName, {this.bgName, Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered() && event.checkComplete()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("DialogueEvent execution $nodeName $bgName");
    menu = DialogueMenu(nodeName, bgName);
    game.stage.menuManager.pushMenu(menu);

  }
  @override
  bool checkComplete() {
    if(checkStarted()) {
      return menu.dialogue.finished;}
    return false;
  } 
}

class PanEvent extends Event{
  static List<Event> observers = [];
  final Point<int> destination;
  late final Vector2 centeredPosition;
  PanEvent(this.destination, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered() && event.checkComplete()));
    return observers;
  }
  @override
  void execute() {
    super.execute();
    debugPrint("PanEvent: Pan to $destination");
    // game.stage.cursor.snapToTile(destination);
    centeredPosition = game.stage.cursor.centerCameraOn(destination);
    
    
  }
  @override
  bool checkComplete() {
    if(checkStarted() && _isCompleted) return true;
    if(absoluteError(centeredPosition, game.stage.cursor.position) < 1){
      _isCompleted = true;
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
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered() && event.checkComplete()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("StartTurnEvent: Start turn $turn for $factionName");
    game.stage.activeFaction = game.stage.factionMap[factionName];
    await Future.delayed(const Duration(milliseconds: 1000));
    completeEvent();
    game.stage.activeFaction!.startTurn();
  }
}

class TakeTurnEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  TakeTurnEvent(this.factionName, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered() && event.checkComplete()));
    return observers;
  }
  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("TakeTurnEvent: Take ${game.stage.turn} for $factionName");
    game.stage.activeFaction!.takeTurn();
    completeEvent();
  }

}

class EndTurnEvent extends Event{
  static List<Event> observers = [];
  String factionName;
  EndTurnEvent(this.factionName, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered() && event.checkComplete()));
    return observers;
  }
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
    completeEvent();
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
    observers.removeWhere((event) => (event.checkTriggered() && event.checkComplete()));
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
    completeEvent();
  }
}

class DeathEvent extends Event {
  static List<Event> observers = [];
  final Unit unit;
  static void initialize(EventQueue eventQueue) {
    eventQueue.registerClassObserver<DamageEvent>((damageEvent) {
      if (damageEvent.unit.hp <= 0) {
        // Trigger DeathEvent
        var deathEvent = DeathEvent(damageEvent.unit);
        EventQueue eventQueue = damageEvent.findParent() as EventQueue;
        eventQueue.addEventBatchToHead([deathEvent]);
      }
    });
  }

  DeathEvent(this.unit, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered() && event.checkComplete()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    debugPrint("DeathEvent: ${unit.name} has died.");
    unit.die();
    completeEvent();
  }
}