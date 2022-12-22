require "factions/equip/generic"


equip_typeOutfits_coreSystems["Derivative"] = equip_shipOutfits_coreSystems["Proteron Derivative"]
equip_typeOutfits_coreSystems["Kahan"] = {
   "Milspec Orion 5501 Core System"
}
equip_typeOutfits_coreSystems["Archimedes"] = {
   "Milspec Orion 9901 Core System"
}
equip_typeOutfits_coreSystems["Watson"] = {
   "Milspec Orion 9901 Core System"
}

equip_typeOutfits_engines["Derivative"] = equip_shipOutfits_engines["Proteron Derivative"]
equip_typeOutfits_engines["Kahan"] = {
   "Tricon Cyclone II Engine",
}
equip_typeOutfits_engines["Archimedes"] = {
   "Tricon Typhoon II Engine",
}
equip_typeOutfits_engines["Watson"] = {
   "Melendez Mammoth XL Engine",
}

equip_typeOutfits_hulls["Derivative"] = equip_shipOutfits_hulls["Proteron Derivative"]
equip_typeOutfits_hulls["Kahan"] = {
   "S&K Medium-Heavy Stealth Plating",
}
equip_typeOutfits_hulls["Archimedes"] = {
   "S&K Superheavy Combat Plating",
}
equip_typeOutfits_hulls["Watson"] = {
   "S&K Superheavy Combat Plating",
}

equip_typeOutfits_weapons["Derivative"] = equip_shipOutfits_weapons["Proteron Derivative"]
equip_typeOutfits_weapons["Kahan"] = {
   {
      num = 2;
      "Railgun", "Heavy Ripper Turret", "Turreted Mass Driver", "Grave Beam",
   },
   {
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
      "Mini Derivative Fighter Bay",
   }
}
equip_typeOutfits_weapons["Archimedes"] = {
   
   {
      num = 1;
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
      "Derivative Fighter Bay",
   },
   {
      "Heavy Laser Turret", "Railgun Turret", "Ragnarok Beam",
      "Derivative Fighter Bay",
   },
   {
      "Heavy Ripper Turret", "Grave Beam",
   },
}
equip_typeOutfits_weapons["Watson"] = {
   {
      num = 2;
      "Heavy Laser Turret", "Railgun Turret", "Ragnarok Beam",
   },
   {
      "Derivative Fighter Bay",
   },
   {
      "Heavy Ripper Turret", "Grave Beam",
   },
}


--[[
-- @brief Does Proteron pilot equipping
--
--    @param p Pilot to equip
--]]
function equip( p )
   equip_generic( p )
end
