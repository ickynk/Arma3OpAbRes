// initPlayerLocal.sqf
waitUntil {!isNull player};

// ---- SAFE DEFAULTS (prevents nil errors in addAction conditions)
missionNamespace setVariable ["missionPhase",     missionNamespace getVariable ["missionPhase", 1]];
missionNamespace setVariable ["strikeFinalized",  missionNamespace getVariable ["strikeFinalized", false]];
missionNamespace setVariable ["strikeBudgetMax",  missionNamespace getVariable ["strikeBudgetMax", 10]];
missionNamespace setVariable ["strikeBudgetUsed", missionNamespace getVariable ["strikeBudgetUsed", 0]];
missionNamespace setVariable ["hvtArrested",      missionNamespace getVariable ["hvtArrested", false]];

// ---- Wait for server state to arrive (MP/JIP safe)
[] spawn {
  waitUntil { !isNil "missionPhase" };
  waitUntil { !isNil "strikeFinalized" };
};

// Optional: quick proof this file is running
systemChat "initPlayerLocal.sqf ran.";

// ---- Common UI notifier (optional)
if (!isNil "fnc_common") then { [] call fnc_common; };

// ---- PHASE 1: Power Panel action
if (!isNil "obj_powerPanel" && {!isNull obj_powerPanel}) then {

  // Optional debug
  systemChat format ["Power panel found: %1", obj_powerPanel];

  obj_powerPanel addAction [
    "<t color='#ffcc00'>Trip Grid (Blackout)</t>",
    { [] remoteExecCall ["fnc_srvTripPower", 2]; },
    nil, 2, true, true, "",
    // CONDITION uses getVariable so it never errors
    "(missionNamespace getVariable ['missionPhase',1]) == 1"
  ];
} else {
  systemChat "WARNING: obj_powerPanel is nil or null (check Eden Variable Name).";
};

// ---- PHASE 2: Strike planning actions
player addAction [
  "<t color='#ff6666'>Add AIR strike point (cost 2)</t>",
  { ["AIR", 2] call fnc_strikeUI; },
  nil, 1.5, true, true, "",
  "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
];

player addAction [
  "<t color='#66aaff'>Add NAVAL fires point (cost 1)</t>",
  { ["NAVAL", 1] call fnc_strikeUI; },
  nil, 1.5, true, true, "",
  "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
];

player addAction [
  "<t color='#cccccc'>Remove last strike point (refund)</t>",
  { ["REMOVE_LAST"] remoteExecCall ["fnc_srvStrikePlan", 2]; },
  nil, 1.2, true, true, "",
  "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
];

player addAction [
  "<t color='#66ff66'>Finalize strike package (start schedule)</t>",
  { ["FINALIZE"] remoteExecCall ["fnc_srvStrikePlan", 2]; },
  nil, 1.2, true, true, "",
  "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
];

// ---- PHASE 3: Arrest action
player addAction [
  "<t color='#66ff66'>Arrest HVT</t>",
  { [] remoteExecCall ["fnc_srvArrestHVT", 2]; },
  nil, 2, true, true, "",
  "((missionNamespace getVariable ['missionPhase',1]) == 3) && !(missionNamespace getVariable ['hvtArrested',false]) && !isNil 'hvt_1' && alive hvt_1 && (player distance hvt_1 < 3)"
];

player addEventHandler ["Respawn", {
  params ["_newUnit", "_oldUnit"];

  // Re-add strike package actions after respawn
  _newUnit addAction [
    "<t color='#ff6666'>Add AIR strike point (cost 2)</t>",
    { ["AIR", 2] call fnc_strikeUI; },
    nil, 1.5, true, true, "",
    "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
  ];

  _newUnit addAction [
    "<t color='#66aaff'>Add NAVAL fires point (cost 1)</t>",
    { ["NAVAL", 1] call fnc_strikeUI; },
    nil, 1.5, true, true, "",
    "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
  ];

  _newUnit addAction [
    "<t color='#cccccc'>Remove last strike point (refund)</t>",
    { ["REMOVE_LAST"] remoteExecCall ["fnc_srvStrikePlan", 2]; },
    nil, 1.2, true, true, "",
    "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
  ];

  _newUnit addAction [
    "<t color='#66ff66'>Finalize strike package (start schedule)</t>",
    { ["FINALIZE"] remoteExecCall ["fnc_srvStrikePlan", 2]; },
    nil, 1.2, true, true, "",
    "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
  ];

  _newUnit addAction [
    "<t color='#66ff66'>Restrain HVT (ACE)</t>",
    {
    if (missionPhase != 3) exitWith {};
    if (missionNamespace getVariable ["hvtArrested", false]) exitWith {};

    // Ask server to mark mission state arrested
    [] remoteExecCall ["fnc_srvArrestHVT", 2];

    // Do the ACE restrain locally on the client who clicked (ACE actions are local)
    if (!isNil "ace_captives_fnc_setHandcuffed") then {
      [hvt_1, true] call ace_captives_fnc_setHandcuffed;
    } else {
      // fallback: at least make him compliant
      hvt_1 playMoveNow "AmovPercMstpSsurWnonDnon";
      hvt_1 setCaptive true;
    };

    hint "HVT restrained. Use ACE Interaction: Escort / Load into vehicle.";
  },
  nil, 2, true, true, "",
  "missionPhase==3 && !hvtArrested && !isNil 'hvt_1' && alive hvt_1 && (player distance hvt_1 < 3)"
];

// Add the action only for players inside heli_player_1, only during phase 3.
// The action appears on the player (works even if they are passenger).
_newUnit addAction [
  "<t color='#ffcc00'>BEGIN ASSAULT (Launch Package)</t>",
  {
    [] remoteExecCall ["fnc_srvBeginCarrierAssault", 2];
    hint "Assault package launching...";
  },
  nil, 2, true, true, "",
  "
    (missionNamespace getVariable ['missionPhase',1]) == 3
    && (vehicle player == heli_player_1)
    && !(missionNamespace getVariable ['assaultBegun',false])
  "
];

}];





