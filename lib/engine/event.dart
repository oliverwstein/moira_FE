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
    final Queue<Event> _events = Queue<Event>();

    void addEvent(Event event) {
        _events.add(event);
    }

    void executeNext() {
        if (_events.isNotEmpty) {
            Event event = _events.removeFirst();
            event.execute();
        }
    }
}
EventQueue loadEventsFromJson(String jsonString) {
    var data = jsonDecode(jsonString);
    EventQueue queue = EventQueue();

    for (var eventData in data['events']) {
        Event event;

        switch (eventData['type']) {
            case 'UnitCreationEvent':
                break;
            case 'DialogueEvent':
                event = DialogueEvent([]);
                queue.addEvent(event);
                break;
        }        
    }
    return queue;
}

class UnitCreationEvent extends Event{
  final String name;
  final Point<int> gridCoord;
  int? level;
  List<String>? items;
  Point<int>? destination;
  late final Unit unit;
  

  UnitCreationEvent(this.name, this.gridCoord, {this.level, this.items, this.destination});

  @override
  Future<Unit> execute() async {
    dev.log("Create unit $name");
    unit = Unit.fromJSON(gridCoord, name, level: level, itemStrings: items);
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

