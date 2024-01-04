
import 'package:flame/components.dart';
import 'engine.dart';

class ItemType {
  final String name;

  const ItemType(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ItemType && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

// Define some static instances of ItemType that can be used globally
class ItemTypes {
  static const main = ItemType("main");
  static const side = ItemType("side");
  static const treasure = ItemType("treasure");
  static const gear = ItemType("gear");
}

enum Damage {
  charge(str: 1, dex: 0, mag: 0, wis: 0),
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

class Item extends Component {
  late String name;
  late ItemType type;
  late int might;
  late int hit;
  late (int, int) combatRange;
  late bool magic;
  late Damage damage;
  late List<ItemType> types;

  Item({
    required this.name,
    required this.type,
    required this.might,
    required this.hit,
    required this.combatRange,
    required this.magic,
    required this.damage,
    List<ItemType>? types,
  }) {
    this.types = types ?? [type];
  }
  Item.fromConfig(ItemConfig config)
      : this(
          name: config.name,
          type: config.type,
          might: config.might,
          hit: config.hit,
          combatRange: config.combatRange,
          magic: config.magic,
          damage: config.damage,
        );
}

class ItemConfig {
  final String name;
  final ItemType type;
  final int might;
  final int hit;
  final (int, int) combatRange;
  final bool magic;
  final Damage damage;

  const ItemConfig({
    required this.name,
    required this.type,
    required this.might,
    required this.hit,
    required this.combatRange,
    required this.magic,
    required this.damage,
  });
}

class Longsword extends Item {
  static const ItemConfig longswordDefaults = ItemConfig(
    name: "Longsword",
    type: ItemTypes.main, 
    might: 6,
    hit: 75,
    combatRange: (1, 1),
    magic: false,
    damage: Damage.slash,
  );

  Longsword() : super.fromConfig(longswordDefaults);
}

class WoodAxe extends Item {
  static const ItemConfig WoodAxeDefaults = ItemConfig(
    name: "Wood Axe",
    type: ItemTypes.main, 
    might: 6,
    hit: 75,
    combatRange: (1, 1),
    magic: false,
    damage: Damage.smash,
  );

  WoodAxe() : super.fromConfig(WoodAxeDefaults);
}