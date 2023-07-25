require("factions/equip/generic")


equip_typeOutfits_coreSystems["Fidelity"] = {
   "Milspec Prometheus 2203 Core System",
}
equip_typeOutfits_coreSystems["Shaman"] = {
   "Milspec Prometheus 3603 Core System",
}
equip_typeOutfits_coreSystems["Preacher"] = {
   "Milspec Orion 4801 Core System",
}
equip_typeOutfits_coreSystems["Dogma"] = {
   "Milspec Orion 9901 Core System",
}
equip_typeOutfits_coreSystems["Divinity"] = {
   "Milspec Orion 9901 Core System",
}

equip_typeOutfits_engines["Fidelity"] = {
   "Tricon Zephyr Engine",
}
equip_typeOutfits_engines["Shaman"] = {
   "Tricon Zephyr II Engine",
}
equip_typeOutfits_engines["Preacher"] = {
   "Tricon Cyclone Engine",
}
equip_typeOutfits_engines["Reverence"] = {
   "Tricon Cyclone Engine",
}
equip_typeOutfits_engines["Dogma"] = {
   "Unicorp Eagle 6500 Engine", "Tricon Typhoon II Engine",
}
equip_typeOutfits_engines["Divinity"] = {
   "Melendez Mammoth XL Engine",
}

equip_typeOutfits_hulls["Fidelity"] = {
   "S&K Ultralight Stealth Plating", "S&K Ultralight Combat Plating",
}
equip_typeOutfits_hulls["Shaman"] = {
   "S&K Light Stealth Plating", "S&K Light Combat Plating",
}
equip_typeOutfits_hulls["Preacher"] = {
   "S&K Medium Combat Plating",
}
equip_typeOutfits_hulls["Reverence"] = {
   "S&K Medium Combat Plating",
}
equip_typeOutfits_hulls["Dogma"] = {
   "Unicorp D-72 Heavy Plating", "S&K Superheavy Combat Plating",
}
equip_typeOutfits_hulls["Divinity"] = {
   "S&K Superheavy Combat Plating",
}

equip_typeOutfits_weapons["Fidelity"] = equip_shipOutfits_weapons["Sirius Fidelity"]
equip_typeOutfits_weapons["Shaman"] = {
   {
      varied = true;
      "TeraCom Fury Launcher", "TeraCom Medusa Launcher",
      "Unicorp Headhunter Launcher",
   },
   {
      "Razor MK2",
   },
}
equip_typeOutfits_weapons["Preacher"] = {
   {
      num = 1;
      "TeraCom Fury Launcher",
   },
   {
      "Enygma Systems Spearhead Launcher",
   },
   {
      probability = {
         ["Slicer"] = 8,
      };
      "Slicer", "Razor MK2",
   },
}
equip_typeOutfits_weapons["Reverence"] = {
   {
      "Enygma Systems Spearhead Launcher",
   },
   {
      probability = {
         ["Slicer"] = 8,
      };
      "Slicer", "Razor MK2",
   },
}
equip_typeOutfits_weapons["Dogma"] = {
   {
      num = 1;
      "Fidelity Fighter Bay",
   },
   {
      "Heavy Razor Turret",
   },
   {
      "Razor Turret MK2",
   },
}
equip_typeOutfits_weapons["Divinity"] = {
   {
      "Fidelity Fighter Bay",
   },
   {
      "Heavy Razor Turret",
   },
   {
      "Razor Turret MK2",
   },
}


--[[
-- @brief Does sirius pilot equipping
--
--    @param p Pilot to equip
--]]
function equip( p )
   equip_generic( p )
end
