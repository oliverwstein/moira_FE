import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

abstract class Event {
  void execute() {}
}

mixin Observer {
    void onEvent(Event event);
}

class EventQueue {
  final Queue<List<Event>> _events = Queue<List<Event>>();

  void addEvent(Event event) {
      _events.add([event]);
  }

  void executeNext() {
      if (_events.isNotEmpty) {
          List<Event> eventBatch = _events.removeFirst();
          for (Event event in eventBatch) {event.execute();}
      }
  }
  
  void addBatch(List<Event> eventBatch) {
    _events.add(eventBatch);
  }
}

EventQueue loadEventsFromJson(String jsonString) {
  var data = jsonDecode(jsonString);
  EventQueue queue = EventQueue();

  for (List<dynamic> eventBatchList in data['events']) {
    for (Map eventData in eventBatchList){
      List<Event> eventBatch = [];
      switch (eventData['type']) {
          case 'UnitCreationEvent':
            String name = eventData['name'];
            String team = eventData['team'];
            Point<int> gridCoord = Point(eventData['gridCoord'][0], eventData['gridCoord'][1]);
            int level = eventData['level'];
            List<String> itemStrings = eventData['items'];
            eventBatch.add(UnitCreationEvent(name, gridCoord, level:level, teamString: team, items:itemStrings));
            break;
          case 'DialogueEvent':
            eventBatch.add(DialogueEvent([]));
            break;
      }
      queue.addBatch(eventBatch);
    }
          
  }
  return queue;
}

class UnitCreationEvent extends Event{
  final String name;
  final String? teamString;
  final Point<int> gridCoord;
  int? level;
  List<String>? items;
  Point<int>? destination;
  late final Unit unit;
  

  UnitCreationEvent(this.name, this.gridCoord, {this.level, this.teamString, this.items, this.destination});

  @override
  Future<Unit> execute() async {
    dev.log("Create unit $name");
    unit = Unit.fromJSON(gridCoord, name, level: level, teamString: teamString, itemStrings: items);
    // Wait for unit's onLoad to complete
    await unit.loadCompleted;
    return unit;
  }
}

class DialogueEvent extends Event {
    List<String> dialogueLines;

    DialogueEvent(this.dialogueLines);

    @override
    void execute() {
        // Logic for handling dialogue
    }
}

