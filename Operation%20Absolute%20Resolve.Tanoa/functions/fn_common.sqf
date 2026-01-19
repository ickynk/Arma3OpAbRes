// functions\fn_common.sqf
if (!hasInterface) exitWith {};

missionNamespace setVariable ["_lastPhase", -1];

[] spawn {
  while {true} do {
    private _p = missionNamespace getVariable ["missionPhase", 1];
    private _last = missionNamespace getVariable ["_lastPhase", -1];

    if (_p != _last) then {
      missionNamespace setVariable ["_lastPhase", _p];

      switch (_p) do {
        case 1: { hint "PHASE 1: Sabotage the coal plant to black out the island."; };
        case 2: { hint "PHASE 2: Call strikes (Map Click) and confirm BDA."; };
        case 3: { hint "PHASE 3: Insert, ARREST HVT, and extract by helicopter."; };
      };
    };
    sleep 2;
  };
};
