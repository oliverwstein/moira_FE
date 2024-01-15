import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:moira/content/content.dart';

abstract class Event {
  void execute() {}
}

mixin Observer {
    void onEvent(Event event);
}

class EventQueue {
    Queue<Event> _events = Queue<Event>();

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
                // event = UnitCreationEvent();
                break;
            case 'DialogueEvent':
                // event = DialogueEvent();
                break;
            // Other cases
        }

        // queue.addEvent(event);
    }

    return queue;
}

class UnitCreationEvent extends Event {
    Unit unit;
    Point<int> startPosition;
    Point<int>? endPosition; // Optional

    UnitCreationEvent(this.unit, this.startPosition, {this.endPosition});

    @override
    void execute() {
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

