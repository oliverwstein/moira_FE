import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:moira/content/content.dart';

mixin UnitBehavior on PositionComponent {
  Point<int> get _tilePosition => (this as Unit).tilePosition;
  MoiraGame get game;
  Unit get unit => (this as Unit);

  List<Unit> getEnemiesInRange(){
    List<Unit> targets = [];
    
    return targets;
  }
}