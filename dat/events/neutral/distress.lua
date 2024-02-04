--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Distress Call Event">
 <priority>100</priority>
 <trigger>enter</trigger>
 <chance>15</chance>
 <cond>player.misnDone("The Space Family")</cond>
 <notes>
  <done_misn name="The Space Family" />
 </notes>
</event>
--]]
--[[

   EVENT: Distress Call
   DESCRIPTION: A random ship transmits a distress call.

--]]

local fmt = require "fmt"
local pilotname = require "pilotname"

local sos_msg = {
   _("Mayday! This is {pilot}. I am shipwrecked. Please help."),
   _("This is {pilot}. If you get this message, please assist, or tell someone I'm in distress. Comm is not responding. I've no nav control. Please assist."),
   _("This is {pilot} urgently requesting rescue. All systems down. If you get this message, please assist."),
   _("Come at once. This is {pilot}. All systems down. Requesting immediate rescue."),
   _("Mayday! This is {pilot}. All systems down. Cannot last much longer. Losing power. Please rescue immediately."),
   _("This is {pilot}. It's a mayday, mayday, mayday. I am shipwrecked. Please help."),
   _("Come quick. This is {pilot}. Urgently need rescue."),
   _("Attention all ships: this is {pilot}. I am in urgent need of rescue. Please hurry."),
   _("Attention: this is {pilot} urgently requesting rescue. All systems down. Losing air. Please hurry."),
   _("This is {pilot} calling for immediate rescue. Please hurry."),
   _("Mayday! Does anyone read me? All systems down. In urgent need of rescue."),
   _("This is {pilot}. Mayday, mayday. All systems down. In need of rescue."),
}


function create()
   local density, volatility = system.cur():nebula()
   if volatility > 0 then
      -- Nebula volatility will destroy derelicts, which would be a bit
      -- weird, so skip the event if there's any nebula volatility.
      evt.finish()
   end

   hook.jumpout("exit")
   hook.land("exit")

   local all_pilots = pilot.get()

   local class_chances = {
      ["Freighter"] = 0.6,
      ["Armored Transport"] = 0.4,
      ["Corvette"] = 0.2,
      ["Destroyer"] = 0.1,
      ["Cruiser"] = 0.05,
      ["Carrier"] = 0.01,
   }

   local pilots = {}
   for i = 1, #all_pilots do
      local p = all_pilots[i]
      local fac = p:faction()
      if fac == faction.get("Civilian") or fac == faction.get("Trader")
            or fac == faction.get("Miner") then
         local shipclass = p:ship():class()
         local chance = class_chances[shipclass]
         if chance == nil or rnd.rnd() < chance then
            pilots[#pilots + 1] = p
         end
      end
   end

   if #pilots <= 0 then
      evt.finish()
   end

   local p = pilots[rnd.rnd(1, #pilots)]
   if p:exists() and p:memory().natural then
      -- Make sure the pilot isn't too close to a planet.
      local planets = system.cur():planets()
      for i = 1, #planets do
         local pnt = planets[i]
         if vec2.dist(p:pos(), pnt:pos()) < pnt:radius() * 3 then
            evt.finish()
         end
      end

      local mem = p:memory()
      mem.natural = false
      mem.kill_reward = nil
      p:rename(pilotname.generic())
      p:disable()
      p:setHilight()
      p:setNoClear()
      p:setLeader(nil)
      p:pay(-p:credits())

      hook.timer(5, "timer_sos", p)
      hook.pilot(p, "board", "pilot_board")

      -- Remove followers so they don't sit there next to the wing of
      -- the empty ship.
      for i, fp in ipairs(p:followers()) do
         fp:setLeader(nil)
      end
   end
end


function timer_sos(p)
   local msg = sos_msg[rnd.rnd(1, #sos_msg)]
   p:broadcast(fmt.f(msg, {pilot=p:name()}))
   hook.timer(20, "timer_sos", p)
end


function pilot_board(p, boarder)
   if boarder ~= player.pilot() then
      return
   end

   local mem = p:memory()
   mem.kill_reward = nil

   -- Set to a blank faction so there's no reputation shenanigans.
   local f = faction.dynAdd(nil, N_("Derelict"), nil, {ai="idle"})
   p:setFaction(f)

   p:setHilight(false)

   naik.missionStart("Distress Rescue")
   evt.finish()
end


function exit()
   evt.finish()
end
