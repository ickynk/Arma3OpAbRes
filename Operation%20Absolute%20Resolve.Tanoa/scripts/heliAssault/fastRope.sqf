// scripts\heliAssault\fastRope.sqf
if (!isServer) exitWith {};
params ["_heli", "_slotPos"];

if (isNull _heli || !alive _heli) exitWith {};

private _grp = group (driver _heli);

// --- CONFIG
private _ropeAGL = 30;          // FORCE this altitude above ground
private _approachRadius = 45;   // start clamping when within this distance
private _clampSeconds = 6;      // how long to clamp altitude before roping
private _speedCap = 22;         // keep it slow and stable
// ------------

// Clear WPs and move to slot
[_grp] call fnc_clearWaypoints;

_heli flyInHeight _ropeAGL;
_heli limitSpeed _speedCap;

private _wp = _grp addWaypoint [_slotPos, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "LIMITED";
_wp setWaypointCompletionRadius 15;

// Wait until near slot (or timeout)
private _t0 = time;
waitUntil {
  sleep 0.5;
  !alive _heli
  || ((_heli distance2D _slotPos) < _approachRadius && (speed _heli) < 50)
  || (time > _t0 + 120)
};
if (!alive _heli) exitWith {};

// --- HARD CLAMP ALTITUDE TO 30m AGL ---
// We do this briefly to overcome AI refusing flyInHeight.
private _tClamp = time + _clampSeconds;

while {alive _heli && time < _tClamp} do {
  // Keep XY near the slot (prevents drift while clamping)
  private _x = _slotPos select 0;
  private _y = _slotPos select 1;

  // setPosATL uses AGL for Z (perfect for "30m above ground")
  _heli setPosATL [_x, _y, _ropeAGL];

  // Remove vertical bob / momentum that can fight the clamp
  _heli setVelocity [0, 0, 0];
  _heli limitSpeed _speedCap;

  sleep 0.10;
};

// Give a tiny settle
sleep 0.5;

// --- ACE FAST ROPE ---
private _didRope = false;

// Equip ropes / FRIES if your ACE build supports it
if (!isNil "ace_fastroping_fnc_equipFRIES") then {
  [_heli] call ace_fastroping_fnc_equipFRIES;
  sleep 0.5;
};

// Trigger fast rope if available
if (!isNil "ace_fastroping_fnc_fastRope") then {
  [_heli] call ace_fastroping_fnc_fastRope;
  _didRope = true;
};

// Fallback if ACE function not present
if (!_didRope) then {
  {
    unassignVehicle _x;
    moveOut _x;
  } forEach (assignedCargo _heli);
};
