//==============================================================================
// functions/fn_deWeaponUI.sqf
//==============================================================================
// Client function: Opens map for player to select DE weapon target location
// - Only available during Phase 3 (Assault phase)
// - Cooldown between uses to prevent spam
// - Sends selected position to server for processing
//
// Parameters: None
//
// Called from: Player action menu (initPlayerLocal.sqf)
// Runs on: Client with interface
//==============================================================================

if (!hasInterface) exitWith {};

// Only available during Phase 3 (assault phase)
if ((missionNamespace getVariable ["missionPhase", 1]) != 3) exitWith {
  hint "Directed Energy Weapon only available during assault phase.";
};

// Cooldown check (30 second cooldown between uses)
private _lastUse = missionNamespace getVariable ["de_lastUseTime", 0];
private _cooldown = 30;
if (time - _lastUse < _cooldown) exitWith {
  private _remaining = ceil (_cooldown - (time - _lastUse));
  hint format ["Directed Energy Weapon on cooldown.\nAvailable in %1 seconds.", _remaining];
};

hint "Select target location on the map.\n\nDirected Energy Weapon\n- 50m radius effect\n- 60% effectiveness rate\n- Incapacitates OpFor for 60 seconds";

openMap true;

onMapSingleClick "
  openMap false;
  onMapSingleClick {};
  missionNamespace setVariable ['de_lastUseTime', time];
  ['DE', _pos] remoteExecCall ['fnc_srvStrikeExecute', 2];
  hint 'Directed Energy Weapon firing...';
";
