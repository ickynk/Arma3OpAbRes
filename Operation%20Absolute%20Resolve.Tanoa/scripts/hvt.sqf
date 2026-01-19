// scripts\hvt.sqf
if (!isServer) exitWith {};

hvt_1 allowFleeing 0;
hvt_1 setCaptive true;

// Make him hard to accidentally kill (still possible if you want)
hvt_1 addEventHandler ["HandleDamage", {
  params ["_unit","","_damage"];
  _damage min 0.85
}];

fnc_srvArrestHVT = {
  if (missionPhase != 3) exitWith {};
  if (hvtArrested) exitWith {};

  hvtArrested = true; publicVariable "hvtArrested";
  removeAllWeapons hvt_1;
  hvt_1 setCaptive true;
  hvt_1 setVariable ["ace_captives_isHandcuffed", true, true];
  hvt_1 playMoveNow "AmovPercMstpSsurWnonDnon";

  ["tsk_arrest","SUCCEEDED"] call BIS_fnc_taskSetState;

  // Now require extraction
  // You can also auto-attach him to a player for escort if you want (ACE has restraint/drag if enabled)
};
publicVariable "fnc_srvArrestHVT";
