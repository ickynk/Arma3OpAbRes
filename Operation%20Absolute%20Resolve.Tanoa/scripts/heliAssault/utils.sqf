// scripts\heliAssault\utils.sqf
if (!isServer) exitWith {};

// Return an array of world positions around LZ for each helo
fnc_getLZSlots = {
  params ["_lzPos", "_count", ["_spacing", 70]];

  // Good default offsets for 2–4 helos (meters)
  private _slots = [
    [  0,   0, 0],
    [ _spacing,  40, 0],
    [-_spacing,  40, 0],
    [  0, _spacing + 20, 0]
  ];

  // If more helos than slots, put them on a ring
  if (_count > count _slots) then {
    _slots = [];
    for "_i" from 0 to (_count - 1) do {
      private _ang = _i * (360 / _count);
      _slots pushBack [ (sin _ang) * _spacing, (cos _ang) * _spacing, 0 ];
    };
  };

  private _out = [];
  for "_i" from 0 to (_count - 1) do {
    private _o = _slots select _i;
    _out pushBack (_lzPos vectorAdd _o);
  };
  _out
};
publicVariable "fnc_getLZSlots";

fnc_clearWaypoints = {
  params ["_grp"];
  { deleteWaypoint _x } forEach waypoints _grp;
};

fnc_wakeAircraft = {
  params ["_veh", ["_height", 70]];
  if (isNull _veh) exitWith {};

  _veh hideObjectGlobal false;
  _veh enableSimulationGlobal true;
  _veh engineOn true;
  _veh flyInHeight _height;

  // Nudge up a little if on deck to avoid weird collision at rotor start
  private _p = getPosASL _veh;
  _veh setPosASL [_p#0, _p#1, (_p#2) + 1.5];
};
