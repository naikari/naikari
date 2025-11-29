--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Mercenary Handler">
 <trigger>enter</trigger>
 <priority>100</priority>
 <chance>100</chance>
 <flags>
  <unique />
 </flags>
</event>
--]]
--[[

   Mercenary Handler Event

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

--

   This event runs when entering systems and causes mercenaries to spawn
   and interact in interesting ways with pilots in the system.

--]]

local fleet = require "fleet"
local formation = require "formation"


local paying_factions = {
   "Coälition",
   "Empire",
   "Frontier",
   "Independent",
}


function create()
   evt.finish() -- Event disabled for now.
   local total_presence = 0
   local presences = system.cur():presences()
   for i, s in ipairs(paying_factions) do
      if presences[s] then
         total_presence = total_presence + presences[s]
      end
   end

   max_mercenaries = total_presence / 400
   mercenaries = 0

   spawn_timer()

   hook.land("end_event")
   hook.jumpout("end_event")
end


function spawn_merc(source)
   local choices_small = {
      "Llama", "Hyena", "Shark", "Lancelot", "Vendetta", "Ancestor",
   }
   local choices_medium = {
      "Ancestor", "Admonisher", "Phalanx", "Pacifier", "Vigilance",
   }
   local choices_heavy = {
      "Pacifier", "Vigilance", "Kestrel", "Hawking",
   }
   local names = {
      Llama = _("Mercenary Llama"),
      Hyena = _("Mercenary Hyena"),
      Shark = _("Mercenary Shark"),
      Lancelot = _("Mercenary Lancelot"),
      Vendetta = _("Mercenary Vendetta"),
      Ancestor = _("Mercenary Ancestor"),
      Admonisher = _("Mercenary Admonisher"),
      Phalanx = _("Mercenary Phalanx"),
      ["Pacifier"] = _("Mercenary Pacifier"),
      Vigilance = _("Mercenary Vigilance"),
      Kestrel = _("Mercenary Kestrel"),
      Hawking = _("Mercenary Hawking"),
   }
   local fleet_choices = {
      Lancelot = {"Hyena", "Shark"},
      Vendetta = {"Hyena", "Shark"},
      Ancestor = {"Hyena", "Shark"},
      Admonisher = {"Hyena", "Shark", "Lancelot"},
      Phalanx = {"Hyena", "Shark", "Lancelot"},
      ["Pacifier"] = {"Shark", "Lancelot", "Vendetta", "Ancestor"},
      Vigilance = {"Shark", "Lancelot", "Vendetta", "Ancestor"},
      Kestrel = {"Lancelot", "Vendetta", "Ancestor"},
      Hawking = {"Lancelot", "Vendetta", "Ancestor", "Admonisher", "Phalanx"},
   }

   local merc_ship
   local nescorts = 0
   if max_mercenaries - mercenaries < 1 or rnd.rnd() < 0.7 then
      merc_ship = choices_small[rnd.rnd(1, #choices_small)]
      nescorts = rnd.rnd(0, 6)
   elseif rnd.rnd() < 0.2 then
      merc_ship = choices_medium[rnd.rnd(1, #choices_medium)]
      nescorts = rnd.rnd(0, 8)
   else
      merc_ship = choices_heavy[rnd.rnd(1, #choices_heavy)]
      nescorts = rnd.rnd(0, 8)
   end

   local merc = pilot.add(merc_ship, "Mercenary", source, names[merc_ship])
   merc:memory().natural = true

   local escorts = {}
   local choices = fleet_choices[merc_ship]
   if nescorts and choices ~= nil and #choices > 0 then
      local n = rnd.rnd(0, 8)
      local form = formation.random_key()
      merc:memory().formation = form
      for i=1,nescorts do
         local eship = choices[rnd.rnd(1, #choices)]
         local escort = pilot.add(eship, "Mercenary", source, names[eship])
         local escortmem = escort:memory()
         escortmem.formation = form
         escortmem.natural = true
         escort:setLeader(merc)
         escorts[#escorts + 1] = escort
      end
   end

   -- Trigger a hook to allow missions to do things with mercenaries.
   naik.hookTrigger("merc_spawn", merc)

   -- Check to make sure the mercenary exists, in case the spawn trigger
   -- was used to destroy the mercenary.
   if merc:exists() then
      set_target(merc, merc:memory().bounty or choose_target())
      hook.pilot(merc, "death", "leader_death")
      mercenaries = mercenaries + 1
   end
end


function choose_target()
   -- Chance to choose no target
   if rnd.rnd() < 0.5 then
      return nil
   end

   local presences = system.cur():presences()

   local hire_faction = system.cur():faction()
   if hire_faction == nil or rnd.rnd() < 0.1 then
      -- Copy faction choices table
      local choices = {}
      for i, s in ipairs(paying_factions) do
         choices[#choices + 1] = s
      end

      while #choices > 0 do
         local i = rnd.rnd(1, #choices)
         local fact = choices[i]

         -- Delete the chosen faction
         choices[i] = choices[#choices]
         choices[#choices] = nil

         if presences[fact] then
            hire_faction = faction.get(fact)
            break
         end
      end
   end

   if hire_faction == nil then
      return nil
   end

   local choices = hire_faction:enemies()

   local target_faction
   while #choices > 0 do
      local i = rnd.rnd(1, #choices)
      local fact = choices[i]

      -- Delete the chosen faction
      choices[i] = choices[#choices]
      choices[#choices] = nil

      if presences[fact:nameRaw()] then
         target_faction = fact
         break
      end
   end

   if target_faction == nil then
      return nil
   end

   local pre_choices = pilot.get(target_faction)
   local choices = {}
   for i, p in ipairs(pre_choices) do
      if p:memory().natural then
         table.insert(choices, p)
      end
   end

   if hire_faction:playerStanding() < 0 then
      table.insert(choices, player.pilot())
   end

   if #choices <= 0 then
      return nil
   end

   return choices[rnd.rnd(1, #choices)]
end


function set_target(merc_pilot, bounty)
   if bounty == nil or not bounty:exists() then
      return
   end
   merc_pilot:memory().bounty = bounty
   bounty:memory().natural = false
   hook.timer(2, "search_timer", merc_pilot)
end


function clear_orders(merc_pilot)
   merc_pilot:control(false)
   merc_pilot:taskClear()
   for i, p in ipairs(merc_pilot:followers()) do
      merc_pilot:control(false)
      merc_pilot:taskClear()
   end
end


function search_timer(merc_pilot)
   if merc_pilot == nil or not merc_pilot:exists() then
      return
   end

   local bounty = merc_pilot:memory().bounty
   if bounty == nil or not bounty:exists() then
      clear_orders(merc_pilot)
      set_target(merc_pilot, choose_target())
      return
   end

   if merc_pilot:inrange(bounty) then
      if bounty == player.pilot() then
         merc_pilot:setHostile()
         for i, p in ipairs(merc_pilot:followers()) do
            p:setHostile()
         end
         -- No need to continue with the timer since AI will take care
         -- of the rest for hostility against the player.
         return
      else
         merc_pilot:control()
         merc_pilot:attack(bounty)
         for i, p in ipairs(merc_pilot:followers()) do
            p:control()
            p:attack(bounty)
         end
      end
   else
      clear_orders(merc_pilot)
   end

   hook.timer(1, "search_timer", merc_pilot)
end


function leader_death(ldr)
   mercenaries = mercenaries - 1
   local bounty = ldr:memory().bounty
   for i, p in ipairs(ldr:followers()) do
      if p:exists() then
         p:control(false)
         p:taskClear()
         p:setLeader(nil)
         p:changeAI("mercenary")
         set_target(p, bounty)
         hook.pilot(p, "death", "leader_death")
         mercenaries = mercenaries + 1
      end
   end
end


function spawn_timer()
   hook.timer(10, "spawn_timer")
   if mercenaries >= max_mercenaries then
      return
   end
   if rnd.rnd() < 0.5 then
      local sys = system.cur()
      local sources = {}

      -- Possible systems to jump in from
      for i, jmp in ipairs(sys:jumps(true)) do
         local source = jmp:dest()
         -- Have to get the real jump that would be used to get here.
         -- Ensures that they don't try to spawn thru a jump that's
         -- hidden or exit-only on the other side.
         local rjump = jump.get(source, sys)
         if rjump ~= nil and not rjump:hidden() and not rjump:exitonly() then
            sources[#sources + 1] = source
         end
      end

      -- Possible planet/stations to takeoff from
      for i, pl in ipairs(sys:planets()) do
         if pl:services()["land"] and not pl:restriction() then
            sources[#sources + 1] = pl
         end
      end

      spawn_merc(sources[rnd.rnd(1, #sources)])
   end
end


function end_event()
   evt.finish()
end
