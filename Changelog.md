# NAIKARI CHANGELOG

## 0.13.0

### Major Changes

* Completely changed the vision of the game to focus on extreme
  customization, personalization, and exploration.
* Completely deleted and started remaking the universe.
* Completely deleted or replaced most factions. (New factions will be
  added as development progresses.)
* Started writing an entirely new plot, with some elements kept.
* Completely gutted CPU from the game; the only hard limit is now number
  of slots.
* Added, removed, and changed several missions and events.
* Replaced generic civilian NPCs with a single bartender NPC who
  provides information in a more structured manner.

### Other Changes

* Changed IJKL layout to use Semicolon for secondary weapon.
* Removed the large stars from the background.
* Moved the listener Z axis position further away (which fixes an issue
  where large ships could lead to stereo audio getting separated in a
  weird way).
* Adjusted sound balancing and changed default volume levels to match.
* Renamed several stats.
* Changed the default Ship Computer control to F1.
* Removed planet and bar descriptions.
* Added a date display to the Spaceport tab of land windows.
* Improved the method for selecting cargo missions (which should reduce
  the occurrence of odd scenarios like a desert world shipping water to
  a water world).
* Removed NPC "importance" markers; how important an NPC is now has to
  be determined by context.
* Increased disable inflicted by lethal weapons significantly.
* Renamed Time Constant to "Time Passage Rate".
* Changed and normalized the display names of planet services, avoiding
  the need to use the word "tab" when talking about one of the planet
  tabs in dialog, and making what the tabs display the same as what the
  services list in space displays.
* Removed all licenses which only served as a monetary hindrance to
  buying ships and outfits (like the Medium Weapon License). Outfits and
  ships which previously required these licenses no longer require them.
* Renamed most outfits, several ships, and some ship fabricators.
* Replaced outfit descriptions with fully technical ones that focus on
  explaining their mechanics, rather than attempting worldbuilding with
  them.
* Weapon aim lines are now shown for targeted asteroids as well as
  targeted pilots.

### Bugfixes

* Fixed an error in the way tabs handled mouse click positioning.

## 0.12.0

### Major Changes

* Added the Elephant, a bulk freighter which is essentially an upsized
  variant of the Mule.
* Overhauled lots of the coloring to improve colorblind accessibility
  and better unify the coloring schemes.
  * Text colors on screens related to outfits and ships now generally
    indicate something "good" with blue, something "bad" with yellow
    and an asterisk, and something "dangerous" or "critical" with red
    and a pair of exclamation points.
  * Weapon sets shown in the Ship Computer are now colored black for
    irrelevant slots, dark red for relevant but unused slots, and blue
    at two separate brightness levels for used slots.
  * The borders around slots which indicate that an outfit is required,
    exclusive, or has a special type (like core slots, fighter bay
    slots, and bio-weapon slots) are different colors, and the slot
    indicators in the shipyard are now drawn in the same way rather than
    with colored triangles. The color for required outfits is unchanged,
    but for otherwise exclusive or special-typed slots, the coloring is
    a 2-color blue gradient. (With full color vision, they just look
    like brighter shades of blue or cyan.)
  * The selected ship slot in the Equipment tab is now indicated with an
    outline, rather than replacing the color of the entire slot.
  * CPU bar is now orange with a black background, while mass limit bar
    bar is now blue with a black background.
  * Hidden jump hyperspace lanes on the starmap are now indicated as
    orange instead of red.
  * The selected autonav path on the starmap is now colored two shades
    of blue and a shade of orange, rather than the previous green,
    yellow, and red coloring.
  * Standard jump points are now a blue-green color, while hidden jump
    points are a slightly yellow-shifted red color.
  * Jump trails are now green instead of magenta.
* Added a proper hidden tutorial demonstrating weapon heat and Active
  Cooldown: the Llama's stats have been modified so that its forward
  weapons heat up much faster than most ships, and the asteroids in
  Hakoi have been given much more health, pretty much guaranteeing that
  the player's weapons overheat during the mission. When they do, Ian
  Structure gently suggests engaging Active Cooldown to get your weapons
  to start working better again.

### Other Changes

* Added several more possible randomly-generated pilot names.
* Yachts are now generally equipped more lightly.
* Split the Fighter class into Fighter and Light Fighter classes.
* Split the Cruiser class into Cruiser, Light Cruiser, and Battleship
  classes.
* Adjusted the way AI ships are equipped.
* Afterburner outfits now properly display their heat up stat.
* Lowered energy cost and increased heatup time for afterburners (making
  them more widely usable).
* Reordered stats on ships for better consistency.
* Fixed an issue where a beam turning off would stop the sound effect
  from playing on any beam at all which uses the same sound effect.
* Renamed "wrist computers" to "palmtops".
* The type of colorblindness simulated can now be configured via the
  Options menu rather than having to edit the shader file.
* Changed TC display to be relative instead of absolute (meaning e.g. a
  doubling of time passage rate is displayed as "+100%" instead of
  "200%" as it was previously).
* Energy regeneration is now simply linear, just like shield, armor, and
  fuel regeneration, which also brings it in-line with the way energy
  costs of weapons and activated outfits work.
* Derelicts now award less credits on average, but can rarely give very
  large rewards.
* Increased mass limit of Hellburner a bit.
* Emergency Shield Booster is now a medium outfit and has been made a
  bit stronger.
* Ship Computer embedded maps are now centered on the current system
  when navigating to the tabs they're in.
* The first derelict boarded is now guaranteed to give a large sum of
  credits.
* Amount of deposit for hired escorts which is eligible for refunding is
  now displayed in the escorts' credentials.
* You can now board hired escorts to rescue them if they are disabled.
* Made jammers use a bit less energy.
* Doubled all weapon energy costs. (This is to correspond with the move
  to linear energy regeneration.)
* The Empire Recruitment mission is now always guaranteed to spawn after
  you fulfill its condition (i.e. Lieutenant Chesc now follows you
  around everywhere you go in Empire territory).
* Added an event following the Big Time mission where Commander Soldner
  scolds you for going off on your own.
* Added a master volume knob to the Options menu.
* Teddy Bears From Space now guarantees a bit more for its reward.
* Jumps that you only know one direction of are now displayed in the
  starmap as if they were one-way jumps.
* Shrunk the blinker on selected pilot to its original size.
* Replaced the extra blinker on hilighted pilots with the animated
  circle which is used for hilighted planets and jumps.
* Derelict, distress, and shipwreck events can no longer spawn on top of
  or extremely close to planets or jump points.
* Modernized the way the position of the Shipwrecked August is
  determined. (The way it was previously determined was a leftover from
  Naev's very early days, where systems were small and centered around
  singular planets.)
* Renamed the "Defaults" button in the Input tab of the Options menu to
  "Presets".
* Added hotkeys for buttons in the Options menu.
* Adjusted wording of text in some missions.
* Made Turret Conversion Module medium, and took away most of its
  downsides.

### Bugfixes

* Fixed a bug that caused text in the second Ian Structure mission's OSD
  to get cut off.
* Fixed a mistake in the text of the race missions that caused racer
  names to display as "nil".
* Fixed and touched up text explanations for map trade modes.
* Fixed a bug where you couldn't get trade information for a system
  while landed on a planet without commodities.
* Fixed a bug where one planet's hilight could obscure another planet
  on the radar and overlay.
* Fixed a possibility of the time compression display showing "TC +0%"
  or "TC -0%".
* Fixed asteroid mining and boarded ship looting not updating the OSD of
  the Commodity Run mission.

## 0.11.0

### Major Changes

* Added a trio of outfits called "Thrust Bracers" (one for each slot
  size). These outfits boost engine mass limit in exchange for use of a
  structural slot.
* Added a map to the Cargo tab in the Ship Computer which works the same
  way as the map on the Commodity tab in the land window.
* Added an event where a pilot is in distress and needs rescue,
  following the Space Family mission (but these follow-up rescues have a
  less strict completion requirement of just needing to land on an
  inhabited planet).
* Removed the "Buy Local Map" button which was previously found on every
  planet. This means you can now only buy a local map at planets with an
  outfitter.
* Increased the power of less-than-lethal weaponry; damage output of
  Heavy Ion Cannon, Heavy Ion Turret, and Medusa Missile outfits has
  been substantially buffed, and damage penalty when using Weapons
  Ionizers has been decreased from -70% to -20%.
* Added more missions to the Hakoi Pirates campaign.
* Touched up the way reputation loss from combat is handled in an effort
  to avoid punishing the player for self-defense.
  * Killing a faction's ships alone now only drops your standing down to
    as little as -20%. (Your standing can still go below that as a
    result of distressing, so this only protects against further
    standing loss for self-defense.)
  * Attacking civilians now causes standing losses to all main factions
    present in the current system, in a manner similar to standing losses
    that happen when you attack a faction's allies.
* Increased the speed penalty for going over the engine mass limit.
  Going slightly over will still be fine in general, but the situation
  where the wrong engine was often ideal has been substantially
  mitigated. It's also now virtually impossible to fly a large ship with
  medium or small engines without the help of thrust bracers.

### Other Changes

* Enabled the teleport event which can happen when a Za'lek test engine
  is equipped. (The code was there, but it was turned off.
* Touched up the way audio volume and "brown noise" is handled during
  time compression. Now, in nearly all cases, maximum time compression
  leads to regular audio getting muted and the compression "brown noise"
  playing at full volume. (Previously, this was highly dependent on the
  TC Velocity setting as well as the speed of your ship, which could
  lead to situations with some ships and with some TC Velocity values
  where maximum time compression would come with an obnoxious,
  continuous high-pitched screeching noise coming from the engines.)
* The Nexus campaign now follows the Baron Prince mission and is
  more directly tied into the Baron campaign.
* Removed the third Nexus mission.
* Added a portrait for Baron Dovai Sauterfeldt and adjusted the initial
  description of his appearance to match. The portrait is used in the
  Shark mission.
* Lowered risk reward for cargo missions (which means their rewards
  don't shoot quite as high in areas with high pirate presence).
* Jump transition shader is now black instead of white.
* Board key now auto-targets a boardable pilot if none is selected (like
  the land and hyperspace keys).
* Distance you can gather gatherables from is based on the size of your
  ship, rather than a constant.
* Adjusted the AI refueling code so it's a bit more reliable when the
  pilot it's trying to refuel is moving.
* Changed the explanation of what a "skate-board" is in the Prince
  mission.
* Removed the "Ian's Courage" mission (since its purpose is outdated and
  it contradicts the direction we're now taking Ian Structure's
  character).
* OSD entries will now abbreviate themselves if there is not enough room
  to show all OSD entries of every mission.
* Reworked the way reputation gain and loss from combat is calculated.
  The effect is fairly subtle, but it should make these reputation
  changes feel less static.
* Removed the "visible messages" option; maximum visible messages is now
  controlled by the GUIs.
* Reorganized the Options menu to make it more compact and intuitive.
* Removed pirate maps from standard pirate outfitters and instead added
  them as possible offerings from black market dealers on pirate
  strongholds.
* Introduction mission ("Point of Sale") now hilights the planet it
  tells you to land on.
* Added an explanation of what "TC" means in Ian Structure's second
  mission.
* Removed the "Hitman" missions in Alteris.
* The OSD now hilights missions in the current system orange instead of
  white (so you can see at a glance which entries are most immediately
  relevant).
* Added a new Ragnarok Beam shop graphic recently added to Naev.
* The sub-entries in the OSD used by the second Ian Structure mission
  now get hilighted alongside the main entry.
* Slightly changed some of the UI colors: text entry boxes now display
  white text instead of green, the Lua console now prints gray text
  instead of green, the list hilight color has been changed from green
  to dark blue, the news feed is now white instead of green, and the
  dots indicating full knowledge of a system in the discovery mode of
  the starmap are now gold instead of green. (In short, there's a lot
  less of the color green.)
* Dvaered reputation is no longer gained when you do Empire missions.
* Increased the time the game will wait before spawning the Baron
  mission after declining it.
* Progress toward gaining Dvaered standing is now displayed in the OSD
  for the fourth Hakoi Pirates mission.
* Changed default value of TC Velocity from 5000 to 2500.
* Dvaered pilots from the warlords battle event are no longer used by
  other missions and events. (This fixes a bit of weirdness when it
  interacts with the Seek and Destroy mission.)
* Improved the visibility of the filled dots in the travel and discovery
  modes of the starmap; they are now smaller, but with black outlines.
* Changed the "friend" and "hostile" colors to make them more
  colorblind-accessible, particularly with protanopia and deuteranopia.
  (The previous colors weren't entirely terrible, but they weren't the
  most ideal choice.)

### Bugfixes

* Fixed an issue with radar clicking in the Legacy GUI.
* Fixed a regression which caused speed limitation to not work correctly
  at very small values.
* Fixed image arrays (e.g. outfit lists) causing mouseover alt-text to
  show up when keyboard navigation was used even if the mouse wasn't
  over the image array.
* Fixed player selling fuel getting counted as mission earnings for the
  purposes of hired escorts (which caused them to take a cut from the
  sale).
* Fixed an issue where some fighter bay shop graphics would get
  stretched in certain contexts (such as the GUI's weapon display).
* Fixed Shipwrecked August staying hilighted after you rescued its
  occupants.
* Fixed a bug which caused autonav actions to not successfully supersede
  and cancel auto-hyperspacing.
* Fixed the Credence in the Teenager mission spawning with empty shields
  and battery.
* Fixed the Credence in the Teenager mission coming with credits and
  cargo that you were able to loot.
* Fixed some repetitiveness in the text of the third Hakoi Pirates
  mission.
* Fixed Laser Turret MK1 mistakenly having twice as much mass and damage
  output as intended.
* Fixed the Seek and Destroy mission not spawning an informant at load
  time.
* Fixed an issue where the Seek and Destroy mission could refer to bar
  informants as "the pilot".
* Fixed a bug where attempting to clear target while Autonav is
  attempting to board would lead to the nearest boardable target getting
  immediately selected. (Clearing the target while attempting to
  auto-board now aborts Autonav.)
* Fixed a grammar error in the Power Overdrive Module description.

## 0.10.1

* Fixed a bug which could cause speed-restricted AI pilots to be unable
  to jump.

## 0.10.0

### Major Changes

* Planets you need to land on and jump points which lead you to systems
  you need to go to are now hilighted (similar to the way Naev does it,
  but a little better).
* Added the "Turret Conversion Module", which enables turning all of a
  ship's weapons into turrets.
* Completely overhauled the race missions: instead of boarding randomly
  placed stationary pilots, you now pass thru a random set of planets
  and/or jump points for a certain number of laps.
* Traders will now sometimes broadcast requests for fuel, which the
  player can answer by hailing them.

### Other Gameplay Changes

* Reduced the number of hidden jumps given to the FLF.
* Removed "hypergates" (which were really just glorified jump points to
  a hub system), since they don't really seem to be all that useful in
  gameplay and don't make much sense lore-wise.
* Warlords battle no longer sets the faction of the winning side to the
  standard Dvaered faction (which means you don't risk e.g. reputation
  loss if you find yourself on the losing side).
* Added a garbage dump location to Empire space.
* Slightly improved the waste dump mission.
* Adjusted some hyperspace connections in the universe.
* Removed the randomness from the Drinking Aristocrat mission which
  could lead to needing to make as many as nine stops. The total number
  of stops (including the correct one) is now fixed at exactly four
  (three wrong ones plus the correct one).
* Forward-facing beams now rotate in the same manner as turret beams,
  rather than instantly facing their target.
* Changed the balancing to give large turrets an inherent advantage over
  large forward-facing weapons, now that forward-facing weapons can be
  easily converted into turrets.
* Civilian NPCs are now smaller in number, but much more likely to give
  rewards.
* Reduced the number of services on introductory worlds, to more
  gradually introduce planetary services to new players.
* Generic planets can now always be bribed, even with minimum standing.
* Bribe price for "low-class" planets is now lower.
* "High-class" planets can now be bribed as long as you are not enemies
  with their faction, but at a very high bribe cost.
* Different factions now have different landing bribe costs.
* The Derelict event is now less common, but hilights the derelict so
  it's more visible.
* The Derelict event no longer spawns in systems with volatile nebulae
  (since the nebula would destroy them, which would be a bit weird).
* Mercenaries no longer protect civilians and other peaceful AI pilots.
* Larger and factional derelicts are now rarer than smaller and
  non-factional derelicts.
* Quicksilver, Koäla, and Mule now all have three weapon slots.

### Other Changes

* Replaced the cross display of system position markers (as used by e.g.
  patrol missions) with a shader based on the one Naev uses for the
  autonav go-to position indicator. This makes these markers much easier
  to see especially when they happen to be on top of planets (as is the
  case for patrol missions).
* Removed the superfluous "TARGET" text next to the autonav go-to
  position indicator.
* Aiming helper crosshair now has an outline.
* The target clear control will now clear an asteroid target as well.
* Relaxed some of our eccentric usage of diaereses. It's no longer used
  on "ao", "ei", "eu", or "ea". This also means that the subtitle is now
  "Eye of Chaos" instead of "Eye of Chaös".
* New saves now include information about what system they're landed on
  in the load screen.
* Removed use of system claims for some missions.
* Autonav resets speed less aggressively, and by default (togglable with
  an option in the Options menu) does so even less aggressively by
  ignoring passive (not actively hostile) enemies entirely.
* Land and Jump keys will now cycle thru targets if already in the
  process of auto-landing / auto-hyperspacing.
* Hilighted pilots no longer come with a text label.
* Clicking on empty space now clears the current target.
* The Mission Computer now centers the newly selected mission again when
  you click on a mission in the list.
* The map in the current missions list in the Ship Computer can now be
  interacted with just like on the Mission Computer.
* The letter on outfits in the outfitter now indicates outfit type
  (weapon, utility, stucture) again, instead of size.
* Adjusted text colors to make colored text easier to read.
* Changed the autobrake key to make it engage active cooldown without a
  second press (as in Naev).
* Added some more pilot names.
* The first Ian Structure mission now tells you the reward up-front and
  explains credits conversion instead of the second Ian Structure
  mission doing so.
* AI ships now have an amount of fuel which is matched to where they
  spawned from (i.e. they always have full fuel when taking off, and
  they always have no more than their max fuel minus their fuel
  consumption when jumping in).
* All ships in the Warlords Battle event are now hilighted, rather than
  just hilighting the leaders.
* Simplified and fixed the way near zoom is chosen (it was previously
  based on velocity and didn't really follow the Zoom Near setting in
  practice; now, the near zoom level is static).
* Setting zoom levels no longer "requires" a restart. (It wasn't
  entirely necessary before, but the options menu told you that it was
  and changing the settings messed up the stars in the background
  temporarily).
* CPU usage for outfits is now displayed as a positive "CPU Usage" value
  instead of a negative "CPU" value.
* Salvador now has no Empire presence (to match the Hakoi Pirates
  storyline).
* Adjusted some wording in the third Hakoi Pirates mission.
* Removed mention of Arnold Smith's "boss" in the Shark mission.
* Renamed the second Nexus mission to "Nexus False Flag".
* Changed the word "steal" to "loot" in the boarding window (since it
  fits better with boarding derelicts).

### Bugfixes

* Text of system position markers is now "optimized" to avoid collision
  with planet/jump overlay text.
* Fixed player and asteroid radar icons being allowed outside the
  overlay boundaries.
* Fixed some potential for conflicts with the Hitman missions.
* Fixed a typo in the Emergency Shield Booster description.
* Fixed a potential for inconsistent text in the Love Train mission.
* Fixed a design oversight which meant player fighter bay escorts did
  not escape jump as intended.
* Fixed dust amount not being recalculated on resize events.
* Fixed Dolmen missing common outfits.
* Fixed an issue where the Credence in the Teenager mission could get
  stuck flying around in circles.
* Fixed a mistake in the code which could lead to combat music playing
  when it shouldn't.
* Fixed the Credence in the Teenager mission not being given bad cores
  as intended (which is meant to slow it down and make it easier to
  catch).
* Fixed mass limit of afterburners being listed as tonnes rather than
  kilotonnes.
* Fixed failure to update the hilighted OSD objective in the Shark
  mission if a Shark was acquired via trade-in.
* Fixed the Hakoi Pirates missions not generating portraits when loading
  the game while landed at the destination planet.
* Fixed Empire ships interfering in the Dvaered warlords battle event
  and attacking the player.
* Fixed a rare bug that could cause fighter bay fighters to enter a
  limbo state when changing systems (which would continue until the
  clear orders command was given).
* Fixed display when gathering from asteroids to show kilotonnes rather
  than tonnes.
* Fixed derelicts giving reputation changes and kill rewards when you
  blew them up (which didn't make much sense as they're derelicts with
  no living occupants).

## 0.9.0

### Major Changes

* Added the Neo GUI, a new GUI intended to combine the strengths of the
  Brushed and Slim GUIs, as the new default GUI.
* Redesigned the Commodity tab of the land window:
  * Selected commodity information now sits below the commodity list,
    and does not include the commodity graphic.
  * Where the selected commodity information previously was, it now
    displays a map showing the "cost" view for the selected commodity.
* Redesigned the mission computer:
  * The positions of the mission description and the map have been
    swapped, giving the map more space.
  * The map now shows the markers for all unaccepted missions, not just
    the one you happen to have selected. The one you have selected is
    hilighted so you can still easily see where it is.
  * The mission list now hilights missions whose destination is your
    currently selected system.
  * The map is now displayed in minimal mode by default; this can be
    toggled with a "Minimal Mode" checkbox.
* Completely overhauled the trader escort mission: it now puts trader
  pilots under your wing (like escorts), with the caveat that you cannot
  issue orders to them. Completing the mission now only requires landing
  at the designated planet with the convoy intact. (The plan is to
  extend this change to unique escort missions as well, but this work
  hasn't been done yet.)
* Added some more missions to the Hakoi Pirates campaign.

### Other Gameplay Changes

* Hypergates event now adds knowledge of the hypergates.
* Sirius ships no longer refuse to run away from combat by default.
  (They now run away with the same amount of damage as Empire and
  Soromid ships.)
* Patrol missions now cause marked hostiles to never run away.
* Most AI pilots will now stop shooting a target once it has been
  disabled.
* Added a simple derelict event that randomly disables some pilots when
  entering a system.
* Fuel request event is now more likely to appear.
* Tweaked capital-class weaponry to make the different weapon types
  more differentiated (to bring them in-line with their smaller
  counterparts).
* Doubled the disable amount for all lethal weapons (which makes the
  Heavy Razor Turret and Enygma Systems Spearhead Launcher a bit
  better and should also make pilots getting incidentally disabled
  during a fight a bit more commonplace).
* Baron Prince now spawns artifact hunters in any system you enter, but
  is less likely to do so until you confirm you found the real artifact.
* Removed the restriction that disallowed boarding a pilot multiple
  times.
* Pirates will now steal cargo in addition to credits from the player.

### Other Interface Changes

* Exposed TC velocity via the options menu (which controls how much
  faster the game gets during time compression).
* The map no longer fades between modes and instead just instantly
  switches to the new mode. This also fixes a problem where it would
  always start in the default mode and then fade into the selected mode
  when you opened the map.
* The map trade views now explicitly include the unit (¢/kt) instead of
  just displaying raw numbers.
* Inverted the "high" and "low" colors for the map trade displays:
  orange is now used for high prices and blue is now used for low
  prices.
* Improved the System Info display, improving the description text's
  coloring and adding information that was previously missing.
* Whether or not right-clicking on a pilot causes you to follow them is
  now a togglable option. (Previously it was context-dependent.)
* Made cargo mission description headers gray (the same as most
  headers).
* Added a display of bolt weapons' "optimum range" (maximum range at
  which they inflict their full damage amount).
* Changed the mission failure messages for cargo missions to match other
  missions better.
* The options menu no longer (falsely) tells you that you need to
  restart the game to change the scale factor, and it now always
  properly updates after changing the scale factor setting.
* Made the FPS Limit textbox in the options menu a bit bigger.
* Moved the Reload Time stat in launchers' stat lists to a more logical
  place.

### Other Changes

* Fleets are now organized centrally such that if a pilot has a parent,
  any of its own followers will go into formation with said parent. This
  makes fleets look sleeker and more organized when some AI pilots in
  said fleets are equipped with fighter bays.
* Moved things around in Gamma Polaris to reduce conflicts in the
  overlay.
* Anglicized the spelling of the name of the Empire lieutenant you are
  recruited by, changing "Czesc" to "Chesc".
* Changed the spellings used for some words:
  * "Minuscule" is spelled "miniscule".
  * "Pursue" is spelled "persue".
  * "Though" is spelled "thô".
  * "Through" is spelled "thru".
* Added and updated several NPC portraits.
* New games now always start with the same music track playing.
* Improved the way no-run behavior (used by some missions) is
  implemented.
* Started changing the way missions and events prevent conflicts away
  from strict system claims and toward other methods that still allow
  multiple missions and events to have in one system. (This is still a
  work-in-progress.)
* Made some optimizations to the code which should help a bit with
  performance in busy systems.
* Made some small improvements to the way the AI works.
* Removed the Sirius Preach event.
* Za'lek Test mission no longer refuses to spawn if another Za'lek Test
  mission is active.
* Trader pilots now only form groups using the standard formation;
  they don't also randomly sit next to each other anymore.
* Made the different factions' weapon use a bit more distinct.
* Removed the "Baron Flintley" event which showed up after the Prince
  mission.
* Collective drones are now universally unresponsive again.

### Bugfixes

* Fixed the Commodity tab showing "¢" for the purchase price indication
  instead of the correct "¢/kt".
* Added a proper guard against a situation that could invisibly switch
  your weapon set to an empty one (althô this was unlikely to actually
  happen due to Naikari's default weapon sets).
* Fixed an issue where pressing the Starmap key to close the starmap
  would fail to run code that was supposed to run when the starmap
  closed (and thus caused some display oddities).
* Fixed land window tabs other than the commodity tab not updating when
  cargo was added to or removed from the player's ship.
* Fixed an issue in Baron Prince where exiting and reloading the game
  while landed at an artifact seller NPC's planet would cause you to
  have to takeoff reland to spawn the NPC again.
* Fixed cinematics mode messing with the GUI viewport when it shouldn't
  (which caused the Slim GUI to be messed up during cinematics).
* Fixed AI not being able to behave properly when out of fuel.
* Fixed a long-standing bug where AI pilots could get stuck spinning
  around in circles while trying to land and a similar bug when trying
  to hyperspace.
* Fixed filtering for outfits always checking against English names even
  when another language is the current language.
* Fixed the class of Marius Station.
* Fixed the Empire Recruitment mission sometimes choosing Hakoi as its
  destination.
* Fixed Aillis not having common outfits available.


## 0.8.0

* Improved generic NPC messages.
* Dvaered Vigilance is now slower than the standard Vigilance.
* Increased the number of generic NPCs that spawn to 4–14.
* Added black market dealers to black market planets; they sell you a
  randomly chosen high rarity outfit.
* There are now three different variants of the Za'lek Test Engine:
  small, medium, and large.
* Sound engine now avoids playing the same sound multiple times at once.
* Positional audio is more accurate to what you see on the screen and
  more headphone-friendly.
* Hopefully fixed an uncommon but not entirely rare crash on Linux
  release builds.
* Removed ammo stealing from the boarding window, since ammo stealing
  has never really been useful. You can now only steal credits, fuel,
  and cargo from boarded ships.
* Added a "Steal All" button to the boarding window which attempts to
  steal everything that can be stolen.
* Added an IJKL layout option as one of the defaults.
* Added hotkeys to several dialog boxes.
* Removed a nebula background which had sharp edges.
* Improved several NPC portraits.
* Made use of the old-fashioned diaeresis in English text.
* Fixed a bug where dialog boxes could cause the game to register
  unpressed keys as pressed.
* Slightly modified introductory missions' appearance times to improve
  the new user experience and in particular to avoid overloading new
  players early on.
* Standard ES cargo missions are now more common than long-distance,
  and long-distance ES cargo missions now require 5% Empire reputation.
* Bar NPCs will now sometimes give you a small amount of cargo when you
  approach them.
* Fixed a bug which could cause the Hyperspace key to incorrectly
  perform an escape jump if you had performed an escape jump recently.
* The special revered class of Siriusites is now referred to as the
  "Touchèd", rather than the "Touched" (indicating that the "E" is
  pronounced, as in "learnèd" and "blessèd").
* Bribing a pilot now bribes their followers as well, most notably
  affecting launched escorts (which previously couldn't be bribed).
* Added measures taken after bribing a pilot to ensure the fight doesn't
  resume due to stray shots in most circumstances.
* Changed the subtitle from "Imperial Storm" to "Eye of Chaös".
* Improved handling of conflicting keybinds; previously, only one of a
  pair of conflicting keybinds would register, and which one it was
  wasn't deliberately designed in any way (for example, the "hail" key
  would always jam the "autohail" key). Now, most conflicting keybinds
  will cause both actions to happen, and where it doesn't, which action
  is taken is more deliberate (for example, the "autohail" key now takes
  precedence over the "hail" key).
* Environmental damage (such as the nebula) can no longer "kill-steal"
  from the player.
* Fixed an issue where using the Load button while landed could cause
  loss of data (as it didn't save before loading).
* The game now auto-saves normally on planets with no refuel service.
  (It previously did not do so as a measure to protect against getting
  stranded, but this is no longer needed in Naikari.)
* Nerfed the Photon Dagger's damage, making it equal to the Banshee
  Rocket.
* Removed the time limit from the Shadow Run mission.
* Improved the Shark mission's handling of the OSD and markers.
* Fixed a bug which caused escort kills to never count for the player
  like they were supposed to.

## 0.7.0

### Major Changes

* Engines now come with fuel regeneration as standard.
* Replaced the Sightseeing mission with a new "Cruise" mission, where
  you take passengers to a destination and can stop by at attractions
  along the way.
* Replaced the Empire Shipping campaign with a new campaign
  investigating the appearance of pirates in Hakoi. (The first two
  missions in this new campaign are finished as of this release.)
* Rewrote the story for the Coming Out campaign and removed the fifth
  and sixth missions in it (to be replaced by missions that relate to
  the story we're building up). The story always had some level of
  focus on bigotry, but it's been made more central to its plot, and now
  involves the Soromid government. This modified Coming Out campaign
  will serve as a path to join the Soromid.
* A limited selection of AI pilots will now perform the Escape Jump
  maneuver if their armor drops to a certain threshold in battle. The AI
  pilots that will do this are: the player's escorts, civilians,
  traders, and miners. (All other AI pilots intentionally will never
  perform the maneuver, since this could be annoying to a player trying
  to do things like hunt bounties.)

### Other Mission Changes

* Changed the OSD titles of Cargo and Rush Cargo to not say "mission".
* Renamed the "Empire Shipping" log to "Empire Recruitment" (to adapt it
  to the new Hakoi pirates campaign).
* The Space Family mission no longer permanently goes away by destroying
  their ship, and has a higher chance of appearing after the first time.
* The Reynir and Teenager missions now have a 100% chance of showing up
  as long as their requirements are met.
* The Teenager mission has been revamped to be more thorough in its
  teaching of how to disable and board ships, and is now given by Terra
  instead of a nameless NPC. It now requires completion of Terra's Cargo
  as a prerequisite.
* Adjusted text to better interweave the Reynir missions with missions
  preceding and following it.
* The Shadow campaign now requires a Mercenary License before you can
  start it.
* The Baron Comm event has a higher chance of happening and doesn't
  intentionally delay itself like it used to.
* Removed the minor Cynthia campaign.
* The FLF Diversion mission no longer requires landing on Sindbad to
  collect your pay.
* The Commodity Run mission now waits to mark its corresponding system
  until after the required commodity has been obtained.
* Improved the prefixes of Cargo and Rush Cargo missions so you can more
  easily tell them apart at a glance.
* Added highlighting of some key words in the Terra's Cargo mission.
* The leader in the Trader Convoy mission now has a maximum speed of
  80% of its own speed or 80% of the player's speed, whichever is
  lower. This ensures that all ships involved have a relatively easy
  time catching up.
* The Baron Prince mission now only spawns hostile artifact hunters in
  the artifact systems, and in the system Flintley is in.
* Adjusted the Trader Convoy AI to make them a little better at staying
  close together. (This reduces, but does not entirely eliminate, a
  tendency for the following ships to break formation when a dangerous
  pirate is nearby.)
* The Commodity Run mission now prevents multiple Commodity Runs from
  being accepted at the same planet at the same time.
* The Trader Escort mission now unmarks escorted ships if you abort
  while out in space.
* Removed generation of "Pilot's Manual" log entries by the introductory
  mission (Point of Sale).
* Fixed the first Coming Out mission selecting planets that might be
  unlandable.
* The third Shark mission now utilizes standard mercenaries to create
  danger for the player rather than spawning its own.
* The Warlords Battle event has been touched up: the engagement starts
  earlier, failsafes have been added for anomalous conditions, and a
  warlord's team is highlighted and visible after the warlord dies.
* Chelsea's speed in the third and fourth Coming Out missions is limited
  to no more than 80% of the player's speed.


### Other Changes

* You can now preemptively quit the game while it is still loading
  (instead of needing to wait until loading is finished).
* Attempting to quit the game from the main menu with the close button
  no longer asks for a confirmation (making it behave the same as the
  Exit Game button while in the main menu).
* Doubled the heat reduction of Forward Shock Absorbers and Targeting
  Array to make them more appealing.
* Removed the dependency on GLPK (which Naikari wasn't actually taking
  advantage of).
* Added a "Current Missions" button to the Mission Computer, which opens
  the Missions tab of the Ship Computer (showing your current active
  missions).
* Changed the default controls:
  * "Target Next" is now bound to the "T" key, rather than
    "Target Nearest". ("Target Nearest" is now unbound by default.)
  * "Autoface" is now bound to the "E" key under WASD and ZQSD.
  * "Escape Jump" is now bound to the "Q" key under WASD, the "A" key
    under ZQSD, and the "E" key under arrow keys.
* The "Target Next" and "Target Previous" keys will now target the
  nearest applicable target if you are not targeting anything, and then
  cycle through all of the targets like before. This makes these
  controls a little easier to use.
* Mercenary Llamas now come equipped with Photon Daggers.
* Music now fades out rather than stopping suddenly when music needs to
  change due to landing on a planet.
* The AI is now more robust against cases of having the afterburner on
  when it shouldn't (which could occasionally mess with things like
  maintaining formation or landing).
* Enemy Presence, for the purpose of deciding whether to reset time
  compression during autonav, now considers only the player's exact
  range as a factor, rather than the player's range plus a buffer. This
  reduces the occurrence of unactionable slowdowns. Additionally, the
  check is more strict with what enemies it considers to be dangerous,
  for the same reason.
* Changed Mizar's nebula hue to the default.
* Fixed several instances of planets that had been missed during the
  universe overhaul in version 0.5.0.
* Removed the CPU cost of Forward Shock Absorbers.
* Fixed the Race2 mission having an error when attempting to proceed
  after loading your save.
* Moved the armor regeneration stat of bioships to bio-shells and made
  it gradually increase as the shell levels up.
* Changed the Time Constant of the Fidelity and Brigand (setting it to
  0.875 for both, the same as the Shark and other light fighters).
* Bioships now gain XP from mining in addition to getting paid.
* Unguided rockets will now auto-aim at asteroids, just like bolt
  weapons.


## 0.6.0

### Major Changes

* Added a new outfit: the Photon Dagger. This now serves as an
  introductory secondary weapon: it's available on all outfitters and is
  equipped to several ships by default (including the player's starting
  ship). It does high damage, similar to the Banshee rockets, and is
  very fast (actually the speed of light, if you work it out), but
  unlike the Banshee rockets, it has to be manually aimed and has a bit
  of a shorter range.
* Added a new mission introducing the outfitter and how to customize
  ships.
* Added "hypergates" which appear as you make friends or enemies of the
  Empire and the Great Houses. (They function like regular jump gates,
  but over long distances.)
* Changed the Collective to be neutral to the player by default, while
  also adding a standard jump point between Collective and Soromid space
  (which previously existed but was a one-way hidden jump).
* Added support for saving and loading arbitrary snapshots.
* Added APUs (Auxiliary Processing Units) which can be used to expand a
  ship's CPU capacity.
* Added some medium and large sized weapon enhancement utilities
  (similar to the Power Regulation Override and Rotary Turbo Modulator
  outfits).

### Other Changes

* Made the Collective drones stronger. (They were previously nerfed so
  they wouldn't be too frustrating in the old Collective campaign.)
* Changed generic cargo missions to have a special set of messages and a
  small faction standing boost for the destination planet's faction if
  they were high-tier ("Urgent" or "Emergency" in the case of rush cargo
  missions, "large cargo delivery" or "bulk freight delivery" in the
  case of regular cargo missions).
* Changed the Shroedinger's default weapon to the Razor MK1.
* Za'lek Test mission no longer looks through your other ships to pry
  off a Za'lek Test Engine from them (meaning you can now use them to
  hoard these engines, if you want to).
* Added conditions to prevent news entries for the Za'lek Test and race
  missions from being regenerated after you've finished them.
* Increased the number of music tracks used for the Empire and the
  Collective.
* Seek and Destroy mission now has its trail go cold significantly
  slower, ensuring you always have at least three chances to catch your
  target.
* Adjusted rarities of outfits: outfits which are only available in
  certain regions (but not only at military stations) now have a rarity
  of 1. Electron Burst Cannon is now rarity 2 instead of 3, since Za'lek
  military stations offer it.
* Reworked the Dvaered warlords event so that it's more likely to show
  up, offers a higher reward, and the winners become normal Dvaered
  ships.
* You can now hail ships even if disabled.
* Added randomization of NPC backgrounds.
* Added some text to the Unicorp Fury Launcher and Laser Turret MK1
  descriptions to help new players learn about how to properly use
  guided missiles and turreted weapons, respectively.
* Missions and events that check whether the player killed or attacked
  something now recursively check not only direct subordinates, but
  subordinates of subordinates, etc. This matters if you hire an escort
  who themself has their own escorts; it means those escorts' kills will
  now count e.g. for earning bounties.
* Added the Black Market service to several stations.
* Collective Drones are now explicitly labeled as such (rather than
  being merely labeled as "Drone" or "Heavy Drone").
* The event explaining how to ask for fuel now spawns a different kind
  of pilot depending on what factions are present in the current system
  (supporting the same factions as the fuel request event). It also no
  longer spawns in systems with none of these supported factions
  present.
* Slightly improved AI behavior when their leader dies.
* The Empire Recruitment mission now explicitly tells you where to find
  the mission computer.
* Removed the now obsolete afterburner "rumble" display (which always
  said "0 Rumble", since we don't use the "rumble" feature anymore).
* Changed the "no land" text in the Empire FLF prisoner exchange mission
  to something that makes more sense and avoids potential confusion over
  its meaning.
* Adjusted the mining AI so that miners are less likely to end up in a
  limbo state.
* Doubled the size of Suna and the amount of space used by the Dark
  Shadow mission, to bring Dark Shadow in-line with the increased radar
  range introduced in version 0.5.
* Added another medium Structural slot to the Za'lek Demon.
* Changed the order that stats of ships and outfits are displayed to
  make a little more sense.
* Changed the layout of the buttons on the list dialog (used by the
  Combat Practice mission) to be consistent with the rest of the UI.
* Seek and Destroy mission no longer leaves you able to ask repeat
  questions after you've already gotten the next location (which had no
  benefit to the player, only causing the special hail hook to
  interrupt e.g. attempts to bribe pilots or attempts to refuel
  needlessly, and introducing the possibility of accidentally paying an
  extra fee for the exact same information).
* Doubled the range that escorts consider to be "close" (to coincide
  with the increased common weapon range).
* Hired escorts now use the same AI as fighter bay escorts.
* Auto-aiming now automatically disengages if simply shooting forward is
  more accurate for a given bullet. This ensures that the auto-aiming
  system only ever *increases* accuracy, and never reduces accuracy.
* Improved the hired escorts explanatory text for how royalties work.
* Hired escorts now have a chance to disband when their payment is less
  than their promised royalty (which can happen if you run out of
  credits *and* you hire so many escorts that the total royalties you
  pay is greater than 100%).
* The Seek and Destroy mission will no longer spawn NPCs at Class 1
  stations (as these are restricted military stations).
* Changed the music used in the credits to be the same as the music used
  in the main menu.
* Increased the Goddard and Dvaered Goddard time constant from 175% to
  200%.

### Bugfixes

* Fixed the escorts in Shadow Vigil not actually defending the diplomat
  they're supposed to be escorting.
* Fixed the class of Vigilance Station (was class A for some reason).
* Fixed a bug where a previous running game's addition of faction
  presence through the Unidiff system could stay added when starting a
  new game or loading a game without that presence addition. This was
  most noticeable in Hakoi, where if you started a new game after
  loading an established game which added pirates to Hakoi, some of
  those pirates would stick around in the new game even though it's
  supposed to be pirate-free.
* Fixed a bug where a ship that was refueling you could abandon the
  refueling if it got too far away from its leader.
* Fixed a bug that caused the death menu to never show the "continue"
  option on saves with certain special characters in their names.
* Fixed a failure to warn of a version mismatch when attempting to load
  a save file from a newer version of the game.
* Fixed the Anxious Merchant mission failing to spawn.
* Fixed an occasional, generally non-fatal bug with dynamic factions
  (used by missions and events) which could eventually cause warnings
  and potentially unexpected AI behavior.
* Fixed a few planets having a non-existent graphic defined as their
  land graphics.
* Fixed slightly misleading display of afterburner stats.
* Fixed a bug where weapon tracking did not behave as intended.
* Fixed some missions causing your fighter bay escorts to disappear.
* Fixed a memory leak caused by the escort command menu.
* Patched a flaw in the AI code that may fix odd cases of AI pilots
  getting stuck rotating forever when trying to do certain tasks.
* Fixed Akios Station being listed as Class 0 when it should be Class 1.

## 0.5.2

* Fixed some OpenGL code that made assumptions that are invalid in the
  OpenGL spec, causing the game to not display on some systems as a
  result.

## 0.5.1

* Made it so that the player's escorts do not respond to AI distress
  calls. This prevents annoying situations where they pull away from
  formation unnecessarily or, worse, go to help an ally against a
  faction who's an enemy to them, but who you would rather remain
  neutral with.
* Fixed a breakage in the Collective AI initialization code.

## 0.5.0

### Major Gameplay and Design Changes

* Cargo missions now reward much more credits if they are on a route
  that has pirate presence.
* Increased the amount of health medium-heavy and heavier ships have.
* Weapons have been heavily altered. Weapon damage, range, and behavior
  vary a lot more widely than before.
* Removed the faction standing cap system. You can now gain as much
  reputation as you want with all factions (even the Collective). This
  also means all ships and outfits are available to obtain without
  having to resort to piracy.
* Added refined Unicorp platings, which serve as a middle-ground between
  the basic plating and the S&K platings. These new Unicorp X platings
  use the graphics of the Unicorp B platings Naev used to have.
* Added automatic bounties awarded whenever you kill a faction's enemy
  within a system it has presence in (e.g. killing pirates in systems
  with Empire presence, or killing FLF pilots in systems with Dvaered
  presence).
* Coupled together Frontier and FLF standing: if you are enemies with
  the Frontier, FLF standing will not go any higher than your Frontier
  standing (and your reputation will drop to enemy status when you
  become enemies with the Frontier).
* Buffed the Rotary Turbo Modulator.
* Buffed the Gawain's speed and takeoff speed. (It was already the
  fastest ship in the galaxy before, but the difference is now more
  pronounced.)
* Increased variation of commodity prices.
* Removed the mission computer bounty missions and the Assault on
  Unicorn mission as these are now redundant (bounties are earned
  without having to have a corresponding quest).
* Significantly improved the Seek and Destroy mission: difficulty levels
  have been added (like the old bounty missions had), the way NPCs
  behave is now more customized per-faction, and when you arrive at the
  appropriate system, you now need to locate your target within the
  system (similar to the ship stealing mission). The mission also now
  rewards you immediately upon completion instead of requiring you to
  land to collect your reward.
* Replaced the news entry generator, which previously just generated
  random filler with no connection to the story, with news entries that
  are relevant to the player, like mission hints.
* Added "escape jumps", which allow you to engage your hyperspace engine
  without actually going into hyperspace, taking you to a distant part
  of the system at a cost of one jump of fuel, all of your battery
  charge, half of your remaining shield, and half of your remaining
  armor. (The maneuver takes you a distance of around 30,000 mAU.)
* Converted the Reynir mission into a hidden tutorial for the local
  jumps feature and changed the rewarded commodity from Food (hot dogs)
  to Luxury Goods (robot teddy bears), making it more rewarding.
* "High-class" planets now require 10% reputation instead of 0% to land
  on.
* Removed the DIY-Nerds mission (the one where you take a group of nerds
  to a science fair or something). It never felt all that important and
  wasn't really worth doing.
* Civilians and traders will now always offer to refuel you if you
  cannot make a jump, even if you don't have credits to pay them.
* Collective drones will now refuel you if you are friendly to them.
* Added a rare "refuel request" event which causes an NPC pilot who
  needs fuel to request assistance from the player in exchange for some
  credits.
* Essentially completely redesigned the universe, most notably changing
  what planets sell, but also changing or removing some planets and
  systems. The new design has the following characteristics:
  * All planets contain a common set of basic outfits, which includes
    the "MK1" forward-facing variant of each type of weapon, basic stat
    enhancers, maps, the Mercenary License, and the low-quality
    zero-cost cores.
  * Each faction has a different set of weapons that they sell, with
    Independent and Frontier planets getting the weapons of their
    neighbors. The Empire sells laser weapons, the Soromid sell plasma
    weapons, the Dvaered sell impact weapons, the Za'lek sell beam
    weapons, and the Siriusites sell razor weapons.
  * Made sure every planet has a purpose within the system; no more
    redundant, useless planets that you would never want to land on,
    unless those planets are "low-class" (making them useful to
    outlaws).
  * Planets and stations that require more reputation to land on give
    progressively more access to exclusive ships and outfits, and
    progressively better outfits in general.
  * Planets with both an outfitter and a shipyard have their outfits
    chosen deliberately to compliment the ships they have on offer.
  * All licenses needed to purchase all outfits and ships on a given
    planet are available for purchase on that same planet (no more need
    to go looking for the license you need).
  * Changed jump points in some locations (particularly in Sirius space)
    to avoid inordinate numbers of dead-end systems. Dead-end systems
    still exist, but they are now much less common and an effort was
    made to ensure that the ones that still exist are worth going to
    for some reason or another, or otherwise serve a legitimate gameplay
    purpose.
* The race mission no longer requires you to be piloting a yacht ship to
  participate, and the ships you race against are more varied.

### Other Changes

* All bar missions are prevented from spawning in Hakoi and Eneguez
  until you finish the Ian Structure missions.
* The Empire Recruitment mission is now guaranteed to send you to a
  nearby planet with commodities as well as missions.
* Removed a random chance that existed of pirates attacking to kill
  (meaning they will now always stop attacking and board you as soon as
  you're disabled).
* Added some rescue code to the starting missions in case the player
  takes off their weapons, installing new laser cannons for them in the
  moment that they're needed.
* The Options menu now always shows 1280×720 as a stock resolution
  choice, even if not listed as a supported mode by the OS (since that
  is Naikari's default resolution), and no longer shows a choice with
  the resolution you were at when opening the Options menu.
* Double-tap afterburn is now disabled by default.
* Replaced "cycles" with "galactic years", which are 36,000,000 galactic
  seconds long (360 galactic days). Lore-wise, time units are now
  defined in relation to our 24-hour Earth days, meaning the new
  galactic year is exactly 360 days.
* The economy system no longer tracks "price knowledge". The player now
  always has perfect knowledge of pricing variation for all discovered
  planets and systems.
* The patrol mission now rewards you immediately upon completion without
  having to land in the faction's territory first.
* Changed the unit of mass used from tonnes to kilotonnes (meaning we no
  longer have the silliness of space carriers weighing less than naval
  aircraft carriers, etc).
* The game no longer refuses to resize a maximized window if you tell it
  to in the Options menu. (This change also fixes bugs with the code
  that implemented this restriction.)
* Changed the way autonav detects "hostile presence" for the purposes
  of determining whether to reset the speed that time passes. It now
  only counts ships that are close enough that one of the two ships
  will be within weapon range soon (or already are). This avoids most
  unnecessary time slowdowns while also being cautious enough to give
  advance warning to the player.
* Made it so that the debris graphics in asteroid fields are entirely
  separate from the asteroids themselves, making it more obvious which
  asteroids are real and which are just decoration.
* Changed the relation between real-world time passage and in-universe
  time passage: one real-world second is now equal to 750 in-universe
  seconds, rather than 30 in-universe seconds as before. In tandem, the
  primary components to a date have been changed from year, hour, second
  to year, day, second. (In-game time-related things have been changed
  to now use days instead of hours; for example, jump time is now one
  day instead of one hour.)
* Changed the distance unit used from kilometers to thousandths of an
  astronomical unit (mAU).
* Changed the display of unidirectional jumps in the map to use the
  color black for the exit-only side, rather than white. This is a bit
  more intuitive and also should be easier to see for colorblind
  players.
* Auto-saves are no longer disabled when landing on planets that do not
  refuel you. Instead, the design philosophy is being shifted to
  ensuring that unwinnable states are impossible anywhere you're allowed
  to land.
* Made NPC mercenaries no longer explicitly enemies with pirates (though
  they will still usually attack pirates due to their "bounty hunting"
  behavior).
* The System Info display now shows planets' color and character
  (indicating whether or not they can be landed on) on the selection
  list, which makes it much easier to navigate.
* Default weapons for ships now vary (instead of all of them using laser
  weaponry); Sirius ships have razor weaponry, Dvaered ships have
  kinetic weaponry, and Za'lek ships have beam weaponry. (Soromid ships
  already had bio-plasma weaponry since that was the only option.)
* Improved the patrol mission's detection of hostile ships and made it
  more sensitive.
* Reworked bullet graphics to make better use of what's available. There
  are no longer large numbers of weapons using the same graphics as each
  other.
* Race missions now use random portraits, rather than always one
  particular portrait.

### Bugfixes

* Fixed some problems with the way the Combat Practice mission closed
  out.
* Fixed the rescue script that activates when you take off, which had
  several small problems in how it worked caused by changes that weren't
  properly accommodated.
* Fixed a bug which caused the game to sometimes try to change to an
  arbitrary small resolution (640×480 in all observed cases) on some
  systems (noticed on Windows, but may have affected others) when
  clicking OK in the options menu.
* Fixed a problem where the Waste Dump mission would make your own
  escorts hostile toward you if you aborted it while in space.
* Extremely high turn rates no longer have the potential to mess up
  autonav during time compression.
* Fixed a rare bug caused by dying while in the landing procedure.
* Fixed possibility of dying while landing due to nebula volatility.
* Added code to prevent phantom 0 kt cargo entries from showing up in
  your cargo list.
* Fixed escorts of AI ships not jumping when their leader jumped (which
  left them adrift in the system indefinitely).
* Fixed the player being allowed to board and steal credits from their
  own hired escorts.
* Adjusted the music script to hopefully fix an uncommon bug where
  combat music played while landed.
* Fixed a double land denial message when attempting to land on
  something you're not allowed to land on with the land key.
* Fixed a game-breaking bug where the "animal trouble" event made it
  impossible to proceed with the game without rescuing yourself via the
  Lua console due to a script error.
* Fixed spawning of hostile mercenaries by the third Nexus mission (it
  was spawning the mercenaries, but failed to set them as hostile to the
  player).
* Fixed Za'lek non-drone ships being impossible to hail, as with drones.
* Fixed AI ships which spawned prior to you entering a system being
  uncooperative and/or unresponsive.
* Fixed a 14-year-old bug where the comm_no flag of AI ships (the one
  that caused the text "No response" to be printed rather than showing
  the comm window when you hailed them) pointed to an arbitrary ship,
  rather than necessarily pointing to the relevant one. This usually
  didn't have noticeable effects, *except* that it caused Za'lek boss
  ships to be unresponsive, as if they were drones, most of the time.

## 0.4.1

* Added conversion brackets to the starting missions showing what the
  "t" and "¢" suffixes mean.
* Reverted the change that causes Target Nearest to exclude escorts, as
  this caused a regression where you couldn't target them by clicking on
  them.
* Reverted an experimental SDL hint which broke the non-Linux builds and
  likely wasn't necessary anyway.

## 0.4.0

* Corrected the calculation for beam heat-up; the previous inaccuracy
  led to beams heating up faster than they were supposed to.
* Adjusted the Equipment screen and the Info ship tab, showing the
  player's credits on the Equipment screen and the ship's value on the
  Info ship tab.
* Added a Net Worth stat to the Info overview tab, showing the total
  value of your credits, ships, and outfits combined.
* Added some NPC messages.
* Fixed and adjusted some missions.
* Knowledge of the FLF's hidden jumps is now erased if you betray them.
* Fixed bad rendering of marker text.
* The FLF/Dvaered derelicts event now requires a Mercenary License and
  can only occur outside of Frontier space.
* Changed the name of the Info Window to Ship Computer.
* New combat practice mission available through the mission computer.
* New map showing waste disposal locations.
* Opening tutorial replaced with a new start-of-game campaign that
  teaches the basics of playing the game in a more natural and
  integrated fashion. This new campaign is now integrated with the
  Empire Recruitment mission, used as the basis for why you are
  recruited by the Empire rather than them just randomly choosing a warm
  body.
* Reworked the trader escort mission: the trader convoy now travels as
  a more natural fleet (going into a formation), and it also limits its
  speed so it isn't faster than you.
* Replaced the UST time system inherited from Naev with a slightly
  different time system which is called GCT, or Galactic Common Time.
  The time units are the same, but "periods" are now called "galactic
  hours", "hectoseconds" are now called "galactic minutes",
  "decaperiods" are now called "galactic days", and the words "week"
  and "month" are now colloquially used to describe time units similar
  to a week or a month.
* The Equipment screen's slot tooltips now show slot properties even
  when an item is equipped, alongside the properties of the equipped
  item.
* Added tooltips when the mouse is placed over the shipyard slot
  indicator squares. The tooltips are identical to the tooltips shown on
  the Equipment screen; they show what kind of slot they indicate and
  what outfit comes with the ship in that slot, if any.
* Right-clicking on jump points no longer engages auto-hyperspace
  behavior and instead simply falls back to standard location-based
  autonav. This is for consistency with planet auto-landing.
* The detail of shipyards being required to manage ships you aren't
  currently flying in the Equipment screen has been removed; the
  Equipment screen now functions identically on all planets that have
  them. The previous paradigm was unnecessarily confusing and didn't
  really add anything to the game.
* Added a quantity display to the image array in the Commodity tab,
  allowing you to see at a glance what cargo you're carrying.
* Added a "Follow Target" keyboard control (bound to F by default).
* The Target Nearest key now will not ever target your own escorts,
  since this is not something you're likely to want to do. The Target
  Next and Target Previous keys can still target your escorts if needed.
* Added a jump that's easy to miss to the Frontier map.
* Imported new ion and razor weaponry graphics from Naev.
* The Brushed GUI now displays the instant mode weapon set for weapons
  assigned to them. This is particularly important as it shows the
  player how to launch fighters from fighter bays with the default
  weapon configuration. To accommodate this change and keep it looking
  consistent, the Brushed GUI has been altered slightly.
* Hired escorts now list their speed so you can know in advance whether
  or not they can keep up with your ship.
* Removed the intro crawl when starting a new game. It didn't really add
  anything necessary, it was basically just a history lesson delivered
  in a rather boring manner. Any such information could easily be
  conveyed in better ways and most of it already is.
* Changed the mission marker colors and slot size colors to yellow,
  orange, and red, retaining full colorblind accessibility and the
  gradual color shift of the previous coloring while making the colors
  used more distinct.
* AI ships that come with fighter bays now count more toward filling the
  presence quota, which means they no longer inflate the amount of ships
  in the system like they used to.

## 0.3.0

* Changed Soromid taunts (the old ones inherited from Naev sounded too
  much like social darwinism, a harmful and pseudo-scientific ideology).
* Changed volume sliders to show a percentage in a standard form rather
  than the raw floating-point numbers that were previously displayed.
* The alt text when hovering your mouse over an outfit has been
  slightly rearranged and a credits display has been added to it.
* Removed the once-per-version "Welcome to Naikari" message.
* Pirate names are now generated in a different way which should be a
  bit nicer.
* Added many more possibilities for the randomly generated pilot names.
* Fixed a bug which caused pirate cargo missions to incorrectly
  calculate number of jumps to the destination (leading to lower
  rewards and a warning about you not knowing the fastest route).
* Fixed a cosmetic bug which could lead to you having phantom cargo
  after stealing cargo from ships (caused by a condition that would lead
  to AI pilots having 0 tonnes of a cargo added to them).
* Bombers now have a 20% radar range bonus (which makes their missiles
  more accurate).
* Restructured the FLF campaign so that the "Anti-Dvaered" and "Hero"
  storylines happen in parallel, rather than in an entangled fashion.
* Tutorial has been streamlined so that it introduces the game much
  better than before.
* System names for unknown systems that are marked by a mission are now
  consistently displayed everywhere (whereas previously they were
  displayed in the starmap's sidebar, but nowhere else).
* Fixed some problems with the Waste Dump mission.
* Pulled new beam store graphics from Naev.
* Escort missions now have hardened claims, preventing edge cases of
  escort missions conflicting with other missions that do things like
  clear the system. A side effect of this is that trader escort missions
  are now only offered one at a time. In tandem with this, escort
  missions' probability has been adjusted so that they are still seen
  frequently, and the trader escort mission in particular has been given
  a higher priority so that bounty missions don't prevent it from
  showing up.
* Fixed glitchy text in overlay when appearing over other text.
* Fixed pirates sometimes using Lancelot fighter bays.
* Added several new texts for the Love Train mission.
* Changed the story context of the first FLF diversion mission; it is
  now a diversion to rescue FLF soldiers trapped in a Dvaered system.
* Added several new components for randomly generated pilot names.
* Mace rockets no longer have thrust, and rockets with thrust no longer
  start at 0 speed. This change was made because the calculations the
  game made for range were not even close when trying to account for the
  acceleration component (a problem that has existed for many years in
  Naev but only became a problem because of mace rockets' reduced
  range). Thrust is now used solely for guided missiles.
* Removed the planet named "Sheik Hall" since it has no gameplay value
  and its name is iffy.

## 0.2.1

* Fixed a bug that caused the game to not start under Windows.

## 0.2.0

* Changed the land and takeoff music to be the same as ambient music.
* Adjusted balancing of outfits and ships, most noticeably changing the
  Kestrel's two large fighter bay slots to medium fighter bay slots and
  making the Huntsman torpedo much stronger.
* All ships now come with pre-installed weapons when you buy them, not
  just your first ship.
* The warning shown when warping into a system with a volatile nebula
  now shows exactly how much damage your shield and armor take from it,
  rather than only showing the direct volatility rating.
* AI pilots now launch fighters if they have fighter bays.
* Several new fighter bays have been added (mostly miniaturized versions
  of existing fighter bays, but also three variations of a Shark
  fighter bay).
* Hired escorts that are created on restricted planets and stations now
  pilot factional military ships.
* The Info window's missions tab now displays the current objective
  according to the OSD.
* Logo now lights up red for Autism Acceptance Month, turns into a
  rainbow for Queer Pride Month, and turns into aromantic pride colors
  for Aromantic Spectrum Awareness Week.
* Asteroid Scanner now always shows you scan information for asteroids
  you can see, rather than only after you've targeted them.
* Replaced Improved Refrigeration Cycle with the Rotary Turbo Modulator,
  which does the opposite of what the Improved Refrigeration Cycle did
  and serves as an equivalent to the Power Regulation Override outfit
  for turrets.
* Instant mode weapons now show up on the weapon bar in the Brushed GUI.
* Ship Stealing mission now allows stealing of non-designated targets,
  at the cost of having to pay for the entire value of the ship (meaning
  it can't be used to make credits, it can only be used to steal
  particular ships you want to add to your collection). If it fails, it
  keeps running so you can steal a ship of your choice instead, and the
  OSD message changes to note this.
* Adjusted how much money ships carry to hopefully make illegal piracy
  more rewarding and make pirating pirates less rewarding, while also
  adding variety to piracy (some factions carry a lot of credits, some
  carry very little).
* Pirates no longer have a one-way hidden jump to Collective space
  (which served no purpose and was essentially just a death trap).
* Adjusted speed and size range of background nebulae and stars so they
  look nicer.
* Ship Stealing targets now lose most of their ammo in addition to armor
  and battery, and their armor regeneration is now disabled.
* Added a limit to mercenary group size in systems with low paying
  faction presence.
* Normalized some wonky presence costs, which in particular prevents
  Za'lek drones from outnumbering pirates in systems where they're
  supposed to have lower presence than them.
* Added a new set of stations and hidden jumps to help pirates get to
  Sirius space.
* The Brushed and Slim GUIs now hide the radar while the overlay is
  open.
* Maps now each have their own individual graphics, rather than all of
  them sharing the same graphic. The graphics are screenshots showing a
  Discovery mode map window showing just the information provided by the
  respective map.
* Improved the way music tracks are chosen, preventing needless music
  changes and allowing nebula ambient music in factional areas.
* Fixed some pirates on pirate worlds being described as civilians.
* Afterburners no longer cause the screen to wobble.
* Removed the "Time Constant" tutorial, both to avoid making the system
  look more significant than it is and because the information about how
  to equip ships is redundant now that this is effectively
  self-documented (with all ships coming with reasonable weapons).
* Removed the ability to delete ship logs, which was a feature that
  didn't have any real utility for the player and risked deleting
  important information.
* Simplified the ship log display, removing the "log type" selector and
  adding a display of the currently selected log.

## 0.1.3

* Fixed Drunkard mission not being able to start up.
* Fixed Nebula Probe mission failing to advance to the next step after
  launching the probe (making it impossible to complete).
* Fixed extra copy of the Pinnacle during the Baron campaign missions.
* Fixed Pinnacle stalling after completing Baron missions (caused by a
  long-standing API bug).
* Fixed Anxious Merchant mission being unable to be accepted.

## 0.1.2

* Properly fixed a segfault in 0.1.0. Version 0.1.1 attempted a fix, but
  the fix turned out to be faulty and led to breakage.

## 0.1.1

Faulty release.

## 0.1.0

Initial release.
