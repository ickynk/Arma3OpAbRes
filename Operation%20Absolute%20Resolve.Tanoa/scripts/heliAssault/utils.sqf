//==============================================================================
// scripts/heliAssault/utils.sqf
//==============================================================================
// Helicopter assault utility functions
// Provides helper functions for LZ slot calculation and aircraft management
//
// Functions:
//   fnc_getLZSlots - Calculate spread positions around an LZ
//   fnc_clearWaypoints - Remove all waypoints from a group
//   fnc_wakeAircraft - Prepare aircraft for flight (engine on, unhide, etc.)
//
// Called from: initServer.sqf, beginAssault.sqf
// Runs on: Server only
//==============================================================================

if (!isServer) exitWith {};

//------------------------------------------------------------------------------
// Function: Get LZ slot positions
// Returns an array of world positions around the LZ for each helicopter
//------------------------------------------------------------------------------
fnc_getLZSlots = {
  params ["_lzPos", "_count", ["_spacing", 70]];

  // Predefined offsets for 2-4 helicopters (meters)
  private _slots = [
    [  0,   0, 0],
    [ _spacing,  40, 0],
    [-_spacing,  40, 0],
    [  0, _spacing + 20, 0]
  ];

  // If more helicopters than slots, arrange them in a circle
  if (_count > count _slots) then {
    _slots = [];
    for "_i" from 0 to (_count - 1) do {
      private _ang = _i * (360 / _count);
      _slots pushBack [ (sin _ang) * _spacing, (cos _ang) * _spacing, 0 ];
    };
  };

  // Convert offsets to world positions
  private _out = [];
  for "_i" from 0 to (_count - 1) do {
    private _o = _slots select _i;
    _out pushBack (_lzPos vectorAdd _o);
  };
  _out
};
publicVariable "fnc_getLZSlots";

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
