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
      "FL21-U Lumina Gun", "FC22-U Crystal Gun", "FK21-U Katana Gun",
   },
}

equip_classOutfits_weapons["Courier"] = {
   {
      "TL21-S Lumina Turret", "TC22-S Crystal Turret", "TK21-S Katana Turret",
   },
}

equip_classOutfits_weapons["Freighter"] = {
   {
      num = 1;
      "TL54-M Lumina Turret", "TC54-M Crystal Turret", "TK54-M Katana Turret",
      "TS81-M Spear Turret",
   },
   {
      "TMT40-M Tiger Missile Turret",
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
