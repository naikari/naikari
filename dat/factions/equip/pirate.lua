require "factions/equip/generic"


-- Probability of cargo by class.
equip_classCargo["Yacht"] = .5
equip_classCargo["Luxury Yacht"] = .5
equip_classCargo["Scout"] = .5
equip_classCargo["Courier"] = .5
equip_classCargo["Freighter"] = .5
equip_classCargo["Armored Transport"] = .5
equip_classCargo["Bulk Freighter"] = 0.5
equip_classCargo["Fighter"] = .5
equip_classCargo["Bomber"] = .5
equip_classCargo["Corvette"] = .5
equip_classCargo["Destroyer"] = .5
equip_classCargo["Cruiser"] = .5
equip_classCargo["Carrier"] = .5
equip_classCargo["Drone"] = .1
equip_classCargo["Heavy Drone"] = .1


equip_typeOutfits_coreSystems["Hyena"] = {
   "Makeshift Small APU",
}
equip_typeOutfits_coreSystems["Shark"] = {
   "Makeshift Small APU",
   "Exacorp ET-200 APU",
}
equip_typeOutfits_coreSystems["Vendetta"] = {
   "Makeshift Small APU",
   "Exacorp ET-300 APU",
}
equip_typeOutfits_coreSystems["Lancelot"] = equip_typeOutfits_coreSystems["Vendetta"]
equip_typeOutfits_coreSystems["Ancestor"] = equip_typeOutfits_coreSystems["Vendetta"]
equip_typeOutfits_coreSystems["Phalanx"] = {
   "Makeshift Medium APU",
   "Exacorp ET-500 APU",
}
equip_typeOutfits_coreSystems["Admonisher"] = equip_typeOutfits_coreSystems["Phalanx"]
equip_typeOutfits_coreSystems["Rhino"] = {
   "Makeshift Medium APU",
   "Exacorp ET-600 APU",
   "Intek Prometheus 6502 APU",
}
equip_typeOutfits_coreSystems["Kestrel"] = {
   "Makeshift Large APU",
   "Exacorp ET-800 APU",
   "Intek Prometheus 8702 APU",
   "Intek Orion 3301 APU",
}

equip_typeOutfits_engines["Hyena"] = {
   "Beat Up Small Engine",
}
equip_typeOutfits_engines["Shark"] = {
   "Beat Up Small Engine",
   "Exacorp HS-150 Engine",
}
equip_typeOutfits_engines["Vendetta"] = {
   "Beat Up Small Engine",
   "Exacorp HS-300 Engine",
}
equip_typeOutfits_engines["Lancelot"] = equip_typeOutfits_engines["Vendetta"]
equip_typeOutfits_engines["Ancestor"] = equip_typeOutfits_engines["Vendetta"]
equip_typeOutfits_engines["Phalanx"] = {
   "Beat Up Medium Engine",
   "Exacorp HS-700 Engine",
}
equip_typeOutfits_engines["Admonisher"] = equip_typeOutfits_engines["Phalanx"]
equip_typeOutfits_engines["Rhino"] = {
   "Beat Up Medium Engine",
   "Exacorp HS-1200 Engine",
   "NGL Hauler 1600F Engine",
}
equip_typeOutfits_engines["Kestrel"] = {
   "Beat Up Large Engine",
   "Exacorp HS-4500 Engine",
   "Flex Gust 3800S Engine",
}

equip_typeOutfits_hulls["Hyena"] = {
   "Patchwork Light Hull",
}
equip_typeOutfits_hulls["Shark"] = {
   "Patchwork Light Hull",
   "Exacorp D-2 Hull",
}
equip_typeOutfits_hulls["Vendetta"] = {
   "Patchwork Light Hull",
   "Exacorp D-4 Hull",
}
equip_typeOutfits_hulls["Lancelot"] = equip_typeOutfits_hulls["Vendetta"]
equip_typeOutfits_hulls["Ancestor"] = equip_typeOutfits_hulls["Vendetta"]
equip_typeOutfits_hulls["Phalanx"] = {
   "Patchwork Medium Hull",
   "Exacorp D-12 Hull",
}
equip_typeOutfits_hulls["Admonisher"] = equip_typeOutfits_hulls["Phalanx"]
equip_typeOutfits_hulls["Rhino"] = {
   "Patchwork Medium Hull",
   "Exacorp D-24 Hull",
   "Exacorp X-24 Hull",
   "NGL Medium Cargo Hull",
}
equip_typeOutfits_hulls["Kestrel"] = {
   "Patchwork Heavy Hull",
   "Exacorp D-48 Hull",
   "Exacorp X-48 Hull",
   "SHL Heavy Combat Hull",
}

equip_typeOutfits_weapons["Hyena"] = {
   {
      varied = true,
      probability = {
         ["Fi21-S Ion-Shackle Gun"] = 12,
      };
      "Fi21-S Ion-Shackle Gun",
      "FL21-U Lumina Gun",
      "FC22-U Crystal Gun",
      "FK21-U Katana Gun",
   },
}
equip_typeOutfits_weapons["Shark"] = {
   {
      varied = true, num = 1;
      "FRC80-U Claw Rocket Gun",
      "Fi21-S Ion-Shackle Gun",
   },
   {
      varied = true,
      probability = {
         ["Fi21-S Ion-Shackle Gun"] = 16,
      };
      "Fi21-S Ion-Shackle Gun",
      "FL21-U Lumina Gun",
      "FC22-U Crystal Gun",
      "FK21-U Katana Gun",
      "FRS60-U Stinger Rocket Gun",
   },
}
equip_typeOutfits_weapons["Vendetta"] = {
   {
      varied = true,
      probability = {
         ["Fi21-S Ion-Shackle Gun"] = 28,
      };
      "Fi21-S Ion-Shackle Gun",
      "FL27-S Lumina Gun",
      "FC28-S Crystal Gun",
      "FK27-S Katana Gun",
      "FL21-U Lumina Gun",
      "FC22-U Crystal Gun",
      "FK21-U Katana Gun",
      "FRS60-U Stinger Rocket Gun",
   },
}
equip_typeOutfits_weapons["Ancestor"] = {
   {
      varied = true;
      "FMS300-H Spider Missile Gun",
   },
   {
      varied = true,
      probability = {
         ["Fi21-S Ion-Shackle Gun"] = 16,
      };
      "Fi21-S Ion-Shackle Gun",
      "FL27-S Lumina Gun",
      "FC28-S Crystal Gun",
      "FK27-S Katana Gun",
      "FRS60-U Stinger Rocket Gun",
   },
}
equip_typeOutfits_weapons["Admonisher"] = {
   {
      varied = true;
      "FMS300-H Spider Missile Gun", 
      "FMS2000-H Spider Torpedo Gun",
   },
   {
      varied = true;
      "FL50-H Lumina Gun",
      "FC50-H Crystal Gun",
      "FK50-H Katana Gun",
   },
}
equip_typeOutfits_weapons["Phalanx"] = {
   {
      varied = true;
      "FMS300-H Spider Missile Gun", 
      "FMS2000-H Spider Torpedo Gun",
   },
   {
      varied = true;
      "FL50-H Lumina Gun",
      "FC50-H Crystal Gun",
      "FK50-H Katana Gun",
   },
}
equip_typeOutfits_weapons["Rhino"] = {
   {
      varied = true,
      probability = {
         ["Ti193-X Ion-Shackle Turret"] = 12,
      };
      "Ti193-X Ion-Shackle Turret",
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TC110-L Crystal Turret",
   },
   {
      varied = true,
      probability = {
         ["TRV250-M Venom Grenade Turret"] = 4,
      };
      "TRV250-M Venom Grenade Turret",
      "TMO75-M Orca Missile Turret",
   },
}
equip_typeOutfits_weapons["Kestrel"] = {
   {
      varied = true,
      probability = {
         ["Ti193-X Ion-Shackle Turret"] = 12,
      };
      "Ti193-X Ion-Shackle Turret",
      "TL110-L Lumina Turret",
      "TC110-L Crystal Turret",
      "TK110-L Katana Turret",
   },
   {
      varied = true,
      probability = {
         ["TRV250-M Venom Grenade Turret"] = 4,
      };
      "TRV250-M Venom Grenade Turret",
      "TMO75-M Orca Missile Turret",
   },
}


--[[
-- @brief Does pirate pilot equipping
--
--    @param p Pilot to equip
--]]
function equip( p )
   equip_generic( p )
end
