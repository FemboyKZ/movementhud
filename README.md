# MovementHUD

A versatile SourceMod plugin providing customizable displays for player movement.

FKZ fork of LoB fork. Some changes taken from [AXE fork](https://github.com/cinyan10/movementhud).

## **Installation**

1. Download the [latest release](https://github.com/FemboyKZ/movementhud/releases)
2. Extract all the files into `csgo`

> :warning: **If you are using KZTimer**: This doesn't work.

## **Differences** - LoB

- Is now fully integrated into GOKZ, no tracking module required.
- MHUD options in `!options` removed, however still available with !mhud as usual.
- Add first tick gain indicator (usually indicating W release and strafe key press at the same time).
- Fix MHUD key display wiggling around, especially with mouse display on for 1080p/1440p resolutions.
- Fix MHUD display taking over GOKZ's display, hiding features like race announcements.
- Better GOKZ replay bot integration.
- Add more color by speed options.
- Slightly increase display quality.

## **Differences** - AXE

- JB and PERF indicator colors.
- EB and Crouched indicators.
- Pref handling bugfix.

## **Differences** - FKZ

- Distance prediction for LJs based on [7yPh00N's plugin](https://github.com/7yPh00N/Distance_Prediction_Plugin)
