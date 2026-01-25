//==============================================================================
// scripts/heliAssault/beginAssault.sqf
//==============================================================================
// Phase 3 helicopter assault sequence
// - Launches AI CAS (Close Air Support) helicopters with SAD waypoints
// - Flies assault helicopters to LZ using waypoints and lands them
// - Troops disembark after landing
//
// Required Eden objects (variable names):
//   - heli_assault_2, heli_assault_3, heli_player_1 (assault helicopters)
//   - heli_cas_1, heli_cas_2 (optional CAS helicopters)
//
// Required markers:
//   - mrk_lz (Landing Zone center point)
//
// Called from: fnc_srvBeginCarrierAssault (initServer.sqf)
// Runs on: Server only
//==============================================================================

if (!isServer) exitWith {};

//------------------------------------------------------------------------------
// Configuration
//------------------------------------------------------------------------------
// Pull vehicle references from Eden (safe, returns objNull if missing)
private _heliAssault2 = missionNamespace getVariable ["heli_assault_2", objNull];
private _heliAssault3 = missionNamespace getVariable ["heli_assault_3", objNull];
private _heliPlayer1  = missionNamespace getVariable ["heli_player_1",  objNull];

// Assault helicopters (will fly to LZ and land)
private _assaultHelis = [_heliAssault2, _heliAssault3, _heliPlayer1];

// Landing position offsets for each helicopter (relative to LZ center)
// Spaced 50m apart in a line formation to prevent rotor collision
private _landingOffsets = [
  [0, 0],       // First helicopter lands at LZ center
  [50, 0],      // Second helicopter lands 50m east
  [-50, 0]      // Third helicopter lands 50m west
];

// Optional CAS helicopters (AI-controlled, NOT on recorded tracks)
private _casHelis = [];
private _heliCas1 = missionNamespace getVariable ["heli_cas_1", objNull];
private _heliCas2 = missionNamespace getVariable ["heli_cas_2", objNull];
if (!isNull _heliCas1) then { _casHelis pushBack _heliCas1; };
if (!isNull _heliCas2) then { _casHelis pushBack _heliCas2; };

// Landing zone
private _lzCenter = getMarkerPos "mrk_lz";

// Landing configuration
private _approachHeight = 100;           // Altitude for approach to LZ (meters AGL)
private _approachSpeed = 150;            // Speed limit during approach (km/h)

//------------------------------------------------------------------------------
// Diagnostic logging
//------------------------------------------------------------------------------
diag_log format ["[ASSAULT] beginAssault started. Assault2=%1 Assault3=%2 PlayerHelo=%3 CAS1=%4 CAS2=%5",
  _heliAssault2, _heliAssault3, _heliPlayer1, _heliCas1, _heliCas2
];

//------------------------------------------------------------------------------
// Helper function: Wake aircraft for flight
//------------------------------------------------------------------------------
private _wakeForPlayback = {
  params ["_veh"];
  if (isNull _veh) exitWith {};

  // If you used the "carrierCold" pattern:
  if (_veh getVariable ["carrierCold", false]) then {
    _veh setFuel 1;
    _veh lock false;
    _veh setVariable ["carrierCold", false, true];
  } else {
    // Otherwise still ensure it can fly
    _veh setFuel 1;
    _veh lock false;
  };

  _veh allowDamage false;
  _veh engineOn true;

  // Tiny nudge to prevent deck collision nick
  private _p = getPosASL _veh;
  _veh setPosASL [_p#0, _p#1, (_p#2 + 0.3)];
  _veh setVelocity [0,0,0];

  // Re-enable damage after settle
  [_veh] spawn {
    params ["_v"];
    sleep 2;
    if (!isNull _v) then { _v allowDamage true; };
  };
};


//------------------------------------------------------------------------------
// Phase 1: Launch CAS helicopters (optional, AI-controlled)
//------------------------------------------------------------------------------
{
  private _veh = _x;
  if (isNull _veh) then { continue; };

  [_veh] call _wakeForPlayback;

  private _pilot = driver _veh;
  if (isNull _pilot) then {
    diag_log format ["[ASSAULT] WARNING: CAS helo %1 has no pilot/driver.", _veh];
    continue;
  };

  private _grp = group _pilot;
  { deleteWaypoint _x } forEach waypoints _grp;

  _grp setBehaviourStrong "AWARE";
  _grp setCombatMode "RED";
  _grp setSpeedMode "FULL";

  _veh flyInHeight 120;
  _veh limitSpeed 120;

  private _wp = _grp addWaypoint [_lzCenter, 0];
  _wp setWaypointType "SAD";
  _wp setWaypointCompletionRadius 800;

  private _cycle = _grp addWaypoint [_lzCenter, 0];
  _cycle setWaypointType "CYCLE";

} forEach _casHelis;


//------------------------------------------------------------------------------
// Phase 2: Launch assault helicopters to LZ (waypoint-based landing)
//------------------------------------------------------------------------------
for "_i" from 0 to ((count _assaultHelis) - 1) do {

  private _veh = _assaultHelis select _i;
  private _offset = _landingOffsets select _i;

  if (isNull _veh) then {
    diag_log format ["[ASSAULT] ERROR: Assault helo index %1 is null. Check Eden variable name (heli_assault_2/3/player_1).", _i];
    continue;
  };

  // Wake up the helicopter
  [_veh] call _wakeForPlayback;

  private _pilot = driver _veh;
  if (isNull _pilot) then {
    diag_log format ["[ASSAULT] WARNING: Assault helo %1 has no pilot/driver.", _veh];
    continue;
  };

  private _grp = group _pilot;

  // Clear existing waypoints
  { deleteWaypoint _x } forEach waypoints _grp;

  // Calculate landing position with offset
  private _landingPos = [
    (_lzCenter select 0) + (_offset select 0),
    (_lzCenter select 1) + (_offset select 1),
    0
  ];

  // Set flight parameters
  _grp setBehaviourStrong "CARELESS";
  _grp setCombatMode "BLUE";
  _grp setSpeedMode "FULL";

  _veh flyInHeight _approachHeight;
  _veh limitSpeed _approachSpeed;

  // Waypoint 1: MOVE to landing position
  private _wp1 = _grp addWaypoint [_landingPos, 0];
  _wp1 setWaypointType "MOVE";
  _wp1 setWaypointSpeed "FULL";
  _wp1 setWaypointCompletionRadius 50;

  // Waypoint 2: TR UNLOAD (Transport Unload) - helicopter lands and troops disembark
  private _wp2 = _grp addWaypoint [_landingPos, 0];
  _wp2 setWaypointType "TR UNLOAD";
  _wp2 setWaypointSpeed "LIMITED";
  _wp2 setWaypointCompletionRadius 20;

  // Waypoint 3: HOLD position after unload
  private _wp3 = _grp addWaypoint [_landingPos, 0];
  _wp3 setWaypointType "HOLD";

  diag_log format ["[ASSAULT] Assault helo idx=%1 assigned landing at %2 (offset %3)",
    _i, _landingPos, _offset
  ];

  // Spawn monitoring thread for this helicopter to handle landing and disembark
  [_veh, _landingPos, _i] spawn {
    params ["_heli", "_landPos", "_idx"];

    // Wait until helicopter is close to landing position
    waitUntil {
      sleep 1;
      !alive _heli || ((_heli distance2D _landPos) < 100)
    };
    if (!alive _heli) exitWith {};

    // Order helicopter to land
    _heli land "LAND";

    // Wait until helicopter has landed (on ground or very close)
    waitUntil {
      sleep 0.5;
      !alive _heli || isTouchingGround _heli || ((getPosATL _heli) select 2) < 2
    };
    if (!alive _heli) exitWith {};

    diag_log format ["[ASSAULT] Assault helo idx=%1 has landed at %2", _idx, getPosATL _heli];

    // Brief pause before disembark
    sleep 2;

    // Order all cargo to disembark
    {
      unassignVehicle _x;
      [_x] orderGetIn false;
      _x action ["GetOut", _heli];
    } forEach (crew _heli select { _heli getCargoIndex _x >= 0 });

    diag_log format ["[ASSAULT] Assault helo idx=%1 troops disembarked", _idx];
  };
};
