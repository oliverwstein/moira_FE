import 'dart:collection';
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