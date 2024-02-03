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
  triggerEvent() {
    trigger = null;}
  startEvent() {
    _isStarted = true;}
  completeEvent() {
    _isCompleted = true;}
  bool checkTriggered(){return (trigger == null);}
  bool checkStarted(){return _isStarted;}
  bool checkComplete(){return _isCompleted;}
  Event({this.trigger, this.name});
  void execute(){
    _isStarted = true;
  }
  static List getObserversByClassName(String eventClassName){
    // UPDATE THIS WHENEVER YOU CREATE A NEW EVENT CLASS
    switch (eventClassName) {
    case 'UnitCreationEvent':
      return UnitCreationEvent.observers;
    case 'UnitMoveEvent':
      return UnitMoveEvent.observers;
    case 'UnitExhaustEvent':
      return UnitExhaustEvent.observers;
    case 'UnitDeathEvent':
      return UnitDeathEvent.observers;
    case 'UnitExitEvent':
      return UnitExitEvent.observers;
    case 'UnitOrderEvent':
      return UnitOrderEvent.observers;
    case 'UnitActionEvent':
      return UnitActionEvent.observers;
    case 'StartCombatEvent':
      return StartCombatEvent.observers;
    case 'CombatRoundEvent':
      return CombatRoundEvent.observers;
    case 'EndCombatEvent':
      return EndCombatEvent.observers;
    case 'AttackEvent':
      return AttackEvent.observers;
    case 'HitEvent':
      return HitEvent.observers;
    case 'MissEvent':
      return MissEvent.observers;
    case 'CritEvent':
      return CritEvent.observers;
    case 'DamageEvent':
      return DamageEvent.observers;
    case 'StartTurnEvent':
      return StartTurnEvent.observers;
    case 'TakeTurnEvent':
      return TakeTurnEvent.observers;
    case 'EndTurnEvent':
      return EndTurnEvent.observers;
    case 'FactionCreationEvent':
      return FactionCreationEvent.observers;
    case 'VisitEvent':
      return VisitEvent.observers;
    case 'RansackEvent':
      return RansackEvent.observers;
    case 'BesiegeEvent':
      return BesiegeEvent.observers;
    case 'SeizeEvent':
      return SeizeEvent.observers;
    case 'DialogueEvent':
      return DialogueEvent.observers;
    case 'PanEvent':
      return PanEvent.observers;
    case 'VantageEvent':
      return VantageEvent.observers;
    case 'CantoEvent':
      return CantoEvent.observers;
    default:
      return [];
    }
  }

  List<Event> getObservers();

  @override 
  void update(double dt) {
    if(!checkTriggered()) return;
    if(!_isStarted) {
      execute();
      return;
      }
    if(checkComplete()) {
      game.eventQueue.addEventBatch(dispatch());
      removeFromParent();
      }
  }

  List<Event> dispatch() {
    List<Event> batch = [];
    for (var observer in getObservers()) {
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
  bool processing = false;
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
    children.register<CombatRoundEvent>();
  }

  void addEventBatch(List<Event> eventBatch) {
    if(eventBatch.isNotEmpty) eventBatches.add(eventBatch);
  }
  void addEventBatchToHead(List<Event> eventBatch) {
    if(eventBatch.isNotEmpty) eventBatches.addFirst(eventBatch);
  }

  List<Event> currentBatch() {
    return children.query<Event>().where((event) => event.checkTriggered()).toList();
  }

  @override
  void update(double dt) {
    if(currentBatch().isEmpty){
      if(eventBatches.isNotEmpty){
        eventBatches.removeFirst().forEach(add);
        processing = true;
      } else {
        processing = false;
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
            List<String>? orderStrings;
            if (eventData['orders'] != null) {
              orderStrings = List<String>.from(eventData['orders']);
            }
            event = UnitCreationEvent(name, tilePosition, factionName, level:level, items:itemStrings, orders: orderStrings, destination: destination, name: eventName);
            break;
          case 'UnitMoveEvent':
            String unitName = eventData['unitName'];
            Point<int> destination = Point(eventData['destination'][0], eventData['destination'][1]);
            double speed = eventData['speed'] ?? 2;
            bool chainCamera = eventData['chainCamera'] ?? false;
            event = UnitMoveEvent.named(unitName, destination, speed: speed, chainCamera: chainCamera);
            break;
          case 'UnitExitEvent':
            String unitName = eventData['unitName'];
            event = UnitExitEvent.named(unitName);
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
            double speed = eventData['speed'] ?? 300;
            event = PanEvent(destination, name: eventName, speed: speed);
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
          case 'BesiegeEvent':
            String castleName = eventData['castle'];
            bool duel = eventData['duel'] ?? false;
            CastleGate? gate = CastleGate.getCastleByName(game, castleName);
            assert(gate != null);
            event = BesiegeEvent(gate!, duel: duel);
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

class PanEvent extends Event {
  static List<Event> observers = [];
  final Point<int> destination;
  late final Vector2 destinationPosition;
  double speed;
  PanEvent(this.destination, {Trigger? trigger, String? name, this.speed = 300}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }
  @override
  void execute() {
    super.execute();
    debugPrint("PanEvent: Pan to $destination");
    game.stage.cursor.snapToTile(destination);
    destinationPosition = game.stage.cursor.centerCameraOn(destination, speed);
  }
  @override
  bool checkComplete() {
    if(checkStarted() && _isCompleted) {
      game.eventQueue.dispatchEvent(this);
      return true;}
    if(absoluteError(game.camera.viewfinder.position, destinationPosition) < 1){
      game.eventQueue.dispatchEvent(this);
      _isCompleted = true;
      return true;
    }
    return false;
  } 
}