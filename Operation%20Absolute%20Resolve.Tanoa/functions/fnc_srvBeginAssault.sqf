fnc_srvBeginAssault = {
  if (!isServer) exitWith {};
  if ((missionNamespace getVariable ["missionPhase",1]) != 3) exitWith {};
  if (missionNamespace getVariable ["assaultBegun", false]) exitWith {};
  missionNamespace setVariable ["assaultBegun", true, true];


  // Package lists (edit as needed)
  private _assaultHelis = [heli_player_1, heli_assault_2, heli_assault_3];
  private _casHelis     = [heli_cas_1]; // optional; remove if not used

  private _lz = getMarkerPos "mrk_lz";

// Build unique LZ slot positions
private _slots = [_lz, count _assaultHelis] call fnc_getLZSlots;

{
  private _heli = _x;
  private _slotPos = _slots select _forEachIndex;
  private _delay = _forEachIndex * 3;  // stagger launch: 0s, 3s, 6s...

  [_heli, _slotPos, _delay] spawn {
    params ["_heli","_slotPos","_delay"];
    sleep _delay;

    if (isNull _heli) exitWith {};

    _heli hideObjectGlobal false;
    _heli enableSimulationGlobal true;
    _heli engineOn true;

    _heli flyInHeight 70;
    _heli limitSpeed 70; // keeps them from bunching up as hard

    private _grp = group (driver _heli);

    // Clean waypoints
    { deleteWaypoint _x } forEach waypoints _grp;

    // Make them less “all rush same point”
    _grp setFormation "WEDGE";
    _grp setBehaviourStrong "AWARE";
    _grp setCombatMode "YELLOW";
    _grp setSpeedMode "NORMAL";

    // MOVE to their unique slot near LZ
    private _wp = _grp addWaypoint [_slotPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointCompletionRadius 80;
    _wp setWaypointSpeed "NORMAL";
  };
} forEach _assaultHelis;

  // CAS: orbit / engage near LZ (optional)
  {
    if (!isNull _x) then {
      _x hideObjectGlobal false;
      _x enableSimulationGlobal true;
      _x engineOn true;

      _x flyInHeight 120;
      private _grp = group (driver _x);
      { deleteWaypoint _x } forEach waypoints _grp;

      _grp setBehaviourStrong "AWARE";
      _grp setCombatMode "RED";
      _grp setSpeedMode "FULL";

      // SAD around LZ
      private _wpSAD = _grp addWaypoint [_lz, 0];
      _wpSAD setWaypointType "SAD";
      _wpSAD setWaypointCompletionRadius 600;

      // Cycle
      private _wpC = _grp addWaypoint [_lz, 0];
      _wpC setWaypointType "CYCLE";
    };
  } forEach _casHelis;

  // After a short travel time, make assault helos fast-rope when close
  // (We do it with a monitor loop so it works no matter route/time.)
  [_assaultHelis] spawn {
    params ["_assaultHelis"];
    private _lz = getMarkerPos "mrk_lz";

    while {true} do {
      private _allDone = true;

      {
        if (!isNull _x && alive _x) then {
          // If this helo still has cargo units aboard and is near LZ, rope them
          private _cargo = (crew _x) select { alive _x && (_x in _x) }; // dummy-safe; we'll override below
        };
      } forEach _assaultHelis;

      // We'll rope each helo once using a variable flag:
      {
        if (!isNull _x && alive _x) then {
          if (!(_x getVariable ["didFastRope", false]) && ((_x distance2D _lz) < 250)) then {
            [_x, _lz] call fnc_srvFastRopeAtLZ;
            _x setVariable ["didFastRope", true, true];
          };
        };
      } forEach _assaultHelis;

      // Exit when all helos have roped
      _allDone = { _x getVariable ["didFastRope", false] } count _assaultHelis == count _assaultHelis;
      if (_allDone) exitWith {};

      sleep 5;
    };
  };

};
publicVariable "fnc_srvBeginAssault";