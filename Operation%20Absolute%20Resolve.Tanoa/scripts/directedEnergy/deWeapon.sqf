//==============================================================================
// scripts/directedEnergy/deWeapon.sqf
//==============================================================================
// Directed Energy Weapon System - BluFor Non-Lethal Incapacitation
// Simulates effects similar to acoustic/microwave directed energy weapons
// Causes targets to become disoriented and incapacitated
//
// Effects on targets:
//   - AI skills reduced to near-zero (disoriented, can't aim/react)
//   - Forced into incapacitated animation (clutching head, prone)
//   - AI systems disabled (can't move, target, or fight)
//   - Optional: Visual/audio effects for player targets
//
// Usage:
//   [_centerPos, _radius] call fnc_deWeaponFire;
//   [_unit] call fnc_deApplyEffect;
//
// Called from: Mission triggers, UI system, or script
// Runs on: Server only
//==============================================================================

if (!isServer) exitWith {};

//------------------------------------------------------------------------------
// Configuration
//------------------------------------------------------------------------------
DE_EFFECT_DURATION = 60;           // How long the effect lasts (seconds)
DE_SKILL_LEVEL = 0.01;             // AI skill level when affected (near-zero)
DE_DEFAULT_RADIUS = 50;            // Default effect radius (meters)
DE_EFFECTIVENESS = 0.6;            // 60% chance to affect each target

// Animations for incapacitated state (will cycle through these)
DE_INCAP_ANIMATIONS = [
  "AinjPpneMstpSnonWnonDnon",      // Injured prone, no weapon
  "AinjPpneMstpSnonWrflDnon",      // Injured prone, with rifle
  "AmovPpneMstpSrasWrflDnon"       // Prone surrender position
];

//------------------------------------------------------------------------------
// Function: Apply directed energy effect to a single unit
//------------------------------------------------------------------------------
missionNamespace setVariable ["fnc_deApplyEffect", {
  params ["_unit", ["_duration", DE_EFFECT_DURATION]];

  if (isNull _unit) exitWith {false};
  if (!alive _unit) exitWith {false};
  if (_unit getVariable ["de_affected", false]) exitWith {false}; // Already affected

  // BluFor units are immune (friendly fire protection)
  if (side _unit == west) exitWith {false};

  // 60% effectiveness rate - some targets resist the effect
  if (random 1 > DE_EFFECTIVENESS) exitWith {
    diag_log format ["[DE_WEAPON] %1 resisted the effect", _unit];
    false
  };

  // Mark unit as affected
  _unit setVariable ["de_affected", true, true];

  // Store original skill values for restoration
  private _originalSkills = [
    ["aimingAccuracy", _unit skill "aimingAccuracy"],
    ["aimingShake", _unit skill "aimingShake"],
    ["aimingSpeed", _unit skill "aimingSpeed"],
    ["spotDistance", _unit skill "spotDistance"],
    ["spotTime", _unit skill "spotTime"],
    ["courage", _unit skill "courage"],
    ["reloadSpeed", _unit skill "reloadSpeed"],
    ["commanding", _unit skill "commanding"],
    ["general", _unit skill "general"]
  ];
  _unit setVariable ["de_originalSkills", _originalSkills, true];

  // Reduce all skills to near-zero
  {
    _unit setSkill [_x select 0, DE_SKILL_LEVEL];
  } forEach _originalSkills;

  // Disable AI capabilities
  {
    _unit disableAI _x;
  } forEach ["TARGET", "AUTOTARGET", "MOVE", "ANIM", "TEAMSWITCH", "FSM", "AIMINGERROR", "SUPPRESSION", "CHECKVISIBLE", "AUTOCOMBAT", "COVER", "PATH"];

  // Force unit to drop to ground
  _unit setUnitPos "DOWN";

  // Play incapacitation animation
  private _anim = selectRandom DE_INCAP_ANIMATIONS;
  [_unit, _anim] remoteExec ["playMoveNow", 0];

  // Drop weapon (makes them less threatening)
  if (currentWeapon _unit != "") then {
    _unit action ["DropWeapon", _unit, currentWeapon _unit];
  };

  // Log the effect
  diag_log format ["[DE_WEAPON] Effect applied to %1 at %2", _unit, getPosATL _unit];

  // Spawn recovery thread
  [_unit, _duration, _originalSkills] spawn {
    params ["_u", "_dur", "_skills"];

    sleep _dur;

    if (isNull _u || !alive _u) exitWith {};

    // Restore original skills
    {
      _u setSkill [_x select 0, _x select 1];
    } forEach _skills;

    // Re-enable AI
    {
      _u enableAI _x;
    } forEach ["TARGET", "AUTOTARGET", "MOVE", "ANIM", "TEAMSWITCH", "FSM", "AIMINGERROR", "SUPPRESSION", "CHECKVISIBLE", "AUTOCOMBAT", "COVER", "PATH"];

    // Allow unit to stand again
    _u setUnitPos "AUTO";

    // Clear affected flag
    _u setVariable ["de_affected", false, true];
    _u setVariable ["de_originalSkills", nil, true];

    diag_log format ["[DE_WEAPON] Effect worn off for %1", _u];
  };

  true  // Return success
}];

//------------------------------------------------------------------------------
// Function: Fire directed energy weapon at area
//------------------------------------------------------------------------------
missionNamespace setVariable ["fnc_deWeaponFire", {
  params ["_centerPos", ["_radius", DE_DEFAULT_RADIUS], ["_duration", DE_EFFECT_DURATION]];

  diag_log format ["[DE_WEAPON] Firing at %1 with radius %2m", _centerPos, _radius];

  // Create visual effect at target location (energy pulse)
  private _effect = "MemoryPointGlow" createVehicle _centerPos;
  if (!isNull _effect) then {
    [_effect] spawn {
      params ["_e"];
      sleep 3;
      deleteVehicle _e;
    };
  };

  // Sound effect - low frequency pulse (audible to nearby players)
  [[_centerPos], {
    params ["_pos"];
    playSound3D ["A3\Sounds_F\sfx\alarmCar.wss", objNull, false, _pos, 2, 0.3, 500];
  }] remoteExec ["call", 0];

  // Find all OpFor units in radius (only targets east side - enemy forces)
  private _targetUnits = [];
  {
    if (alive _x && {side _x == east} && {_x distance _centerPos <= _radius}) then {
      _targetUnits pushBack _x;
    };
  } forEach allUnits;

  // Apply effect to targets (60% effectiveness rate applied in fnc_deApplyEffect)
  private _affectedCount = 0;
  {
    private _wasAffected = [_x, _duration] call fnc_deApplyEffect;
    if (_wasAffected) then { _affectedCount = _affectedCount + 1; };
    sleep 0.1; // Slight stagger to prevent simultaneous processing
  } forEach _targetUnits;

  // Return count of affected units
  diag_log format ["[DE_WEAPON] Targeted %1 units, affected %2 (60%% effectiveness)", count _targetUnits, _affectedCount];
  _affectedCount
}];

//------------------------------------------------------------------------------
// Function: Create directed energy strike (similar to air/naval strike system)
//------------------------------------------------------------------------------
missionNamespace setVariable ["fnc_deStrikeExecute", {
  params ["_pos", ["_radius", DE_DEFAULT_RADIUS]];

  if (!isServer) exitWith {};

  // Broadcast notification
  ["Directed Energy Weapon Deployed"] remoteExec ["hint", 0];

  // Visual warning effect (energy buildup)
  private _light = "#lightpoint" createVehicle _pos;
  _light setLightBrightness 1;
  _light setLightColor [0.5, 0.5, 1];
  _light setLightAmbient [0.2, 0.2, 0.4];

  // Buildup phase
  for "_i" from 1 to 10 do {
    _light setLightBrightness (_i / 5);
    sleep 0.2;
  };

  // Fire the weapon
  [_pos, _radius] call fnc_deWeaponFire;

  // Dissipate effect
  for "_i" from 10 to 1 step -1 do {
    _light setLightBrightness (_i / 5);
    sleep 0.1;
  };

  deleteVehicle _light;
}];

diag_log "[DE_WEAPON] Directed Energy Weapon system loaded";
