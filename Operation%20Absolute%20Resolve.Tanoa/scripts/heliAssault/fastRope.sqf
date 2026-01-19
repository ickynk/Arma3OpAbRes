//==============================================================================
// scripts/heliAssault/fastRope.sqf
//==============================================================================
// Helicopter fast-rope insertion script
// - Flies helicopter to designated slot position
// - Clamps altitude at 30m AGL for stable hover
// - Deploys ACE fast-rope (or fallback: eject cargo)
//
// Parameters:
//   _heli - OBJECT: Helicopter to rope from
//   _slotPos - ARRAY: Target hover position [x,y,z]
//
// Called from: beginAssault.sqf (spawned for each assault heli)
// Runs on: Server only
// Requires: ACE3 Fast Roping (optional, has fallback)
//==============================================================================

if (!isServer) exitWith {};
params ["_heli", "_slotPos"];

if (isNull _heli || !alive _heli) exitWith {};

private _grp = group (driver _heli);

//------------------------------------------------------------------------------
// Configuration
//------------------------------------------------------------------------------
private _ropeAGL = 30;                   // Altitude above ground for fast-rope
private _approachRadius = 45;            // Distance to start altitude clamp
private _clampSeconds = 6;               // Duration to maintain hover before rope
private _speedCap = 22;                  // Speed limit for stable approach

//------------------------------------------------------------------------------
// Approach phase
//------------------------------------------------------------------------------
[_grp] call fnc_clearWaypoints;

_heli flyInHeight _ropeAGL;
_heli limitSpeed _speedCap;

private _wp = _grp addWaypoint [_slotPos, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "LIMITED";
_wp setWaypointCompletionRadius 15;

// Wait until near slot (or timeout after 2 minutes)
private _t0 = time;
waitUntil {
  sleep 0.5;
  !alive _heli
  || ((_heli distance2D _slotPos) < _approachRadius && (speed _heli) < 50)
  || (time > _t0 + 120)
};
if (!alive _heli) exitWith {};

//------------------------------------------------------------------------------
// Altitude clamp phase (stabilizes helicopter for rope deployment)
//------------------------------------------------------------------------------
private _tClamp = time + _clampSeconds;

while {alive _heli && time < _tClamp} do {
  // Lock position at slot coordinates, 30m AGL
  private _x = _slotPos select 0;
  private _y = _slotPos select 1;

  _heli setPosATL [_x, _y, _ropeAGL];

  // Remove vertical momentum to prevent bobbing
  _heli setVelocity [0, 0, 0];
  _heli limitSpeed _speedCap;

  sleep 0.10;
};

// Brief settle time
sleep 0.5;

//------------------------------------------------------------------------------
// Fast-rope deployment (ACE3)
//------------------------------------------------------------------------------
private _didRope = false;

// Equip FRIES (Fast Rope Insertion Extraction System)
if (!isNil "ace_fastroping_fnc_equipFRIES") then {
  [_heli] call ace_fastroping_fnc_equipFRIES;
  sleep 0.5;
};

// Deploy fast-rope
if (!isNil "ace_fastroping_fnc_fastRope") then {
  [_heli] call ace_fastroping_fnc_fastRope;
  _didRope = true;
};

// Fallback: Basic cargo eject if ACE not available
if (!_didRope) then {
  {
    unassignVehicle _x;
    moveOut _x;
  } forEach (assignedCargo _heli);
};
