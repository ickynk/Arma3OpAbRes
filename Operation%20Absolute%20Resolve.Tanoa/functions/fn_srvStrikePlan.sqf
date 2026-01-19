if (!isServer) exitWith {};
params ["_mode", "_type", "_pos", "_cost"];

private _broadcastStatus = {
  publicVariable "strikeBudgetUsed";
  publicVariable "strikeFinalized";
  publicVariable "strikePlan";
};

switch (_mode) do {

  case "ADD": {
    if (strikeFinalized) exitWith {};
    private _newUsed = strikeBudgetUsed + _cost;
    if (_newUsed > strikeBudgetMax) exitWith {
      ["Budget exceeded. Remove a point or choose cheaper fires."] remoteExec ["hint", 0];
    };

    strikeBudgetUsed = _newUsed;
    strikePlan pushBack [_type, _pos, _cost];

    ["Strike point added."] remoteExec ["hint", 0];
    call _broadcastStatus;
  };

  case "REMOVE_LAST": {
    if (strikeFinalized) exitWith {};
    if ((count strikePlan) == 0) exitWith {
      ["No strike points to remove."] remoteExec ["hint", 0];
    };

    private _last = strikePlan deleteAt ((count strikePlan) - 1);
    private _refund = _last select 2;
    strikeBudgetUsed = (strikeBudgetUsed - _refund) max 0;

    ["Removed last strike point."] remoteExec ["hint", 0];
    call _broadcastStatus;
  };

  case "FINALIZE": {
    if (strikeFinalized) exitWith {};
    if ((count strikePlan) == 0) exitWith {
      ["Add at least one strike point before finalizing."] remoteExec ["hint", 0];
    };

    // OPTIONAL RULE: require at least one point near each major target area
    // If you want this, place markers: mrk_port, mrk_airport, mrk_base and enforce distances here.

    strikeFinalized = true;
    ["Strike package FINALIZED. Random strikes will begin shortly and continue for the remainder of the mission."] remoteExec ["hint", 0];
    call _broadcastStatus;

    // Mark Phase 2 task complete & move to Phase 3
    ["tsk_strikes", "SUCCEEDED"] call BIS_fnc_taskSetState;
    ["tsk_arrest", "ASSIGNED"] call BIS_fnc_taskSetState;

    // Start scheduler loop
    [] execVM "scripts\strikeScheduler.sqf";

    // Advance phase + role swap
    [3] call fnc_phaseAdvance;
  };
};
