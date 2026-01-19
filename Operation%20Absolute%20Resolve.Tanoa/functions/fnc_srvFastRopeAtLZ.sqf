fnc_srvFastRopeAtLZ = {
  if (!isServer) exitWith {};
  params ["_heli", "_lzPos"];

  if (isNull _heli || !alive _heli) exitWith {};

  // Stabilize hover over LZ
  _heli flyInHeight 25;
  _heli limitSpeed 55;

  // Force a hover-ish hold by giving a MOVE waypoint right on LZ, slow speed
  private _grp = group (driver _heli);
  { deleteWaypoint _x } forEach waypoints _grp;

  private _wp = _grp addWaypoint [_lzPos, 0];
  _wp setWaypointType "MOVE";
  _wp setWaypointSpeed "LIMITED";
  _wp setWaypointCompletionRadius 30;

  // Wait until close enough and slow enough
  private _t0 = time;
  waitUntil {
    sleep 0.5;
    (!alive _heli)
    || ((_heli distance2D _lzPos) < 35 && (speed _heli) < 40)
    || (time > _t0 + 90)
  };
  if (!alive _heli) exitWith {};

  // ACE FASTROPE (best if ace_fastroping is present)
  // These function names are correct for most ACE3 builds; if yours differs, tell me and I’ll adapt.
  if (!isNil "ace_fastroping_fnc_equipFRIES") then {
    // Equip ropes if not already
    [_heli] call ace_fastroping_fnc_equipFRIES;
  };

  // Let it settle
  sleep 1.5;

  if (!isNil "ace_fastroping_fnc_fastRope") then {
    [_heli] call ace_fastroping_fnc_fastRope;
  } else {
    // Fallback: unload normally if fastrope fn not available
    { unassignVehicle _x; moveOut _x; } forEach (assignedCargo _heli);
  };
};
publicVariable "fnc_srvFastRopeAtLZ";