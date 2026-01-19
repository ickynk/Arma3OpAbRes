//==============================================================================
// scripts/strikeScheduler.sqf
//==============================================================================
// Server-side strike scheduler for Phase 2/3
// - Randomly selects strike points from finalized strike plan
// - Executes strikes at random intervals
// - Continues until mission end (or optional stop conditions)
//
// Configuration:
//   _minDelay: Minimum seconds between strikes (default: 1)
//   _maxDelay: Maximum seconds between strikes (default: 5)
//   _stopAfterExtract: Stop strikes after HVT extracted (default: false)
//
// Called from: fn_srvStrikePlan.sqf (when package finalized)
// Runs on: Server only
//==============================================================================

if (!isServer) exitWith {};
if (!strikeFinalized) exitWith {};

//------------------------------------------------------------------------------
// Configuration
//------------------------------------------------------------------------------
private _minDelay = 1;                   // Minimum seconds between strikes
private _maxDelay = 5;                   // Maximum seconds between strikes
private _stopAfterExtract = false;       // Stop strikes after HVT extracted

//------------------------------------------------------------------------------
// Main strike loop
//------------------------------------------------------------------------------
while { strikeFinalized } do {

  // Optional stop condition: HVT extracted and near RTB
  if (_stopAfterExtract) then {
    if ((hvtArrested) && (hvt_1 in heli_exfil_1) && (heli_exfil_1 distance2D (getMarkerPos "mrk_rtb") < 200)) exitWith {};
  };

  sleep (_minDelay + random (_maxDelay - _minDelay));

  if ((count strikePlan) == 0) then { continue; };

  // Pick a random strike point from the plan
  private _pick = selectRandom strikePlan;
  private _type = _pick select 0;
  private _pos  = _pick select 1;

  // Notify all players
  [format ["Incoming %1 fires near grid!", _type]] remoteExec ["hint", 0];

  // Execute the strike
  [_type, _pos] call fnc_srvStrikeExecute;
};
