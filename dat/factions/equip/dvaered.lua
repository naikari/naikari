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
         ["Vulcan Gun"] = 4, ["Gauss Gun"] = 4,
      };
      "Vulcan Gun", "Gauss Gun",
      "Unicorp Mace Launcher", "TeraCom Mace Launcher",
   },
   {
      num = 2, probability = {
         ["Vulcan Gun"] = 4, ["Gauss Gun"] = 4,
      };
      "Vulcan Gun", "Gauss Gun",
      "Unicorp Mace Launcher", "TeraCom Mace Launcher",
   },
   {
      probability = {
         ["Vulcan Gun"] = 4, ["Gauss Gun"] = 4,
      };
      "Vulcan Gun", "Gauss Gun",
      "Unicorp Mace Launcher", "TeraCom Mace Launcher",
   },
}
equip_typeOutfits_weapons["Ancestor"] = {
   {
      varied = true;
      "Unicorp Headhunter Launcher", "Unicorp Vengeance Launcher",
   },
   {
      varied = true;
      "Vulcan Gun", "TeraCom Mace Launcher",
   },
}
equip_typeOutfits_weapons["Phalanx"] = {
   {
      num = 1;
      "Unicorp Caesar IV Launcher", "TeraCom Imperator Launcher",
   },
   {
      varied = true;
      "Unicorp Headhunter Launcher", "Unicorp Vengeance Launcher",
      "TeraCom Headhunter Launcher", "TeraCom Vengeance Launcher",
   },
   {
      probability = {
         ["Shredder"] = 8,
      };
      "Shredder", "Vulcan Gun",
   },
}
equip_typeOutfits_weapons["Vigilance"] = {
   {
      "Railgun",
   },
   {
      num = 1;
      "Enygma Systems Turreted Headhunter Launcher",
   },
   {
      num = 1;
      "Mass Driver",
      "Enygma Systems Turreted Headhunter Launcher",
   },
   {
      "Mass Driver",
   },
}
equip_typeOutfits_weapons["Goddard"] = {
   {
      num = 1;
      "Enygma Systems Turreted Headhunter Launcher",
   },
   {
      "Repeating Railgun",
   },
   {
      "Railgun",
   },
}

equip_typeOutfits_structurals["Phalanx"] = {
   {
      varied = true;
      "Medium Fuel Pod", "Battery II", "Shield Capacitor II",
      "Plasteel Plating", "Active Plating",
   },
}
equip_typeOutfits_structurals["Vigilance"] = {
   {
      varied = true;
      "Large Fuel Pod", "Battery III", "Shield Capacitor IV",
      "Shield Capacitor III", "Nanobond Plating",
   },
   {
      varied = true;
      "Medium Fuel Pod", "Battery II", "Shield Capacitor II",
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
