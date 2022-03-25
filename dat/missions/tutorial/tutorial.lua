--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Tutorial">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>1</priority>
  <location>None</location>
 </avail>
 <notes>
  <provides name="Continued Tutorial">If you say yes to more help</provides>
 </notes>
</mission>
--]]
--[[

   Tutorial Mission

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

--]]

local fmt = require "fmt"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"


a_commodity = commodity.get("Water")
an_outfit = outfit.get("Heavy Laser Turret")

intro_text  = _([["Congratulations on your first space ship, {player}!" Ian Structure, who sold the {shipname} to you, says through the radio. "You have made an excellent decision to purchase from Melendez Corporation! Our ships are prized for their reliability and affordability. I promise, you won't be disappointed!" You are skeptical of the sales pitch, of course; you really only bought this ship because it was the only one you could afford. Still, you tactfully thank the salesperson.

"Now that we have you out in space for the first time, how about I go over your new ship's controls with you real quick? No charge!"]])

nothanks_text  = _([["Ha, I guess you're eager to start, eh? Well, I won't hold you back. I have uploaded some useful information which you can review any time you like by checking the Tutorial section of your ship log. The ship log can be found in the Info window, which you can access by pressing {infokey}, or by pressing {menukey} and clicking the 'Info' button. Good luck!" With Ian Structure now gone, you set off on your journey.]])

movement_text = _([["Alright, let's go over how to pilot your new state-of-the-art ship from Melendez Corporation, then!" You resist the urge to roll your eyes. "Moving is pretty simple: rotate your ship with {leftkey} and {rightkey}, and thrust to move your ship forward with {accelkey}! You can also use {reversekey} to rotate your ship to the direction opposite of your current movement, or to reverse thrust if you purchase and install a Reverse Thruster onto your Melendez Corporation starship. Give it a try by flying over to {planet}! You see it on your screen, right? It 's the planet right next to you."]])

objectives_text = _([["Perfect! That was easy enough, right? We at Melendez Corporation recommend this manner of flight, which we call 'keyboard flight'.

However, there is one other way you can fly if you so choose: press {mouseflykey} on your console and your Melendez Corporation ship will turn toward your #bmouse pointer#0 automatically! You can then thrust either with {accelkey}, the #bmiddle mouse button#0, or either of the #bextra mouse buttons#0. What method you use to pilot your ship is entirely up to you.

"Ah, you may also have noticed the mission on-screen display on your monitor! As you can see, you completed your first objective of the Tutorial mission, so the next objective is now being highlighted."]])

landing_text = _([["On that note, let's go over landing! All kinds of actions, like landing on planets, hailing ships, boarding disabled ships, and jumping to other systems can be accomplished by #bdouble-clicking#0 on an applicable target, or alternatively by pressing certain buttons on your control console. How about you try landing on {planet}? You can engage the automatic landing procedure either by #bdouble-clicking#0 on the planet or its radar icon, or by targeting the planet with {target_planet_key} and then pressing {landkey}. Give it a try!"]])

land_text = _([["Excellent! The landing was successful. Melendez Corporation uses advanced artificial intelligence technology so that you never have to worry about your ship crashing. It may seem like a small thing, but it wasn't long ago when pilots had to land manually and crashes were commonplace! We at Melendez Corporation pride ourselves in protecting the safety of our valued customers and ensuring that your ship is reliable and resilient.

"When you land, your ship is refueled automatically and you can do things such as talk to civilians at the bar, buy new ship components, configure your ship, and most importantly, accept missions from the Mission Computer. Why don't we look around? As you can see, we are currently on the Landing Main tab, where you can learn about the planet and buy a local map. Click all the other tabs below and I'll give you a tour through what else you can do on a planet. When you are done, click the 'Take Off' button so we can continue."]])

bar_text = _([["This is the Spaceport Bar, where you can read the latest news, but more importantly, you can meet civilians, hire pilots to join your fleet, and sometimes find unique mission opportunities! I recommend regularly talking to patrons at the bar, at least early on. Some may have useful tips for you, or you may even find a local to help you find nearby systems!"]])

mission_text = _([["This is the Mission Computer, where you can find basic missions in the official mission database. Missions are how you make your living as a pilot, so I recommend you check this screen often to see where the money-making opportunities are!

"When picking missions, pay attention to how much they pay. You'll want to strike a balance of choosing missions that you're capable of doing, but getting paid as much as possible to do them. Once you've accepted a mission, you can review it at any time via the Info window by pressing {infokey}."]])

outfits_text = _([["This is the Outfitter, where you can buy new outfits to make your Melendez Corporation starship even better! You can fit your ship with new weapons, extra cargo space, more powerful core systems, and more! Regional maps which can help you explore the galaxy more easily can also be purchased here, as well as licenses required for higher-end weaponry and starships (such as our top-of-the-line Melendez Mule Bulk Cargo Starship, widely sought after for its unmatched cargo capacity).

"As you can see, a series of tabs at the top of your screen allow you to filter outfits by type: 'W' for weapons, 'U' for utilities, 'S' for structurals, 'Core' for cores, and 'Other' for anything else. Different planets have different outfits available; if you don't see a specific outfit you're looking for, you can search for it via the 'Find Outfits' button."]])

shipyard_text = _([["This is the Shipyard, where you can buy new starships to either replace the one you've got, or to add to your collection! You can then either buy a ship with the 'Buy' button, or trade your current ship in for the new ship with the 'Trade-In' button. Different planets have different ships available; if you don't see a specific ship you're looking for, you can search for it via the 'Find Ships' button.

"You have no need for this screen right now, but later on, when you've saved up enough, you'll likely want to upgrade your ship to an even better one, depending on what kinds of tasks you will be performing. I highly recommend either our Melendez Quicksilver Rush Cargo Starship for cargo missions that have a time limit, or our Melendez Koala Compact Bulk Cargo Starship for missions that require carrying large amounts of cargo. We sincerely thank you for shopping with Melendez Corporation!"]])

equipment_text = _([["This is the Equipment screen, available on all planets and stations with an outfitter or a shipyard. Here, you can equip your ships with outfits you own and sell outfits you have no more use for. If the planet or station you're landed at has a shipyard, you can also change which ship you're flying and sell unneeded ships and outfits. Selling a ship that still has outfits equipped will also lead to those outfits being sold along with the ship, so do keep that in mind.

"You will notice that your ship comes with two laser cannons by default. If you make any changes to your ship now, please ensure that you still have two weapons equipped, as you will need those later for practicing combat. Besides, flying around space without any weapons can be very risky."]])

commodity_text = _([["This is the Commodity screen, where you can buy and sell commodities. Commodity prices vary from planet to planet and even over time, so you can use this screen to attempt to make money by buying low and selling high. Here, it's useful to hold the Shift and/or Ctrl keys to adjust how many tonnes of the commodity you're buying or selling at once.

"If you're unsure what's profitable to buy or sell, the starmap (which we will cover later) allows you to compare known average prices across the galaxy. The news terminal at the bar also includes up-to-date price information for specific nearby planets."]])

overlay_text = _([["Welcome back to space, {player}! Let's continue discussing moving around in space. As mentioned before, you can move around space manually, no problem. However, you will often want to travel large distances, and navigating everywhere manually could be a bit tedious. That is why we at Melendez Corporation always include the latest Autonav technology with all of our ships! When your ship is piloted with autonav, while the trip takes just as long in real time, advanced Melendez Corporation technology allows you to step away from your controls, making it seem as though time is passing at a faster rate (a phenomenon we call 'time compression'). And don't worry; if any hostile pilots are detected, our Autonav system automatically alerts you so you can return to your controls, ending time compression. This can be configured in the Options menu.

"Allow me to demonstrate. To start with, please press {overlaykey} to open your ship's overlay map."]])

autonav_text = _([["Good job! As you can see, your overlay map shows several indicator icons. These icons represent objects in the current system that are visible to you: planets, jump points, ships, and asteroids. These icons are color-coded to indicate whether the objects are friendly, neutral, or hostile, and planets are also marked with symbols which serve the same purpose for colorblind accessibility.

"Now that the overlay map is open, you can use your mouse to interact with objects the same way you would with the actual object. In addition, you can fly to any location in the system automatically by #bright-clicking#0 on its corresponding location on the overlay map.

"Why don't you give it a try by using Autonav to fly over to {planet}? Simply #bright-click#0 on your overlay map's {planet} icon and watch in amazement as autonav takes you there quickly, easily, and painlessly."]])

target_text = _([["Great job! As you can see, by using Autonav, the perceived duration of your trip was cut substantially. You will grow to appreciate this feature in your Melendez Corporation ship in time, especially as you travel from system to system delivering goods and such.

"Let's now practice combat. You won't need this if you stick to the safe systems in the southern Empire core, but sadly, you are likely to encounter pirate scum if you venture further out, so you need to know how to defend yourself. Fortunately, your ship comes pre-equipped with state-of-the-art laser cannons for just that reason!

"I will launch a combat practice drone off of {planet} now for you to fight. Don't worry; our drone does not have any weapons and will not harm you. To start with, target the drone by pressing {target_hostile_key}."]])

combat_text = _([["Easy, isn't it? It's also possible to target any ship by clicking on it, but that method is often too slow for the heat of battle.

"As you can see, targeting the drone allows you to see information about the ship. More importantly, though, targeting the drone enables automatic weapon tracking systems which help ease aiming. When you are within firing range of a targeted ship, you will see a series of lines around your ship to help with aiming. The circle indicates where the targeted ship is expected to be by the time your bullets reach them, on average. If your weapons are within firing range of the target, you will also see a cross which indicates where your weapons are pointed at and a pair of lines on either side of the cross indicating how much your weapons will swivel to compensate for imprecise aiming.

"Your weapons are fired with {primarykey} and {secondarykey}. Give it a try and shoot the practice drone down!"]])

infoscreen_text =_([["Excellent work taking out that drone! By the way, you can configure the way your weapons shoot from the Weapons tab of the Info window, which can be accessed by pressing {infokey} or by pressing {menukey} and then clicking on the Info button. The Info window also lets you view information about your ship, cargo, current missions, and reputation with the various factions. You will likely be referencing it a lot.]])

cooldown_text = _([["Now, as you may have noticed while you shot down the practice drone, shield regenerates over time, but armor does not. This is not universal, of course; some ships, particularly larger ships, feature advanced armor repair technology. But even then, armor regeneration is usually much slower than shield regeneration.

"You may have also noticed your heat meters going up and your weapons becoming less accurate as your ship and weapons got hot. This is normal, but too much heat can make your weapons difficult to use, which is why we at Melendez Corporation recommend using active cooldown when it is safe to do so. Let's practice using it. Engage active cooldown and wait for it to cool your ship down completely. You can engage active cooldown by pressing {autobrake_key} twice."]])

jumping_text = _([["Good job! Your ship is now fully cooled off. In addition to using Active Cooldown, you can also cool off by landing on any planet or station.

"I think it's about time for a change in scenery, don't you? There are many systems in the universe; this one is but a tiny sliver of what can be found out there! Traveling through systems is accomplished through jump points. Like planets, you usually need to find these by exploring the area, talking to the locals, or buying maps. Once you have found a jump point, you can use it by #bdouble-clicking#0 on it.

Traveling long distances that way can be rather repetitive and inconvenient, however, so let's take a look at a better interface for traveling between stars: the starmap! To start with, please open the starmap by pressing {starmapkey}.]])

starmap_text = _([["Behold, perhaps the most useful tool in your arsenal! This map shows all systems that you know about, where you need to go for missions, and even detailed information about each system! The starmap also allows for much easier travel. By selecting a destination system that you know the route to and clicking the 'Autonav' button, autonav automatically plans a route for you and will pilot your ship all the way to the destination system, as long as your ship has enough fuel. Let me show you!

"I've taken the liberty of placing a destination marker on your starmap for the {system} system. You probably can't see the name of the system, but you should nonetheless see the marker I placed on your starmap. All you need to do is click on that system, and then click on the 'Autonav' button. Once you've done that, you can sit back and relax as autonav takes care of the rest!"]])

fuel_text = _([["Was that easy, or was that easy? As you can see, the trip consumed fuel. You consume fuel any time you make a jump and can refuel by landing on a friendly planet. Standard engines have enough fuel to make up to three jumps before refueling, though higher-end engines have more fuel capacity and some ships may have their own supplementary fuel tanks. In any case, you will want to plan your routes so that you don't end up in a system where you can't land without fuel.

"Now, then, why don't we put your knowledge to the test? I have placed a new marker on your starmap showing the location of your final destination: {system}, the heart of the Empire and home to the Emperor's famous warship, the Emperor's Wrath. This time, you will need to use what I taught you to find your way to your destination on your own. Let's see what you've learned!"]])

ask_continue_text = _([[Ian Structure gives you a round of applause as you enter {system}. "Phenominal piloting, {player}! Truly stunning! I must say, you are a natural-born pilot and your new Melendez Corporation Starship suits you well! I have no doubt about it, you are ready to make your way in space, and I'm sure you will have millions of credits in no time!

"That said, there are other aspects of piloting I wasn't able to get into here. If you like, I can continue to give you guidance, free of charge! I promise to be unobtrusive; I'll just pop in and let you know about some other things when they become relevant. What do you say?"]])

continue_yes_text = _([["Splendid! I'll leave you to your travels and keep an eye out. If you miss or forget anything, check the Tutorial section of your ship log; it can be found in the Info window, which you can access by pressing {infokey}, or by pressing {menukey} and then clicking the 'Info' button. Best of luck!"]])

continue_no_text = _([["Ah, ok! In that case, I wish you good luck in your travels. You can review all the information we've gone through by checking the Tutorial section of your ship log; it can be found in the Info window, which you can access by pressing {infokey}, or by pressing {menukey} and clicking the 'Info' button. I may add additional entries to the Tutorial log if I think of them, as well. Thank you for shopping with Melendez Corporation!" Ian Structure ceases contact and you let out a sigh of relief. You had no idea the level of annoyance you were getting into. At least you learned how to pilot the ship, though!]])

movement_log = _([[Basic movement can be accomplished by the movement keys (Accelerate, Turn Left, Turn Right, and Reverse; W, A, D, and S by default). The Reverse key either turns your ship to the direction opposite of your current movement, or thrusts backwards if you have a Reverse Thruster equipped.

Alternatively, you can enable mouse flight by pressing the Mouse Flight key (Ctrl+X by default), which causes your ship to automatically point toward your mouse pointer. You can then thrust with the Accelerate key (W by default), middle mouse button, or either of the extra mouse buttons.]])
objectives_log = _([[The mission on-screen display highlights your current objective for each mission. When you complete one objective, the next objective is highlighted.]])
landing_log = _([[You can land on any planet by either double-clicking on it, or by targeting the planet with the Target Planet button and then pressing the Land key (L by default). The landing procedure is automatic. If no planet is selected, pressing the Land key will initiate the automatic landing procedure for the closest suitable planet if possible.]])
land_log = _([[When you land, your ship is refueled automatically if the planet or station has the "Refuel" service. Most planets and stations have the "Refuel" service, though there are some exceptions.]])
bar_log = _([[The Spaceport Bar allows you to read the news, meet civilians, hire pilots to join your fleet, and sometimes find unique missions. You can click on any patron of the bar and then click on the Approach button to approach them. Some civilians may lend helpful advice.]])
mission_log = _([[You can find basic missions in the official mission database via the Mission Computer (Missions tab while landed). You can review your active missions at any time via the Info window, which you can open by pressing the Information Menu key (I by default) or by pressing the Small Menu key (Escape by default) and pressing the "Info" button.]])
outfits_log = _([[You can buy and sell outfits for your ship at the Outfitter (Outfits tab while landed). You can also buy regional maps, which can help you explore the galaxy more easily, and licenses which are required for higher-end weapons and ships.

The tabs at the top of the outfitter allow you to filter outfits by type: "W" for weapons, "U" for utilities, "S" for structurals, "Core" for cores, and "Other" for anything outside those categories (most notably, maps and licenses). Different planets have different outfits available; if you don't see a specific outfit you're looking for, you can search for it via the "Find Outfits" button.]])
shipyard_log = _([[You can buy new ships at the Shipyard. You can then either buy a ship you want with the "Buy" button, or trade your current ship in for the new ship with the "Trade-In" button. Different planets have different ships available; if you don't see a specific ship you're looking for, you can search for it via the 'Find Ships' button.

Different ships are specialized for different tasks, so you should choose your ship based on what tasks you will be performing.]])
equipment_log = _([[The Equipment screen is available on all planets which have either an outfitter or a shipyard. You can use the Equipment screen to equip your ship with outfits you own and sell outfits you have no more use for. If the planet or station you're landed at has a shipyard, you can also change which ship you're flying and sell unneeded ships. Selling a ship that still has outfits equipped will also lead to those outfits being sold along with the ship.]])
commodity_log = _([[You can buy and sell commodities via the Commodity screen. Commodity prices vary from planet to planet and even over time, so you can use this screen to attempt to make money by buying low and selling high. Here, it's useful to hold the Shift and/or Ctrl keys to adjust how many tonnes of the commodity you're buying or selling at once.

If you're unsure what's profitable to buy or sell, you can press the Open Star Map key (M by default) to view the star map and then click on the "Mode" button for various price overviews. The news terminal at the Spaceport Bar also includes price information for specific nearby planets.]])
autonav_log = _([[You can open your ship's overlay map by pressing the Overlay Map key (Tab by default). Through the overlay map, you can right-click on any location, planet, ship, or jump point to engage Autonav, which will cause you to automatically fly toward what you clicked on. While Autonav is engaged, passage of time will speed up so that you don't have to wait to arrive at your destination in real-time. Time will reset to normal speed if hostile pilots are detected by default. This can be configured from the Options menu, which you can access by pressing the Menu key (Escape by default).]])
combat_log = _([[You can target an enemy ship either by either clicking on it or by pressing the Target Nearest Hostile key (R by default). You can then fire your weapons at them with the Fire Primary Weapon key (Space by default) and the Fire Secondary Weapon key (Left Shift by default).]])
infoscreen_log = _([[You can configure the way your weapons shoot from the Weapons tab of the Info window, which you can open by pressing the Information Menu key (I by default) or by pressing the Small Menu key (Escape by default) and pressing the "Info" button.]])
cooldown_log = _([[As you fire your weapons, they and subsequently your ship get hotter. Too much heat causes your weapons to lose accuracy. You can cool down your ship at any time in space by pressing the Autobrake key (Ctrl+B by default) twice. You can also cool down your ship by landing on any planet or station.]])
jumping_log = _([[Traveling through systems is accomplished through jump points, which you usually need to find by exploring the area, talking to locals, or buying maps. Once you have found a jump point, you can use it by double-clicking on it.]])
jumping_log2 = _([[You can open your starmap by pressing the Open Star Map key (M by default). Through your starmap, you can click on a system and click on the Autonav button to be automatically transported to the system. This only works if you know a valid route to get there.]])
fuel_log = _([[You consume fuel any time you make a jump and can refuel by landing on a friendly planet. Standard engines have enough fuel to make up to three jumps before refueling, though higher-end engines have more fuel capacity and some ships may have their own supplementary fuel tanks.]])

misn_title = _("Tutorial")
misn_desc = _("Ian Structure has offered to teach you how to fly your ship.")
misn_reward = _("None")

log_text = _([[Ian Structure, the Melendez employee who sold you your first ship, gave you a tutorial on how to pilot it, claiming afterwards that you are "a natural-born pilot".]])


function create ()
   missys = system.get("Hakoi")
   jumpsys = system.get("Eneguoz")
   destsys = system.get("Gamma Polaris")
   start_planet = planet.get("Em 1")
   start_planet_r = 200
   dest_planet = planet.get("Em 5")
   dest_planet_r = 200

   if not misn.claim(missys) then
      print(string.format(
               _("Warning: 'Tutorial' mission was unable to claim system %s!"),
               missys:name()))
      misn.finish(false)
   end

   misn.setTitle(misn_title)
   misn.setDesc(misn_desc)
   misn.setReward(misn_reward)

   accept()
end


function accept ()
   misn.accept()

   -- Add all tutorial logs at the start; this avoids missing logs if
   -- the tutorial is aborted early on.
   addTutLog(movement_log)
   addTutLog(objectives_log)
   addTutLog(landing_log)
   addTutLog(land_log)
   addTutLog(bar_log)
   addTutLog(mission_log)
   addTutLog(outfits_log)
   addTutLog(shipyard_log)
   addTutLog(equipment_log)
   addTutLog(commodity_log)
   addTutLog(autonav_log)
   addTutLog(combat_log)
   addTutLog(infoscreen_log)
   addTutLog(cooldown_log)
   addTutLog(jumping_log)
   addTutLog(jumping_log2)
   addTutLog(fuel_log)

   if tk.yesno("", fmt.f(intro_text,
            {player=player.name(), shipname=player.pilot():name()})) then
      timer_hook = hook.timer(5, "timer")
      hook.land("land")
      hook.takeoff("takeoff")
      hook.enter("enter")
      hook.input("input")

      stage = 1
      create_osd()

      tk.msg("", fmt.f(movement_text,
            {leftkey=tutGetKey("left"), rightkey=tutGetKey("right"),
               accelkey=tutGetKey("accel"), reversekey=tutGetKey("reverse"),
               planet=start_planet:name()}))
   else
      tk.msg("", fmt.f(nothanks_text,
            {infokey=tutGetKey("info"), menukey=tutGetKey("menu")}))
      misn.finish(true)
   end
end


function create_osd()
   local osd_desc = {
      fmt.f(_("Fly to {planet} ({system} system) with the movement keys ({accelkey}, {leftkey}, {reversekey}, {rightkey})"),
         {planet=start_planet:name(), system=missys:name(),
            accelkey=naev.keyGet("accel"), leftkey=naev.keyGet("left"),
            reversekey=naev.keyGet("reverse"), rightkey=naev.keyGet("right")}),
      fmt.f(_("Land on {planet} ({system} system) by double-clicking on it"),
         {planet=start_planet:name(), system=missys:name()}),
      _("Explore the planet as much as you want, then take off by clicking the \"Take Off\" button"),
      fmt.f(_("Press {overlaykey} to open your overlay map"),
         {overlaykey=naev.keyGet("overlay")}),
      fmt.f(_("Autonav to {planet} ({system} system) by right-clicking its icon on the overlay map"),
         {planet=dest_planet:name(), system=missys:name()}),
      fmt.f(_("Press {target_hostile_key} to target the practice drone"),
         {target_hostile_key=naev.keyGet("target_hostile")}),
      fmt.f(_("Face the practice drone using the movement controls, then use {primarykey} and {secondarykey} to fire your weapons and destroy it"),
         {primarykey=naev.keyGet("primary"),
            secondarykey=naev.keyGet("secondary")}),
      fmt.f(_("Engage Active Cooldown by pressing {autobrake_key} twice, then wait for your ship to fully cool down"),
         {autobrake_key=naev.keyGet("autobrake")}),
      fmt.f(_("Press {starmapkey} to open your starmap"),
         {starmapkey=naev.keyGet("starmap")}),
      fmt.f(_("Select {system} (marked on your starmap) by clicking on it in your starmap, then click \"Autonav\" and wait for autonav to fly you there"),
         {system=jumpsys:name()}),
      fmt.f(_("Make use of what you've learned to fly to {system} (marked on your starmap)"),
         {system=destsys:name()}),
   }

   misn.osdCreate(_("Tutorial"), osd_desc)
   misn.osdActive(stage)
end


function timer ()
   hook.rm(timer_hook)
   timer_hook = hook.timer(1, "timer")

   -- Recreate OSD in case key binds have changed.
   create_osd()

   if stage == 1 then
      if system.cur() == missys
            and player.pos():dist(start_planet:pos()) <= start_planet_r then
         stage = 2
         create_osd()

         tk.msg("", fmt.f(objectives_text,
               {mouseflykey=tutGetKey("mousefly"),
                  accelkey=tutGetKey("accel")}))
         tk.msg("", fmt.f(landing_text,
               {planet=start_planet:name(),
                  target_planet_key=tutGetKey("target_planet"),
                  landkey=tutGetKey("land")}))
      end
   elseif stage == 5 then
      if system.cur() == missys
            and player.pos():dist(dest_planet:pos()) <= dest_planet_r then
         stage = 6
         create_osd()
         tk.msg("", fmt.f(target_text,
               {planet=dest_planet:name(),
                  target_hostile_key=tutGetKey("target_hostile")}))
         spawn_drone()
      end
   elseif stage == 8 then
      if player.pilot():temp() <= 250 then
         player.allowLand(true)
         player.pilot():setNoJump(false)
         stage = 9
         create_osd()
         marker = misn.markerAdd(jumpsys, "high")
         tk.msg("", fmt.f(jumping_text, {starmapkey=tutGetKey("starmap")}))
      end
   end
end


function land ()
   hook.rm(timer_hook)
   if stage == 2 then
      stage = 3
      create_osd()
      tk.msg("", land_text)

      bar_hook = hook.land("land_bar", "bar")
      mission_hook = hook.land("land_mission", "mission")
      outfits_hook = hook.land("land_outfits", "outfits")
      shipyard_hook = hook.land("land_shipyard", "shipyard")
      equipment_hook = hook.land("land_equipment", "equipment")
      commodity_hook = hook.land("land_commodity", "commodity")
   end
end


function land_bar ()
   hook.rm(bar_hook)
   tk.msg("", bar_text)
end


function land_mission ()
   hook.rm(mission_hook)
   tk.msg("", fmt.f(mission_text, {infokey=tutGetKey("info")}))
end


function land_outfits ()
   hook.rm(outfits_hook)
   tk.msg("", outfits_text)
end


function land_shipyard ()
   hook.rm(shipyard_hook)
   tk.msg("", shipyard_text)
end


function land_equipment ()
   hook.rm(equipment_hook)
   tk.msg("", equipment_text)
end


function land_commodity ()
   hook.rm(commodity_hook)
   tk.msg("", commodity_text)
end


function takeoff ()
   hook.rm(bar_hook)
   hook.rm(mission_hook)
   hook.rm(outfits_hook)
   hook.rm(shipyard_hook)
   hook.rm(equipment_hook)
   hook.rm(commodity_hook)
end


function enter ()
   hook.rm(timer_hook)
   timer_hook = hook.timer(5, "timer")
   hook.timer(2, "enter_timer")
end


function enter_timer ()
   if stage == 3 then
      stage = 4
      create_osd()
      tk.msg("", fmt.f(overlay_text,
            {player=player.name(), overlaykey=tutGetKey("overlay")}))
   elseif (stage == 6 or stage == 7) and system.cur() == missys then
      stage = 6
      create_osd()
      spawn_drone()
   elseif stage == 10 and system.cur() == jumpsys then
      stage = 11
      create_osd()
      misn.markerMove(marker, destsys)
      tk.msg("", fmt.f(fuel_text, {system=destsys:name()}))
   elseif stage == 11 and system.cur() == destsys then
      addMiscLog(log_text)

      if tk.yesno("", fmt.f(ask_continue_text,
               {system=destsys:name(), player=player.name()})) then
         var.push("_tutorial_passive_active", true)
         tk.msg("", fmt.f(continue_yes_text,
               {infokey=tutGetKey("info"), menukey=tutGetKey("menu")}))
      else
         tk.msg("", fmt.f(continue_no_text,
               {infokey=tutGetKey("info"), menukey=tutGetKey("menu")}))
      end

      misn.finish(true)
   end
end


function input(inputname, inputpress, arg)
   if not inputpress then
      return
   end

   if stage == 4 and inputname == "overlay" then
      stage = 5
      create_osd()
      hook.safe("safe_overlay")
   elseif stage == 6 and inputname == "target_hostile" then
      stage = 7
      create_osd()
      if not combat_text_shown then
         combat_text_shown = true
         hook.safe("safe_combat")
      end
   elseif stage == 9 and inputname == "starmap" then
      stage = 10
      create_osd()
      hook.safe("safe_starmap")
   end
end


function safe_overlay()
   tk.msg("", fmt.f(autonav_text, {planet=dest_planet:name()}))
end


function safe_combat()
   tk.msg("", fmt.f(combat_text,
         {primarykey=tutGetKey("primary"),
            secondarykey=tutGetKey("secondary")}))
end


function safe_starmap()
   tk.msg("", fmt.f(starmap_text, {system=jumpsys:name()}))
end


function pilot_death ()
   player.allowLand(false)
   player.pilot():setNoJump(true)
   hook.timer(2, "pilot_death_timer")
end


function pilot_death_timer ()
   stage = 8
   create_osd()
   tk.msg("", fmt.f(infoscreen_text,
         {infokey=tutGetKey("info"), menukey=tutGetKey("menu")}))
   tk.msg("", fmt.f(cooldown_text, {autobrake_key=tutGetKey("autobrake")}))
end


function spawn_drone()
   local f = faction.dynAdd(
         nil, N_("Melendez"), N_("Melendez Corporation"), {ai="baddie_norun"})
   local p = pilot.add("Hyena", f, dest_planet, _("Practice Drone"),
         {naked=true})

   p:outfitAdd("Previous Generation Small Systems")
   p:outfitAdd("Unicorp D-2 Light Plating")
   p:outfitAdd("Beat Up Small Engine")

   p:setHealth(100, 100)
   p:setEnergy(100)
   p:setTemp(0)
   p:setFuel(true)

   p:setHostile()
   p:setVisplayer()
   p:setHilight()
   hook.pilot(p, "death", "pilot_death")
end


function abort()
   if system.cur() == missys then
      player.allowLand(true)
      player.pilot():setNoJump(false)
   end
   misn.finish(false)
end
