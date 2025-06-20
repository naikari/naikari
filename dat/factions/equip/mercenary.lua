require "factions/equip/generic"


-- Probability of cargo by class.
equip_classCargo["Yacht"] = .1
equip_classCargo["Luxury Yacht"] = .1
equip_classCargo["Scout"] = .1
equip_classCargo["Courier"] = .1
equip_classCargo["Freighter"] = .1
equip_classCargo["Armored Transport"] = .1
equip_classCargo["Bulk Freighter"] = 0.1
equip_classCargo["Fighter"] = .1
equip_classCargo["Bomber"] = .1
equip_classCargo["Corvette"] = .1
equip_classCargo["Destroyer"] = .1
equip_classCargo["Cruiser"] = .1
equip_classCargo["Carrier"] = .1
equip_classCargo["Drone"] = .1
equip_classCargo["Heavy Drone"] = .1

equip_classOutfits_coreSystems["Yacht"] = {
   "Exacorp ET-200 APU",
   "Milspec Aegis 2101 APU",
   "Milspec Prometheus 2102 APU",
   "Milspec Orion 2201 APU",
}
equip_classOutfits_engines["Yacht"] = {
   "Exacorp HS-150 Engine",
   "Tricon Zephyr Engine",
}
equip_classOutfits_hulls["Yacht"] = {
   "Exacorp D-2 Hull",
   "Exacorp X-2 Hull",
   "SHL Ultralight Stealth Hull",
   "SHL Ultralight Combat Hull",
}
equip_classOutfits_weapons["Yacht"] = {
   {
      num = 1;
      "FT80-U Talon Gun",
   },
   {
      "FL21-U Lumina Gun",
      "FR11-U Razor Gun",
      "FC22-U Crystal Gun",
      "FK21-U Katana Gun",
      "FS36-U Spear Gun",
   },
}
equip_classOutfits_weapons["Light Fighter"] = {
      {
         num = 1;
         "FRC80-U Claw Rocket Gun",
         "FRS60-U Stinger Rocket Gun",
      },
      {
         "FL21-U Lumina Gun",
         "FR11-U Razor Gun",
         "FC22-U Crystal Gun",
         "FK21-U Katana Gun",
         "FS36-U Spear Gun",
      },
}
equip_classOutfits_weapons["Fighter"] = {
   {
      "FMT40-S Tiger Missile Gun",
      "FMT80-S Tiger Missile Gun",
   },
   {
      "FL27-S Lumina Gun",
      "FR18-S Razor Gun",
      "FC28-S Crystal Gun",
      "FK27-S Katana Gun",
      "FS46-S Spear Gun",
   },
   {
      "FL21-U Lumina Gun",
      "FR11-U Razor Gun",
      "FC22-U Crystal Gun",
      "FK21-U Katana Gun",
      "FS36-U Spear Gun",
      "FRS60-U Stinger Rocket Gun",
      "FRC80-U Claw Rocket Gun",
   },
}
equip_classOutfits_weapons["Bomber"] = {
   {
      varied = true;
      "FMT40-S Tiger Missile Gun",
      "FMT80-S Tiger Missile Gun",
   },
   {
      "FL27-S Lumina Gun",
      "FR18-S Razor Gun",
      "FC28-S Crystal Gun",
      "FK27-S Katana Gun",
      "FS46-S Spear Gun",
   },
}
equip_classOutfits_weapons["Corvette"] = {
   {
      varied = true;
      "FMT40-S Tiger Missile Gun",
      "FMT80-S Tiger Missile Gun",
      "FMT200-H Tiger Missile Gun",
      "FMO200-H Orca Missile Gun",
      "FMT800-H Tiger Torpedo Gun",
      "FMT1000-H Tiger Torpedo Gun",
   },
   {
      probability = {
         ["FL50-H Lumina Gun"] = 10,
         ["FR39-H Razor Gun"] = 10,
         ["FC50-H Crystal Gun"] = 10,
         ["FK50-H Katana Gun"] = 10,
      };
      "FL50-H Lumina Gun",
      "FR39-H Razor Gun",
      "FC50-H Crystal Gun",
      "FK50-H Katana Gun",
      "FL27-S Lumina Gun",
      "FR18-S Razor Gun",
      "FC28-S Crystal Gun",
      "FK27-S Katana Gun",
      "FS46-S Spear Gun",
   },
}
equip_classOutfits_weapons["Destroyer"] = {
   {
      "FC66-L Crystal Gun",
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TC110-L Crystal Turret",
      "TS150-L Spear Turret",
   },
   {
      num = 1;
      "TMT40-M Tiger Missile Turret",
      "TMT80-M Tiger Missile Turret",
      "Mini Hyena Fighter Bay",
      "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
   {
      num = 1;
      "FL55-M Lumina Gun",
      "FC55-M Crystal Gun",
      "FK55-M Katana Gun",
      "FS78-M Spear Gun",
      "TL54-M Lumina Turret",
      "TR42-M Razor Turret",
      "TC54-M Crystal Turret",
      "TK54-M Katana Turret",
      "TS81-M Spear Turret",
      "TMT40-M Tiger Missile Turret",
      "TMT80-M Tiger Missile Turret",
      "Mini Hyena Fighter Bay",
      "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
   {
      "FL55-M Lumina Gun",
      "FC55-M Crystal Gun",
      "FK55-M Katana Gun",
      "FS78-M Spear Gun",
      "TL54-M Lumina Turret",
      "TR42-M Razor Turret",
      "TC54-M Crystal Turret",
      "TK54-M Katana Turret",
      "TS81-M Spear Turret",
   },
}
equip_classOutfits_weapons["Light Cruiser"] = {
   {
      num = 2;
      "TMT40-M Tiger Missile Turret",
      "TMT80-M Tiger Missile Turret",
      "Mini Hyena Fighter Bay",
      "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
   {
      "FC66-L Crystal Gun",
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TC110-L Crystal Turret",
      "TS150-L Spear Turret",
   },
   {
      "TL54-M Lumina Turret",
      "TR42-M Razor Turret",
      "TC54-M Crystal Turret",
      "TK54-M Katana Turret",
      "TS81-M Spear Turret",
   },
}
equip_classOutfits_weapons["Cruiser"] = {
   {
      num = 2;
      "TMT40-M Tiger Missile Turret",
      "TMT80-M Tiger Missile Turret",
      "Hyena Fighter Bay",
      "Shark Fighter Bay",
      "Lancelot Fighter Bay",
   },
   {
      "FC66-L Crystal Gun",
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TC110-L Crystal Turret",
      "TS150-L Spear Turret",
   },
   {
      "TL54-M Lumina Turret",
      "TR42-M Razor Turret",
      "TC54-M Crystal Turret",
      "TK54-M Katana Turret",
      "TS81-M Spear Turret",
      "Mini Hyena Fighter Bay",
      "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
}
equip_classOutfits_weapons["Battleship"] = {
   {
      num = 2;
      "TMT40-M Tiger Missile Turret",
      "TMT80-M Tiger Missile Turret",
      "Hyena Fighter Bay",
      "Shark Fighter Bay",
      "Lancelot Fighter Bay",
   },
   {
      "TL200-X Lumina Turret",
      "TC200-X Crystal Turret",
      "TS257-X Spear Turret",
   },
   {
      "FC66-L Crystal Gun",
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TC110-L Crystal Turret",
      "TS150-L Spear Turret",
   },
}
equip_classOutfits_weapons["Carrier"] = {
   {
      varied = true;
      "Hyena Fighter Bay",
      "Shark Fighter Bay",
      "Lancelot Fighter Bay",
   },
   {
      "TL200-X Lumina Turret",
      "TC200-X Crystal Turret",
      "TS257-X Spear Turret",
   },
   {
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TC110-L Crystal Turret",
      "TS150-L Spear Turret",
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
