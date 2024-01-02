# moira-FE

## Overview
This Dart/Flutter application is designed to run a Fire Emblem-like tactical RPG game, leveraging the Flame game engine for structure and rendering. The game features a grid-based map where units move and interact through various commands. The core classes interact to manage game state, render sprites, and handle user input.

## Key Components

### MyGame
- Extends Flame's `Game` class.
- Central game loop and state manager.
- Handles the rendering cycle and user input.

### Stage
- Manages the game map including tiles and unit positions.
- Holds reference to `Cursor` and other interactive elements like units.
- Orchestrates game state changes based on user interaction and game rules.

### Cursor
- Manages the user's cursor on the map.
- Interacts with tiles and units, opening menus and selecting units.
- Can move around the map and trigger different actions.

### Unit
- Represents a character or entity on the map.
- Holds stats, position, and can interact with the map (move, attack, etc.).
- Has animations and state management for different actions.

### Tile
- Represents a single square on the grid map.
- Holds terrain information and whether it's occupied by a unit.

### BattleMenu
- A UI component that appears when interacting with units or specific map tiles.
- Provides options like Move, Attack, etc.

### Direction (enum)
- Represents possible movement directions (up, down, left, right).

### Terrain (enum)
- Represents different types of terrain (forest, path, cliff, water, neutral).
- Each terrain type affects unit movement differently.

## Interactions

- **User Input**: Handled through `MyGame` and propagated to active components like `Cursor` or `Unit`.
- **Rendering Cycle**: Managed by Flame's game loop, rendering sprites and UI elements based on state.
- **Movement and Actions**: Units move on the grid, interact with tiles, and change state based on user commands and game rules.

## For LLM Contextual Understanding

### Data Flow
- User commands are processed through `MyGame` and dispatched to components like `Cursor` or `Unit` based on the game state. Units and Cursors manipulate the `Stage` which in turn updates the game's visual and logical representation.

### State Management
- The game's state is a combination of the individual states of tiles, units, and the overall stage. Changes in the state are triggered by user actions and game logic, leading to visual updates and potentially game state transitions.

### Modularity and Expansion
- New features like additional units, terrain types, or rules can be added by extending existing classes or adding new subclasses. The game's architecture is designed to be modular to facilitate easy expansion and modification.

## Compressed Information for LLM

- **Classes and Methods**: Each class and method has a distinct purpose tied to game mechanics, rendering, or user interaction. Understanding the relationships between these components is crucial for modifying or extending functionality.
- **Game Loop and Rendering**: Central to understanding any modifications or debugging is how the game loop interacts with rendering and state management. This affects performance, user experience, and the implementation of new features.
- **State Dependency**: Many actions in the game are dependent on the current state of units, tiles, or the overall game. Any changes to state management need to be carefully considered to avoid breaking game logic or causing unexpected behavior.

