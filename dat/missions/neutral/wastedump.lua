--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Waste Dump">
 <avail>
  <priority>80</priority>
  <chance>30</chance>
  <location>Computer</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[

   Waste Dump

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


text = {
   _("The waste containers are loaded onto your ship and you are paid {credits}. You begin to wonder if accepting this job was really a good ideä."),
   _("Workers pack your cargo hold full of as much garbage as it can hold, then hastily hand you a credit chip containing {credits}. Smelling the garbage, you immediately regret taking the job."),
   _("Your hold is crammed full with garbage and you are summarily paid {credits}. By the time the overpowering stench emanating from your cargo hold is apparent to you, it's too late to back down; you're stuck with this garbage until you can find some place to get rid of it."),
}

finish_text = {}
finish_text[1] = _("You drop the garbage off, relieved to have it out of your ship.")
finish_text[2] = _("You finally drop off the garbage and proceed to disinfect yourself and your cargo hold to the best of your ability.")
finish_text[3] = _("Finally, the garbage leaves your ship and you breathe a sigh of relief.")
finish_text[4] = _("Wrinkling your nose in disgust, you finally rid yourself of the waste containers you have been charged with disposing of.")

abort_text = {}
abort_text[1] = _("Sick and tired of smelling garbage, you illegally jettison the waste containers into space, hoping that no one notices.")
abort_text[2] = _("You decide that the nearest waste dump location is too far away for you to bother to go to and simply jettison the containers of waste. You hope you don't get caught.")
abort_text[3] = _("You dump the waste containers into space illegally, noting that you should make sure not to get caught by authorities.")

abort_landed_text = _("In your desperation to rid yourself of the garbage, you clumsily eject it from your cargo hold while you are still landed. Garbage spills all over the spaceport and local officials immediately take notice. After you apologize profusely and explain the situation away as an accident, the officials let you off with a fine of {credits}.")

abort_landed_broke_text = _([[In your desperation to rid yourself of the garbage, you eject it from your cargo hold while you are still landed. You quickly regret doing this as garbage spills all over the spaceport and local officials immediately take notice. After you apologize profusely and explain the situation away as an accident, the officials let you off with a fine of {credits}.

When you explain that you don't have enough credits to pay the fine, the officials inform you that they will confiscate outfits and cargo you own to make up the difference.]])

nospace_text = _([[You almost accept a mission to fill your ship's cargo hold with garbage, but you find that your ship is packed entirely full and can't fit any of it. Thinking of your cargo hold being equally stuffed with garbage, you realize what you almost got yourself into and breathe a sigh of relief knowing that circumstances prevented you from making a decision you would regret.]])

misn_title = _("Waste Dump")
misn_desc = _("Take as many waste containers off of here as your ship can hold and drop them off at any authorized garbage collection facility. You will be paid immediately, but any attempt to illegally jettison the waste into space will be severely punished if you are caught.")

osd_title = _("Waste Dump")

-- List of possible waste dump planets.
dest_planets = {"The Stinker", "Vaal", "Domestica", "Blossom", "Knive"}


function create ()
   local closest_planet, closest_sys, dist = get_closest_dest()
   if dist == nil then
      misn.finish(false)
   end
   credits_factor = math.max(200, 1000*dist + 500*rnd.sigma())

   if closest_sys ~= nil then
      tempmarker = misn.markerAdd(closest_sys, "computer")
   end

   -- Set mission details
   misn.setTitle(misn_title)
   misn.setDesc(misn_desc)
   misn.setReward(fmt.f(n_("{price} ¢/kt", "{price} ¢/kt", credits_factor),
         {price=fmt.number(credits_factor)}))
end


function accept ()
   local q = player.pilot():cargoFree()
   if q < 1 then
      tk.msg("", nospace_text)
      misn.finish()
   end

   misn.accept()

   misn.markerRm(tempmarker)
   for i, v in ipairs(dest_planets) do
      local p, sys
      p, sys = planet.get(v)
      misn.markerAdd(sys, "computer", p)
   end

   credits = credits_factor * q

   local txt = text[rnd.rnd(1, #text)]
   tk.msg("", fmt.f(txt, {credits=fmt.credits(credits)}))

   local c = misn.cargoNew(N_("Waste Containers"), N_("A bunch of waste containers leaking all sorts of indescribable liquids."))
   cid = misn.cargoAdd(c, q)
   player.pay(credits)

   update_osd()

   hook.jumpin("update_osd")
   hook.land("land")
end


function get_closest_dest()
   local cursys = system.cur()
   local dist = nil
   local closest_planet = nil
   local closest_sys = nil
   for i, v in ipairs(dest_planets) do
      p, sys = planet.get(v)
      local jd = cursys:jumpDist(sys)
      if jd ~= nil and (dist == nil or jd < dist) then
         dist = jd
         closest_planet = p
         closest_sys = sys
      end
   end
   return closest_planet, closest_sys, dist
end


function update_osd()
   local osd_msg = {
      _("Land on any garbage collection facility."),
      _("Alternatively: fly to a system where you won't get caught by authorities, illegally jettison the cargo via the Ship Computer, and jump out of the system before you are discovered"),
   }

   local pnt, sys = get_closest_dest()
   if pnt ~= nil and sys ~= nil then
      osd_msg[1] = fmt.f(_("Land on {planet} ({system} system), or any other garbage collection facility."),
            {planet=pnt:name(), system=sys:name()})
   end

   misn.osdCreate(osd_title, osd_msg)
end


function land()
   local curplanet = planet.cur()
   for i, v in ipairs(dest_planets) do
      if planet.get(v) == curplanet then
         local txt = finish_text[rnd.rnd(1, #finish_text)]
         tk.msg("", txt)
         misn.finish(true)
      end
   end
end


function abort()
   if player.isLanded() then
      misn.cargoRm(cid)
      local fine = 1.1 * credits
      local money = player.credits()
      if money >= fine then
         tk.msg("", fmt.f(abort_landed_text, {credits=fmt.credits(fine)}))
      else
         tk.msg("", fmt.f(abort_landed_broke_text, {credits=fmt.credits(fine)}))

         -- Start by confiscating cargo...
         local pla = planet.cur()
         local t = time.get()
         for i, v in ipairs(player.pilot():cargoList()) do
            local cprice = commodity.get(v.nameRaw):priceAtTime(pla, t)
            fine = math.max(0, fine - cprice)
         end
         player.pilot():cargoRm("all")

         -- And now confiscate outfits until there are no outfits left
         -- or the fine is covered.
         local poutfits = player.outfits()
         while #poutfits > 0 and money < fine do
            local o = outfit.get(poutfits[1])
            fine = math.max(0, fine - o:price())
            player.outfitRm(poutfits[1])

            poutfits = player.outfits()
         end
      end
      player.pay(-fine, "adjust")
      misn.finish(false)
   end

   local txt = abort_text[rnd.rnd(1, #abort_text)]
   tk.msg("", txt)

   misn.cargoJet(cid)

   local pp = player.pilot()
   for i, p in ipairs(pilot.get()) do
      local mem = p:memory()
      if p ~= pp and p:leader(true) ~= pp and mem.natural then
         mem.natural = false
         p:setHostile()
      end
   end

   -- No landing, filthy waste dumper!
   -- XXX: This could potentially cause problems for a theoretical
   -- mission that requires the player to land and also locks the player
   -- out of hyperspacing. Missions really shouldn't do this, but it's
   -- a potential pitfall to keep in mind. For now, we kind of need this
   -- in order to prevent the player from simply cheesing the punishment
   -- by dumping and then immediately landing.
   player.allowLand(false,
         _("It's not safe to land after illegally dumping garbage."))

   misn.finish(true)
end
