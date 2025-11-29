require "factions/equip/generic"


-- Probability of cargo by class.
equip_classCargo["Yacht"] = 0.01
equip_classCargo["Luxury Yacht"] = 0.01
equip_classCargo["Scout"] = 0.01
equip_classCargo["Courier"] = 0.5
equip_classCargo["Freighter"] = 0.5
equip_classCargo["Armored Transport"] = 0.5
equip_classCargo["Bulk Freighter"] = 0.5
equip_classCargo["Fighter"] = 0.01
equip_classCargo["Bomber"] = 0.01
equip_classCargo["Corvette"] = 0.01
equip_classCargo["Destroyer"] = 0.01
equip_classCargo["Cruiser"] = 0.01
equip_classCargo["Carrier"] = 0.01
equip_classCargo["Drone"] = 0.01
equip_classCargo["Heavy Drone"] = 0.01


equip_typeOutfits_coreSystems["Shark"] = {
   "Intek Orion 2201 APU",
}
equip_typeOutfits_coreSystems["Lancelot"] = {
   "Intek Orion 3301 APU",
}
equip_typeOutfits_coreSystems["Admonisher"] = {
   "Intek Orion 5501 APU",
}
equip_typeOutfits_coreSystems["Pacifier"] = {
   "Intek Orion 6601 APU",
}
equip_typeOutfits_coreSystems["Hawking"] = {
   "Intek Orion 8801 APU",
}
equip_typeOutfits_coreSystems["Peacemaker"] = {
   "Intek Orion 9901 APU",
}

equip_typeOutfits_engines["Shark"] = {
   "Flex Tornado 150X Engine",
}
equip_typeOutfits_engines["Lancelot"] = {
   "Flex Cyclone 300X Engine",
}
equip_typeOutfits_engines["Admonisher"] = {
   "Flex Tornado 700X Engine",
}
equip_typeOutfits_engines["Pacifier"] = {
   "Flex Cyclone 1200X Engine",
}
equip_typeOutfits_engines["Hawking"] = {
   "Flex Tornado 4500X Engine",
}
equip_typeOutfits_engines["Peacemaker"] = {
   "Flex Cyclone 6500X Engine",
}

equip_typeOutfits_hulls["Shark"] = {
   "SHL Ultralight Combat Hull",
}
equip_typeOutfits_hulls["Lancelot"] = {
   "SHL Light Combat Hull",
}
equip_typeOutfits_hulls["Admonisher"] = {
   "SHL Medium Combat Hull",
}
equip_typeOutfits_hulls["Pacifier"] = {
   "SHL Medium-Heavy Combat Hull",
}
equip_typeOutfits_hulls["Hawking"] = {
   "SHL Heavy Combat Hull",
}
equip_typeOutfits_hulls["Peacemaker"] = {
   "SHL Superheavy Combat Hull",
}

equip_typeOutfits_weapons["Shark"] = {
   {
      num = 2;
      "FL21-U Lumina Gun",
   },
   {
      "FT80-U Talon Gun",
   },
}
equip_typeOutfits_weapons["Lancelot"] = {
   {
      "FMT40-S Tiger Missile Gun",
   },
   {
      "FL27-S Lumina Gun",
   },
}
equip_typeOutfits_weapons["Admonisher"] = {
   {
      num = 1;
      "FMT800-H Tiger Torpedo Gun",
      "FMT1000-H Tiger Torpedo Gun",
   },
   {
      "FMT80-S Tiger Missile Gun",
      "FMT200-H Tiger Missile Gun",
   },
   {
      "FL50-H Lumina Gun",
   },
}
equip_typeOutfits_weapons["Pacifier"] = {
   {
      "TL110-L Lumina Turret",
   },
   {
      num = 1;
      "TL54-M Lumina Turret",
   },
   {
      "TMT40-M Tiger Missile Turret",
   },
}
equip_typeOutfits_weapons["Hawking"] = {
   {
      num = 6;
      "TL110-L Lumina Turret",
   },
   {
      "TMT80-M Tiger Missile Turret",
   },
}
equip_typeOutfits_weapons["Peacemaker"] = {
   {
      num = 4;
      "TL200-X Lumina Turret",
   },
   {
      "TMT80-M Tiger Missile Turret",
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
