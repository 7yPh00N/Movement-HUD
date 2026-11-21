# Installation

1. Extract the `cstrike` folder from the ZIP file to your game's root directory (normally: `\Half-Life\`)

2. Open the `plugins.ini` file (located in: `\cstrike\addons\amxmodx\configs\`)

3. Add the following 4 lines to the file:

- `mhud_menu.amxx`

- `mhud_speed.amxx`

- `input_overlay.amxx`

- `distance_prediction.amxx`
  
4. Save the file and restart your game

# Commands

## General

- `/mhud` - Open Plugin Settings Menu

## MHUD Speed

- `/mspeed` - Enable/Disable MHUD Speed

- `/mspeeds` - Open MHUD Speed Settings Menu

## Input Overlay

- `/mkey` - Enable/Disable Input Overlay

- `/mkeys` - Open Input Overlay Settings Menu

## Distance Prediction

- `/dp` `/distpred` - Enable/Disable Distance Prediction

- `/dps` - Open Distance Prediction Settings Menu

- `/sonar` - Enable/Disable Sonar

- `/rtpredhud` - Enable/Disable Real-Time Prediction HUD

- `/bestpredhud` - Enable/Disable Best Predicted Distance HUD

- `/landingpred` - Enable/Disable Landing Area Prediction

- `/ljpred` - Long Jump

- `/hjpred` - High Jump

- `/cjpred` - Count Jump

- `/scjpred` - Stand-Up Count Jump

- `/dcjpred` - Double Count Jump

- `/mcjpred` - Multi Count Jump

- `/wjpred` - Weird Jump

- `/sbjpred` - Stand-Up Bhop Jump

- `/bjpred` - Bhop Jump

- `/ldjpred` - Ladder Jump

- `/dpmethod` `/expected` - Switch the prediction method between Predicted and Expected (also item 8 in `/dps`)

# Expected distance (this fork)

The original prediction ("Predicted") assumes you stop strafing right now and fly straight on at your current velocity. This fork adds a second method, **Expected**, which assumes you keep strafing the way you have so far in this jump:

- **Gain rate** `c = (s² − s0²) / air time`, where `s0` is the takeoff speed and `s` the current horizontal speed.
- **Efficiency** `η = a / path`: the straight distance from takeoff divided by the path actually flown.

`Expected = a + (1 − loss) · L+ + 32`
