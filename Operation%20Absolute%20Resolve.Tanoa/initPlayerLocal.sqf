//==============================================================================
// initPlayerLocal.sqf
//==============================================================================
// Runs on each client when they join the mission
// Sets up player actions for all three mission phases
//==============================================================================

waitUntil {!isNull player};

//------------------------------------------------------------------------------
// SAFE DEFAULTS (prevents nil errors in addAction conditions)
//------------------------------------------------------------------------------
missionNamespace setVariable ["missionPhase",     missionNamespace getVariable ["missionPhase", 1]];
missionNamespace setVariable ["strikeFinalized",  missionNamespace getVariable ["strikeFinalized", false]];
missionNamespace setVariable ["strikeBudgetMax",  missionNamespace getVariable ["strikeBudgetMax", 10]];
missionNamespace setVariable ["strikeBudgetUsed", missionNamespace getVariable ["strikeBudgetUsed", 0]];
missionNamespace setVariable ["hvtArrested",      missionNamespace getVariable ["hvtArrested", false]];

//------------------------------------------------------------------------------
// Wait for server state to arrive (MP/JIP safe)
//------------------------------------------------------------------------------
[] spawn {
  waitUntil { !isNil "missionPhase" };
  waitUntil { !isNil "strikeFinalized" };
};

systemChat "initPlayerLocal.sqf ran.";

//------------------------------------------------------------------------------
// Common UI notifier
//------------------------------------------------------------------------------
if (!isNil "fnc_common") then { [] call fnc_common; };

//------------------------------------------------------------------------------
// FUNCTION: Add player actions (called on init and respawn)
//------------------------------------------------------------------------------
fnc_addPlayerActions = {
  params ["_unit"];

  // PHASE 2: Strike planning actions
  _unit addAction [
    "<t color='#ff6666'>Add AIR strike point (cost 2)</t>",
    { ["AIR", 2] call fnc_strikeUI; },
    nil, 1.5, true, true, "",
    "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
  ];

  _unit addAction [
    "<t color='#66aaff'>Add NAVAL fires point (cost 1)</t>",
    { ["NAVAL", 1] call fnc_strikeUI; },
    nil, 1.5, true, true, "",
    "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
  ];

  _unit addAction [
    "<t color='#cccccc'>Remove last strike point (refund)</t>",
    { ["REMOVE_LAST"] remoteExecCall ["fnc_srvStrikePlan", 2]; },
    nil, 1.2, true, true, "",
    "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
  ];

  _unit addAction [
    "<t color='#66ff66'>Finalize strike package (start schedule)</t>",
    { ["FINALIZE"] remoteExecCall ["fnc_srvStrikePlan", 2]; },
    nil, 1.2, true, true, "",
    "((missionNamespace getVariable ['missionPhase',1]) == 2) && !(missionNamespace getVariable ['strikeFinalized',false])"
  ];

  // PHASE 3: HVT Arrest action
  _unit addAction [
    "<t color='#66ff66'>Arrest HVT (ACE)</t>",
    {
      if (missionPhase != 3) exitWith {};
      if (missionNamespace getVariable ["hvtArrested", false]) exitWith {};

      // Notify server to update mission state
      [] remoteExecCall ["fnc_srvArrestHVT", 2];

      // Apply ACE handcuffs if available
      if (!isNil "ace_captives_fnc_setHandcuffed") then {
        [hvt_1, true] call ace_captives_fnc_setHandcuffed;
      } else {
        // Fallback: basic surrender animation
        hvt_1 playMoveNow "AmovPercMstpSsurWnonDnon";
        hvt_1 setCaptive true;
      };

      hint "HVT restrained. Use ACE Interaction: Escort / Load into vehicle.";
    },
    nil, 2, true, true, "",
    "((missionNamespace getVariable ['missionPhase',1]) == 3) && !(missionNamespace getVariable ['hvtArrested',false]) && !isNil 'hvt_1' && alive hvt_1 && (player distance hvt_1 < 3)"
  ];

  // PHASE 3: Begin assault action (only available in player heli)
  _unit addAction [
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
};

//------------------------------------------------------------------------------
// PHASE 1: Power Panel action (on static object)
//------------------------------------------------------------------------------
if (!isNil "obj_powerPanel" && {!isNull obj_powerPanel}) then {
  systemChat format ["Power panel found: %1", obj_powerPanel];

  obj_powerPanel addAction [
    "<t color='#ffcc00'>Trip Grid (Blackout)</t>",
    { [] remoteExecCall ["fnc_srvTripPower", 2]; },
    nil, 2, true, true, "",
    "(missionNamespace getVariable ['missionPhase',1]) == 1"
  ];
} else {
  systemChat "WARNING: obj_powerPanel is nil or null (check Eden Variable Name).";
};

//------------------------------------------------------------------------------
// Add actions to player at init
//------------------------------------------------------------------------------
[player] call fnc_addPlayerActions;

//------------------------------------------------------------------------------
// Respawn handler - re-add actions to new unit
//------------------------------------------------------------------------------
player addEventHandler ["Respawn", {
  params ["_newUnit", "_oldUnit"];
  [_newUnit] call fnc_addPlayerActions;
}];





