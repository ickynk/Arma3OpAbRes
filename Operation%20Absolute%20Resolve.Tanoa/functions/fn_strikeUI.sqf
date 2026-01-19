//==============================================================================
// functions/fn_strikeUI.sqf
//==============================================================================
// Client function: Opens map for player to select a strike target location
// - Validates strike is allowed (Phase 2, not finalized)
// - Shows remaining budget
// - Sends selected position to server for processing
//
// Parameters:
//   _type - STRING: Strike type ("AIR" or "NAVAL")
//   _cost - NUMBER: Point cost of this strike type
//
// Called from: Player action menu (initPlayerLocal.sqf)
// Runs on: Client with interface
//==============================================================================

params ["_type", "_cost"];
if (!hasInterface) exitWith {};
if (missionPhase != 2) exitWith { hint "Strike planning not active."; };
if (strikeFinalized) exitWith { hint "Strike package already finalized."; };

private _remaining = (strikeBudgetMax - strikeBudgetUsed);
hint format ["Select a point on the map.\nType: %1 | Cost: %2\nRemaining: %3", _type, _cost, _remaining];

openMap true;

onMapSingleClick format ["
  openMap false;
  onMapSingleClick {};
  ['ADD', '%1', _pos, %2] remoteExecCall ['fnc_srvStrikePlan', 2];
", _type, _cost];
