require "factions/equip/generic"


equip_typeOutfits_weapons["Perspicacity"] = {
   {
      "FL21-U Lumina Gun", "FR11-U Razor Gun", "FRS60-U Stinger Rocket Gun",
      "FRC80-U Claw Rocket Gun", "FRB50-U Buzzer Cell Gun",
   },
}
equip_typeOutfits_weapons["Ingenuity"] = {
   {
      "FL21-U Lumina Gun", "FR11-U Razor Gun", "FRS60-U Stinger Rocket Gun",
      "FRC80-U Claw Rocket Gun", "FRB50-U Buzzer Cell Gun",
   },
}
equip_typeOutfits_weapons["Scintillation"] = {
   {
      varied = true;
      "FMT40-S Tiger Missile Gun", "FMS300-H Spider Missile Gun",
      "FMT80-S Tiger Missile Gun", "FMO75-S Orca Missile Gun",
   },
   {
      "FL27-S Lumina Gun", "FR18-S Razor Gun",
   },
}
equip_typeOutfits_weapons["Virtuosity"] = {
   {
      varied = true;
      "FMT40-S Tiger Missile Gun", "FMT80-S Tiger Missile Gun",
      "FMS300-H Spider Missile Gun", "FMT200-H Tiger Missile Gun",
      "FMO200-H Orca Missile Gun", "FMT800-H Tiger Torpedo Gun",
      "FMT1000-H Tiger Torpedo Gun", "FMO75-S Orca Missile Gun",
   },
   {
      probability = {
         ["FL50-H Lumina Gun"] = 8, ["FR39-H Razor Gun"] = 8,
      };
      "FL50-H Lumina Gun", "FR39-H Razor Gun", "FL27-S Lumina Gun", "FR18-S Razor Gun",
   },
}
equip_typeOutfits_weapons["Taciturnity"] = {
   {
      "TL110-L Lumina Turret", "TS150-L Spear Turret", "Ti193-X Ion-Shackle Turret",
   },
   {
      num = 1;
      "TMT40-M Tiger Missile Turret",
      "TMO75-M Orca Missile Turret",
   },
   {
      "TL54-M Lumina Turret", "TR42-M Razor Turret", "TS81-M Spear Turret",
      "TRV250-M Venom Grenade Turret", "TMT40-M Tiger Missile Turret",
      "TMO75-M Orca Missile Turret",
   },
}
equip_typeOutfits_weapons["Apprehension"] = {
   {
      "TL110-L Lumina Turret", "TS150-L Spear Turret", "Ti193-X Ion-Shackle Turret",
   },
   {
      num = 1;
      "TMT40-M Tiger Missile Turret",
      "TMO75-M Orca Missile Turret",
   },
   {
      "TL54-M Lumina Turret", "TR42-M Razor Turret", "TS81-M Spear Turret",
      "TRV250-M Venom Grenade Turret", "TMT40-M Tiger Missile Turret",
      "TMO75-M Orca Missile Turret",
   },
}
equip_typeOutfits_weapons["Certitude"] = {
   {
      num = 1;
      "TMT40-M Tiger Missile Turret",
      "TMO75-M Orca Missile Turret",
   },
   {
      "TL200-X Lumina Turret", "TS257-X Spear Turret",
   },
   {
      "TL110-L Lumina Turret", "TS150-L Spear Turret", "Ti193-X Ion-Shackle Turret",
   },
}

equip_typeOutfits_structurals["Perspicacity"] = {
   {
      varied = true, probability = {
         ["Small Fuel Pod"] = 4, ["Improved Stabilizer"] = 2
      };
      "Small Fuel Pod", "Improved Stabilizer", "Small Shield Capacitor",
      "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Ingenuity"] = {
   {
      varied = true, probability = {
         ["Steering Thrusters"] = 4, ["Engine Reroute"] = 4,
      };
      "Small Fuel Pod", "Steering Thrusters", "Engine Reroute", "Small Battery",
      "Small Shield Capacitor", "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Scintillation"] = {
   {
      varied = true;
      "Small Fuel Pod", "Steering Thrusters", "Engine Reroute", "Small Shield Capacitor",
      "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Virtuosity"] = {
   {
      varied = true;
      "Medium Fuel Pod", "Medium Battery", "Medium Shield Capacitor",
      "Plasteel Plating", "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Taciturnity"] = {
   {
      varied = true, probability = {
         ["Small Cargo Pod"] = 15, ["Medium Fuel Pod"] = 3,
      };
      "Small Cargo Pod", "Medium Fuel Pod", "Medium Battery", "Medium Shield Capacitor",
      "Plasteel Plating", "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Apprehension"] = {
   {
      varied = true;
      "Large Fuel Pod", "Large Battery", "Dense Shield Capacitor",
      "Large Shield Capacitor", "Nanobond Plating",
   },
   {
      varied = true;
      "Medium Fuel Pod", "Medium Battery", "Medium Shield Capacitor",
      "Plasteel Plating", "Adaptive Stealth Plating",
   },
}


--[[
-- @brief Does Thurion pilot equipping
--
--    @param p Pilot to equip
--]]
function equip( p )
   equip_generic( p )
end
