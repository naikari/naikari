--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Distress Rescue">
 <avail>
  <priority>75</priority>
  <chance>100</chance>
  <location>None</location>
 </avail>
 <notes>
  <done_evt name="Distress Call Event" />
 </notes>
</mission>
--]]
--[[
-- This is the mission part of the shipwrecked Space Family mission, started from a random event.
-- See dat/events/neutral/shipwreck
--]]

local fmt = require "fmt"


local accept_text = {
   _([[You board the ship and rescue its pilot. They ask you to drop them off at any inhabited planet and promise {credits} in exchange.]]),
   _([["Thank you so much for the rescue. I thought I was a goner for sure! Now, if you'll just drop me off at any inhabited planet, I'll give you {credits}."]]),
}

local land_text = {
   _([[You drop off the pilot you rescued and they give you {credits} in exchange.]]),
}

-- Mission details
local misn_title = _("Pilot Rescue")


function create()
   credits = rnd.rnd(40000, 120000)

   misn.accept()
   misn.setTitle(misn_title)
   misn.setReward(fmt.credits(credits))
   misn.setDesc(_("You rescued a pilot who was in distress. They need you to take them to any inhabited planet."))

   local text = accept_text[rnd.rnd(1, #accept_text)]
   tk.msg("", fmt.f(text, {credits=fmt.credits(credits)}))

   local osd_text = {
      _("Land on any inhabited planet"),
   }
   misn.osdCreate(misn_title, osd_text)

   hook.land("land")
end


function land()
   local pnt = planet.cur()
   local fac = pnt:faction()
   if not p:services()["inhabited"] or fac == faction.get("Pirate") then
      return
   end

   local text = land_text[rnd.rnd(1, #land_text)]
   tk.msg("", fmt.f(text, {credits=fmt.credits(credits)}))
   player.pay(credits)
   misn.finish(true)
end
