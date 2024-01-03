// ignore_for_file: unnecessary_overrides
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

import 'engine.dart';
class BattleMenu extends PositionComponent with HasGameRef<MyGame>, HasVisibility implements CommandHandler {
  /// BattleMenu is a component that represents the in-game menu for actions such as attack, move, etc.
  /// It extends PositionComponent and implements CommandHandler for handling keyboard inputs,
  /// along with HasVisibility for managing its visibility state.
  ///
  /// Attributes:
  /// - `menuSprite`: The visual representation of the menu.
  /// - `pointer`: AnimatedPointer object that indicates the current selection in the menu.
  ///
  /// Methods:
  /// - `handleCommand(command)`: Handles command inputs to navigate the menu or trigger actions.
  /// - `select()`: Handles the action of selecting a menu item, toggling menu visibility, and setting the active component.
  /// - `onLoad()`: Asynchronously loads resources necessary for the BattleMenu and initializes its components.
  /// - `toggleVisibility()`: Toggles the visibility of the BattleMenu.
  /// - `render(canvas)`: Renders the BattleMenu to the provided canvas, only if it's visible.
  ///
  /// Constructor:
  /// Initializes the BattleMenu component, setting up its visibility and subcomponents.
  ///
  /// Usage:
  /// The BattleMenu is used to display a list of actions that a player can take during their turn,
  /// such as moving units or attacking. It's typically brought up when a unit is selected and provides
  /// the means to choose what action to take next.
  ///
  /// Connects with:
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
  /// - AnimatedPointer: Utilizes AnimatedPointer to indicate the current selection within the menu.
  /// - Stage: Interacts with Stage to control game flow, toggling active components based on menu selection.

  late final SpriteComponent menuSprite;
  late final AnimatedPointer pointer;

  @override
  bool handleCommand(LogicalKeyboardKey command) {
    bool handled = false;
    if (command == LogicalKeyboardKey.arrowUp) {
      pointer.moveUp();
      handled = true;
    } else if (command == LogicalKeyboardKey.arrowDown) {
      pointer.moveDown();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyA) {
      select();
      handled = true;
    } else if (command == LogicalKeyboardKey.keyB || command == LogicalKeyboardKey.keyM) {
      select();
      handled = true;
    }
    return handled;
  }

  void select(){
    Stage stage = parent!.parent as Stage;
    switch (pointer.currentIndex) {
      case 0: // unit
        break;
      case 1: // items
        break;
      case 2: // status
        break;
      case 3: // skills
        break;
      case 4: // options
        break;
      case 5: // save game
        break;
      case 6: // end turn
        stage.endTurn();
    }
    
    stage.activeComponent = stage.cursor;
    toggleVisibility();
  }

  @override
  Future<void> onLoad() async {
    // Load and position the menu sprite
    menuSprite = SpriteComponent(
        sprite: await gameRef.loadSprite('action_menu.png'),
    );
    add(menuSprite);

    // Create and position the pointer
    pointer = AnimatedPointer();
    add(pointer);
    isVisible = false;
  }

  void toggleVisibility() {
    isVisible = !isVisible;
    // Additional logic to show/hide or enable/disable
  }

  @override
  void render(ui.Canvas canvas) {
    if (isVisible) {
      
      super.render(canvas);  // Render only if menu is visible
    }
  }
}

class AnimatedPointer extends PositionComponent with HasGameRef<MyGame> {
  /// AnimatedPointer is a component that represents the selection pointer in the BattleMenu,
  /// highlighting the current option selected by the player. It extends PositionComponent
  /// and is used within the BattleMenu to navigate between different options.
  ///
  /// Attributes:
  /// - `_animationComponent`: Component for rendering pointer animations.
  /// - `pointerSheet`: SpriteSheet for pointer animations.
  /// - `stepY`: The vertical distance between menu items, used to move the pointer up and down.
  /// - `currentIndex`: The index of the current menu item selected.
  /// - `tileSize`: Size of the pointer in pixels, can be adjusted with the game's scale factor.
  ///
  /// Methods:
  /// - `onLoad()`: Asynchronously loads resources necessary for the AnimatedPointer, such as animations.
  /// - `moveUp()`: Moves the pointer up in the menu, decreasing the currentIndex.
  /// - `moveDown()`: Moves the pointer down in the menu, increasing the currentIndex.
  /// - `updatePosition()`: Updates the position of the pointer based on the currentIndex.
  ///
  /// Constructor:
  /// Initializes the AnimatedPointer with a default size and index.
  ///
  /// Usage:
  /// The AnimatedPointer is used within the BattleMenu to visually indicate the current selection.
  /// It moves up and down as the player navigates the menu options, providing feedback on the current choice.
  ///
  /// Connects with:
  /// - BattleMenu: AnimatedPointer is a subcomponent of BattleMenu, indicating the current menu selection.
  /// - MyGame: Inherits properties and methods from HasGameRef<MyGame> for game reference.
  late final SpriteAnimationComponent _animationComponent;
  late final SpriteSheet pointerSheet;

  // Adjust these based on your menu layout
  final double stepY = 16; // The vertical distance between menu items
  int currentIndex = 0;   // The index of the current menu item

  late double tileSize;

  AnimatedPointer() {
    // Initial size, will be updated in onLoad
    tileSize = 16;
  }
  @override
  Future<void> onLoad() async {
    // Load the cursor image and create the animation component
    ui.Image pointerImage = await gameRef.images.load('selection_pointer.png');
    pointerSheet = SpriteSheet.fromColumnsAndRows(
      image: pointerImage,
      columns: 3,
      rows: 1,
    );

    _animationComponent = SpriteAnimationComponent(
      animation: pointerSheet.createAnimation(row: 0, stepTime: .2),
      size: Vector2.all(tileSize), // Use tileSize for initial size
    );

    add(_animationComponent);

    // Set the initial size and position of the cursor
    size = Vector2.all(tileSize);
  }

  void moveUp() {
    if (currentIndex > 0) {
      currentIndex--;
      updatePosition();
    } else {
      currentIndex = 6;
      updatePosition();
    }
  }

  void moveDown() {
    if (currentIndex < 6) {
      currentIndex++;
      updatePosition();
    } else {
      currentIndex = 0;
      updatePosition();
    }
  }

  void updatePosition() {
    // Update the position of the pointer based on the current index
    y = 5 + stepY * currentIndex;
  }
}
