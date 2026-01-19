missionPhase = 1; publicVariable "missionPhase";
tanoukaPowerOn = true; publicVariable "tanoukaPowerOn";

strikeBudgetMax = 10;
strikeBudgetUsed = 0;
strikeFinalized = false;

// Each entry: ["AIR"|"NAVAL", [x,y,z], cost]
strikePlan = [];

publicVariable "strikeBudgetMax";
publicVariable "strikeBudgetUsed";
publicVariable "strikeFinalized";
publicVariable "strikePlan";
call compileFinal preprocessFileLineNumbers "scripts\heliAssault\tracks.sqf";
publicVariable "TRACK_ASSAULT_2";
publicVariable "TRACK_ASSAULT_3";
publicVariable "TRACK_PLAYER_1";


// Tasks
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

// Server functions
publicVariable "fnc_srvStrikePlan";
publicVariable "fnc_srvStrikeExecute";

// Systems
[] execVM "scripts\power.sqf";
[] execVM "scripts\hvt.sqf";

fnc_srvTripPower = {
  if (!isServer) exitWith {};
  if (missionPhase != 1) exitWith {};

  tanoukaPowerOn = false; publicVariable "tanoukaPowerOn";

  ["tsk_blackout","SUCCEEDED"] call BIS_fnc_taskSetState;
  ["tsk_strikes","ASSIGNED"] call BIS_fnc_taskSetState;

  // Move into Phase 2 + role swap (respawn)
  [2] call fnc_phaseAdvance;
};
publicVariable "fnc_srvTripPower";

assaultBegun = false;
publicVariable "assaultBegun";

// Compile/Load helicopter assault utilities & functions
call compileFinal preprocessFileLineNumbers "scripts\heliAssault\utils.sqf";

// Server entry point: begin assault
fnc_srvBeginCarrierAssault = {
  if (!isServer) exitWith {};
  if (assaultBegun) exitWith {};
  if ((missionNamespace getVariable ["missionPhase", 1]) != 3) exitWith {};

  assaultBegun = true;
  publicVariable "assaultBegun";

  [] execVM "scripts\heliAssault\beginAssault.sqf";
};
publicVariable "fnc_srvBeginCarrierAssault";




