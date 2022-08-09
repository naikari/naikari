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

local fmt = require "fmt"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"


intro_text  = _([["Welcome to space, {player}, and congratulations on your purchase!" the salesperson who sold you this ship says through the radio. "I am sure the {shipname} will serve you well! Here at Melendez Corporation, our ships are prized for their reliability and affordability. I promise, you won't be disappointed!" You barely resist the temptation to roll your eyes at the remark; you really only bought this ship because it was the only one you could afford. Still, you tactfully thank the salesperson.]])

movement_text = _([["Now, so that your test flight goes as smoothly as possible, I will explain the controls of your state-of-the art Melendez Corporation starship! There are two basic modes: keyboard flight, and mouse flight.

"To move via keyboard flight, rotate your ship with {leftkey} and {rightkey}, and thrust to move your ship forward with {accelkey}. You can also use {reversekey} to rotate your ship to the direction opposite of your current movement, which can be useful for bringing your vessel to a stop.

"To move via mouse flight, you must first enable it by pressing {mouseflykey}. While mouse flight is enabled, your ship will automatically turn toward your #bmouse pointer#0, like magic! You can then thrust either with {accelkey}, as you would do in keyboard flight, or you can alternatively use the #bmiddle mouse button#0 or either of the #bextra mouse buttons#0.

"Why don't you give both systems a try? Experiment with the flight controls as much as you'd like, then fly over to where {planet} is. You see it on your screen, right? It's the planet right next to you."]])

landing_text = _([["I see you have a great handle on the controls of your new Melendez Corporation ship! It's a perfect fit for you, don't you think? Your control of the vessel is absolutely stunning, magnificent!

"You may continue to practice flying for as long as you need. When you are ready, please return to {planet} to finalize your paperwork. To do so, simply #bdouble-click#0 on the planet, or if you prefer to use your keyboard, target it with {target_planet_key} and then press {landkey}. I will be waiting for you at the spaceport!"]])

land_text = _([[You watch as your ship automatically initiates landing procedures, taking you safely through the atmosphere and into the planet's space port, touching down at an empty spot reserved for you. As your hatch opens and you step out of your ship, an exhausted dock worker greets you and makes you sign a form. Once you've done so, she pushes some buttons and you watch in amazement as robotic drones immediately get to work checking your ship for damage and ensuring your fuel tanks are full. Noticing your expression, the worker lets out a chuckle. "First time landing, eh?" she quips. "It'll all be normal to you before long."

"Ah, there you are, {player}!" the voice of the salesperson interrupts. You look in the direction of the voice and see an obnoxiously dressed person with a huge grin. "I see your Melendez Corporation starship is serving you well. Now, if you would follow me, we can finalize that paperwork."

Several signatures later, you are officially bequeathed ownership of the Llama. The salesperson pats you on the back. "You have made an excellent choice, {player}! I'm sure you'll be making millions of credits in no time! In fact, I know just where to start. A gentleman at the bar is looking for a hired hand, and I assure you, he pays good credits! I've told him about you and he said he would be thrilled to hire you for a job!" After shaking the salesperson's hand one last time, you figure you might as well meet this man the salesperson mentioned and see if the job is worthwhile.]])

movement_log = _([[Basic movement can be accomplished by the movement keys (Accelerate, Turn Left, Turn Right, and Reverse; W, A, D, and S by default). The Reverse key either turns your ship to the direction opposite of your current movement, or thrusts backwards if you have a Reverse Thruster equipped.

Alternatively, you can enable mouse flight by pressing the Mouse Flight key (Ctrl+X by default), which causes your ship to automatically point toward your mouse pointer. You can then thrust with the Accelerate key (W by default), middle mouse button, or either of the extra mouse buttons.]])
objectives_log = _([[The mission on-screen display highlights your current objective for each mission. When you complete one objective, the next objective is highlighted.]])
landing_log = _([[You can land on any planet by either double-clicking on it, or by targeting the planet with the Target Planet button and then pressing the Land key (L by default). The landing procedure is automatic. If no planet is selected, pressing the Land key will initiate the automatic landing procedure for the closest suitable planet if possible.]])
land_log = _([[When you land, your ship is refueled automatically if the planet or station has the "Refuel" service. Most planets and stations have the "Refuel" service, though there are some exceptions.]])
bar_log = _([[The Spaceport Bar allows you to read the news, meet civilians, hire pilots to join your fleet, and sometimes find unique missions. You can click on any patron of the bar and then click on the Approach button to approach them. Some civilians may lend helpful advice.]])
mission_log = _([[You can find basic missions in the official mission database via the Mission Computer (Missions tab while landed). You can review your active missions at any time via the ship computer, which you can open by pressing the Ship Computer key (I by default) or by pressing the Small Menu key (Escape by default) and pressing the "Ship Computer" button.]])
outfits_log = _([[You can buy and sell outfits for your ship at the Outfitter (Outfits tab while landed). You can also buy regional maps, which can help you explore the galaxy more easily, and licenses which are required for higher-end weapons and ships.

The tabs at the top of the outfitter allow you to filter outfits by type: "W" for weapons, "U" for utilities, "S" for structurals, "Core" for cores, and "Other" for anything outside those categories (most notably, maps and licenses). Different planets have different outfits available; if you don't see a specific outfit you're looking for, you can search for it via the "Find Outfits" button.]])
shipyard_log = _([[You can buy new ships at the Shipyard. You can then either buy a ship you want with the "Buy" button, or trade your current ship in for the new ship with the "Trade-In" button. Different planets have different ships available; if you don't see a specific ship you're looking for, you can search for it via the 'Find Ships' button.

Different ships are specialized for different tasks, so you should choose your ship based on what tasks you will be performing.]])
equipment_log = _([[The Equipment screen is available on all planets which have either an outfitter or a shipyard. You can use the Equipment screen to equip your ship with outfits you own and sell outfits you have no more use for. If the planet or station you're landed at has a shipyard, you can also change which ship you're flying and sell unneeded ships. Selling a ship that still has outfits equipped will also lead to those outfits being sold along with the ship.]])
commodity_log = _([[You can buy and sell commodities via the Commodity screen. Commodity prices vary from planet to planet and even over time, so you can use this screen to attempt to make money by buying low and selling high. Here, it's useful to hold the Shift and/or Ctrl keys to adjust how many tonnes of the commodity you're buying or selling at once.

If you're unsure what's profitable to buy or sell, you can press the Open Star Map key (M by default) to view the star map and then click on the "Mode" button for various price overviews. The news terminal at the Spaceport Bar also includes price information for specific nearby planets.]])
autonav_log = _([[You can open your ship's overlay map by pressing the Overlay Map key (Tab by default). Through the overlay map, you can right-click on any location, planet, ship, or jump point to engage Autonav, which will cause you to automatically fly toward what you clicked on. While Autonav is engaged, passage of time will speed up so that you don't have to wait to arrive at your destination in real-time. Time will reset to normal speed if hostile pilots are detected by default. This can be configured from the Options menu, which you can access by pressing the Menu key (Escape by default).]])
combat_log = _([[You can target an enemy ship either by either clicking on it or by pressing the Target Nearest Hostile key (R by default). You can then fire your weapons at them with the Fire Primary Weapon key (Space by default) and the Fire Secondary Weapon key (Left Shift by default).]])
infoscreen_log = _([[You can configure the way your weapons shoot from the Weapons tab of the ship computer, which you can open by pressing the Ship Computer key (I by default) or by pressing the Small Menu key (Escape by default) and pressing the "Ship Computer" button.]])
cooldown_log = _([[As you fire your weapons, they and subsequently your ship get hotter. Too much heat causes your weapons to lose accuracy. You can cool down your ship at any time in space by pressing the Autobrake key (Ctrl+B by default) twice. You can also cool down your ship by landing on any planet or station.]])
jumping_log = _([[Traveling through systems is accomplished through jump points, which you usually need to find by exploring the area, talking to locals, or buying maps. Once you have found a jump point, you can use it by double-clicking on it.]])
jumping_log2 = _([[You can open your starmap by pressing the Open Star Map key (M by default). Through your starmap, you can click on a system and click on the Autonav button to be automatically transported to the system. This only works if you know a valid route to get there.]])
fuel_log = _([[You consume fuel any time you make a jump and can refuel by landing on a friendly planet. Standard engines have enough fuel to make up to three jumps before refueling, though higher-end engines have more fuel capacity and some ships may have their own supplementary fuel tanks.]])
boarding_log = _("To board a ship, you generally must first use disabling weapons, such as ion cannons, to disable it, although some missions and events allow you to board certain ships without disabling them. Once the ship is disabled or otherwise can be boarded, you can board it by either double-clicking on it, or targeting it with the Target Nearest key (T by default) and then pressing the Board Target key (B by default). From there, you generally can steal the ship's credits, cargo, ammo, and/or fuel. Boarding ships can also trigger special mission events.")
nofuel_log = _([[You can hail any other pilot by either double-clicking on them, or by targeting them with the Target Nearest key (T by default) and then pressing the Hail Target key (Y by default). From there, you can ask to be refueled. Most military ships will not be willing to help you, but many civilians and traders will be willing to sell you some fuel for a nominal fee. When you find someone willing to refuel you, you need to stop your ship, which you can do with the Autobrake key (Ctrl+B by default), and wait for them to reach your ship and finish the fuel transfer.

If there are no civilians or traders in the system, you can alternatively attempt to get fuel from a pirate. To do so, you must first hail them and offer a bribe, and if you successfully bribe them, they will often be willing to refuel you if you hail them again and ask for it.]])

misn_title = _("Point of Sale")
misn_desc = _("You have purchased a new ship from Melendez and are in the process of finalizing the sale.")


function create ()
   -- Note: This mission makes no system claims.
   start_planet = planet.get("Em 1")
   start_planet_r = 200

   misn.setTitle(misn_title)
   misn.setDesc(misn_desc)
   misn.setReward(fmt.credits(credits))

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
   addTutLog(boarding_log)
   addTutLog(nofuel_log)

   timer_hook = hook.timer(5, "timer")
   hook.land("land")
   hook.enter("enter")

   stage = 1
   create_osd()

   tk.msg("", fmt.f(intro_text,
         {player=player.name(), shipname=player.pilot():name()}))
   tk.msg("", fmt.f(movement_text,
         {leftkey=tutGetKey("left"), rightkey=tutGetKey("right"),
            accelkey=tutGetKey("accel"), reversekey=tutGetKey("reverse"),
            mouseflykey=tutGetKey("mousefly"), planet=start_planet:name()}))
end


function create_osd()
   local osd_desc = {
      fmt.f(_("Fly to {planet} ({system} system) with the movement keys ({accelkey}, {leftkey}, {reversekey}, {rightkey})"),
         {planet=start_planet:name(), system=missys:name(),
            accelkey=naev.keyGet("accel"), leftkey=naev.keyGet("left"),
            reversekey=naev.keyGet("reverse"), rightkey=naev.keyGet("right")}),
      fmt.f(_("Land on {planet} ({system} system) by double-clicking on it"),
         {planet=start_planet:name(), system=missys:name()}),
   }

   misn.osdCreate(_("Flight Training"), osd_desc)
   misn.osdActive(stage)
end


function timer ()
   hook.rm(timer_hook)
   timer_hook = hook.timer(1, "timer")

   -- Recreate OSD in case key binds have changed.
   create_osd()

   if system.cur() == missys
         and player.pos():dist(start_planet:pos()) <= start_planet_r then
      stage = 2

      tk.msg("", fmt.f(landing_text,
            {planet=start_planet:name(),
               target_planet_key=tutGetKey("target_planet"),
               landkey=tutGetKey("land")}))
      create_osd()
   end
end


function enter()
   hook.rm(timer_hook)
   timer_hook = hook.timer(1, "timer")
end


function land()
   hook.rm(timer_hook)
   if planet.cur() ~= start_planet then
      return
   end

   tk.msg("", fmt.f(land_text, {player=player.name()}))
   misn.finish(true)
end
