if (!isServer) exitWith {};
if (!strikeFinalized) exitWith {};

// Tune these:
private _minDelay = 1;    // seconds
private _maxDelay = 5;   // seconds

// OPTIONAL: stop strikes after HVT extracted? set true to stop.
private _stopAfterExtract = false;

while { strikeFinalized } do {

  // Optional stop condition
  if (_stopAfterExtract) then {
    // Example: HVT in exfil and exfil near RTB marker
    if ((hvtArrested) && (hvt_1 in heli_exfil_1) && (heli_exfil_1 distance2D (getMarkerPos "mrk_rtb") < 200)) exitWith {};
  };

  sleep (_minDelay + random (_maxDelay - _minDelay));

  if ((count strikePlan) == 0) then { continue; };

  // Pick a random planned strike point
  private _pick = selectRandom strikePlan;
  private _type = _pick select 0;
  private _pos  = _pick select 1;

  // Broadcast flavor text (optional)
  [format ["Incoming %1 fires near grid!", _type]] remoteExec ["hint", 0];

  // Execute strike
  [_type, _pos] call fnc_srvStrikeExecute;
};
