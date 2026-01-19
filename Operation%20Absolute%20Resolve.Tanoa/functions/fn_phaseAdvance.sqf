//==============================================================================
// functions/fn_phaseAdvance.sqf
//==============================================================================
// Server function: Advances mission to the next phase
// - Updates global missionPhase variable
// - Moves respawn marker to new staging area
// - Forces all players to respawn for role swap
//
// Parameters:
//   _newPhase - NUMBER: Phase to advance to (1, 2, or 3)
//
// Called from: fnc_srvTripPower, fnc_srvStrikePlan
// Runs on: Server only
//==============================================================================

if (!isServer) exitWith {};
params ["_newPhase"];

missionPhase = _newPhase;
publicVariable "missionPhase";

// Move respawn marker to next staging area
private _mk = switch (_newPhase) do {
  case 1: {"mrk_phase1_spawn"};
  case 2: {"mrk_phase2_spawn"};
  case 3: {"mrk_phase3_spawn"};
  default {"mrk_phase1_spawn"};
};

"respawn_west" setMarkerPos (getMarkerPos _mk);

// Force all players to respawn for role swap
{
  if (isPlayer _x && alive _x) then {
    _x setDamage 1;
  };
} forEach allPlayers;
