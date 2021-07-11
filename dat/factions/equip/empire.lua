require "factions/equip/generic"


equip_typeOutfits_coreSystems["Shark"] = {
   "Milspec Orion 2301 Core System",
}
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

equip_typeOutfits_engines["Shark"] = {
   "Tricon Zephyr Engine",
}
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

equip_typeOutfits_hulls["Shark"] = {
   "S&K Ultralight Stealth Plating", "S&K Ultralight Combat Plating",
}
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

equip_typeOutfits_weapons["Shark"] = {
   {
      num = 1;
      "Unicorp Banshee Launcher", "TeraCom Banshee Launcher",
      "Unicorp Mace Launcher", "TeraCom Mace Launcher",
   },
   {
      "Laser Cannon MK1", "Plasma Blaster MK1", "Ion Cannon",
   },
}
equip_typeOutfits_weapons["Lancelot"] = equip_shipOutfits_weapons["Empire Lancelot"]
equip_typeOutfits_weapons["Admonisher"] = {
   {
      varied = true;
      "Unicorp Fury Launcher", "Unicorp Headhunter Launcher",
      "Unicorp Medusa Launcher", "Unicorp Vengeance Launcher",
      "Enygma Systems Spearhead Launcher", "Unicorp Caesar IV Launcher",
      "TeraCom Fury Launcher", "TeraCom Headhunter Launcher",
      "TeraCom Medusa Launcher", "TeraCom Vengeance Launcher",
      "TeraCom Imperator Launcher", "Enygma Systems Huntsman Launcher",
   },
   {
      probability = {
         ["Ripper Cannon"] = 8, ["Plasma Cannon"] = 4,
      };
      "Ripper Cannon", "Plasma Cannon", "Laser Cannon MK2",
      "Plasma Blaster MK2",
   },
}
equip_typeOutfits_weapons["Pacifier"] = {
   {
      "Heavy Ripper Turret", "Grave Beam", "Heavy Ion Turret",
   },
   {
      num = 1;
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
   },
   {
      num = 1;
      "Laser Turret MK2", "Plasma Turret MK2", "Orion Beam",
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
   },
   {
      "Laser Turret MK2", "Plasma Turret MK2", "Orion Beam",
   },
}

--[[
-- @brief Does empire pilot equipping
--
--    @param p Pilot to equip
--]]
function equip( p )
   if diff.isApplied( "collective_dead" ) then
      equip_typeOutfits_weapons["Peacemaker"] = {
         {
            varied = true;
            "Empire Lancelot Fighter Bay", "Drone Fighter Bay",
         },
         {
            "Turbolaser", "Heavy Laser Turret", "Ragnarok Beam",
         },
         {
            "Heavy Ripper Turret",
         },
      }
   else
      equip_typeOutfits_weapons["Peacemaker"] = {
         {
            varied = true;
            "Empire Lancelot Fighter Bay",
         },
         {
            "Turbolaser", "Heavy Laser Turret", "Ragnarok Beam",
         },
         {
            "Heavy Ripper Turret",
         },
      }
   end
   
   equip_generic( p )
end
