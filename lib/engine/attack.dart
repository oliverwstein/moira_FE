import 'package:flame/components.dart';

import 'engine.dart';
enum Damage {
  trample(str: 1, dex: 0, mag: 0, wis: 0),
  strike(str: .5, dex: .5, mag: 0, wis: 0),
  slash(str: 1.5, dex: .5, mag: 0, wis: 0),
  stab(str: .5, dex: 1, mag: 0, wis: 0),
  smash(str: 2, dex: 0, mag: 0, wis: 0),
  pierce(str: 2, dex: 2, mag: 0, wis: 0),
  blast(str: 0, dex: 0, mag: 1.5, wis: .5),
  smite(str: 0, dex: 0, mag: .5, wis: 1),
  hex(str: 0, dex: 0, mag: 1, wis: 1);

  const Damage({
    required this.str,
    required this.dex,
    required this.mag,
    required this.wis
  });

  final double str;
  final double dex;
  final double mag;
  final double wis;
}

class Attack extends Component {
  /// Each attack has a base amount of might and 
  /// plus one (or more) type of stat scaling
  /// which add a multiple of those stats to might.
  /// Each attack also has a fatigue cost and a damage type,
  /// which is either physical or magical, 
  /// which determines the stat (def or res) that reduces the damage.
  /// as well as the stat that determines accuracy (dex or wis)
  String name;
  int might;
  int hit;
  int fatigue;
  (int, int) combatRange;
  bool magic;
  List<Damage> damages;
  Attack(this.name, this.might, this.hit, this.fatigue, this.combatRange, this.magic, this.damages);
}

