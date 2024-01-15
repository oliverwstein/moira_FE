import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

abstract class Event extends Component with HasGameReference<MoiraGame>{
  bool _isStarted = false;
  bool _isCompleted = false;
  bool checkStarted(){return _isStarted;}
  bool checkComplete(){return _isCompleted;}
  void execute() {}
}

mixin Observer {
    void onEvent(Event event);
}

class EventQueue extends Component with HasGameReference<MoiraGame>{
  final Queue<List<Event>> _events = Queue<List<Event>>();
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  List<Event> _currentBatch = [];

  @override
  void update(double dt) {
    if (_isProcessing) {
      if (_currentBatch.every((event) => event.checkComplete())){
        // If the batch elements have all been completed, clear the batch
        // and allow EventQueue to go on to the next batch.
        _isProcessing = false;
        _currentBatch.clear();
      } else {
        List<Event> batch = [];
        for (Event event in _currentBatch){if (!event.checkStarted()) batch.add(event);}
        executeBatch(batch);}
    }
    if (!_isProcessing && _events.isNotEmpty) {
      // Pop the next batch waiting in the queue as the current batch
      _currentBatch = _events.removeFirst();
      // Execute all events in the current batch simultaneously
      executeBatch(_currentBatch); 
      _isProcessing = true;
    }
  }
  void addEvent(Event event) {
      _events.add([event]);
  }
  void executeBatch(List<Event> batch) {
    // Execute each event in the current batch
    for (var event in batch) {
      game.stage.add(event);
      dev.log("Execute event $event");
      event.execute();
    }
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
  Future<Unit> execute() async {
    _isStarted = true;
    dev.log("Create unit $name");
    unit = Unit.fromJSON(tilePosition, name, level: level, teamString: teamString, itemStrings: items);
    game.stage.add(unit);
    // Wait for unit's onLoad to complete
    await unit.loadCompleted;
    if(destination != null){
      var moveEvent = UnitMoveEvent(unit, destination!);
      await moveEvent.execute();
      while (!moveEvent.checkComplete()) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      dev.log("Unit $name deployed to $destination");
    } 
    _isCompleted = true;
    dev.log("Unit $name Created");
    
    return unit;
  }
}

class UnitMoveEvent extends Event {
  final Point<int> tilePosition;
  final Unit unit;
  UnitMoveEvent(this.unit, this.tilePosition);

  @override
  Future<void> execute() async { // Make this method async
    _isStarted = true;
    dev.log("Event: Move unit ${unit.name}");
    unit.moveTo(tilePosition);

    _isCompleted = true;
    
  }
  @override
  bool checkComplete() {
    dev.log("${unit.tilePosition}, == $tilePosition && $_isStarted)}");
    return (unit.tilePosition == tilePosition && _isStarted);
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

