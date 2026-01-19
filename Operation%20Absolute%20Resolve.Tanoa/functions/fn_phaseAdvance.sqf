// functions\fn_phaseAdvance.sqf
if (!isServer) exitWith {};
params ["_newPhase"];

missionPhase = _newPhase;
publicVariable "missionPhase";

// Move respawn marker to next staging
private _mk = switch (_newPhase) do {
  case 1: {"mrk_phase1_spawn"};
  case 2: {"mrk_phase2_spawn"};
  case 3: {"mrk_phase3_spawn"};
  default {"mrk_phase1_spawn"};
};

"respawn_west" setMarkerPos (getMarkerPos _mk);

// Force everyone to respawn (clean role swap)
{
  if (isPlayer _x && alive _x) then {
    _x setDamage 1;
  };
} forEach allPlayers;
