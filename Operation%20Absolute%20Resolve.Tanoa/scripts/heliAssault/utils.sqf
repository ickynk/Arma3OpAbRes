//==============================================================================
// scripts/heliAssault/utils.sqf
//==============================================================================
// Helicopter assault utility functions
// Provides helper functions for aircraft management
//
// Functions:
//   fnc_clearWaypoints - Remove all waypoints from a group
//   fnc_wakeAircraft - Prepare aircraft for flight (engine on, unhide, etc.)
//
// Called from: initServer.sqf, beginAssault.sqf
// Runs on: Server only
//==============================================================================

if (!isServer) exitWith {};

//------------------------------------------------------------------------------
// Function: Clear all waypoints from a group
//------------------------------------------------------------------------------
fnc_clearWaypoints = {
  params ["_grp"];
  { deleteWaypoint _x } forEach waypoints _grp;
};

//------------------------------------------------------------------------------
// Function: Wake up aircraft for flight
//------------------------------------------------------------------------------
fnc_wakeAircraft = {
  params ["_veh", ["_height", 70]];
  if (isNull _veh) exitWith {};

  _veh hideObjectGlobal false;
  _veh enableSimulationGlobal true;
  _veh engineOn true;
  _veh flyInHeight _height;

  // Nudge up slightly to avoid deck collision at rotor start
  private _p = getPosASL _veh;
  _veh setPosASL [_p#0, _p#1, (_p#2) + 1.5];
};
