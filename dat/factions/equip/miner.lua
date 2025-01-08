require "factions/equip/generic"


-- Probability of cargo by class.
equip_classCargo["Yacht"] = .25
equip_classCargo["Luxury Yacht"] = .25
equip_classCargo["Scout"] = .25
equip_classCargo["Courier"] = .25
equip_classCargo["Freighter"] = .25
equip_classCargo["Armored Transport"] = .25
equip_classCargo["Bulk Freighter"] = 0.25
equip_classCargo["Fighter"] = .25
equip_classCargo["Bomber"] = .25
equip_classCargo["Corvette"] = .25
equip_classCargo["Destroyer"] = .25
equip_classCargo["Cruiser"] = .25
equip_classCargo["Carrier"] = .25
equip_classCargo["Drone"] = .1
equip_classCargo["Heavy Drone"] = .1

equip_classOutfits_weapons["Yacht"] = {
   {
      "FL21-U Lumina Gun", "FM22-U Meteor Gun", "Plasma Blaster MK1",
   },
}

equip_classOutfits_weapons["Courier"] = {
   {
      "TL21-S Lumina Turret", "TM22-S Meteor Turret", "Plasma Turret MK1",
   },
}

equip_classOutfits_weapons["Freighter"] = {
   {
      num = 1;
      "TL54-M Lumina Turret", "TM54-M Meteor Turret", "Plasma Turret MK2",
      "Orion Beam",
   },
   {
      "Enygma Systems Turreted Fury Launcher",
      "Mini Hyena Fighter Bay", "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
}


--[[
-- @brief Does miner pilot equipping
--
--    @param p Pilot to equip
--]]
function equip( p )
   equip_generic( p )
end
