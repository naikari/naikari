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
   "Milspec Aegis 2201 Core System",
   "Milspec Prometheus 2203 Core System", "Milspec Orion 2301 Core System",
}
equip_classOutfits_engines["Yacht"] = {
   "Nexus Dart 150 Engine", "Tricon Zephyr Engine",
}
equip_classOutfits_hulls["Yacht"] = {
   "Unicorp D-2 Light Plating",
   "Unicorp X-2 Light Plating",
   "S&K Ultralight Stealth Plating",
   "S&K Ultralight Combat Plating",
}
equip_classOutfits_weapons["Yacht"] = {
   {
      num = 1;
      "Photon Dagger",
   },
   {
      "Laser Cannon MK1",
      "Razor MK1",
      "Gauss Gun",
      "Plasma Blaster MK1",
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
         "Laser Cannon MK1",
         "Razor MK1",
         "Gauss Gun",
         "Plasma Blaster MK1",
         "Particle Lance",
      },
}
equip_classOutfits_weapons["Fighter"] = {
   {
      "Unicorp Fury Launcher",
      "Unicorp Headhunter Launcher",
   },
   {
      "Laser Cannon MK2",
      "Razor MK2",
      "Vulcan Gun",
      "Plasma Blaster MK2",
      "Orion Lance",
   },
   {
      "Laser Cannon MK1",
      "Razor MK1",
      "Gauss Gun",
      "Plasma Blaster MK1",
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
      "Laser Cannon MK2",
      "Razor MK2",
      "Vulcan Gun",
      "Plasma Blaster MK2",
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
         ["Ripper Cannon"] = 10,
         ["Slicer"] = 10,
         ["Shredder"] = 10,
         ["Plasma Cannon"] = 10,
      };
      "Ripper Cannon",
      "Slicer",
      "Shredder",
      "Plasma Cannon",
      "Laser Cannon MK2",
      "Razor MK2",
      "Vulcan Gun",
      "Plasma Blaster MK2",
      "Orion Lance",
   },
}
equip_classOutfits_weapons["Destroyer"] = {
   {
      "Railgun",
      "Heavy Ripper Turret",
      "Plasma Cluster Turret",
      "Turreted Mass Driver",
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
      "Heavy Ripper Cannon",
      "Mass Driver",
      "Plasma Cluster Cannon",
      "Grave Lance",
      "Laser Turret MK2",
      "Razor Turret MK2",
      "Turreted Vulcan Gun",
      "Plasma Turret MK2",
      "Orion Beam",
      "Enygma Systems Turreted Fury Launcher",
      "Enygma Systems Turreted Headhunter Launcher",
      "Mini Hyena Fighter Bay",
      "Mini Shark Fighter Bay",
      "Mini Lancelot Fighter Bay",
   },
   {
      "Heavy Ripper Cannon",
      "Mass Driver",
      "Plasma Cluster Cannon",
      "Grave Lance",
      "Laser Turret MK2",
      "Razor Turret MK2",
      "Turreted Vulcan Gun",
      "Plasma Turret MK2",
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
      "Railgun",
      "Heavy Ripper Turret",
      "Plasma Cluster Turret",
      "Turreted Mass Driver",
      "Grave Beam",
   },
   {
      "Laser Turret MK2",
      "Razor Turret MK2",
      "Turreted Vulcan Gun",
      "Plasma Turret MK2",
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
      "Railgun",
      "Heavy Ripper Turret",
      "Plasma Cluster Turret",
      "Turreted Mass Driver",
      "Grave Beam",
   },
   {
      "Laser Turret MK2",
      "Razor Turret MK2",
      "Turreted Vulcan Gun",
      "Plasma Turret MK2",
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
      "Heavy Laser Turret",
      "Railgun Turret",
      "Ragnarok Beam",
   },
   {
      "Railgun",
      "Heavy Ripper Turret",
      "Plasma Cluster Turret",
      "Turreted Mass Driver",
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
      "Heavy Laser Turret",
      "Railgun Turret",
      "Ragnarok Beam",
   },
   {
      "Heavy Ripper Turret",
      "Plasma Cluster Turret",
      "Turreted Mass Driver",
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
