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
  <campaign>Tutorial</campaign>
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


local intro_text  = _([["Welcome to space, {player}, and congratulations on your purchase," the salesperson who sold you the {shipname} says over the radio. "I am sure your new ship will serve you well! Here at Melendez Corporation, our ships are prized for their reliability and affordability. I promise, you won't be disappointed!" You barely resist the temptation to roll your eyes at the remark; you really only bought this ship because it was the only one you could afford. Still, you tactfully thank the salesperson.]])

local movement_text = _([["Now, so that your test flight goes as smoothly as possible, I will explain the controls of your state-of-the art Melendez Corporation starship! There are two basic modes: keyboard flight, and mouse flight.

"To move via keyboard flight, rotate your ship with {leftkey} and {rightkey}, and thrust to move your ship forward with {accelkey}. You can also use {reversekey} to rotate your ship to the direction opposite of your current movement, which can be useful for bringing your vessel to a stop.

"To move via mouse flight, you must first enable it by pressing {mouseflykey}. While mouse flight is enabled, your ship will automatically turn toward your #bmouse pointer#0, like magic! You can then thrust either with {accelkey}, as you would in keyboard flight, or you can alternatively use the #bmiddle mouse button#0 or either of the #bextra mouse buttons#0.

"Why don't you give both systems a try? Experiment with the flight controls as much as you'd like, then fly over to where {planet} is. You see it on your screen, right? It's the planet right next to you."]])

local landing_text = _([["I see you have a great handle on the controls of your new Melendez Corporation ship! It's a perfect fit for you, don't you think? Your control of the vessel is absolutely stunning, magnificent!

"You may continue to practice flying for as long as you need. When you are ready, please land on {planet} to finalize your paperwork; you can land double-clicking on {planet} or by pressing {landkey}. I will be waiting for you at the spaceport!"]])

local land_text = _([[You watch as the ship – your ship – automatically guides you safely thru the atmosphere and into the planet's space port, then touches down at an empty spot reserved for you. As soon as the hatch opens and you step out, an exhausted dock worker greets you and makes you sign a form. "Just the standard waiver," she explains. After you sign, she pushes some buttons and you stare as you see robotic drones immediately getting to work checking your ship for damage and ensuring your fuel tanks are full. Noticing your expression, the worker lets out a chuckle. "First time landing, eh?" she quips. "It'll all be normal to you before long."

"Ah, there you are, {player}!" the voice of the salesperson interrupts, prompting the worker to roll her eyes and walk off. You look in the direction of the voice and see the obnoxiously dressed salesperson, wearing a huge grin. "I see your Melendez Corporation starship is serving you well. Now, if you would follow me, we can finalize that paperwork."]])

local finish_text = _([[The salesperson makes you sign dozens of forms: tax forms, waivers, indemnity agreements, and much more that you aren't given enough time to process. When you finish, the salesperson pats you on the back. "You have made an excellent choice, {player}! I'm sure you'll be making millions of credits in no time.

"In fact, I know just where to start. A gentleman at the bar is looking for a hired hand, and I assure you, he pays good rates! I've told him about you and he said he would be thrilled to hire you for a job!" The salesperson offers their hand and, not wanting to be combative, you shake it. "Good luck, {player}!" the salesperson says before swiftly escorting you out of their office.

You figure you might as well meet this man the salesperson mentioned at the #bSpaceport Bar#0 and see if the job is worthwhile.]])

misn_title = _("Point of Sale")
misn_desc = _("You have purchased a new ship from Melendez and are in the process of finalizing the sale.")


function create()
   start_planet, missys = planet.get("Em 1")

   misn.setTitle(misn_title)
   misn.setDesc(misn_desc)
   misn.setReward(_("None"))

   accept()
end


function accept ()
   misn.accept()

   timer_hook = hook.timer(5, "timer")
   hook.land("land")
   hook.enter("enter")

   stage = 1
   create_osd()

   misn.markerAdd(missys, "low", start_planet)

   tk.msg("", fmt.f(intro_text,
         {player=player.name(), shipname=player.pilot():name()}))
   tk.msg("", fmt.f(movement_text,
         {leftkey=tutGetKey("left"), rightkey=tutGetKey("right"),
            accelkey=tutGetKey("accel"), reversekey=tutGetKey("reverse"),
            mouseflykey=tutGetKey("mousefly"), planet=start_planet:name()}))
end


function create_osd()
   local osd_desc = {
      fmt.f(_("Fly to {planet} ({system} system) with the movement keys ({accelkey}, {leftkey}, {reversekey}, {rightkey}) or with mouse flight (enabled with {mouseflykey})"),
         {planet=start_planet:name(), system=missys:name(),
            accelkey=naik.keyGet("accel"), leftkey=naik.keyGet("left"),
            reversekey=naik.keyGet("reverse"), rightkey=naik.keyGet("right"),
            mouseflykey=naik.keyGet("mousefly")}),
      fmt.f(_("Land on {planet} ({system} system) by double-clicking it or pressing {landkey}"),
         {planet=start_planet:name(), system=missys:name(),
            landkey=naik.keyGet("land")}),
   }

   misn.osdCreate(misn_title, osd_desc)
   misn.osdActive(stage)
end


function timer ()
   hook.rm(timer_hook)
   timer_hook = hook.timer(1, "timer")

   -- Recreate OSD in case key binds have changed.
   create_osd()

   if stage == 1 and system.cur() == missys
         and player.pos():dist(start_planet:pos()) <= start_planet:radius() then
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
   tk.msg("", fmt.f(finish_text, {player=player.name()}))
   misn.finish(true)
end
