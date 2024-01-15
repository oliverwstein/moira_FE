import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

abstract class Event extends Component with HasGameReference<MoiraGame>{
  void execute() {}
}

mixin Observer {
    void onEvent(Event event);
}

class EventQueue extends Component with HasGameReference<MoiraGame>{
  final Queue<List<Event>> _events = Queue<List<Event>>();

  void addEvent(Event event) {
      _events.add([event]);
  }

  void executeNext() {
      if (_events.isNotEmpty) {
          List<Event> eventBatch = _events.removeFirst();
          for (Event event in eventBatch) {
            game.world.add(event);
            event.execute();}
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
        dev.log("$eventData");
        switch (eventData['type']) {
            case 'UnitCreationEvent':
              String name = eventData['name'];
              String team = eventData['team'];
              Point<int> gridCoord = Point(eventData['gridCoord'][0], eventData['gridCoord'][1]);
              int? level = eventData['level'];
              List<String>? itemStrings;
              dev.log("${eventData['items']}");
              if (eventData['items'] != null) {
                itemStrings = List<String>.from(eventData['items']);
              }
              eventBatch.add(UnitCreationEvent(name, gridCoord, level:level, teamString: team, items:itemStrings));
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
    game.world.add(unit);
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

