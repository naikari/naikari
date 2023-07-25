require "factions/equip/generic"


equip_typeOutfits_coreSystems["Shark"] = equip_shipOutfits_coreSystems["Empire Shark"]
equip_typeOutfits_coreSystems["Lancelot"] = equip_shipOutfits_coreSystems["Empire Lancelot"]
equip_typeOutfits_coreSystems["Admonisher"] = {
   "Milspec Orion 4801 Core System",
}
equip_typeOutfits_coreSystems["Pacifier"] = {
   "Milspec Orion 5501 Core System",
}
equip_typeOutfits_coreSystems["Hawking"] = {
   "Milspec Orion 8601 Core System",
}
equip_typeOutfits_coreSystems["Peacemaker"] = {
   "Milspec Orion 9901 Core System",
}

equip_typeOutfits_engines["Shark"] = equip_shipOutfits_engines["Empire Shark"]
equip_typeOutfits_engines["Lancelot"] = equip_shipOutfits_engines["Empire Lancelot"]
equip_typeOutfits_engines["Admonisher"] = {
   "Tricon Cyclone Engine",
}
equip_typeOutfits_engines["Pacifier"] = {
   "Tricon Cyclone II Engine",
}
equip_typeOutfits_engines["Hawking"] = {
   "Tricon Typhoon Engine",
}
equip_typeOutfits_engines["Peacemaker"] = {
   "Melendez Mammoth XL Engine",
}

equip_typeOutfits_hulls["Shark"] = equip_shipOutfits_hulls["Empire Shark"]
equip_typeOutfits_hulls["Lancelot"] = equip_shipOutfits_hulls["Empire Lancelot"]
equip_typeOutfits_hulls["Admonisher"] = {
   "S&K Medium Stealth Plating", "S&K Medium Combat Plating",
}
equip_typeOutfits_hulls["Pacifier"] = {
   "S&K Medium-Heavy Stealth Plating", "S&K Medium-Heavy Combat Plating",
}
equip_typeOutfits_hulls["Hawking"] = {
   "Unicorp D-48 Heavy Plating", "S&K Heavy Combat Plating",
}
equip_typeOutfits_hulls["Peacemaker"] = {
   "S&K Superheavy Combat Plating",
}

equip_typeOutfits_weapons["Shark"] = equip_shipOutfits_weapons["Empire Shark"]
equip_typeOutfits_weapons["Lancelot"] = equip_shipOutfits_weapons["Empire Lancelot"]
equip_typeOutfits_weapons["Admonisher"] = {
   {
      varied = true;
      "Unicorp Fury Launcher", "Unicorp Headhunter Launcher",
      "TeraCom Fury Launcher", "TeraCom Headhunter Launcher",
   },
   {
      probability = {
         ["Ripper Cannon"] = 8,
      };
      "Ripper Cannon", "Laser Cannon MK2",
   },
}
equip_typeOutfits_weapons["Pacifier"] = {
   {
      "Heavy Ripper Turret",
   },
   {
      num = 1;
      "Mini Empire Shark Fighter Bay",
      "Mini Empire Lancelot Fighter Bay",
   },
   {
      num = 1;
      "Laser Turret MK2",
      "Mini Empire Shark Fighter Bay",
      "Mini Empire Lancelot Fighter Bay",
   },
   {
      "Laser Turret MK2",
   },
}
equip_typeOutfits_weapons["Hawking"] = {
   {
      num = 1;
      "Empire Shark Fighter Bay", "Empire Lancelot Fighter Bay",
   },
   {
      num = 1;
      "Heavy Ripper Turret",
      "Empire Shark Fighter Bay", "Empire Lancelot Fighter Bay",
   },
   {
      "Heavy Ripper Turret",
   },
}
equip_typeOutfits_weapons["Peacemaker"] = {
   {
      varied = true;
      "Empire Shark Fighter Bay", "Empire Lancelot Fighter Bay",
   },
   {
      "Turbolaser", "Heavy Laser Turret",
   },
   {
      "Heavy Ripper Turret",
   },
}

--[[
-- @brief Does empire pilot equipping
--
--    @param p Pilot to equip
--]]
function equip(p)
   equip_generic(p)
end
