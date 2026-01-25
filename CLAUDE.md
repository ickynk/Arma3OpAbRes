# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Arma 3 multiplayer tactical mission "Operation Absolute Resolve" on Tanoa. Features a three-phase mission flow:
1. **Blackout** - Sabotage coal plant to disable island power
2. **Strike Planning** - Build 10-point airstrike package (AIR: 2pts, NAVAL: 1pt)
3. **Assault & Extraction** - Helicopter assault to arrest HVT while strikes execute randomly

## Development

No build system - SQF scripts run directly in Arma 3. Edit in Eden Mission Editor or text editor, test by launching mission locally or on server.

## Architecture

### File Organization
- `init.sqf` - Compiles all global functions (runs on all machines)
- `initServer.sqf` - Server initialization, mission state, task creation
- `initPlayerLocal.sqf` - Client initialization, player actions, respawn handling
- `functions/` - Core global functions (compiled at mission start)
- `scripts/` - Mission logic and subsystems

### Function Naming
- `fnc_srv*` - Server-side only functions
- `fnc_*` - Client/UI functions
- All compiled with `compileFinal preprocessFileLineNumbers` in `init.sqf`

### Key State Variables
- `missionPhase` (1/2/3) - Current phase
- `strikePlan` - Array of `[["AIR"|"NAVAL"|"DE", [x,y,z], cost], ...]`
- `strikeBudgetUsed` / `strikeBudgetMax` - Strike point economy
- `strikeFinalized` - Package locked
- `tanoukaPowerOn` - Island power state
- `hvtArrested` / `assaultBegun` - Phase 3 progression

### Multiplayer Patterns

Server-authoritative design. Common patterns:
```sqf
// Broadcast state
publicVariable "variableName";

// Client → Server RPC
[] remoteExecCall ["fnc_srvFunctionName", 2];

// Server → All Clients
[message] remoteExec ["hint", 0];
```

JIP-safe with `!isNil` checks and defaults set in init files.

### Action Menu Pattern
```sqf
_unit addAction [
  "<t color='#ff6666'>Label</t>",
  { /* callback */ },
  nil, priority, true, false, "",
  "CONDITION_STRING"  // Evaluated in mission namespace
];
```

### Task System
Uses BIS task framework:
```sqf
[side, taskId, briefing, taskObject, state, priority] call BIS_fnc_taskCreate;
[taskId, newState] call BIS_fnc_taskSetState;
```

## Key Subsystems

### Directed Energy Weapon (`scripts/directedEnergy/`)
Non-lethal incapacitation with 60% effectiveness rate. Disables AI for 60 seconds.

### Helicopter Assault (`scripts/heliAssault/`)
Multi-helicopter coordinated landing with 50m spacing offsets. Uses waypoint-based landing (more reliable than unitPlay tracks). ACE fast-rope support with vanilla fallback.

### Strike System (`functions/fn_srvStrike*.sqf`, `scripts/strikes.sqf`)
- AIR: 8 bombs, 2 points
- NAVAL: 16 shells, 1 point
- `strikeScheduler.sqf` executes random strikes every 1-5 seconds during Phase 3

## Conventions

- Functions have header comments documenting purpose, parameters, and execution context
- Server functions exit early with `if (!isServer) exitWith {}`
- Long-running logic uses `spawn` with `while/sleep` loops
- Eden Editor variable names documented in function headers
