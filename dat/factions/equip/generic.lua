require "jumpdist"


-- Probability of cargo by class.
equip_classCargo = {
   ["Yacht"] = .7,
   ["Luxury Yacht"] = .6,
   ["Scout"] = .05,
   ["Courier"] = .8,
   ["Freighter"] = .8,
   ["Armored Transport"] = .8,
   ["Bulk Freighter"] = 0.8,
   ["Light Fighter"] = .1,
   ["Fighter"] = .1,
   ["Bomber"] = .1,
   ["Corvette"] = .15,
   ["Destroyer"] = .2,
   ["Light Cruiser"] = .2,
   ["Cruiser"] = .2,
   ["Battleship"] = .2,
   ["Carrier"] = .3,
   ["Drone"] = .05,
   ["Heavy Drone"] = .05,
   ["Station"] = 1,
}


-- Table of classes which skip equipping, retaining default outfits.
equip_classSkip = {
   "Drone",
   "Station",
}


-- Table of available APUs by class.
-- `false` means that none should be equipped.
equip_classOutfits_coreSystems = {
   ["Yacht"] = {
      "Exacorp ET-200 APU",
      "Intek Aegis 2101 APU",
      "Intek Prometheus 2102 APU",
   },
   ["Luxury Yacht"] = {
      "Intek Prometheus 2102 APU",
   },
   ["Scout"] = {
      "Exacorp ET-300 APU",
   },
   ["Courier"] = {
      "Exacorp ET-300 APU",
      "Intek Aegis 3201 APU",
   },
   ["Freighter"] = {
      "Exacorp ET-600 APU",
      "Intek Aegis 6501 APU",
   },
   ["Armored Transport"] = {
      "Exacorp ET-600 APU",
      "Intek Aegis 6501 APU",
      "Intek Prometheus 6502 APU",
      "Intek Orion 6601 APU",
   },
   ["Bulk Freighter"] = {
      "Exacorp ET-900 APU",
      "Intek Aegis 9801 APU",
   },
   ["Light Fighter"] = {
      "Exacorp ET-200 APU",
      "Intek Aegis 2101 APU",
      "Intek Prometheus 2102 APU",
      "Intek Orion 2201 APU",
   },
   ["Fighter"] = {
      "Exacorp ET-300 APU",
      "Intek Aegis 3201 APU",
      "Intek Prometheus 3202 APU",
      "Intek Orion 3301 APU",
   },
   ["Bomber"] = {
      "Exacorp ET-300 APU",
      "Intek Aegis 3201 APU",
      "Intek Orion 3301 APU",
   },
   ["Corvette"] = {
      "Exacorp ET-500 APU",
      "Intek Aegis 5401 APU",
      "Intek Orion 5501 APU",
   },
   ["Destroyer"] = {
      "Exacorp ET-600 APU",
      "Intek Aegis 6501 APU",
      "Intek Prometheus 6502 APU",
      "Intek Orion 6601 APU",
   },
   ["Light Cruiser"] = {
      "Exacorp ET-800 APU",
      "Intek Aegis 8701 APU",
      "Intek Prometheus 8702 APU",
      "Intek Orion 8801 APU",
   },
   ["Cruiser"] = {
      "Exacorp ET-800 APU",
      "Intek Aegis 8701 APU",
      "Intek Prometheus 8702 APU",
      "Intek Orion 8801 APU",
   },
   ["Battleship"] = {
      "Exacorp ET-900 APU",
      "Intek Aegis 9801 APU",
      "Intek Prometheus 9802 APU",
      "Intek Orion 9901 APU",
   },
   ["Carrier"] = {
      "Exacorp ET-900 APU",
      "Intek Aegis 9801 APU",
      "Intek Orion 9901 APU",
   },
   ["Drone"] = {
      "Intek Orion 2201 APU",
   },
   ["Heavy Drone"] = {
      "Intek Orion 3301 APU",
   },
   ["Station"] = false,
}


-- Table of available engines by class. `false` means that
-- none should be equipped.
equip_classOutfits_engines = {
   ["Yacht"] = {
      "Exacorp HS-150 Engine",
      "Flex Tornado 150X Engine",
   },
   ["Luxury Yacht"] = {
      "Exacorp HS-150 Engine",
      "Flex Tornado 150X Engine",
   },
   ["Scout"] = {
      "Exacorp HS-150 Engine",
      "Flex Tornado 150X Engine",
   },
   ["Courier"] = {
      "Exacorp HS-300 Engine",
      "Flex Cyclone 300X Engine",
      "NGL Hauler 400F Engine",
   },
   ["Freighter"] = {
      "Exacorp HS-1200 Engine",
      "NGL Hauler 1600F Engine",
   },
   ["Armored Transport"] = {
      "Exacorp HS-1200 Engine",
      "NGL Hauler 1600F Engine",
   },
   ["Bulk Freighter"] = {
      "Exacorp HS-6500 Engine",
      "NGL Hauler 8000F Engine",
   },
   ["Light Fighter"] = {
      "Exacorp HS-150 Engine",
      "Flex Tornado 150X Engine",
   },
   ["Fighter"] = {
      "Exacorp HS-300 Engine",
      "Flex Cyclone 300X Engine",
   },
   ["Bomber"] = {
      "Exacorp HS-300 Engine",
      "Flex Cyclone 300X Engine",
      "NGL Hauler 400F Engine",
   },
   ["Corvette"] = {
      "Exacorp HS-700 Engine",
      "Flex Tornado 700X Engine",
   },
   ["Destroyer"] = {
      "Exacorp HS-1200 Engine",
      "Flex Cyclone 1200X Engine",
   },
   ["Light Cruiser"] = {
      "Exacorp HS-4500 Engine",
      "Flex Tornado 4500X Engine",
      "Flex Gust 3800S Engine",
   },
   ["Cruiser"] = {
      "Exacorp HS-4500 Engine",
      "Flex Tornado 4500X Engine",
   },
   ["Battleship"] = {
      "Exacorp HS-6500 Engine",
      "Flex Cyclone 6500X Engine",
      "NGL Hauler 8000F Engine",
   },
   ["Carrier"] = {
      "Exacorp HS-6500 Engine",
      "Flex Cyclone 6500X Engine",
      "NGL Hauler 8000F Engine",
   },
   ["Drone"] = {
      "Flex Tornado 150X Engine",
   },
   ["Heavy Drone"] = {
      "Flex Cyclone 300X Engine",
   },
   ["Station"] = false,
}


-- Table of available hulls by class. `false` means that
-- none should be equipped.
equip_classOutfits_hulls = {
   ["Yacht"] = {
      "Exacorp D-2 Hull",
      "Exacorp X-2 Hull",
   },
   ["Luxury Yacht"] = {
      "Exacorp D-2 Hull",
      "Exacorp X-2 Hull",
      "SHL Ultralight Stealth Hull",
   },
   ["Scout"] = {
      "Exacorp D-2 Hull",
      "Exacorp X-2 Hull",
      "SHL Ultralight Stealth Hull",
   },
   ["Courier"] = {
      "Exacorp D-4 Hull",
      "Exacorp X-4 Hull",
      "NGL Small Cargo Hull",
   },
   ["Freighter"] = {
      "Exacorp D-24 Hull",
      "Exacorp X-24 Hull",
      "NGL Medium Cargo Hull",
   },
   ["Armored Transport"] = {
      "Exacorp D-24 Hull",
      "Exacorp X-24 Hull",
      "NGL Medium Cargo Hull",
   },
   ["Bulk Freighter"] = {
      "Exacorp D-72 Hull",
      "Exacorp X-72 Hull",
      "NGL Large Cargo Hull",
   },
   ["Light Fighter"] = {
      "Exacorp D-2 Hull",
      "Exacorp X-2 Hull",
      "SHL Ultralight Stealth Hull",
      "SHL Ultralight Combat Hull",
   },
   ["Fighter"] = {
      "Exacorp D-4 Hull",
      "Exacorp X-4 Hull",
      "SHL Light Stealth Hull",
      "SHL Light Combat Hull"
   },
   ["Bomber"] = {
      "Exacorp D-4 Hull",
      "Exacorp X-4 Hull",
      "SHL Light Stealth Hull",
      "SHL Light Combat Hull"
   },
   ["Corvette"] = {
      "Exacorp D-12 Hull",
      "Exacorp X-12 Hull",
      "SHL Medium Stealth Hull",
      "SHL Medium Combat Hull"
   },
   ["Destroyer"] = {
      "Exacorp D-24 Hull",
      "Exacorp X-24 Hull",
      "SHL Medium-Heavy Stealth Hull",
      "SHL Medium-Heavy Combat Hull"
   },
   ["Light Cruiser"] = {
      "Exacorp D-48 Hull",
      "Exacorp X-48 Hull",
      "SHL Heavy Combat Hull",
   },
   ["Cruiser"] = {
      "Exacorp D-48 Hull",
      "Exacorp X-48 Hull",
      "SHL Heavy Combat Hull",
   },
   ["Battleship"] = {
      "Exacorp D-72 Hull",
      "Exacorp X-72 Hull",
      "SHL Superheavy Combat Hull",
   },
   ["Carrier"] = {
      "Exacorp D-72 Hull",
      "Exacorp X-72 Hull",
      "SHL Superheavy Combat Hull",
   },
   ["Drone"] = {
      "SHL Ultralight Combat Hull",
   },
   ["Heavy Drone"] = {
      "SHL Light Combat Hull",
   },
   ["Station"] = false,
}


-- Tables of available weapons by class.
-- See equip_set function for more info.
equip_classOutfits_weapons = {
   ["Yacht"] = {
      {
         num = 1;
         "FT80-U Talon Gun",
         "FL21-U Lumina Gun",
         "FR11-U Razor Gun",
         "FC22-U Crystal Gun",
         "FK21-U Katana Gun",
         "FS36-U Spear Gun",
         "Fi21-S Ion-Shackle Gun",
      },
      {
         "FL21-U Lumina Gun",
         "FR11-U Razor Gun",
         "FC22-U Crystal Gun",
         "FK21-U Katana Gun",
         "FS36-U Spear Gun",
         "Fi21-S Ion-Shackle Gun",
      },
   },
   ["Luxury Yacht"] = {
      {
         num = 1;
         "FT80-U Talon Gun",
         "FL21-U Lumina Gun",
         "FR11-U Razor Gun",
         "FC22-U Crystal Gun",
         "FK21-U Katana Gun",
         "FS36-U Spear Gun",
         "Fi21-S Ion-Shackle Gun",
      },
      {
         "FL21-U Lumina Gun",
         "FR11-U Razor Gun",
         "FC22-U Crystal Gun",
         "FK21-U Katana Gun",
         "FS36-U Spear Gun",
         "Fi21-S Ion-Shackle Gun",
      },
   },
   ["Scout"] = {
      {
         "TL21-S Lumina Turret",
         "TR14-S Razor Turret",
         "TC22-S Crystal Turret",
         "TK21-S Katana Turret",
         "TS36-S Spear Turret",
      },
   },
   ["Courier"] = {
      {
         "TL21-S Lumina Turret",
         "TR14-S Razor Turret",
         "TC22-S Crystal Turret",
         "TK21-S Katana Turret",
         "TS36-S Spear Turret",
      },
   },
   ["Freighter"] = {
      {
         num = 1;
         "TMT40-M Tiger Missile Turret",
         "TMT80-M Tiger Missile Turret",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
      {
         "TL54-M Lumina Turret",
         "TR42-M Razor Turret",
         "TC54-M Crystal Turret",
         "TK54-M Katana Turret",
         "TS81-M Spear Turret",
         "TRV250-M Venom Grenade Turret",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
   },
   ["Armored Transport"] = {
      {
         "TL110-L Lumina Turret",
         "TK110-L Katana Turret",
         "TC110-L Crystal Turret",
         "TS150-L Spear Turret",
         "Ti193-X Ion-Shackle Turret",
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
         "TL54-M Lumina Turret",
         "TR42-M Razor Turret",
         "TC54-M Crystal Turret",
         "TK54-M Katana Turret",
         "TS81-M Spear Turret",
         "TRV250-M Venom Grenade Turret",
         "TMT40-M Tiger Missile Turret",
         "TMT80-M Tiger Missile Turret",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
   },
   ["Bulk Freighter"] = {
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
         "TL110-L Lumina Turret",
         "TK110-L Katana Turret",
         "TC110-L Crystal Turret",
         "TS150-L Spear Turret",
         "Ti193-X Ion-Shackle Turret",
      },
   },
   ["Light Fighter"] = {
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
         "Fi21-S Ion-Shackle Gun",
      },
   },
   ["Fighter"] = {
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
         "Fi21-S Ion-Shackle Gun",
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
   },
   ["Bomber"] = {
      {
         varied = true;
         "FMT40-S Tiger Missile Gun",
         "FMT80-S Tiger Missile Gun",
         "FMS300-H Spider Missile Gun",
      },
      {
         "FL27-S Lumina Gun",
         "FR18-S Razor Gun",
         "FC28-S Crystal Gun",
         "FK27-S Katana Gun",
         "FS46-S Spear Gun",
         "Fi21-S Ion-Shackle Gun",
      },
   },
   ["Corvette"] = {
      {
         varied = true;
         "FMT40-S Tiger Missile Gun",
         "FMT80-S Tiger Missile Gun",
         "FMS300-H Spider Missile Gun",
         "FMT200-H Tiger Missile Gun",
         "FMO200-H Orca Missile Gun",
         "FMT800-H Tiger Torpedo Gun",
         "FMT1000-H Tiger Torpedo Gun",
         "FMS2000-H Spider Torpedo Gun",
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
   },
   ["Destroyer"] = {
      {
         "FC66-L Crystal Gun",
         "TL110-L Lumina Turret",
         "TK110-L Katana Turret",
         "TC110-L Crystal Turret",
         "TS150-L Spear Turret",
         "Ti193-X Ion-Shackle Turret",
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
         "Fi71-M Ion-Shackle Gun",
         "TL54-M Lumina Turret",
         "TR42-M Razor Turret",
         "TC54-M Crystal Turret",
         "TK54-M Katana Turret",
         "TS81-M Spear Turret",
         "TRV250-M Venom Grenade Turret",
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
         "Fi71-M Ion-Shackle Gun",
         "TL54-M Lumina Turret",
         "TR42-M Razor Turret",
         "TC54-M Crystal Turret",
         "TK54-M Katana Turret",
         "TS81-M Spear Turret",
         "TRV250-M Venom Grenade Turret",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
   },
   ["Light Cruiser"] = {
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
         "Ti193-X Ion-Shackle Turret",
      },
      {
         "TL54-M Lumina Turret",
         "TR42-M Razor Turret",
         "TC54-M Crystal Turret",
         "TK54-M Katana Turret",
         "TS81-M Spear Turret",
         "TRV250-M Venom Grenade Turret",
      },
   },
   ["Cruiser"] = {
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
         "Ti193-X Ion-Shackle Turret",
      },
      {
         "TL54-M Lumina Turret",
         "TR42-M Razor Turret",
         "TC54-M Crystal Turret",
         "TK54-M Katana Turret",
         "TS81-M Spear Turret",
         "TRV250-M Venom Grenade Turret",
         "Mini Hyena Fighter Bay",
         "Mini Shark Fighter Bay",
         "Mini Lancelot Fighter Bay",
      },
   },
   ["Battleship"] = {
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
         "Ti193-X Ion-Shackle Turret",
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
         "TL200-X Lumina Turret",
         "TC200-X Crystal Turret",
         "TS257-X Spear Turret",
      },
      {
         "TL110-L Lumina Turret",
         "TK110-L Katana Turret",
         "TC110-L Crystal Turret",
         "TS150-L Spear Turret",
         "Ti193-X Ion-Shackle Turret",
      },
   },
   ["Drone"] = {
      {
         "FB42-U Breaker Gun",
      },
   },
   ["Heavy Drone"] = {
      {
         num = 2;
         "FB42-U Breaker Gun",
      },
      {
         "FRB50-U Buzzer Cell Gun",
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
         "Small Thrust Bracer",
         "Jump Scanner",
         "Light Afterburner",
         "Sensor Array",
      },
   },
   ["Luxury Yacht"] = {
      {
         varied = true;
         "Small Thrust Bracer",
         "Jump Scanner",
         "Light Afterburner",
         "Sensor Array",
      },
   },
   ["Scout"] = {
      {
         varied = true;
         "Rotary Power Accelerator",
         "Droid Repair Crew",
         "Targeting Array",
      },
      {
         varied = true;
         "Small Thrust Bracer",
         "Turbofire Module",
         "Jump Scanner",
         "Light Afterburner",
         "Basic Jammer",
         "Reverse Thrusters",
         "Sensor Array",
      },
   },
   ["Courier"] = {
      {
         varied = true;
         "Small Thrust Bracer",
         "Turbofire Module",
         "Jump Scanner",
         "Heavy Afterburner",
      },
   },
   ["Freighter"] = {
      {
         varied = true;
         "Medium Thrust Bracer",
         "Droid Repair Crew",
         "Emergency Shield Booster",
         "Targeting Array",
         "Improved Power Regulator",
         "Enhanced Jammer",
         "Turbofire Module",
      },
   },
   ["Armored Transport"] = {
      {
         varied = true;
         "Medium Thrust Bracer",
         "Rotary Power Accelerator",
         "Droid Repair Crew",
         "Emergency Shield Booster",
         "Targeting Array",
         "Improved Power Regulator",
         "Enhanced Jammer",
         "Turbofire Module",
      },
   },
   ["Bulk Freighter"] = {
      {
         varied = true;
         "Power Overdrive Module",
         "Turret Conversion Module",
         "Droid Repair Crew",
         "Emergency Shield Booster",
         "Targeting Array",
         "Improved Power Regulator",
      },
   },
   ["Light Fighter"] = {
      {
         varied = true;
         "Light Afterburner",
         "Forward Shock Absorbers",
         "Power Regulation Override",
         "Weapons Ionizer",
         "Reverse Thrusters",
         "Sensor Array",
      },
   },
   ["Fighter"] = {
      {
         varied = true;
         "Heavy Afterburner",
         "Forward Shock Absorbers",
         "Power Regulation Override",
         "Weapons Ionizer",
         "Reverse Thrusters",
         "Sensor Array",
      },
   },
   ["Bomber"] = {
      {
         varied = true;
         "Heavy Afterburner",
         "Forward Shock Absorbers",
         "Power Regulation Override",
         "Enhanced Jammer",
         "Weapons Ionizer",
         "Reverse Thrusters",
         "Sensor Array",
      },
   },
   ["Corvette"] = {
      {
         varied = true;
         "Droid Repair Crew",
         "Emergency Shield Booster",
         "Forward Shock Absorbers",
         "Power Regulation Override",
         "Enhanced Jammer",
         "Weapons Ionizer",
         "Reverse Thrusters",
         "Heavy Afterburner",
         "Sensor Array",
      },
   },
   ["Destroyer"] = {
      {
         varied = true;
         "Power Overdrive Module",
         "Turret Conversion Module",
         "Power Amplification Circuit",
         "Rotary Power Accelerator",
         "Droid Repair Crew",
         "Emergency Shield Booster",
         "Forward Shock Absorbers",
         "Power Regulation Override",
         "Targeting Array",
         "Improved Power Regulator",
         "Weapons Ionizer",
         "Sensor Array",
      },
   },
   ["Light Cruiser"] = {
      {
         varied = true;
         "Power Overdrive Module",
         "Turret Conversion Module",
         "Droid Repair Crew",
         "Emergency Shield Booster",
         "Targeting Array",
         "Improved Power Regulator",
         "Weapons Ionizer",
         "Sensor Array",
      },
   },
   ["Cruiser"] = {
      {
         varied = true;
         "Power Overdrive Module",
         "Turret Conversion Module",
         "Droid Repair Crew",
         "Emergency Shield Booster",
         "Targeting Array",
         "Improved Power Regulator",
         "Weapons Ionizer",
         "Sensor Array",
      },
   },
   ["Battleship"] = {
      {
         varied = true;
         "Power Overdrive Module",
         "Turret Conversion Module",
         "Droid Repair Crew",
         "Emergency Shield Booster",
         "Targeting Array",
         "Improved Power Regulator",
         "Weapons Ionizer",
         "Sensor Array",
      },
   },
   ["Carrier"] = {
      {
         varied = true;
         "Power Overdrive Module",
         "Droid Repair Crew",
         "Turbofire Module",
         "Targeting Array",
         "Improved Power Regulator",
         "Weapons Ionizer",
         "Sensor Array",
      },
   },
   ["Drone"] = {
      {
         "Sensor Array",
      },
   },
   ["Heavy Drone"] = {
      {
         "Sensor Array"
      },
   }
}

-- Tables of available structurals by class.
-- See equip_set function for more info.
equip_classOutfits_structurals = {
   ["Yacht"] = {
      {
         varied = true;
         "Improved Stabilizer",
         "Engine Reroute",
         "Steering Thrusters",
         "Small Battery",
         "Small Shield Capacitor",
         "Small Cargo Pod",
         "Small Fuel Pod",
         "Solar Panel",
      },
   },
   ["Luxury Yacht"] = {
      {
         varied = true;
         "Improved Stabilizer",
         "Engine Reroute",
         "Steering Thrusters",
         "Small Battery",
         "Solar Panel",
      },
   },
   ["Scout"] = {
      {
         varied = true, probability = {
            ["Small Fuel Pod"] = 4,
            ["Improved Stabilizer"] = 2,
         };
         "Small Fuel Pod",
         "Stealth Plating",
         "Improved Stabilizer",
         "Engine Reroute",
         "Small Shield Capacitor",
      },
   },
   ["Courier"] = {
      {
         varied = true, probability = {
            ["Small Cargo Pod"] = 4,
         };
         "Small Cargo Pod",
         "Small Fuel Pod",
         "Improved Stabilizer",
      },
   },
   ["Freighter"] = {
      {
         varied = true, probability = {
            ["Medium Cargo Pod"] = 6,
         };
         "Medium Cargo Pod",
         "Medium Fuel Pod",
      },
   },
   ["Armored Transport"] = {
      {
         varied = true, probability = {
            ["Small Cargo Pod"] = 15,
            ["Medium Fuel Pod"] = 3,
         };
         "Small Cargo Pod",
         "Medium Fuel Pod",
         "Medium Battery",
         "Medium Shield Capacitor",
         "Plasteel Plating",
      },
   },
   ["Bulk Freighter"] = {
      {
         varied = true, probability = {
            ["Large Cargo Pod"] = 6,
         };
         "Large Cargo Pod",
         "Large Fuel Pod",
      },
   },
   ["Light Fighter"] = {
      {
         varied = true, probability = {
            ["Steering Thrusters"] = 4,
            ["Engine Reroute"] = 4,
         };
         "Steering Thrusters",
         "Engine Reroute",
         "Small Battery",
         "Small Shield Capacitor",
         "Small Fuel Pod",
         "Stealth Plating",
         "Solar Panel",
      },
   },
   ["Fighter"] = {
      {
         varied = true, probability = {
            ["Steering Thrusters"] = 4,
            ["Engine Reroute"] = 4,
         };
         "Steering Thrusters",
         "Engine Reroute",
         "Small Battery",
         "Small Shield Capacitor",
         "Small Fuel Pod",
         "Stealth Plating",
         "Solar Panel",
      },
   },
   ["Bomber"] = {
      {
         varied = true;
         "Steering Thrusters",
         "Engine Reroute",
         "Small Shield Capacitor",
         "Small Fuel Pod",
         "Stealth Plating",
         "Solar Panel",
      },
   },
   ["Corvette"] = {
      {
         varied = true;
         "Medium Battery",
         "Medium Shield Capacitor",
         "Plasteel Plating",
         "Medium Fuel Pod",
         "Steering Thrusters",
         "Engine Reroute",
         "Stealth Plating",
         "Solar Panel",
      },
   },
   ["Destroyer"] = {
      {
         varied = true, probability = {
            ["Large Battery"] = 3,
            ["Large Shield Capacitor"] = 3,
            ["Large Fuel Pod"] = 3,
         };
         "Large Battery",
         "Large Shield Capacitor",
         "Large Fuel Pod",
         "Nanobond Plating",
         "Dense Shield Capacitor",
      },
      {
         varied = true;
         "Medium Battery",
         "Medium Shield Capacitor",
         "Plasteel Plating",
         "Medium Fuel Pod",
      },
   },
   ["Light Cruiser"] = {
      {
         varied = true, probability = {
            ["Large Battery"] = 3,
            ["Large Shield Capacitor"] = 3,
            ["Large Fuel Pod"] = 3,
         };
         "Large Battery",
         "Large Shield Capacitor",
         "Large Fuel Pod",
         "Biometal Armor",
         "Nanobond Plating",
         "Dense Shield Capacitor",
      },
      {
         varied = true;
         "Medium Battery",
         "Medium Shield Capacitor",
         "Plasteel Plating",
      },
   },
   ["Cruiser"] = {
      {
         varied = true, probability = {
            ["Large Battery"] = 3,
            ["Large Shield Capacitor"] = 3,
            ["Large Fuel Pod"] = 3,
         };
         "Large Battery",
         "Large Shield Capacitor",
         "Large Fuel Pod",
         "Biometal Armor",
         "Nanobond Plating",
         "Dense Shield Capacitor",
      },
   },
   ["Battleship"] = {
      {
         varied = true, probability = {
            ["Biometal Armor"] = 2,
            ["Nanobond Plating"] = 6,
            ["Dense Shield Capacitor"] = 4,
            ["Large Fuel Pod"] = 3,
         };
         "Biometal Armor",
         "Nanobond Plating",
         "Dense Shield Capacitor",
         "Large Fuel Pod",
         "Large Battery",
         "Large Shield Capacitor",
      },
   },
   ["Carrier"] = {
      {
         varied = true, probability = {
            ["Biometal Armor"] = 2,
            ["Nanobond Plating"] = 6,
            ["Dense Shield Capacitor"] = 4,
            ["Large Fuel Pod"] = 3,
         };
         "Biometal Armor",
         "Nanobond Plating",
         "Dense Shield Capacitor",
         "Large Fuel Pod",
         "Large Battery",
         "Large Shield Capacitor",
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


-- Table of available APUs by base type.
equip_typeOutfits_coreSystems = {
   ["Brigand"] = {
      probability = {
         ["Ultralight Heart Stage X"] = 2
      };
      "Ultralight Heart Stage 1", "Ultralight Heart Stage 2",
      "Ultralight Heart Stage X",
   },
   ["Reaver"] = {
      probability = {
         ["Light Heart Stage X"] = 3
      };
      "Light Heart Stage 1", "Light Heart Stage 2",
      "Light Heart Stage 3", "Light Heart Stage X",
   },
   ["Marauder"] = {
      probability = {
         ["Light Heart Stage X"] = 3
      };
      "Light Heart Stage 1", "Light Heart Stage 2",
      "Light Heart Stage 3", "Light Heart Stage X",
   },
   ["Odium"] = {
      probability = {
         ["Medium Heart Stage X"] = 4
      };
      "Medium Heart Stage 1", "Medium Heart Stage 2",
      "Medium Heart Stage 3", "Medium Heart Stage 4",
      "Medium Heart Stage X",
   },
   ["Nyx"] = {
      probability = {
         ["Medium-Heavy Heart Stage X"] = 5
      };
      "Medium-Heavy Heart Stage 1",
      "Medium-Heavy Heart Stage 2",
      "Medium-Heavy Heart Stage 3",
      "Medium-Heavy Heart Stage 4",
      "Medium-Heavy Heart Stage 5",
      "Medium-Heavy Heart Stage X",
   },
   ["Ira"] = {
      probability = {
         ["Heavy Heart Stage X"] = 6
      };
      "Heavy Heart Stage 1",
      "Heavy Heart Stage 2",
      "Heavy Heart Stage 3",
      "Heavy Heart Stage 4",
      "Heavy Heart Stage 5",
      "Heavy Heart Stage 6",
      "Heavy Heart Stage X",
   },
   ["Arx"] = {
      probability = {
         ["Superheavy Heart Stage X"] = 7
      };
      "Superheavy Heart Stage 1",
      "Superheavy Heart Stage 2",
      "Superheavy Heart Stage 3",
      "Superheavy Heart Stage 4",
      "Superheavy Heart Stage 5",
      "Superheavy Heart Stage 6",
      "Superheavy Heart Stage 7",
      "Superheavy Heart Stage X",
   },
   ["Vox"] = {
      probability = {
         ["Superheavy Heart Stage X"] = 7
      };
      "Superheavy Heart Stage 1",
      "Superheavy Heart Stage 2",
      "Superheavy Heart Stage 3",
      "Superheavy Heart Stage 4",
      "Superheavy Heart Stage 5",
      "Superheavy Heart Stage 6",
      "Superheavy Heart Stage 7",
      "Superheavy Heart Stage X",
   },
}


-- Table of available engines by base type.
equip_typeOutfits_engines = {
   ["Vendetta"] = {
      "Exacorp HS-300 Engine",
      "Flex Cyclone 300X Engine",
      "NGL Hauler 400F Engine",
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
   ["Brigand"] = {
      {
         num = 1;
         "FRC80-U Claw Rocket Gun",
         "FRS60-U Stinger Rocket Gun",
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
         "FMT40-S Tiger Missile Gun",
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
         "FMT40-S Tiger Missile Gun",
         "FMT80-S Tiger Missile Gun",
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
         "FMT40-S Tiger Missile Gun",
         "FMT80-S Tiger Missile Gun",
         "FMT200-H Tiger Missile Gun",
         "FMO200-H Orca Missile Gun",
         "FMT800-H Tiger Torpedo Gun",
         "FMT1000-H Tiger Torpedo Gun",
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
         "FMT40-S Tiger Missile Gun", "FMT80-S Tiger Missile Gun",
      },
      {
         "FK55-M Katana Gun",
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
         "FMT40-S Tiger Missile Gun",
         "FMT80-S Tiger Missile Gun",
         "TMT40-M Tiger Missile Turret",
         "TMT80-M Tiger Missile Turret",
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
         "TK110-L Katana Turret",
      },
   },
   ["Vox"] = {
      {
         num = 1;
         "TMT40-M Tiger Missile Turret",
         "TMT80-M Tiger Missile Turret",
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
            ["Small Cargo Pod"] = 9,
            ["Small Fuel Pod"] = 2
         };
         "Small Cargo Pod",
         "Small Fuel Pod",
      },
   },
}


-- Table of available APUs by ship.
equip_shipOutfits_coreSystems = {
}


-- Table of available engines by ship.
equip_shipOutfits_engines = {
}


-- Table of available hulls by ship.
equip_shipOutfits_hulls = {
}


-- Tables of available weapons by ship.
-- See equip_set function for more info.
equip_shipOutfits_weapons = {
}


-- Tables of available utilities by ship.
-- See equip_set function for more info.
equip_shipOutfits_utilities = {
}

-- Tables of available structurals by ship.
-- See equip_set function for more info.
equip_shipOutfits_structurals = {
}


--[[
Wrapper for pilot.outfitAdd() that prints a warning if no outfits added.
--]]
function equip_warn(p, outfit, q, bypass_cpu, bypass_slot)
   q = q or 1
   local r = pilot.outfitAdd(p, outfit, q, bypass_cpu, bypass_slot)
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
Does generic pilot equipping

   @param p Pilot to equip
   @param[opt] recursive Used internally to track recursive calls.
--]]
function equip_generic(p, recursive)
   local shp = p:ship()
   local shipname = shp:nameRaw()
   local basetype = shp:baseType()
   local class = shp:class()
   local success
   local o

   -- Check to see if equipping should be skipped.
   -- TODO: Should still do cargo adding if applicable.
   -- TODO: Implement type-specific and ship-specific skipping.
   for i = 1, #equip_classSkip do
      if equip_classSkip[i] == class then
         return
      end
   end

   -- Start with an empty ship
   p:outfitRm("all")
   p:outfitRm("cores")

   -- APUs
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
      equip_warn(p, "Exacorp ET-200 APU")
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
      equip_warn(p, "Exacorp HS-300 Engine")
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
      equip_warn(p, "Exacorp D-2 Hull")
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

   -- Check spaceworthiness.
   if not p:spaceworthy() then
      -- Ship is not spaceworthy, so remove cargo and re-equip the ship.
      p:cargoRm("all")
      if recursive then
         -- If we already retried, fall back to default outfits.
         p:outfitEquipDefaults()

         -- Fill ammo.
         p:fillAmmo()

         -- Add fuel.
         local mem = p:memory()
         local stats = p:stats()
         local fcons = stats.fuel_consumption
         local fmax = stats.fuel_max
         if mem.spawn_origin_type == "planet" then
            p:setFuel(true)
         else
            p:setFuel(rnd.uniform(fcons, fmax - fcons))
         end
      else
         -- We've only tried once, so give it another try.
         equip_generic(p, true)
      end
   end
end
