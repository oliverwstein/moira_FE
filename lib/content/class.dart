
// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../engine/engine.dart';
// ignore: constant_identifier_names

class Class extends Component with HasGameRef<MyGame>{
  final String name;
  final String description;
  final int movementRange;
  final List<String> skills;
  final List<String> attacks;
  final List<String> proficiencies;
  final Map<String, int> baseStats;
  final Map<String, int> growths;

  // Factory constructor
  factory Class.fromJson(String name) {
    Map<String, dynamic> classData;

    // Check if the class exists in the map and retrieve its data
    if (MyGame.classMap['classes'].containsKey(name)) {
      classData = MyGame.classMap['classes'][name];
    } else {classData = {};}
    String description = classData['description'] ?? "An unknown foe";
    int movementRange = classData['movementRange'] ?? 6;
    List<String> skills = List<String>.from(classData['skills'] ?? []);
    List<String> attacks = List<String>.from(classData['attacks'] ?? []);
    List<String> proficiencies = List<String>.from(classData['proficiencies'] ?? []);
    Map<String, int> baseStats = Map<String, int>.from(classData['baseStats']);
    Map<String, int> growths = Map<String, int>.from(classData['growths']);
    
    // Return a new Weapon instance
    return Class._internal(name, description, movementRange, skills, attacks, proficiencies, baseStats, growths);
  }
  // Internal constructor for creating instances
  Class._internal(this.name, this.description, this.movementRange, this.skills, this.attacks, this.proficiencies, this.baseStats, this.growths);
}