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
