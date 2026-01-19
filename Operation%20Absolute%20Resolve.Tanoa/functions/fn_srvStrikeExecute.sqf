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
    // Bigger, fewer
    ["Bo_Mk82", 8, 80, 0.45] call _doExplosions;
  };
  case "NAVAL": {
    // More shells, wider
    ["Sh_155mm_AMOS", 16, 120, 0.25] call _doExplosions;
  };
};
