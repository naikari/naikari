require "jumpdist"


-- Probability of cargo by class.
equip_classCargo = {
   ["Yacht"] = .7,
   ["Luxury Yacht"] = .6,
   ["Scout"] = .05,
   ["Courier"] = .8,
   ["Freighter"] = .8,
   ["Armored Transport"] = .8,
   ["Fighter"] = .1,
   ["Bomber"] = .1,
   ["Corvette"] = .15,
   ["Destroyer"] = .2,
   ["Cruiser"] = .2,
   ["Carrier"] = .3,
   ["Drone"] = .05,
   ["Heavy Drone"] = .05,
   ["Station"] = 1,
}

-- Table of available core systems by class. `false` means that
-- none should be equipped.
equip_classOutfits_coreSystems = {
   ["Yacht"] = {
      "Unicorp PT-18 Core System", "Milspec Aegis 2201 Core System",
   },
   ["Luxury Yacht"] = {
      "Unicorp PT-18 Core System", "Milspec Aegis 2201 Core System",
   },
   ["Scout"] = {
      "Unicorp PT-18 Core System", "Milspec Aegis 2201 Core System",
   },
   ["Courier"] = {
      "Unicorp PT-80 Core System", "Milspec Aegis 3601 Core System",
   },
   ["Freighter"] = {
      "Unicorp PT-400 Core System", "Milspec Aegis 5401 Core System",
   },
   ["Armored Transport"] = {
      "Unicorp PT-400 Core System", "Milspec Aegis 5401 Core System",
      "Milspec Aegis 5401 Core System", "Milspec Orion 5501 Core System",
   },
   ["Fighter"] = {
      "Unicorp PT-80 Core System", "Milspec Aegis 3601 Core System",
      "Milspec Prometheus 3603 Core System", "Milspec Orion 3701 Core System",
   },
   ["Bomber"] = {
      "Unicorp PT-80 Core System", "Milspec Aegis 3601 Core System",
      "Milspec Orion 3701 Core System",
   },
   ["Corvette"] = {
      "Unicorp PT-280 Core System", "Milspec Aegis 4701 Core System",
      "Milspec Orion 4801 Core System",
   },
   ["Destroyer"] = {
      "Unicorp PT-400 Core System", "Milspec Aegis 5401 Core System",
      "Milspec Prometheus 5403 Core System", "Milspec Orion 5501 Core System",
   },
   ["Cruiser"] = {
      "Unicorp PT-3400 Core System", "Milspec Aegis 8501 Core System",
      "Milspec Prometheus 8503 Core System", "Milspec Orion 9901 Core System",
   },
   ["Carrier"] = {
      "Unicorp PT-3400 Core System", "Milspec Aegis 8501 Core System",
      "Milspec Orion 9901 Core System",
   },
   ["Drone"] = {
      "Milspec Orion 2301 Core System",
   },
   ["Heavy Drone"] = {
      "Milspec Orion 3701 Core System",
   },
   ["Station"] = false,
}


-- Table of available engines by class. `false` means that
-- none should be equipped.
equip_classOutfits_engines = {
   ["Yacht"] = {
      "Nexus Dart 150 Engine", "Tricon Zephyr Engine",
   },
   ["Luxury Yacht"] = {
      "Nexus Dart 150 Engine", "Tricon Zephyr Engine",
   },
   ["Scout"] = {
      "Nexus Dart 150 Engine", "Tricon Zephyr Engine",
   },
   ["Courier"] = {
      "Unicorp Hawk 300 Engine", "Tricon Zephyr II Engine",
      "Melendez Ox XL Engine",
   },
   ["Freighter"] = {
      "Unicorp Falcon 1200 Engine", "Melendez Buffalo XL Engine",
   },
   ["Armored Transport"] = {
      "Unicorp Falcon 1200 Engine", "Melendez Buffalo XL Engine",
   },
   ["Fighter"] = {
      "Unicorp Hawk 300 Engine", "Tricon Zephyr II Engine",
   },
   ["Bomber"] = {
      "Unicorp Hawk 300 Engine", "Tricon Zephyr II Engine",
      "Melendez Ox XL Engine",
   },
   ["Corvette"] = {
      "Nexus Arrow 700 Engine", "Tricon Cyclone Engine",
   },
   ["Destroyer"] = {
      "Unicorp Falcon 1200 Engine", "Tricon Cyclone II Engine",
   },
   ["Cruiser"] = {
      "Unicorp Eagle 6500 Engine", "Tricon Typhoon II Engine",
   },
   ["Carrier"] = {
      "Unicorp Eagle 6500 Engine", "Tricon Typhoon II Engine",
      "Melendez Mammoth XL Engine",
   },
   ["Drone"] = {
      "Tricon Zephyr Engine",
   },
   ["Heavy Drone"] = {
      "Tricon Zephyr II Engine",
   },
   ["Station"] = false,
}


-- Table of available hulls by class. `false` means that
-- none should be equipped.
equip_classOutfits_hulls = {
   ["Yacht"] = {
      "Unicorp D-2 Light Plating",
      "Unicorp X-2 Light Plating",
   },
   ["Luxury Yacht"] = {
      "Unicorp D-2 Light Plating",
      "Unicorp X-2 Light Plating",
      "S&K Ultralight Stealth Plating",
   },
   ["Scout"] = {
      "Unicorp D-2 Light Plating",
      "Unicorp X-2 Light Plating",
      "S&K Ultralight Stealth Plating",
   },
   ["Courier"] = {
      "Unicorp D-4 Light Plating",
      "Unicorp X-4 Light Plating",
      "S&K Small Cargo Hull",
   },
   ["Freighter"] = {
      "Unicorp D-24 Medium Plating",
      "Unicorp X-24 Medium Plating",
      "S&K Medium Cargo Hull",
   },
   ["Armored Transport"] = {
      "Unicorp D-24 Medium Plating",
      "Unicorp X-24 Medium Plating",
      "S&K Medium Cargo Hull",
   },
   ["Fighter"] = {
      "Unicorp D-4 Light Plating",
      "Unicorp X-4 Light Plating",
      "S&K Light Stealth Plating",
      "S&K Light Combat Plating"
   },
   ["Bomber"] = {
      "Unicorp D-4 Light Plating",
      "Unicorp X-4 Light Plating",
      "S&K Light Stealth Plating",
      "S&K Light Combat Plating"
   },
   ["Corvette"] = {
      "Unicorp D-12 Medium Plating",
      "Unicorp X-12 Medium Plating",
      "S&K Medium Stealth Plating",
      "S&K Medium Combat Plating"
   },
   ["Destroyer"] = {
      "Unicorp D-24 Medium Plating",
      "Unicorp X-24 Medium Plating",
      "S&K Medium-Heavy Stealth Plating",
      "S&K Medium-Heavy Combat Plating"
   },
   ["Cruiser"] = {
      "Unicorp D-72 Heavy Plating",
      "Unicorp X-72 Heavy Plating",
      "S&K Superheavy Combat Plating"
   },
   ["Carrier"] = {
      "Unicorp D-72 Heavy Plating",
      "Unicorp X-72 Heavy Plating",
      "S&K Superheavy Combat Plating"
   },
   ["Drone"] = {
      "S&K Ultralight Combat Plating"
   },
   ["Heavy Drone"] = {
      "S&K Light Combat Plating"
   },
   ["Station"] = false,
}


-- Tables of available weapons by class.
-- See equip_set function for more info.
equip_classOutfits_weapons = {
   ["Yacht"] = {
      {
         "Laser Cannon MK1",
         "Razor MK1",
         "Gauss Gun",
         "Plasma Blaster MK1",
         "Particle Lance",
         "Ion Cannon",
      },
   },
   ["Luxury Yacht"] = {
      {
         "Laser Cannon MK1",
         "Razor MK1",
         "Gauss Gun",
         "Plasma Blaster MK1",
         "Particle Lance",
         "Ion Cannon",
      },
   },
   ["Scout"] = {
      {
         "Laser Cannon MK1",
         "Razor MK1",
         "Gauss Gun",
         "Plasma Blaster MK1",
         "Particle Lance",
         "Ion Cannon",
      },
   },
   ["Courier"] = {
      {
         "Laser Turret MK1",
         "Razor Turret MK1",
         "Turreted Gauss Gun",
         "Plasma Turret MK1",
         "Particle Beam",
      },
   },
   ["Freighter"] = {
      {
         num = 1;
         "Enygma Systems Turreted Fury Launcher",
         "Enygma Systems Turreted Headhunter Launcher",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
      {
         "Laser Turret MK2",
         "Razor Turret MK2",
         "Turreted Vulcan Gun",
         "Plasma Turret MK2",
         "Orion Beam",
         "EMP Grenade Launcher",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
   },
   ["Armored Transport"] = {
      {
         "Heavy Ripper Turret",
         "Plasma Cluster Turret",
         "Turreted Mass Driver",
         "Grave Beam",
         "Heavy Ion Turret",
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
         "Laser Turret MK2",
         "Razor Turret MK2",
         "Turreted Vulcan Gun",
         "Plasma Turret MK2",
         "Orion Beam",
         "EMP Grenade Launcher",
         "Enygma Systems Turreted Fury Launcher",
         "Enygma Systems Turreted Headhunter Launcher",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
   },
   ["Fighter"] = {
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
         "Ion Cannon",
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
   },
   ["Bomber"] = {
      {
         varied = true;
         "Unicorp Fury Launcher",
         "TeraCom Fury Launcher",
         "Unicorp Headhunter Launcher",
         "Unicorp Medusa Launcher",
      },
      {
         "Laser Cannon MK2",
         "Razor MK2",
         "Vulcan Gun",
         "Plasma Blaster MK2",
         "Orion Lance",
         "Ion Cannon",
      },
   },
   ["Corvette"] = {
      {
         varied = true;
         "Unicorp Fury Launcher",
         "TeraCom Fury Launcher",
         "Unicorp Headhunter Launcher",
         "TeraCom Headhunter Launcher",
         "Unicorp Medusa Launcher",
         "TeraCom Medusa Launcher",
         "Unicorp Vengeance Launcher",
         "TeraCom Vengeance Launcher",
         "Enygma Systems Spearhead Launcher",
         "Unicorp Caesar IV Launcher",
         "TeraCom Imperator Launcher",
         "Enygma Systems Huntsman Launcher",
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
   },
   ["Destroyer"] = {
      {
         "Railgun",
         "Heavy Ripper Turret",
         "Plasma Cluster Turret",
         "Turreted Mass Driver",
         "Grave Beam",
         "Heavy Ion Turret",
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
         "Heavy Ion Cannon",
         "Laser Turret MK2",
         "Razor Turret MK2",
         "Turreted Vulcan Gun",
         "Plasma Turret MK2",
         "Orion Beam",
         "EMP Grenade Launcher",
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
         "Heavy Ion Cannon",
         "Laser Turret MK2",
         "Razor Turret MK2",
         "Turreted Vulcan Gun",
         "Plasma Turret MK2",
         "Orion Beam",
         "EMP Grenade Launcher",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
   },
   ["Cruiser"] = {
      {
         num = 1;
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
         "Heavy Ion Turret",
      },
      {
         "Laser Turret MK2",
         "Razor Turret MK2",
         "Turreted Vulcan Gun",
         "Plasma Turret MK2",
         "Orion Beam",
         "EMP Grenade Launcher",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
   },
   ["Carrier"] = {
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
         "Heavy Ion Turret",
      },
   },
   ["Drone"] = {
      {
         "Neutron Disruptor",
      },
   },
   ["Heavy Drone"] = {
      {
         num = 2;
         "Heavy Neutron Disruptor",
      },
      {
         "Electron Burst Cannon",
      },
   },
   ["Station"] = {
      {
         "Base Ripper",
      },
   }
}


-- Tables of available utilities by class.
-- See equip_set function for more info.
equip_classOutfits_utilities = {
   ["Yacht"] = {
      {
         varied = true;
         "Reactor Class I", "Unicorp Scrambler", "Jump Scanner",
         "Generic Afterburner", "Small Shield Booster", "Solar Panel",
         "Sensor Array",
      },
   },
   ["Luxury Yacht"] = {
      {
         varied = true;
         "Reactor Class I", "Unicorp Scrambler", "Jump Scanner",
         "Generic Afterburner", "Small Shield Booster", "Solar Panel",
         "Sensor Array",
      },
   },
   ["Scout"] = {
      {
         varied = true;
         "Reactor Class I", "Unicorp Scrambler", "Jump Scanner",
         "Generic Afterburner", "Small Shield Booster", "Solar Panel",
         "Unicorp Jammer", "Reverse Thrusters", "Sensor Array",
      },
   },
   ["Courier"] = {
      {
         varied = true;
         "Reactor Class I", "Unicorp Scrambler", "Jump Scanner",
         "Generic Afterburner", "Small Shield Booster", "Solar Panel",
         "Rotary Turbo Modulator",
      },
   },
   ["Freighter"] = {
      {
         varied = true;
         "Reactor Class II", "Medium Shield Booster", "Droid Repair Crew",
         "Targeting Array", "Improved Power Regulator",  "Milspec Scrambler",
         "Milspec Jammer", "Emergency Shield Booster",
         "Rotary Turbo Modulator",
      },
   },
   ["Armored Transport"] = {
      {
         varied = true;
         "Reactor Class II", "Medium Shield Booster", "Droid Repair Crew",
         "Targeting Array", "Improved Power Regulator",  "Milspec Scrambler",
         "Milspec Jammer", "Emergency Shield Booster",
         "Rotary Turbo Modulator",
      },
   },
   ["Fighter"] = {
      {
         varied = true;
         "Reactor Class I", "Unicorp Scrambler", "Generic Afterburner",
         "Hellburner", "Small Shield Booster", "Solar Panel",
         "Forward Shock Absorbers", "Power Regulation Override",
         "Weapons Ionizer", "Reverse Thrusters", "Emergency Shield Booster",
         "Sensor Array",
      },
   },
   ["Bomber"] = {
      {
         varied = true;
         "Reactor Class I", "Unicorp Scrambler", "Generic Afterburner",
         "Hellburner", "Small Shield Booster", "Solar Panel",
         "Forward Shock Absorbers", "Power Regulation Override",
         "Milspec Scrambler", "Milspec Jammer", "Weapons Ionizer",
         "Reverse Thrusters", "Emergency Shield Booster", "Sensor Array",
      },
   },
   ["Corvette"] = {
      {
         varied = true;
         "Reactor Class II", "Medium Shield Booster", "Droid Repair Crew",
         "Forward Shock Absorbers", "Power Regulation Override",
         "Milspec Scrambler", "Milspec Jammer", "Weapons Ionizer",
         "Solar Panel", "Reverse Thrusters", "Hellburner",
         "Emergency Shield Booster", "Sensor Array",
      },
   },
   ["Destroyer"] = {
      {
         varied = true;
         "Reactor Class III", "Large Shield Booster", "Reactor Class II",
         "Medium Shield Booster", "Droid Repair Crew",
         "Forward Shock Absorbers", "Power Regulation Override",
         "Targeting Array", "Improved Power Regulator",
         "Turreted Weapons Ionizer", "Solar Panel", "Hellburner",
         "Emergency Shield Booster", "Sensor Array", "Rotary Turbo Modulator",
      },
   },
   ["Cruiser"] = {
      {
         varied = true;
         "Reactor Class III", "Large Shield Booster", "Droid Repair Crew",
         "Targeting Array", "Improved Power Regulator",
         "Turreted Weapons Ionizer", "Solar Panel", "Sensor Array",
         "Rotary Turbo Modulator",
      },
   },
   ["Carrier"] = {
      {
         varied = true;
         "Reactor Class III", "Large Shield Booster", "Droid Repair Crew",
         "Targeting Array", "Turreted Weapons Ionizer", "Sensor Array",
         "Rotary Turbo Modulator",
      },
   },
   ["Drone"] = {
      {
         "Solar Panel",
      },
   },
   ["Heavy Drone"] = {
      {
         num = 1;
         "Sensor Array"
      },
      {
         "Reactor Class I"
      },
   }
}

-- Tables of available structurals by class.
-- See equip_set function for more info.
equip_classOutfits_structurals = {
   ["Yacht"] = {
      {
         varied = true;
         "Cargo Pod", "Fuel Pod", "Battery", "Shield Capacitor",
         "Improved Stabilizer", "Engine Reroute", "Steering Thrusters",
      },
   },
   ["Luxury Yacht"] = {
      {
         varied = true;
         "Improved Stabilizer", "Engine Reroute", "Steering Thrusters",
      },
   },
   ["Scout"] = {
      {
         varied = true, probability = {
            ["Fuel Pod"] = 4, ["Improved Stabilizer"] = 2
         };
         "Fuel Pod", "Improved Stabilizer", "Shield Capacitor",
      },
   },
   ["Courier"] = {
      {
         varied = true, probability = {
            ["Cargo Pod"] = 4,
         };
         "Cargo Pod", "Fuel Pod", "Improved Stabilizer",
      },
   },
   ["Freighter"] = {
      {
         varied = true, probability = {
            ["Medium Cargo Pod"] = 6,
         };
         "Medium Cargo Pod", "Medium Fuel Pod",
      },
   },
   ["Armored Transport"] = {
      {
         varied = true, probability = {
            ["Cargo Pod"] = 15, ["Medium Fuel Pod"] = 3,
         };
         "Cargo Pod", "Medium Fuel Pod", "Battery II", "Shield Capacitor II",
         "Plasteel Plating",
      },
   },
   ["Fighter"] = {
      {
         varied = true, probability = {
            ["Steering Thrusters"] = 4, ["Engine Reroute"] = 4,
         };
         "Fuel Pod", "Steering Thrusters", "Engine Reroute",
         "Battery", "Shield Capacitor",
      },
   },
   ["Bomber"] = {
      {
         varied = true;
         "Fuel Pod", "Steering Thrusters", "Engine Reroute",
         "Shield Capacitor",
      },
   },
   ["Corvette"] = {
      {
         varied = true;
         "Medium Fuel Pod", "Battery II", "Shield Capacitor II",
         "Plasteel Plating",
      },
   },
   ["Destroyer"] = {
      {
         varied = true;
         "Large Fuel Pod", "Battery III", "Shield Capacitor IV",
         "Shield Capacitor III", "Nanobond Plating",
      },
      {
         varied = true;
         "Medium Fuel Pod", "Battery II", "Shield Capacitor II",
         "Plasteel Plating",
      },
   },
   ["Cruiser"] = {
      {
         varied = true, probability = {
            ["Nanobond Plating"] = 3, ["Shield Capacitor IV"] = 2,
         };
         "Large Fuel Pod", "Biometal Armor", "Nanobond Plating",
         "Battery III", "Shield Capacitor III", "Shield Capacitor IV",
      },
   },
   ["Carrier"] = {
      {
         varied = true, probability = {
            ["Nanobond Plating"] = 6, ["Shield Capacitor IV"] = 4,
            ["Large Fuel Pod"] = 3, ["Biometal Armor"] = 2
         };
         "Large Fuel Pod", "Biometal Armor", "Nanobond Plating",
         "Battery III", "Shield Capacitor III", "Shield Capacitor IV",
      },
   },
   ["Drone"] = {
      {
         "Engine Reroute"
      },
   },
   ["Heavy Drone"] = {
      {
         num = 2;
         "Engine Reroute"
      },
      {
         "Steering Thrusters"
      },
   }
}


-- Table of available core systems by base type.
equip_typeOutfits_coreSystems = {
   ["Hyena"] = {
      "Unicorp PT-18 Core System", "Milspec Aegis 2201 Core System",
      "Milspec Prometheus 2203 Core System", "Milspec Orion 2301 Core System",
   },
   ["Shark"] = {
      "Unicorp PT-18 Core System", "Milspec Aegis 2201 Core System",
      "Milspec Hermes 2202 Core System", "Milspec Prometheus 2203 Core System",
      "Milspec Orion 2301 Core System",
   },
   ["Fidelity"] = {
      "Unicorp PT-18 Core System", "Milspec Aegis 2201 Core System",
      "Milspec Prometheus 2203 Core System", "Milspec Orion 2301 Core System",
   },
   ["Derivative"] = {
      "Unicorp PT-18 Core System", "Milspec Aegis 2201 Core System",
      "Milspec Prometheus 2203 Core System", "Milspec Orion 2301 Core System",
   },
   ["Vendetta"] = {
      "Unicorp PT-80 Core System", "Milspec Aegis 3601 Core System",
      "Milspec Hermes 3602 Core System", "Milspec Prometheus 3603 Core System",
      "Milspec Orion 3701 Core System",
   },
   ["Kestrel"] = {
      "Unicorp PT-750 Core System", "Milspec Aegis 8501 Core System",
      "Milspec Prometheus 8503 Core System", "Milspec Orion 8601 Core System",
   },
   ["Hawking"] = {
      "Unicorp PT-750 Core System", "Milspec Aegis 8501 Core System",
      "Milspec Prometheus 8503 Core System", "Milspec Orion 8601 Core System",
   },
   ["Brigand"] = {
      probability = {
         ["Ultralight Brain Stage X"] = 2
      };
      "Ultralight Brain Stage 1", "Ultralight Brain Stage 2",
      "Ultralight Brain Stage X",
   },
   ["Reaver"] = {
      probability = {
         ["Light Brain Stage X"] = 3
      };
      "Light Brain Stage 1", "Light Brain Stage 2",
      "Light Brain Stage 3", "Light Brain Stage X",
   },
   ["Marauder"] = {
      probability = {
         ["Light Brain Stage X"] = 3
      };
      "Light Brain Stage 1", "Light Brain Stage 2",
      "Light Brain Stage 3", "Light Brain Stage X",
   },
   ["Odium"] = {
      probability = {
         ["Medium Brain Stage X"] = 4
      };
      "Medium Brain Stage 1", "Medium Brain Stage 2",
      "Medium Brain Stage 3", "Medium Brain Stage 4",
      "Medium Brain Stage X",
   },
   ["Nyx"] = {
      probability = {
         ["Medium-Heavy Brain Stage X"] = 5
      };
      "Medium-Heavy Brain Stage 1",
      "Medium-Heavy Brain Stage 2",
      "Medium-Heavy Brain Stage 3",
      "Medium-Heavy Brain Stage 4",
      "Medium-Heavy Brain Stage 5",
      "Medium-Heavy Brain Stage X",
   },
   ["Ira"] = {
      probability = {
         ["Heavy Brain Stage X"] = 6
      };
      "Heavy Brain Stage 1",
      "Heavy Brain Stage 2",
      "Heavy Brain Stage 3",
      "Heavy Brain Stage 4",
      "Heavy Brain Stage 5",
      "Heavy Brain Stage 6",
      "Heavy Brain Stage X",
   },
   ["Arx"] = {
      probability = {
         ["Superheavy Brain Stage X"] = 7
      };
      "Superheavy Brain Stage 1",
      "Superheavy Brain Stage 2",
      "Superheavy Brain Stage 3",
      "Superheavy Brain Stage 4",
      "Superheavy Brain Stage 5",
      "Superheavy Brain Stage 6",
      "Superheavy Brain Stage 7",
      "Superheavy Brain Stage X",
   },
   ["Vox"] = {
      probability = {
         ["Superheavy Brain Stage X"] = 7
      };
      "Superheavy Brain Stage 1",
      "Superheavy Brain Stage 2",
      "Superheavy Brain Stage 3",
      "Superheavy Brain Stage 4",
      "Superheavy Brain Stage 5",
      "Superheavy Brain Stage 6",
      "Superheavy Brain Stage 7",
      "Superheavy Brain Stage X",
   },
}


-- Table of available engines by base type.
equip_typeOutfits_engines = {
   ["Hyena"] = {
      "Nexus Dart 150 Engine", "Tricon Zephyr Engine",
   },
   ["Shark"] = {
      "Nexus Dart 150 Engine", "Tricon Zephyr Engine",
   },
   ["Fidelity"] = {
      "Nexus Dart 150 Engine", "Tricon Zephyr Engine",
   },
   ["Derivative"] = {
      "Nexus Dart 150 Engine", "Tricon Zephyr Engine",
   },
   ["Vendetta"] = {
      "Unicorp Hawk 300 Engine", "Melendez Ox XL Engine",
      "Tricon Zephyr II Engine",
   },
   ["Kestrel"] = {
      "Nexus Bolt 4500 Engine", "Krain Remige Engine",
      "Tricon Typhoon Engine",
   },
   ["Hawking"] = {
      "Nexus Bolt 4500 Engine", "Tricon Typhoon Engine",
   },
   ["Brigand"] = {
      probability = {
         ["Ultralight Fast Fin Stage X"] = 2
      };
      "Ultralight Fast Fin Stage 1", "Ultralight Fast Fin Stage 2",
      "Ultralight Fast Fin Stage X",
   },
   ["Reaver"] = {
      probability = {
         ["Light Fast Fin Stage X"] = 3
      };
      "Light Fast Fin Stage 1", "Light Fast Fin Stage 2",
      "Light Fast Fin Stage 3", "Light Fast Fin Stage X",
   },
   ["Marauder"] = {
      probability = {
         ["Light Fast Fin Stage X"] = 3
      };
      "Light Fast Fin Stage 1", "Light Fast Fin Stage 2",
      "Light Fast Fin Stage 3", "Light Fast Fin Stage X",
   },
   ["Odium"] = {
      probability = {
         ["Medium Fast Fin Stage X"] = 4
      };
      "Medium Fast Fin Stage 1", "Medium Fast Fin Stage 2",
      "Medium Fast Fin Stage 3", "Medium Fast Fin Stage 4",
      "Medium Fast Fin Stage X",
   },
   ["Nyx"] = {
      probability = {
         ["Medium-Heavy Fast Fin Stage X"] = 5
      };
      "Medium-Heavy Fast Fin Stage 1",
      "Medium-Heavy Fast Fin Stage 2",
      "Medium-Heavy Fast Fin Stage 3",
      "Medium-Heavy Fast Fin Stage 4",
      "Medium-Heavy Fast Fin Stage 5",
      "Medium-Heavy Fast Fin Stage X",
   },
   ["Ira"] = {
      probability = {
         ["Heavy Fast Fin Stage X"] = 6
      };
      "Heavy Fast Fin Stage 1",
      "Heavy Fast Fin Stage 2",
      "Heavy Fast Fin Stage 3",
      "Heavy Fast Fin Stage 4",
      "Heavy Fast Fin Stage 5",
      "Heavy Fast Fin Stage 6",
      "Heavy Fast Fin Stage X",
   },
   ["Arx"] = {
      probability = {
         ["Superheavy Strong Fin Stage X"] = 7
      };
      "Superheavy Strong Fin Stage 1",
      "Superheavy Strong Fin Stage 2",
      "Superheavy Strong Fin Stage 3",
      "Superheavy Strong Fin Stage 4",
      "Superheavy Strong Fin Stage 5",
      "Superheavy Strong Fin Stage 6",
      "Superheavy Strong Fin Stage 7",
      "Superheavy Strong Fin Stage X",
   },
   ["Vox"] = {
      probability = {
         ["Superheavy Strong Fin Stage X"] = 7
      };
      "Superheavy Strong Fin Stage 1",
      "Superheavy Strong Fin Stage 2",
      "Superheavy Strong Fin Stage 3",
      "Superheavy Strong Fin Stage 4",
      "Superheavy Strong Fin Stage 5",
      "Superheavy Strong Fin Stage 6",
      "Superheavy Strong Fin Stage 7",
      "Superheavy Strong Fin Stage X",
   },
}


-- Table of available hulls by base type.
equip_typeOutfits_hulls = {
   ["Hyena"] = {
      "Unicorp D-2 Light Plating", "S&K Ultralight Stealth Plating",
   },
   ["Shark"] = {
      "Unicorp D-2 Light Plating", "S&K Ultralight Stealth Plating",
      "S&K Ultralight Combat Plating",
   },
   ["Fidelity"] = {
      "Unicorp D-2 Light Plating", "S&K Ultralight Stealth Plating",
      "S&K Ultralight Combat Plating",
   },
   ["Derivative"] = {
      "Unicorp D-2 Light Plating", "S&K Ultralight Stealth Plating",
      "S&K Ultralight Combat Plating",
   },
   ["Kestrel"] = {
      "Unicorp D-48 Heavy Plating", "S&K Heavy Combat Plating",
   },
   ["Hawking"] = {
      "Unicorp D-48 Heavy Plating", "S&K Heavy Combat Plating",
   },
   ["Brigand"] = {
      probability = {
         ["Ultralight Shell Stage X"] = 2,
      };
      "Ultralight Shell Stage 1", "Ultralight Shell Stage 2",
      "Ultralight Shell Stage X",
   },
   ["Reaver"] = {
      probability = {
         ["Light Shell Stage X"] = 3,
      };
      "Light Shell Stage 1", "Light Shell Stage 2",
      "Light Shell Stage 3", "Light Shell Stage X",
   },
   ["Marauder"] = {
      probability = {
         ["Light Shell Stage X"] = 3,
      };
      "Light Shell Stage 1", "Light Shell Stage 2",
      "Light Shell Stage 3", "Light Shell Stage X",
   },
   ["Odium"] = {
      probability = {
         ["Medium Shell Stage X"] = 4,
      };
      "Medium Shell Stage 1", "Medium Shell Stage 2",
      "Medium Shell Stage 3", "Medium Shell Stage 4",
      "Medium Shell Stage X",
   },
   ["Nyx"] = {
      probability = {
         ["Medium-Heavy Shell Stage X"] = 5,
      };
      "Medium-Heavy Shell Stage 1",
      "Medium-Heavy Shell Stage 2",
      "Medium-Heavy Shell Stage 3",
      "Medium-Heavy Shell Stage 4",
      "Medium-Heavy Shell Stage 5",
      "Medium-Heavy Shell Stage X",
   },
   ["Ira"] = {
      probability = {
         ["Heavy Shell Stage X"] = 6,
      };
      "Heavy Shell Stage 1",
      "Heavy Shell Stage 2",
      "Heavy Shell Stage 3",
      "Heavy Shell Stage 4",
      "Heavy Shell Stage 5",
      "Heavy Shell Stage 6",
      "Heavy Shell Stage X",
   },
   ["Arx"] = {
      probability = {
         ["Superheavy Shell Stage X"] = 7,
      };
      "Superheavy Shell Stage 1",
      "Superheavy Shell Stage 2",
      "Superheavy Shell Stage 3",
      "Superheavy Shell Stage 4",
      "Superheavy Shell Stage 5",
      "Superheavy Shell Stage 6",
      "Superheavy Shell Stage 7",
      "Superheavy Shell Stage X",
   },
   ["Vox"] = {
      probability = {
         ["Superheavy Shell Stage X"] = 7,
      };
      "Superheavy Shell Stage 1",
      "Superheavy Shell Stage 2",
      "Superheavy Shell Stage 3",
      "Superheavy Shell Stage 4",
      "Superheavy Shell Stage 5",
      "Superheavy Shell Stage 6",
      "Superheavy Shell Stage 7",
      "Superheavy Shell Stage X",
   },
}


-- Tables of available weapons by base type.
-- See equip_set function for more info.
equip_typeOutfits_weapons = {
   ["Hyena"] = {
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
         "Ion Cannon",
      },
   },
   ["Shark"] = {
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
         "Ion Cannon",
      },
   },
   ["Fidelity"] = {
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
         "Ion Cannon",
      },
   },
   ["Derivative"] = {
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
         "Ion Cannon",
      },
   },
   ["Brigand"] = {
      {
         num = 1;
         "Unicorp Banshee Launcher",
         "TeraCom Banshee Launcher",
         "Unicorp Mace Launcher",
         "TeraCom Mace Launcher",
      },
      {
         varied = true, probability = {
            ["BioPlasma Stinger Stage X"] = 3,
         };
         "BioPlasma Stinger Stage 1", "BioPlasma Stinger Stage 2",
         "BioPlasma Stinger Stage 3", "BioPlasma Stinger Stage X",
      },
   },
   ["Reaver"] = {
      {
         "Unicorp Fury Launcher",
      },
      {
         varied = true, probability = {
            ["BioPlasma Stinger Stage X"] = 4,
         };
         "BioPlasma Claw Stage 1", "BioPlasma Claw Stage 2",
         "BioPlasma Claw Stage 3", "BioPlasma Claw Stage 4",
         "BioPlasma Claw Stage X",
      },
      {
         varied = true, probability = {
            ["BioPlasma Stinger Stage X"] = 3,
         };
         "BioPlasma Stinger Stage 1", "BioPlasma Stinger Stage 2",
         "BioPlasma Stinger Stage 3", "BioPlasma Stinger Stage X",
      },
   },
   ["Marauder"] = {
      {
         varied = true;
         "Unicorp Fury Launcher", "TeraCom Fury Launcher",
         "Unicorp Headhunter Launcher",
      },
      {
         varied = true, probability = {
            ["BioPlasma Claw Stage X"] = 4,
         };
         "BioPlasma Claw Stage 1", "BioPlasma Claw Stage 2",
         "BioPlasma Claw Stage 3", "BioPlasma Claw Stage 4",
         "BioPlasma Claw Stage X",
      },
      {
         varied = true, probability = {
            ["BioPlasma Stinger Stage X"] = 3,
         };
         "BioPlasma Stinger Stage 1", "BioPlasma Stinger Stage 2",
         "BioPlasma Stinger Stage 3", "BioPlasma Stinger Stage X",
      },
   },
   ["Odium"] = {
      {
         varied = true;
         "TeraCom Fury Launcher",
         "TeraCom Headhunter Launcher",
         "Unicorp Vengeance Launcher",
         "TeraCom Vengeance Launcher",
         "Enygma Systems Spearhead Launcher",
         "Unicorp Caesar IV Launcher",
         "TeraCom Imperator Launcher",
      },
      {
         varied = true, probability = {
            ["BioPlasma Fang Stage X"] = 5,
         };
         "BioPlasma Fang Stage 1", "BioPlasma Fang Stage 2",
         "BioPlasma Fang Stage 3", "BioPlasma Fang Stage 4",
         "BioPlasma Fang Stage 5", "BioPlasma Fang Stage X",
      },
      {
         varied = true, probability = {
            ["BioPlasma Claw Stage X"] = 4,
         };
         "BioPlasma Claw Stage 1", "BioPlasma Claw Stage 2",
         "BioPlasma Claw Stage 3", "BioPlasma Claw Stage 4",
         "BioPlasma Claw Stage X",
      },
   },
   ["Nyx"] = {
      {
         varied = true, probability = {
            ["BioPlasma Talon Stage X"] = 6,
         };
         "BioPlasma Talon Stage 1", "BioPlasma Talon Stage 2",
         "BioPlasma Talon Stage 3", "BioPlasma Talon Stage 4",
         "BioPlasma Talon Stage 5", "BioPlasma Talon Stage 6",
         "BioPlasma Talon Stage X",
      },
      {
         num = 1;
         "TeraCom Fury Launcher", "TeraCom Headhunter Launcher",
      },
      {
         "Plasma Cluster Cannon",
      },
      {
         varied = true, probability = {
            ["BioPlasma Claw Stage X"] = 4,
         };
         "BioPlasma Claw Stage 1", "BioPlasma Claw Stage 2",
         "BioPlasma Claw Stage 3", "BioPlasma Claw Stage 4",
         "BioPlasma Claw Stage X",
      },
   },
   ["Ira"] = {
      {
         num = 1;
         "TeraCom Fury Launcher",
         "TeraCom Headhunter Launcher",
         "Enygma Systems Turreted Fury Launcher",
         "Enygma Systems Turreted Headhunter Launcher",
      },
      {
         varied = true, probability = {
            ["BioPlasma Talon Stage X"] = 6,
         };
         "BioPlasma Talon Stage 1", "BioPlasma Talon Stage 2",
         "BioPlasma Talon Stage 3", "BioPlasma Talon Stage 4",
         "BioPlasma Talon Stage 5", "BioPlasma Talon Stage 6",
         "BioPlasma Talon Stage X",
      },
   },
   ["Arx"] = {
      {
         "Brigand Fighter Bay",
      },
      {
         varied = true, probability = {
            ["BioPlasma Tentacle Stage X"] = 7,
         };
         "BioPlasma Tentacle Stage 1", "BioPlasma Tentacle Stage 2",
         "BioPlasma Tentacle Stage 3", "BioPlasma Tentacle Stage 4",
         "BioPlasma Tentacle Stage 5", "BioPlasma Tentacle Stage 6",
         "BioPlasma Tentacle Stage 7", "BioPlasma Tentacle Stage X",
      },
      {
         "Plasma Cluster Turret",
      },
   },
   ["Vox"] = {
      {
         num = 1;
         "Enygma Systems Turreted Fury Launcher",
         "Enygma Systems Turreted Headhunter Launcher",
      },
      {
         varied = true, probability = {
            ["BioPlasma Tentacle Stage X"] = 7,
         };
         "BioPlasma Tentacle Stage 1", "BioPlasma Tentacle Stage 2",
         "BioPlasma Tentacle Stage 3", "BioPlasma Tentacle Stage 4",
         "BioPlasma Tentacle Stage 5", "BioPlasma Tentacle Stage 6",
         "BioPlasma Tentacle Stage 7", "BioPlasma Tentacle Stage X",
      },
   },
}


-- Tables of available utilities by base type.
-- See equip_set function for more info.
equip_typeOutfits_utilities = {}

-- Tables of available structurals by base type.
-- See equip_set function for more info.
equip_typeOutfits_structurals = {
   ["Koäla"] = {
      {
         varied = true, probability = {
            ["Cargo Pod"] = 9, ["Fuel Pod"] = 2
         };
         "Cargo Pod", "Fuel Pod",
      },
   },
}


-- Table of available core systems by ship.
equip_shipOutfits_coreSystems = {
   ["Pirate Shark"] = {
      "Unicorp PT-18 Core System", "Milspec Prometheus 2203 Core System",
   },
   ["Empire Shark"] = {"Milspec Orion 2301 Core System"},
   ["Empire Lancelot"] = {"Milspec Orion 3701 Core System"},
   ["Sirius Fidelity"] = {"Milspec Prometheus 2203 Core System"},
   ["Za'lek Scout Drone"] = {"Milspec Aegis 2201 Core System"},
   ["Za'lek Light Drone"] = {"Milspec Aegis 2201 Core System"},
   ["Za'lek Heavy Drone"] = {"Milspec Aegis 3601 Core System"},
   ["Za'lek Bomber Drone"] = {"Milspec Aegis 3601 Core System"},
   ["Proteron Derivative"] = {"Milspec Orion 2301 Core System"},
}


-- Table of available engines by ship.
equip_shipOutfits_engines = {
   ["Empire Shark"] = {"Tricon Zephyr Engine"},
   ["Empire Lancelot"] = {"Tricon Zephyr II Engine"},
   ["Sirius Fidelity"] = {"Tricon Zephyr Engine"},
   ["Za'lek Scout Drone"] = {"Tricon Zephyr Engine"},
   ["Za'lek Light Drone"] = {"Tricon Zephyr Engine"},
   ["Za'lek Heavy Drone"] = {"Tricon Zephyr II Engine"},
   ["Za'lek Bomber Drone"] = {"Tricon Zephyr II Engine"},
   ["Proteron Derivative"] = {"Tricon Zephyr Engine"},
}


-- Table of available hulls by ship.
equip_shipOutfits_hulls = {
   ["Empire Shark"] = {
      "S&K Ultralight Stealth Plating", "S&K Ultralight Combat Plating",
   },
   ["Empire Lancelot"] = {
      "S&K Light Stealth Plating", "S&K Light Combat Plating",
   },
   ["Sirius Fidelity"] = {
      "S&K Ultralight Stealth Plating", "S&K Ultralight Combat Plating",
   },
   ["Za'lek Scout Drone"] = {"S&K Ultralight Stealth Plating"},
   ["Za'lek Light Drone"] = {"S&K Ultralight Combat Plating"},
   ["Za'lek Heavy Drone"] = {"S&K Light Combat Plating"},
   ["Za'lek Bomber Drone"] = {"S&K Light Stealth Plating"},
   ["Proteron Derivative"] = {"S&K Ultralight Stealth Plating"},
}


-- Tables of available weapons by ship.
-- See equip_set function for more info.
equip_shipOutfits_weapons = {
   ["Pirate Shark"] = {
      {
         varied = true,
         probability = {
            ["Ion Cannon"] = 10,
         };
         "Laser Cannon MK1", "Gauss Gun", "Plasma Blaster MK1",
         "Unicorp Mace Launcher", "TeraCom Mace Launcher",
         "Ion Cannon",
      },
   },
   ["Empire Shark"] = {
      {
         num = 1;
         "Unicorp Banshee Launcher", "TeraCom Banshee Launcher",
      },
      {
         "Laser Cannon MK1",
      },
   },
   ["Empire Lancelot"] = {
      {
         num = 1;
         "Unicorp Fury Launcher", "TeraCom Fury Launcher",
      },
      {
         "Laser Cannon MK2",
      },
   },
   ["Sirius Fidelity"] = {
      {
         num = 1;
         "Photon Dagger",
      },
      {
         "Razor MK1",
      },
   },
   ["Za'lek Scout Drone"] = {
      {
         "Electron Burst Cannon",
      },
   },
   ["Za'lek Light Drone"] = {
      {
         "Particle Lance",
      },
   },
   ["Za'lek Heavy Drone"] = {
      {
         num = 2;
         "Electron Burst Cannon",
      },
      {
         "Orion Lance",
      },
   },
   ["Za'lek Bomber Drone"] = {
      {
         num = 2;
         "TeraCom Fury Launcher",
      },
      {
         "Orion Lance",
      },
   },
   ["Proteron Derivative"] = {
      {
         num = 1;
         "Unicorp Banshee Launcher", "TeraCom Banshee Launcher",
      },
      {
         "Laser Cannon MK1", "Plasma Blaster MK1",
      }
   }
}


-- Tables of available utilities by ship.
-- See equip_set function for more info.
equip_shipOutfits_utilities = {
   ["Za'lek Scout Drone"] = {
      {
         "Sensor Array",
      },
   },
   ["Za'lek Light Drone"] = {
      {
         "Small Shield Booster",
      },
   },
   ["Za'lek Heavy Drone"] = {
      {
         num = 1;
         "Small Shield Booster",
      },
      {
         "Power Regulation Override",
      },
   },
   ["Za'lek Bomber Drone"] = {
      {
         "Sensor Array",
      },
   },
}

-- Tables of available structurals by ship.
-- See equip_set function for more info.
equip_shipOutfits_structurals = {
   ["Za'lek Scout Drone"] = {
      {
         "Engine Reroute",
      },
   },
   ["Za'lek Light Drone"] = {
      {
         "Shield Capacitor",
      },
   },
   ["Za'lek Heavy Drone"] = {
      {
         "Shield Capacitor",
      },
   },
   ["Za'lek Bomber Drone"] = {
      {
         "Improved Stabilizer",
      },
   },
}


--[[
Wrapper for pilot.outfitAdd() that prints a warning if no outfits added.
--]]
function equip_warn(p, outfit, q, bypass)
   q = q or 1
   local r = pilot.outfitAdd(p, outfit, q, bypass)
   if r <= 0 then
      warn(string.format(_("Could not equip %s on pilot %s!"), outfit, p:name()))
   end
   return r
end


--[[
Choose an outfit from a table of outfits.

`set` is split up into sub-tables that are iterated thru. These
tables include a "num" field which indicates how many of the chosen
outfit to equip before moving on to the next set; if nil, the chosen
outfit will be equipped as many times as possible. For example, if you
list 3 tables with "num" set to 2, 1, and nil respectively, two of an
outfit from the first table will be equipped, followed by one of an
outfit from the second table, and then finally all remaining slots will
be filled with an outfit from the third table.

If, rather than equipping multiples of the same outfit you would like to
select a random outfit `num` times, you can do so by setting "varied" to
true.

"probability" can be set to a table specifying the relative chance of
each outfit (keyed by name) to the other outfits. If unspecified, each
outfit will have a relative chance of 1. So for example, if the outfits
are "Foo", "Bar", and "Baz", with no "probability" table, each outfit
will have a 1/3 chance of being selected; however, with this
"probability" table:

@code
probability = {["Foo"] = 6, ["Bar"] = 2}
@endcode

This will lead to "Foo" having a 6/9 (2/3) chance, "Bar" will have a 2/9
chance, and "Baz" will have a 1/9 chance

Note that there should only be one type of outfit (weapons, utilities,
or structurals) in `set`; including multiple types will prevent proper
detection of how many are needed.

   @param p Pilot to equip to.
   @param set table laying out the set of outfits to equip (see below).
--]]
function equip_set(p, set)
   if set == nil then return end

   local num, varied, probability
   local choices, chance, c, i, equipped

   for k, v in ipairs(set) do
      num = v.num
      varied = v.varied
      probability = v.probability

      choices = {}
      for i, choice in ipairs(v) do
         choices[#choices + 1] = choice

         -- Add entries based on "probability".
         if probability ~= nil then
            chance = probability[choice]
            if chance ~= nil then
               -- Starting at 2 because the first one is already in the table.
               for j=2,chance do
                  choices[#choices + 1] = choice
               end
            end
         end
      end

      c = rnd.rnd(1, #choices)
      i = 1
      while #choices > 0 and (num == nil or i <= num) do
         i = i + 1
         if varied then c = rnd.rnd(1, #choices) end

         equipped = p:outfitAdd(choices[c])
         if equipped <= 0 then
            if varied or num == nil then
               table.remove(choices, c)
               c = rnd.rnd(1, #choices)
            else
               break
            end
         end
      end
   end
end


--[[
-- @brief Does generic pilot equipping
--
--    @param p Pilot to equip
--]]
function equip_generic(p)
   -- Start with an empty ship
   p:outfitRm("all")
   p:outfitRm("cores")

   local shp = p:ship()
   local shipname = shp:nameRaw()
   local basetype = shp:baseType()
   local class = shp:class()
   local success
   local o

   -- Core systems
   success = false
   o = equip_shipOutfits_coreSystems[shipname]
   if o == false then
      success = true
   elseif o ~= nil then
      success = equip_warn(p, o[rnd.rnd(1, #o)])
   end
   o = equip_typeOutfits_coreSystems[basetype]
   if o == false then
      success = true
   elseif not success and o ~= nil then
      success = equip_warn(p, o[rnd.rnd(1, #o)])
   end
   o = equip_classOutfits_coreSystems[class]
   if o == false then
      success = true
   elseif not success and o ~= nil then
      success = equip_warn(p, o[rnd.rnd(1, #o)])
   end
   if not success then
      equip_warn(p, "Unicorp PT-18 Core System")
   end

   -- Engines
   success = false
   o = equip_shipOutfits_engines[shipname]
   if o == false then
      success = true
   elseif o ~= nil then
      success = equip_warn(p, o[rnd.rnd(1, #o)])
   end
   o = equip_typeOutfits_engines[basetype]
   if o == false then
      success = true
   elseif not success and o ~= nil then
      success = equip_warn(p, o[rnd.rnd(1, #o)])
   end
   o = equip_classOutfits_engines[class]
   if o == false then
      success = true
   elseif not success and o ~= nil then
      success = equip_warn(p, o[rnd.rnd(1, #o)])
   end
   if not success then
      equip_warn(p, "Unicorp Hawk 300 Engine")
   end

   -- Hulls
   success = false
   o = equip_shipOutfits_hulls[shipname]
   if o == false then
      success = true
   elseif o ~= nil then
      success = equip_warn(p, o[rnd.rnd(1, #o)])
   end
   o = equip_typeOutfits_hulls[basetype]
   if o == false then
      success = true
   elseif not success and o ~= nil then
      success = equip_warn(p, o[rnd.rnd(1, #o)])
   end
   o = equip_classOutfits_hulls[class]
   if o == false then
      success = true
   elseif not success and o ~= nil then
      success = equip_warn(p, o[rnd.rnd(1, #o)])
   end
   if not success then
      equip_warn(p, "Unicorp D-2 Light Plating")
   end

   -- Weapons
   equip_set(p, equip_shipOutfits_weapons[shipname])
   equip_set(p, equip_typeOutfits_weapons[basetype])
   equip_set(p, equip_classOutfits_weapons[class])

   -- Utilities
   equip_set(p, equip_shipOutfits_utilities[shipname])
   equip_set(p, equip_typeOutfits_utilities[basetype])
   equip_set(p, equip_classOutfits_utilities[class])

   -- Structurals
   equip_set(p, equip_shipOutfits_structurals[shipname])
   equip_set(p, equip_typeOutfits_structurals[basetype])
   equip_set(p, equip_classOutfits_structurals[class])

   -- Fill ammo
   p:fillAmmo()

   -- Add fuel
   local mem = p:memory()
   local stats = p:stats()
   local fcons = stats.fuel_consumption
   local fmax = stats.fuel_max
   if mem.spawn_origin_type == "planet" then
      p:setFuel(true)
   else
      p:setFuel(rnd.uniform(fcons, fmax - fcons))
   end

   -- Add cargo
   local pb = equip_classCargo[class]
   if pb == nil then
      warn(string.format(
            "Class %s not handled by equip_classCargo in equip script",
            class))
      return
   end

   if rnd.rnd() < pb then
      local avail_cargo = commodity.getStandard()

      if #avail_cargo > 0 then
         for i = 1, rnd.rnd(1, 3) do
            -- Ensure that 0 tonnes of cargo doesn't get added.
            local freespace = p:cargoFree()
            if freespace < 1 then
               break
            end
            local cargotype = avail_cargo[rnd.rnd(1, #avail_cargo)]
            local ncargo = rnd.rnd(1, freespace)
            p:cargoAdd(cargotype, ncargo)
         end
      end
   end
end
