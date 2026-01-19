//==============================================================================
// functions/fn_srvStrikeExecute.sqf
//==============================================================================
// Server function: Executes a strike at the specified position
// - AIR: 8x Mk82 bombs over 80m radius
// - NAVAL: 16x 155mm shells over 120m radius
//
// Parameters:
//   _type - STRING: Strike type ("AIR" or "NAVAL")
//   _pos - ARRAY: Target position [x,y,z]
//
// Called from: strikeScheduler.sqf
// Runs on: Server only
//==============================================================================

if (!isServer) exitWith {};
params ["_type", "_pos"];

private _doExplosions = {
  params ["_ammo","_count","_spread","_sleep"];
  for "_i" from 1 to _count do {
    private _p = _pos getPos [random _spread, random 360];
    _ammo createVehicle _p;
    sleep _sleep;
  };
};

switch (_type) do {
  case "AIR": {
    // Bigger bombs, fewer impacts, tighter spread
    ["Bo_Mk82", 8, 80, 0.45] call _doExplosions;
  };
  case "NAVAL": {
    // More shells, wider spread, faster rate
    ["Sh_155mm_AMOS", 16, 120, 0.25] call _doExplosions;
  };
};
