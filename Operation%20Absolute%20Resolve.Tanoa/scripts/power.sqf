//==============================================================================
// scripts/power.sqf
//==============================================================================
// Server-side power management system for Phase 1
// - Collects all light objects across Tanoa island
// - Monitors tanoukaPowerOn variable
// - Switches lights ON/OFF based on power state
//
// Called from: initServer.sqf
// Runs on: Server only
//==============================================================================

if (!isServer) exitWith {};

diag_log "[POWER] Collecting island lights...";

// Scan entire map for light objects
private _center = [worldSize / 2, worldSize / 2, 0];
private _radius = worldSize * 0.9;

// Tanoa uses multiple lamp classes
private _lampClasses = [
  "Lamps_base_F",
  "PowerLines_base_F",
  "Land_LampStreet_F",
  "Land_LampStreet_small_F",
  "Land_LampDecor_F",
  "Land_LampSolar_F"
];

private _lamps = [];
{
  _lamps append (nearestObjects [_center, [_x], _radius]);
} forEach _lampClasses;

_lamps = _lamps arrayIntersect _lamps;  // Remove duplicates

diag_log format ["[POWER] %1 light objects found", count _lamps];

// Monitor and enforce power state every 10 seconds
while {true} do {
  if (missionNamespace getVariable ["tanoukaPowerOn", true]) then {
    { _x switchLight "ON"; } forEach _lamps;
  } else {
    { _x switchLight "OFF"; } forEach _lamps;
  };
  sleep 10;
};
