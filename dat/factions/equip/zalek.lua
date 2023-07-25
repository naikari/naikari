require "factions/equip/generic"


equip_typeOutfits_coreSystems["Sting"] = {
   "Milspec Aegis 4701 Core System",
}
equip_typeOutfits_coreSystems["Demon"] = {
   "Milspec Prometheus 5403 Core System",
}
equip_typeOutfits_coreSystems["Mephisto"] = {
   "Milspec Prometheus 8503 Core System",
}
equip_typeOutfits_coreSystems["Diablo"] = {
   "Milspec Orion 9901 Core System",
}
equip_typeOutfits_coreSystems["Hephaestus"] = {
   "Milspec Hermes 9802 Core System",
}

equip_typeOutfits_engines["Sting"] = {
   "Tricon Cyclone Engine",
}
equip_typeOutfits_engines["Demon"] = {
   "Tricon Cyclone II Engine",
}
equip_typeOutfits_engines["Mephisto"] = {
   "Unicorp Eagle 6500 Engine", "Tricon Typhoon II Engine",
}
equip_typeOutfits_engines["Diablo"] = {
   "Tricon Typhoon II Engine",
}
equip_typeOutfits_engines["Hephaestus"] = {
   "Melendez Mammoth XL Engine",
}

equip_typeOutfits_hulls["Sting"] = {
   "S&K Medium Stealth Plating", "S&K Medium Combat Plating",
}
equip_typeOutfits_hulls["Demon"] = {
   "S&K Medium-Heavy Stealth Plating", "S&K Medium-Heavy Combat Plating",
}
equip_typeOutfits_hulls["Mephisto"] = {
   "Unicorp D-48 Heavy Plating", "S&K Heavy Combat Plating",
}
equip_typeOutfits_hulls["Diablo"] = {
   "Unicorp D-48 Heavy Plating", "S&K Heavy Combat Plating",
}
equip_typeOutfits_hulls["Hephaestus"] = {
   "Unicorp D-72 Heavy Plating", "S&K Superheavy Combat Plating",
}

equip_typeOutfits_weapons["Sting"] = {
   {
      "Za'lek Reaper Launcher",
   },
   {
      "TeraCom Headhunter Launcher",
   },
   {
      "Orion Lance",
   },
}
equip_typeOutfits_weapons["Demon"] = {
   {
      "Grave Beam",
   },
   {
      num = 1;
      "Za'lek Hunter Launcher",
      "Mini Za'lek Light Drone Fighter Bay",
   },
   {
      num = 1;
      "Za'lek Hunter Launcher",
      "Mini Za'lek Light Drone Fighter Bay",
      "Orion Beam",
   },
   {
      "Orion Beam",
   },
}
equip_typeOutfits_weapons["Diablo"] = {
   {
      varied = true;
      "Za'lek Light Drone Fighter Bay", "Za'lek Heavy Drone Fighter Bay",
      "Za'lek Bomber Drone Fighter Bay",
   },
   {
      "Ragnarok Beam",
   },
   {
      "Grave Beam",
   },
}
equip_typeOutfits_weapons["Mephisto"] = {
   {
      num = 1;
      "Za'lek Light Drone Fighter Bay", "Za'lek Heavy Drone Fighter Bay",
      "Za'lek Bomber Drone Fighter Bay",
   },
   {
      "Grave Beam",
      "Za'lek Light Drone Fighter Bay", "Za'lek Heavy Drone Fighter Bay",
      "Za'lek Bomber Drone Fighter Bay",
   },
}
equip_typeOutfits_weapons["Hephaestus"] = {
   {
      varied = true;
      "Za'lek Light Drone Fighter Bay", "Za'lek Heavy Drone Fighter Bay",
      "Za'lek Bomber Drone Fighter Bay",
   },
   {
      "Ragnarok Beam",
   },
   {
      "Grave Beam",
   },
}


--[[
-- @brief Does Za'lek pilot equipping
--
--    @param p Pilot to equip
--]]
function equip( p )
   equip_generic( p )
end
