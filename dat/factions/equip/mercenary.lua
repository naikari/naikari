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
      "Photon Dagger",
   },
   {
      "FL21-U Lumina Gun",
      "FR11-U Razor Gun",
      "FM22-U Meteor Gun",
      "FK21-U Katana Gun",
      "Particle Lance",
   },
}
equip_classOutfits_weapons["Light Fighter"] = {
      {
         num = 1;
         "Unicorp Banshee Launcher",
         "Unicorp Mace Launcher",
      },
      {
         "FL21-U Lumina Gun",
         "FR11-U Razor Gun",
         "FM22-U Meteor Gun",
         "FK21-U Katana Gun",
         "Particle Lance",
      },
}
equip_classOutfits_weapons["Fighter"] = {
   {
      "Unicorp Fury Launcher",
      "Unicorp Headhunter Launcher",
   },
   {
      "FL27-S Lumina Gun",
      "FR18-S Razor Gun",
      "FM28-S Meteor Gun",
      "FK27-S Katana Gun",
      "Orion Lance",
   },
   {
      "FL21-U Lumina Gun",
      "FR11-U Razor Gun",
      "FM22-U Meteor Gun",
      "FK21-U Katana Gun",
      "Particle Lance",
      "Unicorp Mace Launcher",
      "Unicorp Banshee Launcher",
   },
}
equip_classOutfits_weapons["Bomber"] = {
   {
      varied = true;
      "Unicorp Fury Launcher",
      "TeraCom Fury Launcher",
      "Unicorp Headhunter Launcher",
   },
   {
      "FL27-S Lumina Gun",
      "FR18-S Razor Gun",
      "FM28-S Meteor Gun",
      "FK27-S Katana Gun",
      "Orion Lance",
   },
}
equip_classOutfits_weapons["Corvette"] = {
   {
      varied = true;
      "Unicorp Fury Launcher",
      "TeraCom Fury Launcher",
      "Unicorp Headhunter Launcher",
      "TeraCom Headhunter Launcher",
      "Unicorp Vengeance Launcher",
      "TeraCom Vengeance Launcher",
      "Enygma Systems Spearhead Launcher",
      "Unicorp Caesar IV Launcher",
      "TeraCom Imperator Launcher",
   },
   {
      probability = {
         ["FL50-H Lumina Gun"] = 10,
         ["FR39-H Razor Gun"] = 10,
         ["FM50-H Meteor Gun"] = 10,
         ["FK50-H Katana Gun"] = 10,
      };
      "FL50-H Lumina Gun",
      "FR39-H Razor Gun",
      "FM50-H Meteor Gun",
      "FK50-H Katana Gun",
      "FL27-S Lumina Gun",
      "FR18-S Razor Gun",
      "FM28-S Meteor Gun",
      "FK27-S Katana Gun",
      "Orion Lance",
   },
}
equip_classOutfits_weapons["Destroyer"] = {
   {
      "FM66-L Meteor Gun",
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TM110-L Meteor Turret",
      "Grave Beam",
   },
   {
      num = 1;
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
      "Mini Hyena Fighter Bay",
      "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
   {
      num = 1;
      "FL55-M Lumina Gun",
      "FM55-M Meteor Gun",
      "FK55-M Katana Gun",
      "Grave Lance",
      "TL54-M Lumina Turret",
      "TR42-M Razor Turret",
      "TM54-M Meteor Turret",
      "TK54-M Katana Turret",
      "Orion Beam",
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
      "Mini Hyena Fighter Bay",
      "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
   {
      "FL55-M Lumina Gun",
      "FM55-M Meteor Gun",
      "FK55-M Katana Gun",
      "Grave Lance",
      "TL54-M Lumina Turret",
      "TR42-M Razor Turret",
      "TM54-M Meteor Turret",
      "TK54-M Katana Turret",
      "Orion Beam",
   },
}
equip_classOutfits_weapons["Light Cruiser"] = {
   {
      num = 2;
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
      "Mini Hyena Fighter Bay",
      "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
   {
      "FM66-L Meteor Gun",
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TM110-L Meteor Turret",
      "Grave Beam",
   },
   {
      "TL54-M Lumina Turret",
      "TR42-M Razor Turret",
      "TM54-M Meteor Turret",
      "TK54-M Katana Turret",
      "Orion Beam",
   },
}
equip_classOutfits_weapons["Cruiser"] = {
   {
      num = 2;
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
      "Hyena Fighter Bay",
      "Shark Fighter Bay",
      "Lancelot Fighter Bay",
   },
   {
      "FM66-L Meteor Gun",
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TM110-L Meteor Turret",
      "Grave Beam",
   },
   {
      "TL54-M Lumina Turret",
      "TR42-M Razor Turret",
      "TM54-M Meteor Turret",
      "TK54-M Katana Turret",
      "Orion Beam",
      "Mini Hyena Fighter Bay",
      "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
}
equip_classOutfits_weapons["Battleship"] = {
   {
      num = 2;
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
      "Hyena Fighter Bay",
      "Shark Fighter Bay",
      "Lancelot Fighter Bay",
   },
   {
      "TL200-X Lumina Turret",
      "TM200-X Meteor Turret",
      "Ragnarok Beam",
   },
   {
      "FM66-L Meteor Gun",
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TM110-L Meteor Turret",
      "Grave Beam",
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
      "TM200-X Meteor Turret",
      "Ragnarok Beam",
   },
   {
      "TL110-L Lumina Turret",
      "TK110-L Katana Turret",
      "TM110-L Meteor Turret",
      "Grave Beam",
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
