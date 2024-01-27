import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

enum Skill {canto, pavise, vantage}

class VantageEvent extends Event {
  static List<Event> observers = [];
  final Combat combat;
  static void initialize(EventQueue eventQueue) {
    eventQueue.registerClassObserver<StartCombatEvent>((combatEvent) {
      if (combatEvent.combat.defender.hasSkill(Skill.vantage)) {
        VantageEvent vantageEvent = VantageEvent(combatEvent.combat);
        EventQueue eventQueue = combatEvent.game.eventQueue;
        eventQueue.addEventBatchToHead([vantageEvent]);
      }
    });
  }
  
  VantageEvent(this.combat, {Trigger? trigger, String? name}) : super(trigger: trigger, name: name);
  @override
  List<Event> getObservers() {
    observers.removeWhere((event) => (event.checkTriggered()));
    return observers;
  }

  @override
  Future<void> execute() async {
    super.execute();
    Unit temp = combat.attacker;
    combat.attacker = combat.defender;
    combat.defender = temp;
    completeEvent();
    game.eventQueue.dispatchEvent(this);
  }
}