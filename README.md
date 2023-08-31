# ROBLOX Melee Combat & Movement System

This repository contains WIP scripts I created for a collaborative project in August 2021 that has since been abandoned. They are uploaded here for archival purposes and are free for reference / use in other projects.

## Features
* Health and Stamina
    * Regenerating health and stamina system
* Dash (Q) and Double Jump (Space)
    * Dash in any direction, providing invincibility but costing stamina
    * Double jump for extra height, costing stamina
* Knockback and Stun (for both players and enemies)
    * Knockback provides uninterruptable force away from the attacker
    * Stun locks the affected character out of moving, jumping, attacking and dodging
* Blocking (RClick)
    * Being attacked while blocking will deplete stamina, and if fully depleted will block-break, leaving the character vulnerable.
* Attack Combo System (LClick)
    * Attacking is a 4 move combo, which will be set back to the beginning if paused for too long.
    * Each move has set data determining:
        * timings
        * damage
        * range
        * effective angle
        * direction
        * immunity to stun during wind-up
        * whether the player can slide during the move by attacking and dashing at the same time.

## File Structure
Each file has a set of comments at the beginning determining a tree of its children in the original project and what types they were. If a Script or LocalScript had script children in the original project, a directory has been created with the same identifier as the parent, and the parent itself has been included within.

## Previews
![alt text](https://github.com/shmove/roblox-melee-movement-system/raw/main/fighting.gif "Fighting Preview")
![alt text](https://github.com/shmove/roblox-melee-movement-system/raw/main/blocking.gif "Blocking Preview")