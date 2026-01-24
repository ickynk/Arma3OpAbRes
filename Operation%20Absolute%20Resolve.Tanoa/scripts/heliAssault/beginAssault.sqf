//==============================================================================
// scripts/heliAssault/beginAssault.sqf
//==============================================================================
// Phase 3 helicopter assault sequence
// - Launches AI CAS (Close Air Support) helicopters with SAD waypoints
// - Plays back pre-recorded tracks for assault helicopters
// - Triggers ACE fast-rope when helicopters reach LZ
//
// Required Eden objects (variable names):
//   - heli_assault_2, heli_assault_3, heli_player_1 (assault helicopters)
//   - heli_cas_1, heli_cas_2 (optional CAS helicopters)
//
// Required markers:
//   - mrk_lz (Landing Zone center point)
//
// Required track files (scripts\heliAssault\tracks\):
//   - track_assault_2.sqf, track_assault_3.sqf, track_player_1.sqf
//
// AI Handling:
//   TARGET/AUTOTARGET disabled and waypoints cleared before track playback.
//   MOVE/PATH must remain enabled - unitPlay requires the AI movement system.
//   AI is NOT re-enabled after playback - helicopters remain stationary at LZ.
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

// Assault helicopters (will playback recorded tracks)
private _assaultHelis = [_heliAssault2, _heliAssault3, _heliPlayer1];

// Matching track files (same order as helicopters)
// Each file is execVM'd on the vehicle owner - track data stays on disk, no network serialization
private _assaultTrackFiles = [
  "scripts\heliAssault\tracks\track_assault_2.sqf",
  "scripts\heliAssault\tracks\track_assault_3.sqf",
  "scripts\heliAssault\tracks\track_player_1.sqf"
];

// Optional CAS helicopters (AI-controlled, NOT on recorded tracks)
private _casHelis = [];
private _heliCas1 = missionNamespace getVariable ["heli_cas_1", objNull];
private _heliCas2 = missionNamespace getVariable ["heli_cas_2", objNull];
if (!isNull _heliCas1) then { _casHelis pushBack _heliCas1; };
if (!isNull _heliCas2) then { _casHelis pushBack _heliCas2; };

// Landing zone
private _lzCenter = getMarkerPos "mrk_lz";

// Fast-rope configuration
private _ropeTriggerRadius = 45;         // Distance from LZ to start fast-rope (meters)
private _ropeStagger       = 8;          // Delay between each helicopter roping (seconds)

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


// --- 2) Start assault helo playback tracks (LOCALITY-SAFE via remoteExec to vehicle owner)
for "_i" from 0 to ((count _assaultHelis) - 1) do {

  private _veh       = _assaultHelis select _i;
  private _trackFile = _assaultTrackFiles select _i;

  if (isNull _veh) then {
    diag_log format ["[ASSAULT] ERROR: Assault helo index %1 is null. Check Eden variable name (heli_assault_2/3/player_1).", _i];
    continue;
  };

  if (_trackFile == "") then {
    diag_log format ["[ASSAULT] ERROR: No track file for index %1. Check _assaultTrackFiles.", _i];
    continue;
  };

  // Wake up first (server-side changes replicate)
  [_veh] call _wakeForPlayback;

  // Debug locality
  diag_log format ["[ASSAULT] Playback helo idx=%1 track=%2 localOnServer=%3 owner=%4",
    _i, _trackFile, local _veh, owner _veh
  ];

  // Disable targeting AI, clear waypoints, then execVM the track file on vehicle owner
  // MOVE/PATH must remain enabled - unitPlay requires the AI movement system
  // Track data stays on disk and is loaded locally via execVM - no network serialization
  [[_veh, _trackFile], {
    params ["_v", "_f"];
    private _p = driver _v;
    if (!isNull _p) then {
      { _p disableAI _x } forEach ["TARGET","AUTOTARGET"];
      private _grp = group _p;
      { deleteWaypoint _x } forEach waypoints _grp;
    };
    [_v] execVM _f;
  }] remoteExec ["BIS_fnc_call", _veh];
};


// --- 3) Fast rope trigger loop (distance-based)
// IMPORTANT: this loop runs on SERVER; ACE fast-rope functions are usually fine server-side,
// but if your modpack requires locality, we remoteExec them to the vehicle locality too.
[] spawn {
  sleep 2;

  private _lz = getMarkerPos "mrk_lz";

  // Rope only assault helos (not CAS)
  private _targets = [
    missionNamespace getVariable ["heli_assault_2", objNull],
    missionNamespace getVariable ["heli_assault_3", objNull]
  ] select { !isNull _x };

  {
    private _veh = _x;
    if (isNull _veh || !alive _veh) then { continue; };

    waitUntil {
      sleep 0.5;
      !alive _veh || ((_veh distance2D _lz) < _ropeTriggerRadius)
    };
    if (!alive _veh) then { continue; };

    // Equip FRIES (run on vehicle locality if present)
    if (!isNil "ace_fastroping_fnc_equipFRIES") then {
      [_veh] remoteExec ["ace_fastroping_fnc_equipFRIES", _veh];
      sleep 0.5;
    };

    // Fast rope (run on vehicle locality if present)
    if (!isNil "ace_fastroping_fnc_fastRope") then {
      [_veh] remoteExec ["ace_fastroping_fnc_fastRope", _veh];
    } else {
      { unassignVehicle _x; moveOut _x; } forEach (assignedCargo _veh);
    };

    sleep _ropeStagger;

  } forEach _targets;
};
