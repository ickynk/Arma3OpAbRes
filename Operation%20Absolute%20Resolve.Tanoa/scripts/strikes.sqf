if (!isServer) exitWith {};

strikeTargets = [
  ["tgt_port",   false],
  ["tgt_airport",false],
  ["tgt_base1",  false]
];
publicVariable "strikeTargets";

fnc_doStrike = {
  params ["_pos", "_type"];

  // Example types: "BOMB", "NAVAL"
  switch (_type) do {
    case "BOMB": {
      // Spawn a few explosions
      for "_i" from 1 to 6 do {
        private _p = _pos getPos [random 35, random 360];
        "Bo_Mk82" createVehicle _p;
        sleep 0.4;
      };
    };
    case "NAVAL": {
      for "_i" from 1 to 10 do {
        private _p = _pos getPos [random 60, random 360];
        "Sh_155mm_AMOS" createVehicle _p;
        sleep 0.25;
      };
    };
  };
};

publicVariable "fnc_doStrike";
