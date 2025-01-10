require "factions/equip/generic"


equip_typeOutfits_weapons["Perspicacity"] = {
   {
      "FL21-U Lumina Gun", "FR11-U Razor Gun", "TeraCom Mace Launcher",
      "TeraCom Banshee Launcher", "Electron Burst Cannon",
   },
}
equip_typeOutfits_weapons["Ingenuity"] = {
   {
      "FL21-U Lumina Gun", "FR11-U Razor Gun", "TeraCom Mace Launcher",
      "TeraCom Banshee Launcher", "Electron Burst Cannon",
   },
}
equip_typeOutfits_weapons["Scintillation"] = {
   {
      varied = true;
      "TeraCom Fury Launcher", "TeraCom Medusa Launcher",
      "Unicorp Headhunter Launcher", "Convulsion Launcher",
   },
   {
      "FL27-S Lumina Gun", "FR18-S Razor Gun",
   },
}
equip_typeOutfits_weapons["Virtuosity"] = {
   {
      varied = true;
      "Unicorp Fury Launcher", "Unicorp Headhunter Launcher",
      "Unicorp Medusa Launcher", "Unicorp Vengeance Launcher",
      "Enygma Systems Spearhead Launcher", "Unicorp Caesar IV Launcher",
      "TeraCom Fury Launcher", "TeraCom Headhunter Launcher",
      "TeraCom Medusa Launcher", "TeraCom Vengeance Launcher",
      "TeraCom Imperator Launcher", "Convulsion Launcher",
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
      "TL110-L Lumina Turret", "TS150-L Spear Turret", "TI193-X Ion-Shackle Turret",
   },
   {
      num = 1;
      "Enygma Systems Turreted Fury Launcher",
      "Turreted Convulsion Launcher",
   },
   {
      "TL54-M Lumina Turret", "TR42-M Razor Turret", "TS81-M Spear Turret",
      "EMP Grenade Launcher", "Enygma Systems Turreted Fury Launcher",
      "Turreted Convulsion Launcher",
   },
}
equip_typeOutfits_weapons["Apprehension"] = {
   {
      "TL110-L Lumina Turret", "TS150-L Spear Turret", "TI193-X Ion-Shackle Turret",
   },
   {
      num = 1;
      "Enygma Systems Turreted Fury Launcher",
      "Turreted Convulsion Launcher",
   },
   {
      "TL54-M Lumina Turret", "TR42-M Razor Turret", "TS81-M Spear Turret",
      "EMP Grenade Launcher", "Enygma Systems Turreted Fury Launcher",
      "Turreted Convulsion Launcher",
   },
}
equip_typeOutfits_weapons["Certitude"] = {
   {
      num = 1;
      "Enygma Systems Turreted Fury Launcher",
      "Turreted Convulsion Launcher",
   },
   {
      "TL200-X Lumina Turret", "TS257-X Spear Turret",
   },
   {
      "TL110-L Lumina Turret", "TS150-L Spear Turret", "TI193-X Ion-Shackle Turret",
   },
}

equip_typeOutfits_structurals["Perspicacity"] = {
   {
      varied = true, probability = {
         ["Fuel Pod"] = 4, ["Improved Stabilizer"] = 2
      };
      "Fuel Pod", "Improved Stabilizer", "Shield Capacitor",
      "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Ingenuity"] = {
   {
      varied = true, probability = {
         ["Steering Thrusters"] = 4, ["Engine Reroute"] = 4,
      };
      "Fuel Pod", "Steering Thrusters", "Engine Reroute", "Battery",
      "Shield Capacitor", "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Scintillation"] = {
   {
      varied = true;
      "Fuel Pod", "Steering Thrusters", "Engine Reroute", "Shield Capacitor",
      "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Virtuosity"] = {
   {
      varied = true;
      "Medium Fuel Pod", "Battery II", "Shield Capacitor II",
      "Plasteel Plating", "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Taciturnity"] = {
   {
      varied = true, probability = {
         ["Cargo Pod"] = 15, ["Medium Fuel Pod"] = 3,
      };
      "Cargo Pod", "Medium Fuel Pod", "Battery II", "Shield Capacitor II",
      "Plasteel Plating", "Adaptive Stealth Plating",
   },
}
equip_typeOutfits_structurals["Apprehension"] = {
   {
      varied = true;
      "Large Fuel Pod", "Battery III", "Shield Capacitor IV",
      "Shield Capacitor III", "Nanobond Plating",
   },
   {
      varied = true;
      "Medium Fuel Pod", "Battery II", "Shield Capacitor II",
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
