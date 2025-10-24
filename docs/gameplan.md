# Project Overview

Game Type: 2D tactical strategy, chess-like mechanics but with battlefield dynamics.

Goal: Capture opponent’s home base while growing and managing your army.


## Core Features (MVP):
- Map with squares/territories (grid-based).
- Player and AI each have a home base.
- A few types of units (fighters) with distinct abilities.
- Units grow stronger the longer they survive/fight.
- Units generate more fighters when holding a square long enough.
- Multi-move per turn (max 3 moves per unit for now).
- AI reacts to player moves (turn-based decision-making, not real-time).
- Army stats tracked: strength, distribution, past moves.
- Game ends when home base is captured.


## Mechanics Summary
- Unit movement: 1-3 squares per turn. Can attack enemy units in adjacent squares.
- Combat: Strength of attacker vs. defender. Bonuses if backed up by allied units.
- Growth: Holding territory spawns new units over time.
- Unit leveling: Units gain experience when surviving attacks.
- AI:
    - Analyzes player moves each turn.
    - Chooses counter-moves (attack, defend, flank, reinforce).
    - Tracks player style (weak points, strategies, patterns).
    - Scales strength relative to player (70–130% range for balance).


## AI Approach for MVP
Simplified version for 48h:

- Turn-based AI (reacts after player moves).
- Rule-based + scoring:
    - Assign score to each move (attack, defend, reinforce).
    - Pick the move with highest score.

- Track simple metrics:
    - Player’s strong/weak squares.
    - Most used strategies.
    - Balance AI strength dynamically: AI units = player units × 1.1 (or scale factor).
- Optional stretch: Add “flanking” or “support” logic if time allows.


## 48h MVP Development Plan
Day 0–0.5 (Setup & Planning)
- Set up project structure (Unity/Pygame).
- Create basic grid map.
- Define unit classes and attributes (strength, movement, level).
- Draw placeholders for units/tiles (no polished art needed).

Day 0.5–1.5 (Core Mechanics)
- Implement player input & movement.
- Combat mechanics: attack, defend, flanking bonus.
- Home base and win/loss condition.
- Territory control and unit spawn over time.

Day 1.5–2 (AI & Game Loop)
- Implement turn-based AI:
    - Evaluate player moves.
    - Make best move per turn (rule-based scoring).
    - Adjust AI army size relative to player.
- Track player behavior (simple stats: where attacks, weak points).
- Multi-move mechanics for units.
- Test for balancing (ensure AI is challenging but winnable).

Optional Stretch Features
- Unit leveling/experience system.
- AI flanking/support logic.
- Small tactical hints/analysis post-match (not advisor mode).
- More unit types or special abilities.

Deliverables for 48h Hackathon
1. Playable MVP:
    - Player vs. AI on 2D grid map.
    - Turn-based combat, multi-move units, home base mechanics.
    - AI analyzes player moves and scales difficulty.
2. Core Mechanics Document:
    - Grid map rules, unit types, combat rules.
    - AI decision logic (how moves are scored and chosen).
3. Post-Match Stats:
    - Simple player strategy tracking (optional for MVP, stretch for hackathon).

Key Notes
- MVP focus: Playable game with AI that adapts and challenges the player.
- Time management: Skip advanced AI learning (RL, deep stats) for hackathon; do rule-based scoring.
- Polish later: Visuals, animations, extra AI strategy layers.
- Your goal: Make it challenging, winnable, and tactical.