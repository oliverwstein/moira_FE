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
  final MoiraGame game;
  final String name;
  final Point<int> gridCoord;
  int? level;
  late final Unit unit;
  Point<int>? destination;

  UnitCreationEvent(this.game, this.name, this.gridCoord, {this.level, this.destination});

  @override
  Future<Unit> execute() async {
    dev.log("Create unit $name");
    unit = level != null ? Unit.fromJSON(gridCoord, name, level: level) : Unit.fromJSON(gridCoord, name);
    game.stage.add(unit);
    game.stage.tileMap[gridCoord]!.setUnit(unit);

    // Wait for unit's onLoad to complete
    await unit.loadCompleted;

    // Mark as completed once the unit has finished being created.
    _isCompleted = true;
    // Move the unit to its destination
    if(destination != gridCoord) {
      game.eventQueue.currentBatch().add(UnitMoveEvent(game, unit, destination));
      game.eventQueue.currentBatch().remove(this);
    }
    
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

