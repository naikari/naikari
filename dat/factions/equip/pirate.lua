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

equip_typeOutfits_coreSystems["Hyena"] = equip_shipOutfits_coreSystems["Pirate Shark"]
equip_typeOutfits_coreSystems["Shark"] = equip_shipOutfits_coreSystems["Pirate Shark"]
equip_typeOutfits_coreSystems["Vendetta"] = {
   "Exacorp ET-300 APU",
   "Intek Prometheus 3202 APU",
}
equip_typeOutfits_coreSystems["Lancelot"] = equip_typeOutfits_coreSystems["Vendetta"]
equip_typeOutfits_coreSystems["Ancestor"] = equip_typeOutfits_coreSystems["Vendetta"]
equip_typeOutfits_coreSystems["Phalanx"] = {
   "Exacorp ET-500 APU",
   "Intek Prometheus 5402 APU",
}
equip_typeOutfits_coreSystems["Admonisher"] = equip_typeOutfits_coreSystems["Phalanx"]
equip_typeOutfits_coreSystems["Pacifier"] = {
   "Exacorp ET-600 APU",
   "Intek Prometheus 6502 APU",
}
equip_typeOutfits_coreSystems["Kestrel"] = {
   "Exacorp ET-800 APU",
   "Intek Prometheus 8702 APU",
}

equip_typeOutfits_engines["Rhino"] = {
   "Exacorp HS-1200 Engine",
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
