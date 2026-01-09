# Dyanomaze

<p align="center">
  <img src="assets/main.jpeg" width="450">
</p>

A 3D arcade survival game built with the Godot Engine. This project combines precision platforming with melee combat, challenging players to navigate a maze of dynamically shifting pillars. Their journey is hammered with enemy ghosts and a spooky environment with ambient spotlight.

## Key Features

- **Hybrid Camera System:** Real-time toggle between Top-Down (RPG-style movement) and First-Person (FPS-style strafing) modes to adapt to different challenges.
- **Dynamic Environment:** A "floor-is-lava" hazard system where the safe ground consists of pillars that launch up damaging the player.
- **Melee Combat:** Straightforward sword mechanics to clear ghost enemies that home towards the player.
- **Power ups:** Randomly scattered mugs that replish HP during traversal

<p align="center">
  <img src="assets/gameplay_loop.gif" width="450">
</p>

<p align="center">
  <img src="assets/FPS_gameplay_loop.gif" width="450">
</p>

## Controls

| Action | Input |

| **Move** | W, A, S, D |

| **Attack** | Left Click / Space |

| **Toggle View (FPS/TPS)** | V |

| **Unlock Mouse** | ESC |

## Technical Implementation

### Hybrid Movement Logic

I needed the controls to feel different depending on the camera.

- Top-Down: Movement is locked to world coordinates (North is always Up).
- FPS: Movement is relative to where you are looking. I used vector math to rotate the inputs so "Forward" always means "Forward for the camera," regardless of which way the character model is facing.
  The "Headless" Rendering Trick Using one character model for both views caused the camera to clip inside the face in FPS mode.
  The Fix: I wrote a script that loops through the skeleton's children. When you switch to FPS, it hides the Head mesh (setting it to "Shadows Only") but keeps the Body and Arms visible. This stops the clipping while keeping the game immersive.

### Fake FPS Arms

The third-person animations held the sword too low to be seen in First-Person view. Instead of making new animations, I used code to override the bone position.
Every frame, the script forces the sword’s BoneAttachment to move up and rotate towards the camera.
Added a simple "Lerp" (smoothing) to this movement, which created a natural-looking weapon sway without needing complex physics.

### Combat Timing

I didn't want players to deal damage just by standing next to enemies.
The Hitbox is turned on and off by the Animation Player itself. Damage only counts during the specific frames where the sword is swinging.
I also added a 0.2s blend time to movement animations so the character doesn't "snap" between running and stopping.

### Game Manager & Signals

I kept the Player logic separate from the Game logic.
A global GameManager singleton handles health, game over states, and difficulty settings.
The Player script just sends signals (like "I died" or "I won") and lets the Manager handle the rest. This makes it easy to restart the level without breaking the code.

## Installation

1.  Clone the repository:
    ```bash
    git clone [https://github.com/yourusername/dyanomaze.git](https://github.com/yourusername/dyanomaze.git)
    ```
2.  Open the `project.godot` file using Godot Engine 4.x.
3.  Ensure the input map is configured (if not imported automatically):
    - `change_view`: mapped to **V**
    - `jump`/`accept`: mapped to **Space**

- **Engine:** Godot 4.x

## Things left to do

1. Expand the territory and add border assets
2. Color the different pillars
3. Introduce different health modes
4. Add another level to the existing platform
5. Adding sound effects
