require "factions/equip/generic"


equip_typeOutfits_hulls["Vendetta"] = {
   "SHL Light Combat Hull",
}
equip_typeOutfits_hulls["Ancestor"] = {
   "SHL Light Combat Hull",
}
equip_typeOutfits_hulls["Phalanx"] = {
   "SHL Medium Combat Hull",
}
equip_typeOutfits_hulls["Vigilance"] = {
   "SHL Medium-Heavy Combat Hull",
}
equip_typeOutfits_hulls["Goddard"] = {
   "SHL Superheavy Combat Hull",
}

equip_typeOutfits_weapons["Vendetta"] = {
   {
      num = 2, probability = {
         ["FC28-S Crystal Gun"] = 4, ["FC22-U Crystal Gun"] = 4,
      };
      "FC28-S Crystal Gun", "FC22-U Crystal Gun",
      "FRS60-U Stinger Rocket Gun",
   },
   {
      num = 2, probability = {
         ["FC28-S Crystal Gun"] = 4, ["FC22-U Crystal Gun"] = 4,
      };
      "FC28-S Crystal Gun", "FC22-U Crystal Gun",
      "FRS60-U Stinger Rocket Gun",
   },
   {
      probability = {
         ["FC28-S Crystal Gun"] = 4, ["FC22-U Crystal Gun"] = 4,
      };
      "FC28-S Crystal Gun", "FC22-U Crystal Gun",
      "FRS60-U Stinger Rocket Gun",
   },
}
equip_typeOutfits_weapons["Ancestor"] = {
   {
      varied = true;
      "FMT80-S Tiger Missile Gun", "FMT200-H Tiger Missile Gun",
   },
   {
      varied = true;
      "FC28-S Crystal Gun", "FRS60-U Stinger Rocket Gun",
   },
}
equip_typeOutfits_weapons["Phalanx"] = {
   {
      num = 1;
      "FMT800-H Tiger Torpedo Gun", "FMT1000-H Tiger Torpedo Gun",
   },
   {
      varied = true;
      "FMT80-S Tiger Missile Gun", "FMT200-H Tiger Missile Gun",
   },
   {
      probability = {
         ["FC50-H Crystal Gun"] = 8,
      };
      "FC50-H Crystal Gun", "FC28-S Crystal Gun",
   },
}
equip_typeOutfits_weapons["Vigilance"] = {
   {
      "FC66-L Crystal Gun",
   },
   {
      num = 1;
      "TMT80-M Tiger Missile Turret",
   },
   {
      num = 1;
      "FC55-M Crystal Gun",
      "TMT80-M Tiger Missile Turret",
   },
   {
      "FC55-M Crystal Gun",
   },
}
equip_typeOutfits_weapons["Goddard"] = {
   {
      num = 1;
      "TMT80-M Tiger Missile Turret",
   },
   {
      "FC200-X Crystal Gun",
   },
   {
      "FC66-L Crystal Gun",
   },
}

equip_typeOutfits_structurals["Phalanx"] = {
   {
      varied = true;
      "Medium Fuel Pod", "Medium Battery", "Medium Shield Capacitor",
      "Plasteel Plating", "Active Plating",
   },
}
equip_typeOutfits_structurals["Vigilance"] = {
   {
      varied = true;
      "Large Fuel Pod", "Large Battery", "Dense Shield Capacitor",
      "Large Shield Capacitor", "Nanobond Plating",
   },
   {
      varied = true;
      "Medium Fuel Pod", "Medium Battery", "Medium Shield Capacitor",
      "Plasteel Plating", "Active Plating",
   },
}


--[[
-- @brief Does Dvaered pilot equipping
--
--    @param p Pilot to equip
--]]
function equip( p )
   equip_generic( p )
end
