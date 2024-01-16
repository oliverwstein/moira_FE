import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:async/async.dart';
import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

abstract class Event extends Component with HasGameReference<MoiraGame>{
  Future<void> execute() async{}
  Future<void> checkComplete() async {}
}

mixin Observer {
    void onEvent(Event event);
}

class EventQueue extends Component with HasGameReference<MoiraGame>{
  final Queue<List<Event>> _events = Queue<List<Event>>();
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  List<Event> _currentBatch = [];

  void executeBatch(List<Event> batch) {
    FutureGroup futureGroup = FutureGroup();

    for (var event in batch) {
      game.stage.add(event);
      dev.log("Execute event $event");
      event.execute();
      futureGroup.add(event.checkComplete());
    }
    futureGroup.close();
    futureGroup.future.then((_) {
      _isProcessing = false;
      dev.log("All events in batch completed");
    });
  }

@override
void update(double dt) {
  super.update(dt);

  if (!_isProcessing && _events.isNotEmpty) {
    _isProcessing = true;
    _currentBatch = _events.removeFirst();
    executeBatch(_currentBatch);
  }
}
  void addEvent(Event event) {
      _events.add([event]);
  }
  void executeNext() {
      if (_events.isNotEmpty) {
          _currentBatch = _events.removeFirst();
          executeBatch(_currentBatch);
    }
  }
  
  void addBatch(List<Event> eventBatch) {
    _events.add(eventBatch);
  }
  void loadEventsFromJson(dynamic jsonData) {
    for (List<dynamic> eventBatch in jsonData) {
      // dev.log("$eventBatch");
      for (Map eventData in eventBatch){
        List<Event> eventBatch = [];
        switch (eventData['type']) {
            case 'UnitCreationEvent':
              String name = eventData['name'];
              String team = eventData['team'];
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
              eventBatch.add(UnitCreationEvent(name, tilePosition, level:level, teamString: team, items:itemStrings, destination: destination));
              break;
            case 'DialogueEvent':
              eventBatch.add(DialogueEvent([]));
              break;
        }
        addBatch(eventBatch);
      }  
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
  Future<void> execute() async {
    dev.log("Create unit $name");
    unit = Unit.fromJSON(tilePosition, name, level: level, teamString: teamString, itemStrings: items);
    game.stage.add(unit);
    if (destination != null) {
      var moveEvent = UnitMoveEvent(unit, destination!);
      moveEvent.execute();  // Start the move event but don't await it
      dev.log("Unit $name deployed to $destination");
    } else {
      destination = tilePosition;
    }
  dev.log("Unit $name Created");
  }
  @override
  Future<void> checkComplete() async {
    if (unit.tilePosition != destination){
      await Future.delayed(const Duration(seconds: 1));
      checkComplete();
    } 
  }
}

class UnitMoveEvent extends Event {
  final Point<int> tilePosition;
  final Unit unit;
  UnitMoveEvent(this.unit, this.tilePosition);

  @override
  Future<void> execute() async { // Make this method async
    dev.log("Event: Move unit ${unit.name}");
    unit.moveTo(tilePosition);
  }
}

class DialogueEvent extends Event {
    List<String> dialogueLines;

    DialogueEvent(this.dialogueLines);

    @override
    Future<void> execute() async {
        // Logic for handling dialogue
    }
}

