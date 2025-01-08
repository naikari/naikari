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
   "Milspec Prometheus 3202 APU",
}
equip_typeOutfits_coreSystems["Lancelot"] = equip_typeOutfits_coreSystems["Vendetta"]
equip_typeOutfits_coreSystems["Ancestor"] = equip_typeOutfits_coreSystems["Vendetta"]
equip_typeOutfits_coreSystems["Phalanx"] = {
   "Exacorp ET-500 APU",
   "Milspec Prometheus 5402 APU",
}
equip_typeOutfits_coreSystems["Admonisher"] = equip_typeOutfits_coreSystems["Phalanx"]
equip_typeOutfits_coreSystems["Pacifier"] = {
   "Exacorp ET-600 APU",
   "Milspec Prometheus 6502 APU",
}
equip_typeOutfits_coreSystems["Kestrel"] = {
   "Exacorp ET-800 APU",
   "Milspec Prometheus 8702 APU",
}

equip_typeOutfits_engines["Rhino"] = {
   "Exacorp HS-1200 Engine",
}

equip_typeOutfits_weapons["Hyena"] = equip_shipOutfits_weapons["Pirate Shark"]
equip_typeOutfits_weapons["Shark"] = equip_shipOutfits_weapons["Pirate Shark"]
equip_typeOutfits_weapons["Vendetta"] = {
   {
      varied = true,
      probability = {
         ["Ion Cannon"] = 16,
      };
      "FL27-S Lumina Gun", "FM28-S Meteor Gun", "Plasma Blaster MK2",
      "FL21-U Lumina Gun", "FM22-U Meteor Gun", "Plasma Blaster MK1",
      "Unicorp Mace Launcher", "TeraCom Mace Launcher",
      "Ion Cannon",
   },
}
equip_typeOutfits_weapons["Ancestor"] = {
   {
      varied = true;
      "Unicorp Medusa Launcher",
   },
   {
      varied = true,
      probability = {
         ["Ion Cannon"] = 16,
      };
      "FL27-S Lumina Gun", "FM28-S Meteor Gun", "Plasma Blaster MK2",
      "FL21-U Lumina Gun", "FM22-U Meteor Gun", "Plasma Blaster MK1",
      "Unicorp Mace Launcher", "TeraCom Mace Launcher",
      "Ion Cannon",
   },
}
equip_typeOutfits_weapons["Phalanx"] = {
   {
      varied = true;
      "Unicorp Medusa Launcher", "TeraCom Medusa Launcher", 
      "Enygma Systems Huntsman Launcher",
   },
   {
      varied = true;
      "FL50-H Lumina Gun", "FM50-H Meteor Gun", "Plasma Cannon",
      "FL27-S Lumina Gun", "FM28-S Meteor Gun", "Plasma Blaster MK2",
   },
}
equip_typeOutfits_weapons["Rhino"] = {
   {
      varied = true,
      probability = {
         ["Heavy Ion Turret"] = 6,
      };
      "TL110-L Lumina Turret", "Plasma Cluster Turret", "TM110-L Meteor Turret",
      "Heavy Ion Turret",
   },
   {
      varied = true, num = 1;
      "Mini Hyena Fighter Bay", "Mini Pirate Shark Fighter Bay",
   },
   {
      varied = true,
      probability = {
         ["EMP Grenade Launcher"] = 6,
      };
      "TL54-M Lumina Turret", "TM54-M Meteor Turret", "Plasma Turret MK2",
      "EMP Grenade Launcher",
      "Mini Hyena Fighter Bay", "Mini Pirate Shark Fighter Bay",
   },
}
equip_typeOutfits_weapons["Kestrel"] = {
   {
      varied = true,
      probability = {
         ["Heavy Ion Turret"] = 6,
      };
      "TL110-L Lumina Turret", "TM200-X Meteor Turret", "Plasma Cluster Turret",
      "Heavy Ion Turret",
   },
   {
      varied = true, num = 2;
      "Mini Hyena Fighter Bay", "Mini Pirate Shark Fighter Bay",
   },
   {
      varied = true,
      probability = {
         ["EMP Grenade Launcher"] = 6,
      };
      "TL54-M Lumina Turret", "TM54-M Meteor Turret", "Plasma Turret MK2",
      "EMP Grenade Launcher",
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
