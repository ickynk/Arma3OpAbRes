//==============================================================================
// initServer.sqf
//==============================================================================
// Server initialization - runs only on the server machine
// Sets up global variables, tasks, and server-side systems
//==============================================================================

//------------------------------------------------------------------------------
// Mission phase tracking
//------------------------------------------------------------------------------
missionPhase = 1;                        // Current phase: 1=Blackout, 2=Strikes, 3=Assault
publicVariable "missionPhase";

tanoukaPowerOn = true;                   // Island power state
publicVariable "tanoukaPowerOn";

//------------------------------------------------------------------------------
// Strike system configuration
//------------------------------------------------------------------------------
strikeBudgetMax = 10;                    // Total points available for strike package
strikeBudgetUsed = 0;                    // Points currently spent
strikeFinalized = false;                 // Whether strike package is locked in

// Strike plan array - each entry: ["AIR"|"NAVAL", [x,y,z], cost]
strikePlan = [];

publicVariable "strikeBudgetMax";
publicVariable "strikeBudgetUsed";
publicVariable "strikeFinalized";
publicVariable "strikePlan";

//------------------------------------------------------------------------------
// Load helicopter recorded tracks (for Phase 3 assault)
//------------------------------------------------------------------------------
call compileFinal preprocessFileLineNumbers "scripts\heliAssault\tracks.sqf";
publicVariable "TRACK_ASSAULT_2";
publicVariable "TRACK_ASSAULT_3";
publicVariable "TRACK_PLAYER_1";


//------------------------------------------------------------------------------
// Create mission tasks (BIS task system)
//------------------------------------------------------------------------------
[
  west,
  "tsk_blackout",
  ["Sabotage the coal plant to black out the island.", "BLACKOUT", ""],
  obj_powerPanel,
  "ASSIGNED",
  1,
  true
] call BIS_fnc_taskCreate;

[
  west,
  "tsk_strikes",
  ["Build a 10-point strike package (map clicks). Once finalized, strikes will occur at random intervals for the remainder of the mission.", "STRIKE PACKAGE", ""],
  [0,0,0],
  "CREATED",
  1,
  true
] call BIS_fnc_taskCreate;

[
  west,
  "tsk_arrest",
  ["Insert, breach the Tanouka compound, arrest the HVT, and extract by helicopter.", "HVT ARREST", ""],
  hvt_1,
  "CREATED",
  1,
  true
] call BIS_fnc_taskCreate;

//------------------------------------------------------------------------------
// Publish server functions for remote execution
//------------------------------------------------------------------------------
publicVariable "fnc_srvStrikePlan";
publicVariable "fnc_srvStrikeExecute";

//------------------------------------------------------------------------------
// Start server-side systems
//------------------------------------------------------------------------------
[] execVM "scripts\power.sqf";           // Island power management
[] execVM "scripts\hvt.sqf";             // HVT setup and arrest handler

//------------------------------------------------------------------------------
// PHASE 1: Server function - Trip power (blackout)
//------------------------------------------------------------------------------
fnc_srvTripPower = {
  if (!isServer) exitWith {};
  if (missionPhase != 1) exitWith {};

  tanoukaPowerOn = false;
  publicVariable "tanoukaPowerOn";

  ["tsk_blackout","SUCCEEDED"] call BIS_fnc_taskSetState;
  ["tsk_strikes","ASSIGNED"] call BIS_fnc_taskSetState;

  // Advance to Phase 2 + force respawn for role swap
  [2] call fnc_phaseAdvance;
};
publicVariable "fnc_srvTripPower";

//------------------------------------------------------------------------------
// PHASE 3: Assault state tracking
//------------------------------------------------------------------------------
assaultBegun = false;
publicVariable "assaultBegun";

// Load helicopter assault utilities
call compileFinal preprocessFileLineNumbers "scripts\heliAssault\utils.sqf";

//------------------------------------------------------------------------------
// PHASE 3: Server function - Begin carrier assault
//------------------------------------------------------------------------------
fnc_srvBeginCarrierAssault = {
  if (!isServer) exitWith {};
  if (assaultBegun) exitWith {};                            // Prevent duplicate launches
  if ((missionNamespace getVariable ["missionPhase", 1]) != 3) exitWith {};

  assaultBegun = true;
  publicVariable "assaultBegun";

  [] execVM "scripts\heliAssault\beginAssault.sqf";
};
publicVariable "fnc_srvBeginCarrierAssault";




