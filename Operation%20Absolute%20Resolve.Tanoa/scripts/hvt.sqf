//==============================================================================
// scripts/hvt.sqf
//==============================================================================
// Server-side HVT (High Value Target) setup for Phase 3
// - Configures HVT behavior (won't flee, hard to kill)
// - Defines server function for arresting HVT
//
// Called from: initServer.sqf
// Runs on: Server only
//
// Required Eden object: hvt_1 (variable name of target unit)
//==============================================================================

if (!isServer) exitWith {};

// Configure HVT behavior
hvt_1 allowFleeing 0;
hvt_1 setCaptive true;

// Make HVT hard to accidentally kill (caps damage at 85%)
hvt_1 addEventHandler ["HandleDamage", {
  params ["_unit","","_damage"];
  _damage min 0.85
}];

//------------------------------------------------------------------------------
// Server function: Arrest HVT
//------------------------------------------------------------------------------
fnc_srvArrestHVT = {
  if (missionPhase != 3) exitWith {};
  if (hvtArrested) exitWith {};

  hvtArrested = true;
  publicVariable "hvtArrested";

  // Disarm and restrain HVT
  removeAllWeapons hvt_1;
  hvt_1 setCaptive true;
  hvt_1 setVariable ["ace_captives_isHandcuffed", true, true];
  hvt_1 playMoveNow "AmovPercMstpSsurWnonDnon";

  ["tsk_arrest","SUCCEEDED"] call BIS_fnc_taskSetState;

  // HVT is now ready for extraction
  // Players can use ACE Interaction to escort/drag and load into vehicle
};
publicVariable "fnc_srvArrestHVT";
