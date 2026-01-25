//==============================================================================
// init.sqf
//==============================================================================
// Main initialization file - runs on ALL machines (server, client, headless)
// Compiles all global functions used throughout the mission
//==============================================================================

//------------------------------------------------------------------------------
// Compile global functions
//------------------------------------------------------------------------------
fnc_common            = compileFinal preprocessFileLineNumbers "functions\fn_common.sqf";
fnc_phaseAdvance      = compileFinal preprocessFileLineNumbers "functions\fn_phaseAdvance.sqf";

fnc_strikeUI          = compileFinal preprocessFileLineNumbers "functions\fn_strikeUI.sqf";
fnc_srvStrikePlan     = compileFinal preprocessFileLineNumbers "functions\fn_srvStrikePlan.sqf";
fnc_srvStrikeExecute  = compileFinal preprocessFileLineNumbers "functions\fn_srvStrikeExecute.sqf";
fnc_deWeaponUI        = compileFinal preprocessFileLineNumbers "functions\fn_deWeaponUI.sqf";
