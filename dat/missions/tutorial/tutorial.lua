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

require "events/tutorial/tutorial_common"
require "missions/neutral/common"


a_commodity = commodity.get( "Water" )
an_outfit = outfit.get( "Heavy Laser Turret" )

intro_text  = _([["Congratulations on your first space ship, %s!" Captain T. Practice, who sold the %s to you, says through the radio. "You have made an excellent decision to purchase from Melendez Corporation! Our ships are prized for their reliability and affordability. I promise, you won't be disappointed!" You are skeptical of the sales pitch, of course; you really only bought this ship because it was the only one you could afford. Still, you tactfully thank the salesperson.

"Now that we have you out in space for the first time, how about I go over your new ship's controls with you real quick? No charge!"]])

nothanks_text  = _([["Ha, I guess you're eager to start, eh? Well, I won't hold you back. Just remember that you can review all of your ship's controls in the Options menu. Good luck!" And with that, you set off on your journey.]])

movement_text = _([["Alright, let's go over how to pilot your new state-of-the-art ship from Melendez Corporation, then!" You resist the urge to roll your eyes. "Moving is pretty simple: rotate your ship with %s and %s, and thrust to move your ship forward with %s! You can also use %s to rotate your ship to the direction opposite of your current movement, or to reverse thrust if you purchase and install a Reverse Thruster onto your Melendez Corporation starship. Give it a try by flying over to %s! You see it on your screen, right? It's the planet right next to you."]])
movement_log = _([[Basic movement can be accomplished by the movement keys (Accelerate, Turn Left, Turn Right, and Reverse; W, A, D, and S by default), which allow you to control your ship manually; or by the Mouse Flight key (Ctrl+X by default), which automatically pilots your ship toward your mouse pointer. The Reverse key either turns your ship to the direction opposite of your current movement, or thrusts backwards if you have a Reverse Thruster equipped.]])

objectives_text = _([["Perfect! That was easy enough, right? We at Melendez Corporation recommend this manner of flight, which we call 'keyboard flight'. However, there is one other way you can fly if you so choose: press %s on your console and your Melendez Corporation ship will follow your #bmouse pointer#0 automatically! It's up to you which method you prefer to use.

"Ah, you may also have noticed the mission on-screen display on your monitor! As you can see, you completed your first objective of the Tutorial mission, so the next objective is now being highlighted."]])
objectives_log = _([[The mission on-screen display highlights your current objective for each mission. When you complete one objective, the next objective is highlighted.]])

landing_text = _([["On that note, let's go over landing! All kinds of actions, like landing on planets, hailing ships, boarding disabled ships, and jumping to other systems can be accomplished by #bdouble-clicking#0 on an applicable target, or alternatively by pressing certain buttons on your control console. How about you try landing on %s? You can engage the automatic landing procedure either by #bdouble-clicking#0 on the planet or its radar icon, or by targeting the planet with %s and then pressing %s. Give it a try!"]])
landing_log = _([[You can land on any planet by either double-clicking on it, or by targeting the planet with the Target Planet button and then pressing the Land button. The landing procedure is automatic.]])

land_text = _([["Excellent! The landing was successful. Melendez Corporation uses advanced artificial intelligence technology so that you never have to worry about your ship crashing. It may seem like a small thing, but it wasn't long ago when pilots had to land manually and crashes were commonplace! We at Melendez Corporation pride ourselves in protecting the safety of our valued customers and ensuring that your ship is reliable and resilient.

"When you land, your ship is refueled automatically and you can do things such as talk to civilians at the bar, buy new ship components, configure your ship, and most importantly, accept missions from the Mission Computer. Why don't we look around? As you can see, we are currently on the Landing Main tab, where you can learn about the planet and buy a local map. Click all the other tabs below and I'll give you a tour through what else you can do on a planet. When you are done, click the 'Take Off' button so we can continue."]])
land_log = _([[When you land, your ship is refueled automatically if the planet or station supports refueling.]])

bar_text = _([["This is the Spaceport Bar, where you can read the latest news (as you can see on your right at the moment), but more importantly, you can meet civilians, hire pilots to join your fleet, and sometimes find unique mission opportunities! Click on someone in the bar and then click on the Approach button to approach them. I recommend regularly talking to civilians at the bar, at least early on. There may be pilots among them who may have useful tips for you!"]])
bar_log = _([[The Spaceport Bar allows you to read the news, meet civilians, hire pilots to join your fleet, and sometimes find unique missions. You can click on any patron of the bar and then click on the Approach button to approach them. Some civilians may lend helpful advice.]])

mission_text = _([["This is the Mission Computer, where you can find basic missions in the official mission database. Missions are how you make your living as a pilot, so I recommend you check this screen often to see where the money-making opportunities are! You can see that each mission is given a brief summary, and by clicking them, you will be able to see more information about the mission. Since many missions involve cargo, you can also see how much free space is available in your ship in the top-right.

"When picking missions, pay attention to how much they pay. You'll want to strike a balance of choosing missions that you're capable of doing, but getting paid as much as possible to do them. Once you've chosen a mission, click the 'Accept Mission' button on the bottom-right and it will be added to your active missions, which you can review via the Info window by pressing %s."]])
mission_log = _([[You can find basic missions in the official mission database via the Mission Computer (Missions tab while landed). Each mission is given a brief summary in the list on the left, and you can click on these summaries to see more information about a particular mission. Once you've chosen a mission, you can click the "Accept Mission" button on the bottom-right to add the mission to your active missions. You can review your active missions at any time via the Info window, which you can open by pressing the Information Menu key (I by default) or by pressing the Small Menu key (Escape by default) and pressing the "Info" button.]])

outfits_text = _([["This is the Outfitter, where you can buy new outfits to make your Melendez Corporation starship even better! You can fit your ship with new weapons, extra cargo space, more powerful core systems, and more! Regional maps which can help you explore the galaxy more easily can also be purchased here, as well as licenses required for higher-end weaponry and starships (for example, you will require a Large Civilian Vessel License to purchase our top-of-the-line Melendez Mule Bulk Cargo Starship, widely sought after for its unmatched cargo capacity).

"As you can see, a series of tabs at the top of your screen allow you to filter outfits by type: 'W' for weapons, 'U' for utilities, 'S' for structurals, 'Core' for cores, and 'Other' for anything outside of those categories (most notably, regional maps and licenses). When you see an outfit that interests you, click on it to see more information about it, then either click on the 'Buy' button to buy it or click on the 'Sell' button to sell it (if you have one in your possession). Different planets have different outfits available; if you don't see a specific outfit you're looking for, you can search for it via the 'Find Outfits' button."]])
outfits_log = _([[You can buy and sell outfits for your ship at the Outfitter (Outfits tab while landed). You can also buy regional maps, which can help you explore the galaxy more easily, and licenses which are required for higher-end weapons and ships.

The tabs at the top of the outfitter allow you to filter outfits by type: "W" for weapons, "U" for utilities, "S" for structurals, "Core" for cores, and "Other" for anything outside those categories (most notably, maps and licenses). You can click on any outfit listed to see more information about it, then either click on the "Buy" button to buy it or click on the "Sell" button to sell it (if you currently have one). Different planets have different outfits available; if you don't see a specific outfit you're looking for, you can search for it via the "Find Outfits" button.]])

shipyard_text = _([["This is the Shipyard, where you can buy new starships to either replace the one you've got, or to add to your collection! On the left of this screen, you will see ships available on the planet you're currently on. Click on a ship you're interested in learning more about. You can then either buy the ship with the 'Buy' button, or trade your current ship in for the new ship with the 'Trade-In' button. Different planets have different ships available; if you don't see a specific ship you're looking for, you can search for it via the 'Find Ships' button.

"You have no need for this screen right now, but later on, when you've saved up enough, you'll likely want to upgrade your ship to an even better one, depending on what kinds of tasks you will be performing. Melendez Corporation specializes primarily in cargo ships. I highly recommend either our Melendez Quicksilver Rush Cargo Starship for cargo missions that have a time limit, or our Melendez Koala Compact Bulk Cargo Starship for missions that require carrying large amounts of cargo. We sincerely thank you for shopping with Melendez Corporation!"]])
shipyard_log = _([[You can buy new ships at the Shipyard. Ships available on the planet you're currently on are listed on the left; click on a ship to learn more about it. You can then either buy the ship with the "Buy" button, or trade your current ship in for the new ship with the "Trade-In" button. Different planets have different ships available; if you don't see a specific ship you're looking for, you can search for it via the 'Find Ships' button.

Different ships are specialized for different tasks, so you should choose your ship based on what tasks you will be performing.]])

equipment_text = _([["This is the Equipment screen, which is available only on planets which have either an outfitter or a shipyard. Here, you can equip your ship with any outfits you have bought at the Outfitter. If and only if the current planet has a shipyard, you can also do so with any other ship you own, and you can swap which ship you are currently piloting by selecting another ship and clicking the 'Swap Ship' button. You can also sell those other ships (but not your current ship) with the 'Sell Ship' button, if you decide that you no longer need them. Selling a ship that still has outfits equipped will also lead to those outfits being sold along with the ship, so do keep that in mind if there's an outfit you need to keep.

"If you make any changes to your ship now, please ensure that you still have two weapons equipped, as you will need those later for practicing combat and flying around space without any weapons can be very risky anyway."]])
equipment_log = _([[The Equipment screen is available only on planets which have either an outfitter or a shipyard. You can use the Equipment screen to equip your ship with any outfits you have bought at the Outfitter. If and only if the current planet has a shipyard, you can also do so with any other ship you own, and you can swap which ship you are currently piloting by selecting another ship and clicking the "Swap Ship" button. You can also sell those other ships (but not your current ship) with the "Sell Ship" button, if you decide that you no longer need them. Selling a ship that still has outfits equipped will also lead to those outfits being sold along with the ship.]])

commodity_text = _([["This is the Commodity screen, where you can buy and sell commodities. Commodity prices vary from planet to planet and even over time, so you can use this screen to attempt to make money by buying low and selling high. Click on a commodity to see information about it, most notably its average price per tonne, and click on the 'Buy' and 'Sell' buttons to buy or sell some of the commodity, respectively. Here, it's useful to hold the Shift and/or Ctrl keys to adjust the modifier of how many tonnes of the commodity you're buying or selling at once. This will reduce the number of times you have to click on the Buy and Sell buttons.

"If you're unsure what's profitable to buy or sell, you can press %s to view the star map and then click on the 'Mode' button for various price overviews. The news terminal at the bar also includes price information for specific nearby planets."]])
commodity_log = _([[You can buy and sell commodities via the Commodity screen. Commodity prices vary from planet to planet and even over time, so you can use this screen to attempt to make money by buying low and selling high. Click on a commodity to see information about it, most notably its average price per tonne, and click on the "Buy" and "Sell" buttons to buy or sell some of the commodity, respectively. Here, it's useful to hold the Shift and/or Ctrl keys to adjust the modifier of how many tonnes of the commodity you're buying or selling at once. This will reduce the number of times you have to click on the Buy and Sell buttons.

If you're unsure what's profitable to buy or sell, you can press the Star Map key (M by default) to view the star map and then click on the "Mode" button for various price overviews. The news terminal at the Spaceport Bar also includes price information for specific nearby planets.]])

autonav_text = _([["Welcome back to space, %s! Let's continue discussing moving around in space. As mentioned before, you can move around space manually, no problem. However, you will often want to travel large distances, and navigating everywhere manually could be a bit tedious. That is why we at Melendez Corporation always require the latest Autonav technology with all of our ships!

"Autonav is simple and elegant. Simply press %s to open your ship's overlay map, then simply #bright-click#0 on any location, planet, ship, or jump point to instantly take your ship right to it! The trip will take just as long, but advanced Melendez Corporation technology allows you to step away from your controls, making it seem as though time is passing at a faster rate. And don't worry; if any hostile pilots are detected, our Autonav system automatically alerts you so that you can observe the situation and respond in whatever fashion is deemed necessary. This can be configured from the Options menu, which you can access by pressing %s.

"Why don't you try using Autonav to fly over to %s? You should be able to see it on your overlay map."]])
autonav_log = _([[You can open your ship's overlay map by pressing the Overlay Map key (Tab by default). Through the overlay map, you can right-click on any location, planet, ship, or jump point to engage Autonav, which will cause you to automatically fly toward what you clicked on. While Autonav is engaged, passage of time will speed up so that you don't have to wait to arrive at your destination in real-time. Time will reset to normal speed if hostile pilots are detected by default. This can be configured from the Options menu, which you can access by pressing the Menu key (Escape by default).]])

combat_text = _([["Great job! As you can see, by using Autonav, the perceived duration of your trip was cut substantially. You will grow to appreciate this feature in your Melendez Corporation ship in time, especially as you travel from system to system delivering goods and such.

"Let's now practice combat. You won't need this if you stick to the safe systems in the Empire core, but sadly, you are likely to encounter pirate scum if you venture further out, so you need to know how to defend yourself. Fortunately, your ship comes pre-equipped with state-of-the-art laser cannons for just that reason!

"I will launch a combat practice drone off of %s now for you to fight. Don't worry; our drone does not have any weapons and will not harm you. Target the drone by clicking on it or by pressing %s, then use your weapons, controlled with %s and %s, to take out the drone!

"Ah, yes, one more tip before I launch the drone: if your weapons start losing their accuracy, it's because they're becoming overheated. You can remedy that by pressing %s twice to engage active cooling."]])
combat_log = _([[You can target an enemy ship either by either clicking on it or by pressing the Target Nearest Hostile key (R by default). You can then fire your weapons at them with the Fire Primary Weapon key (Space by default) and the Fire Secondary Weapon key (Left Shift by default).]])

infoscreen_text =_([["Excellent work taking out that drone! As you may have noticed, shield regenerates over time, but armor does not. This is not universal, of course; some ships, particularly larger ships, feature advanced armor repair technology. But even then, armor regeneration is usually much slower than shield regeneration.

"It is also worth noting that you can configure the way your weapons shoot from the Weapons tab of the Info window, which can be accessed by pressing %s or by pressing %s and then clicking on the Info button. The Info window also lets you view information about your ship, cargo, current missions, and reputation with the various factions. You will likely be referencing it a lot."]])
infoscreen_log = _([[You can configure the way your weapons shoot from the Weapons tab of the Info window, which you can open by pressing the Information Menu key (I by default) or by pressing the Small Menu key (Escape by default) and pressing the "Info" button.]])

cooldown_text = _([["You may have also noticed your heat meters going up and your weapons becoming less accurate as your ship and weapons got hot. This is normal, but too much heat can make your weapons difficult to use, which is why we at Melendez Corporation recommend using active cooling when it is safe to do so. Let's practice using it. Engage active cooldown and wait for it to cool your ship down completely. As I said before, you can engage active cooling by pressing %s twice."]])
cooldown_log = _([[As you fire your weapons, they and subsequently your ship get hotter. Too much heat causes your weapons to lose accuracy. You can cool down your ship at any time in space by pressing the Autobrake key (Ctrl+B by default) twice. You can also cool down your ship by landing on any planet or station.]])

jumping_text = _([["Good job! Your ship is now fully cooled off. In addition to using Active Cooldown, you can also cool off by landing on any planet or station.

"I think we should try venturing outside of this system! There are many systems in the universe; this one is but a tiny sliver of what can be found out there!

"Traveling through systems is accomplished through jump points. Like planets, you usually need to find these by exploring the area, talking to the locals, or buying maps. Once you have found a jump point, you can use it by #bdouble-clicking#0 on it.

"But there is yet a better way to navigate across systems! By pressing %s, you can open your starmap. The starmap shows you all of the systems you currently know about. Through your starmap, you can click on a system and click on the Autonav button to be automatically transported to the system! Of course, this only works if you know a valid route to get there, but you will find that this method of travel greatly simplifies things.

"Why don't you give it a try and jump to the nearby %s system? You should see an indicator blip on your map; missions often use these blips to show you where to go next. You will have to make two jumps and may have to do some exploration to find the second jump point. Let's see what you've learned!"]])
jumping_log = _([[Traveling through systems is accomplished through jump points, which you usually need to find by exploring the area, talking to locals, or buying maps. Once you have found a jump point, you can use it by double-clicking on it.]])
jumping_log2 = _([[You can open your starmap by pressing the Star Map key (M by default). Through your starmap, you can click on a system and click on the Autonav button to be automatically transported to the system. This only works if you know a valid route to get there.]])

fuel_text = _([["You have done very well, %s! As you can see, the trip consumed fuel. You consume fuel any time you make a jump and can refuel by landing on a friendly planet. Standard engines have enough fuel to make up to three jumps before refueling, though higher-end engines have more fuel capacity and some ships may have their own supplementary fuel tanks. Try to plan your routes so that you don't end up in a system where you can't land without fuel.

"If you do get stuck without fuel in such a system, you can try to ask other pilots if they have fuel to spare by #bdouble-clicking#0 on them, or by selecting them with %s and then pressing %s. However, waiting for other pilots to refuel you puts you at risk of being attacked by pirates, so I recommend avoiding that situation if you can.

"Ah, that reminds me: you can also attempt to bribe hostile ships, such as pirates, by hailing them. Bribes work better on some factions than on others; pirates will happily take your offer and may even sell you fuel afterwards, but other factions may be less forthcoming."]])
fuel_log = _([[You consume fuel any time you make a jump and can refuel by landing on a friendly planet. Standard engines have enough fuel to make up to three jumps before refueling, though higher-end engines have more fuel capacity and some ships may have their own supplementary fuel tanks.]])
fuel_log2 = _([[If you get stuck without fuel in a system where you can't land, you can try to ask other pilots if they have fuel to spare by double-clicking them, or by selecting them with the Target Nearest key (T by default) and then pressing the Hail Target key (Y by default). You can also hail hostile ships to attempt to bribe them. Bribes generally work on pirates, but may be less effective against other factions.]])

ask_continue_text = _([["That's all the basics! I must say, you are a natural-born pilot and your new Melendez ship suits you well! That said, there are other aspects of piloting I wasn't able to get into here. If you like, I can continue to give you guidance, free of charge! I promise to be unobtrusive; I'll just pop in and let you know about some other things when they become relevant. What do you say?"]])

continue_yes_text = _([["Splendid! I'll leave you to your travels and keep an eye out. If you miss or forget anything, check the Tutorial section of your ship log; it can be found in the Info window, which you can access by pressing %s. Best of luck!"]])

continue_no_text = _([["Ah, ok! In that case, I wish you good luck in your travels. You can review all the information we've gone through by checking the Tutorial section of your ship log; it can be found in the Info window, which you can access by pressing %s. Thank you for shopping with Melendez Corporation!" Captain T. Practice ceases contact and you let out a sigh of relief. You had no idea the level of annoyance you were getting into. At least you learned how to pilot the ship, though!]])

misn_title = _("Tutorial")
misn_desc = _("Captain T. Practice has offered to teach you how to fly your ship.")
misn_reward = _("None")

osd_title = _("Tutorial")
osd_desc = {}
osd_desc[1] = _("Fly to %s in the %s system with the movement keys (%s, %s, %s, %s)")
osd_desc[2] = _("Land on %s in the %s system by double-clicking on it")
osd_desc[3] = _("Open the overlay map with %s and go to %s in the %s system by right-clicking its icon on the overlay map")
osd_desc[4] = _("Destroy the practice drone near %s in the %s system by using %s and %s to fire your weapons")
osd_desc[5] = _("Engage Active Cooldown by pressing %s twice, then wait for your ship to fully cool down")
osd_desc[6] = _("Open your starmap with %s and jump to the %s system using its Autonav feature")
osd_desc["__save"] = true

log_text = _([[Captain T. Practice, the Melendez employee who sold you your first ship, gave you a tutorial on how to pilot it, claiming afterwards that you are "a natural-born pilot".]])


function create ()
   missys = system.get( "Hakoi" )
   destsys = system.get( "Qex" )
   start_planet = planet.get( "Em 1" )
   start_planet_r = 200
   dest_planet = planet.get( "Em 5" )
   dest_planet_r = 200

   if not misn.claim( missys ) then
      print( string.format(_( "Warning: 'Tutorial' mission was unable to claim system %s!"), missys:name() ) )
      misn.finish( false )
   end

   misn.setTitle( misn_title )
   misn.setDesc( misn_desc )
   misn.setReward( misn_reward )

   accept()
end


function accept ()
   misn.accept()

   if tk.yesno( "", intro_text:format(
            player.name(), player.pilot():name() ) ) then
      timer_hook = hook.timer( 5000, "timer" )
      hook.land("land")
      hook.takeoff("takeoff")
      hook.enter("enter")
      
      osd_desc[1] = osd_desc[1]:format(
            start_planet:name(), missys:name(), naev.keyGet("accel"),
            naev.keyGet("left"), naev.keyGet("reverse"), naev.keyGet("right"))
      osd_desc[2] = osd_desc[2]:format(start_planet:name(), missys:name())
      osd_desc[3] = osd_desc[3]:format(
            naev.keyGet("overlay"), dest_planet:name(), missys:name())
      osd_desc[4] = osd_desc[4]:format(
            dest_planet:name(), missys:name(), naev.keyGet("primary"),
            naev.keyGet("secondary"))
      osd_desc[5] = osd_desc[5]:format(naev.keyGet("autobrake"))
      osd_desc[6] = osd_desc[6]:format(naev.keyGet("starmap"), destsys:name())
      misn.osdCreate(osd_title, osd_desc)

      stage = 1

      tk.msg("", movement_text:format(
               tutGetKey("left"), tutGetKey("right"), tutGetKey("accel"),
               tutGetKey("reverse"), start_planet:name()))
      addTutLog(movement_log, N_("Navigation"))
   else
      tk.msg("", nothanks_text)
      misn.finish(true)
   end
end


function timer ()
   if timer_hook ~= nil then hook.rm(timer_hook) end
   timer_hook = hook.timer(1000, "timer")

   if stage == 1 then
      if system.cur() == missys
            and player.pos():dist(start_planet:pos()) <= start_planet_r then
         stage = 2
         misn.osdActive(2)

         tk.msg("", objectives_text:format(tutGetKey("mousefly")))
         addTutLog(objectives_log, N_("Missions"))
         tk.msg("", landing_text:format(
                  start_planet:name(), tutGetKey("target_planet"),
                  tutGetKey("land")))
         addTutLog(landing_log, N_("Navigation"))
      end
   elseif stage == 4 then
      if system.cur() == missys
            and player.pos():dist(dest_planet:pos()) <= dest_planet_r then
         stage = 5
         misn.osdActive(4)
         tk.msg("", combat_text:format(
                  dest_planet:name(), tutGetKey("target_hostile"),
                  tutGetKey("primary"), tutGetKey("secondary"),
                  tutGetKey("autobrake")))
         addTutLog(combat_log, N_("Combat"))
         spawn_drone()
      end
   elseif stage == 6 then
      if player.pilot():temp() <= 250 then
         stage = 7
         misn.osdActive(6)
         tk.msg("", jumping_text:format(tutGetKey("starmap"), destsys:name()))
         addTutLog(jumping_log, N_("Navigation"))
         addTutLog(jumping_log2, N_("Navigation"))
      end
   end
end


function land ()
   if timer_hook ~= nil then hook.rm(timer_hook) end
   if stage == 2 then
      stage = 3
      tk.msg("", land_text)
      addTutLog(land_log, N_("Planets and Stations"))
      bar_hook = hook.land("land_bar", "bar")
      mission_hook = hook.land("land_mission", "mission")
      outfits_hook = hook.land("land_outfits", "outfits")
      shipyard_hook = hook.land("land_shipyard", "shipyard")
      equipment_hook = hook.land("land_equipment", "equipment")
      commodity_hook = hook.land("land_commodity", "commodity")
   end
end


function land_bar ()
   if bar_hook ~= nil then hook.rm(bar_hook) end
   tk.msg("", bar_text)
   addTutLog(bar_log, N_("Planets and Stations"))
end


function land_mission ()
   if mission_hook ~= nil then hook.rm(mission_hook) end
   tk.msg("", mission_text:format(tutGetKey("info")))
   addTutLog(mission_log, N_("Missions"))
end


function land_outfits ()
   if outfits_hook ~= nil then hook.rm(outfits_hook) end
   tk.msg("", outfits_text)
   addTutLog(outfits_log, N_("Ship Upgrades"))
end


function land_shipyard ()
   if shipyard_hook ~= nil then hook.rm(shipyard_hook) end
   tk.msg("", shipyard_text)
   addTutLog(shipyard_log, N_("Ship Upgrades"))
end


function land_equipment ()
   if equipment_hook ~= nil then hook.rm(equipment_hook) end
   tk.msg("", equipment_text)
   addTutLog(equipment_log, N_("Ship Upgrades"))
end


function land_commodity ()
   if commodity_hook ~= nil then hook.rm(commodity_hook) end
   tk.msg("", commodity_text:format(tutGetKey("starmap")))
   addTutLog(commodity_log, N_("Commodity Trading"))
end


function takeoff ()
   if bar_hook ~= nil then hook.rm(bar_hook) end
   if mission_hook ~= nil then hook.rm(mission_hook) end
   if outfits_hook ~= nil then hook.rm(outfits_hook) end
   if shipyard_hook ~= nil then hook.rm(shipyard_hook) end
   if equipment_hook ~= nil then hook.rm(equipment_hook) end
   if commodity_hook ~= nil then hook.rm(commodity_hook) end
end


function enter ()
   if timer_hook ~= nil then hook.rm( timer_hook ) end
   timer_hook = hook.timer( 5000, "timer" )
   hook.timer( 2000, "enter_timer" )
end


function enter_timer ()
   if stage == 3 then
      stage = 4
      misn.osdActive( 3 )
      tk.msg("", autonav_text:format(player.name(), tutGetKey("overlay"),
               tutGetKey("menu"), dest_planet:name()))
      addTutLog(autonav_log, N_("Navigation"))
   elseif stage == 5 and system.cur() == missys then
      spawn_drone()
   elseif stage == 7 and system.cur() == destsys then
      tk.msg("", fuel_text:format(player.name(), tutGetKey("target_next"),
               tutGetKey("hail")))
      addTutLog(fuel_log, N_("Fuel"))
      addTutLog(fuel_log2, N_("Fuel"))

      addMiscLog(log_text)

      if tk.yesno("", ask_continue_text) then
         var.push("_tutorial_passive_active", true)
         tk.msg("", continue_yes_text:format(tutGetKey("info")))
      else
         tk.msg("", continue_no_text:format(tutGetKey("info")))
      end

      misn.finish(true)
   end
end


function pilot_death ()
   hook.timer(2000, "pilot_death_timer")
end


function pilot_death_timer ()
   stage = 6
   misn.osdActive(5)
   misn.markerAdd(destsys, "high")
   tk.msg("", infoscreen_text:format(tutGetKey("info"), tutGetKey("menu")))
   addTutLog(infoscreen_log, N_("Info Window"))
   tk.msg("", cooldown_text:format(tutGetKey("autobrake")))
   addTutLog(cooldown_log, N_("Active Cooling"))
end


function spawn_drone ()
   local p = pilot.add("Hyena", "Dummy", dest_planet, _("Practice Drone"),
         {ai="baddie_norun"})

   p:rmOutfit("all")
   p:rmOutfit("cores")
   p:addOutfit("Previous Generation Small Systems")
   p:addOutfit("Patchwork Light Plating")
   p:addOutfit("Beat Up Small Engine")

   p:setHealth(100, 100)
   p:setEnergy(100)
   p:setTemp(0)
   p:setFuel(true)

   p:setHostile()
   p:setVisplayer()
   p:setHilight()
   hook.pilot(p, "death", "pilot_death")
end
