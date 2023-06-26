--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Combat Practice">
 <avail>
  <priority>100</priority>
  <chance>100</chance>
  <cond>not player.misnActive("Combat Practice")</cond>
  <location>Computer</location>
 </avail>
 <notes>
  <campaign>Tutorial</campaign>
 </notes>
</mission>
--]]
--[[

   Combat Practice

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

   MISSION: Combat Practice
   DESCRIPTION: Offers combat practice against enemies, customizable.

--]]

local fmt = require "fmt"
local fleet = require "fleet"
local misnhelper = require "misnhelper"

-- Mission details
misn_title = _("Combat Practice")
misn_desc = _([[Combat practice session against AI-powered drones (type chosen by you) to take place in the next system you enter in which no missions or events are taking place. You and your hired escorts cannot be destroyed during the practice fight, but can be damaged and disabled. Landing or leaving the system will instantly abort the mission.]])


function unpack(t, i)
   i = i or 1
   if t[i] ~= nil then
      return t[i], unpack(t, i + 1)
   end
end


function create()
   -- Note: this mission makes no system claims.
   misn.setTitle(misn_title)
   misn.setDesc(misn_desc)
   misn.setReward(_("None"))
end


function accept()
   local boss_choices = {
      "Llama",
      "Gawain",
      "Quicksilver",
      "Koäla",
      "Mule",
      "Rhino",
      "Hyena",
      "Shark",
      "Proteron Derivative",
      "Lancelot",
      "Vendetta",
      "Ancestor",
      "Admonisher",
      "Phalanx",
      "Pacifier",
      "Vigilance",
      "Proteron Kahan",
      "Kestrel",
      "Hawking",
      "Goddard",
      "Proteron Archimedes",
      "Proteron Watson",
      true,
   }
   local boss_disp = {
      _("Llama (yacht)"),
      _("Gawain (luxury yacht)"),
      _("Quicksilver (courier)"),
      _("Koäla (heavy courier)"),
      _("Mule (freighter)"),
      _("Rhino (armored transport)"),
      _("Hyena (ultralight fighter)"),
      _("Shark (light fighter)"),
      _("Derivative (light fighter)"),
      _("Lancelot (heavy fighter)"),
      _("Vendetta (heavy fighter)"),
      _("Ancestor (bomber)"),
      _("Admonisher (corvette)"),
      _("Phalanx (corvette)"),
      _("Pacifier (destroyer)"),
      _("Vigilance (destroyer)"),
      _("Kahan (destroyer)"),
      _("Kestrel (light cruiser)"),
      _("Hawking (cruiser)"),
      _("Goddard (heavy cruiser)"),
      _("Archimedes (heavy cruiser)"),
      _("Watson (carrier)"),
      p_("ship_type", "Random"),
   }
   local n, boss_text = tk.list(_("Combat Practice"),
         _("Select the leader of the practice drone fleet."),
         unpack(boss_disp))

   boss = boss_choices[n]
   if boss == true then
      local n = rnd.rnd(1, #boss_choices)
      boss = boss_choices[n]
      boss_text = boss_disp[n]
      tk.msg("", fmt.f(_("Random ship chosen: {ship}"), {ship=boss_text}))
   elseif boss == nil then
      misn.finish()
   end

   misn.accept()

   local n, fleet_text = tk.choice(_("Combat Practice"),
         _("Select how large of a fleet the leader should have."),
         p_("fleet_size", "None (no escorts)"),
         p_("fleet_size", "Small (~3 escorts)"),
         p_("fleet_size", "Medium (~6 escorts)"),
         p_("fleet_size", "Large (~10 escorts)"))

   fleet_size = n - 1

   misn.setDesc(fmt.f(_("{desc}\n\nLeader: {boss}\nFleet size: {fleet_size}"),
         {desc=misn_desc, boss=boss_text, fleet_size=fleet_text}))

   numdrones = 1
   if fleet_size == 3 then
      numdrones = 11
   elseif fleet_size == 2 then
      numdrones = 7
   elseif fleet_size == 1 then
      numdrones = 4
   end

   local osd_msg = {
      _("Fly to any system which is not being used by a mission or event"),
      n_("Defeat the practice drone", "Defeat the practice drones", numdrones),
   }
   misn.osdCreate(_("Combat Practice"), osd_msg)

   started = false

   hook.jumpout("exit")
   hook.land("exit")
   -- Triggered by the Tutorial System Claimer event.
   hook.custom("tutcombat_start", "start_hook")
   -- Triggered by the Escort Handler event.
   hook.custom("escort_spawn", "escort_spawn")
end


function start_hook()
   started = true
   pilot.clear()
   pilot.toggleSpawn(false)
   player.pilot():setNoDeath()
   hook.pilot(player.pilot(), "disable", "player_disable")

   misn.osdActive(2)
   
   -- Make the player visible to the AI for a short while so it knows
   -- where to go initially.
   player.pilot():setVisible()
   hook.timer(0.5, "timer_visible")

   -- Just in case, we set existing pilots to no-death (in case hired
   -- escorts have spawned already). The escort_spawn event handles
   -- escorts that spawn later.
   for i, p in ipairs(player.pilot():followers()) do
      -- We don't want fighter bay escorts to be set to no-death since
      -- these escorts can be regenerated, but only when destroyed.
      if not p:flags().escort then
         p:setNoDeath()
      end
   end

   local rad = system.cur():radius()
   local pos = vec2.new(rnd.uniform(-rad, rad), rnd.uniform(-rad, rad))

   local dispname = nil
   if boss == "Proteron Derivative" then
      dispname = _("Derivative")
   elseif boss == "Proteron Kahan" then
      dispname = _("Kahan")
   elseif boss == "Proteron Archimedes" then
      dispname = _("Archimedes")
   elseif boss == "Proteron Watson" then
      dispname = _("Watson")
   end

   local fac = faction.dynAdd(nil, N_("Training"),
         N_("Training Machines, Inc."), {ai="baddie_norun"})

   local boss_p = pilot.add(boss, fac, pos, dispname)
   drones = {boss_p}

   -- Common amount variable (for homogenous fleets)
   local amt_t = {3, 6, 10}
   local amt = amt_t[fleet_size] or 1

   -- Choose the fleet based on ship type and chosen fleet size.
   if fleet_size > 0 then
      if boss == "Gawain" or boss == "Hyena" or boss == "Shark" then
         drones = fleet.add(amt, "Hyena", fac, pos, nil, nil, boss_p)
      elseif boss == "Llama" or boss == "Quicksilver" or boss == "Lancelot"
            or boss == "Vendetta" or boss == "Ancestor" then
         if fleet_size == 3 then
            drones = fleet.add({4, 6}, {"Shark", "Hyena"},
                  fac, pos, nil, nil, boss_p)
         elseif fleet_size == 2 then
            drones = fleet.add({2, 4}, {"Shark", "Hyena"},
                  fac, pos, nil, nil, boss_p)
         else
            drones = fleet.add(amt, "Hyena", fac, pos, nil, nil, boss_p)
         end
      elseif boss == "Koäla" then
         if fleet_size == 3 then
            drones = fleet.add({2, 4, 4}, {"Lancelot", "Shark", "Hyena"},
                  fac, pos, nil, nil, boss_p)
         elseif fleet_size == 2 then
            drones = fleet.add({1, 2, 3}, {"Lancelot", "Shark", "Hyena"},
                  fac, pos, nil, nil, boss_p)
         else
            drones = fleet.add({1, 2}, {"Shark", "Hyena"},
                  fac, pos, nil, nil, boss_p)
         end
      elseif boss == "Admonisher" or boss == "Phalanx" or boss == "Mule"
            or boss == "Rhino" then
         local fighter_t = {"Hyena", "Shark"}
         local fighter = fighter_t[rnd.rnd(1, #fighter_t)]
         if fleet_size == 3 then
            drones = fleet.add({4, 6}, {"Lancelot", fighter},
                  fac, pos, nil, nil, boss_p)
         elseif fleet_size == 2 then
            drones = fleet.add({2, 4}, {"Lancelot", fighter},
                  fac, pos, nil, nil, boss_p)
         else
            drones = fleet.add({1, 2}, {"Lancelot", fighter},
                  fac, pos, nil, nil, boss_p)
         end
      elseif boss == "Pacifier" or boss == "Vigilance" then
         local fighter_t = {"Hyena", "Shark"}
         local fighter = fighter_t[rnd.rnd(1, #fighter_t)]
         if fleet_size == 3 then
            drones = fleet.add({3, 4, 3}, {"Ancestor", "Lancelot", fighter},
                  fac, pos, nil, nil, boss_p)
         elseif fleet_size == 2 then
            drones = fleet.add({1, 2, 3}, {"Ancestor", "Lancelot", fighter},
                  fac, pos, nil, nil, boss_p)
         else
            drones = fleet.add({1, 2}, {"Lancelot", fighter},
                  fac, pos, nil, nil, boss_p)
         end
      elseif boss == "Kestrel" then
         local corvette_t = {"Admonisher", "Phalanx"}
         local corvette = corvette_t[rnd.rnd(1, #corvette_t)]
         if fleet_size == 3 then
            drones = fleet.add({4, 6}, {corvette, "Lancelot"},
                  fac, pos, nil, nil, boss_p)
         elseif fleet_size == 2 then
            drones = fleet.add({2, 4}, {corvette, "Lancelot"},
                  fac, pos, nil, nil, boss_p)
         else
            drones = fleet.add(amt, "Lancelot", fac, pos, nil, nil, boss_p)
         end
      elseif boss == "Hawking" then
         local corvette_t = {"Admonisher", "Phalanx"}
         local corvette = corvette_t[rnd.rnd(1, #corvette_t)]
         local destroyer_t = {"Pacifier", "Vigilance"}
         local destroyer = destroyer_t[rnd.rnd(1, #destroyer_t)]
         if fleet_size == 3 then
            drones = fleet.add({3, 2, 5}, {destroyer, corvette, "Lancelot"},
                  fac, pos, nil, nil, boss_p)
         elseif fleet_size == 2 then
            local elite
            if rnd.rnd() < 0.5 then
               elite = destroyer
            else
               elite = corvette
            end
            drones = fleet.add({2, 4}, {elite, "Lancelot"},
                  fac, pos, nil, nil, boss_p)
         else
            drones = fleet.add(amt, "Lancelot", fac, pos, nil, nil, boss_p)
         end
      elseif boss == "Goddard" then
         local corvette_t = {"Admonisher", "Phalanx"}
         local corvette = corvette_t[rnd.rnd(1, #corvette_t)]
         local destroyer_t = {"Pacifier", "Vigilance"}
         local destroyer = destroyer_t[rnd.rnd(1, #destroyer_t)]
         if fleet_size == 3 then
            drones = fleet.add({4, 2, 4}, {destroyer, corvette, "Lancelot"},
                  fac, pos, nil, nil, boss_p)
         elseif fleet_size == 2 then
            drones = fleet.add({2, 1, 3}, {destroyer, corvette, "Lancelot"},
                  fac, pos, nil, nil, boss_p)
         else
            drones = fleet.add({1, 2}, {destroyer, "Lancelot"},
                  fac, pos, nil, nil, boss_p)
         end
      elseif boss == "Proteron Derivative" or boss == "Proteron Kahan" then
         drones = fleet.add(amt, "Proteron Derivative", fac, pos,
               _("Derivative"), nil, boss_p)
      elseif boss == "Proteron Archimedes" then
         if fleet_size == 3 then
            drones = fleet.add(
                  {3, 7}, {"Proteron Kahan", "Proteron Derivative"}, fac, pos,
                  {_("Kahan"), _("Derivative")}, nil, boss_p)
         elseif fleet_size == 2 then
            drones = fleet.add(
                  {1, 5}, {"Proteron Kahan", "Proteron Derivative"}, fac, pos,
                  {_("Kahan"), _("Derivative")}, nil, boss_p)
         else
            drones = fleet.add(amt, "Proteron Derivative", fac, pos,
                  _("Derivative"), nil, boss_p)
         end
      elseif boss == "Proteron Watson" then
         if fleet_size == 3 then
            drones = fleet.add(
                  {6, 4}, {"Proteron Kahan", "Proteron Derivative"}, fac, pos,
                  {_("Kahan"), _("Derivative")}, nil, boss_p)
         elseif fleet_size == 2 then
            drones = fleet.add(
                  {3, 3}, {"Proteron Kahan", "Proteron Derivative"}, fac, pos,
                  {_("Kahan"), _("Derivative")}, nil, boss_p)
         else
            drones = fleet.add(
                  {1, 2}, {"Proteron Kahan", "Proteron Derivative"}, fac, pos,
                  {_("Kahan"), _("Derivative")}, nil, boss_p)
         end
      else
         drones = fleet.add(amt, "Hyena", fac, pos, nil, nil, boss_p)
      end
   end

   numdrones = #drones

   for i, p in ipairs(drones) do
      p:setHostile()
      p:setHilight()
      hook.pilot(p, "death", "pilot_death")
      hook.pilot(p, "disable", "pilot_death")
      hook.pilot(p, "jump", "pilot_death")
      hook.pilot(p, "land", "pilot_death")
   end
end


function escort_spawn(p)
   if started then
      p:setNoDeath()
   end
end


function timer_visible()
   player.pilot():setVisible(false)
end


function pilot_death(plt)
   -- Disabling counts as defeat, so if still alive, make non-hostile.
   if plt:exists() then
      plt:setHostile(false)
      plt:setHilight(false)
      plt:setInvincible()
      plt:setFuel(true)
      plt:control()
      plt:hyperspace()
   end

   -- Remove this pilot from the list in case it still exists.
   for i, p in ipairs(drones) do
      if p == plt then
         drones[i] = drones[#drones]
         drones[#drones] = nil
         break
      end
   end

   -- Check to see if any other drones are still alive.
   for i, p in ipairs(drones) do
      if p:exists() then
         return
      end
   end

   -- If we're here, no drones are left alive, so finish the mission.
   remove_safety()
   player.msg(n_("MISSION SUCCESSFUL: The practice drone is defeated.",
         "MISSION SUCCESSFUL: All practice drones are defeated.", numdrones))
   misn.finish(true)
end


function player_disable(plt)
   if started then
      for i, p in ipairs(drones) do
         if p:exists() then
            p:setHostile(false)
            p:setHilight(false)
            p:setInvincible()
            p:setFuel(true)
            p:control()
            p:hyperspace()
         end
         for j, f in ipairs(p:followers()) do
            if f:exists() then
               f:setHostile(false)
               f:setInvincible()
               f:setFuel(true)
               f:control()
               f:hyperspace()
            end
         end
      end

      misnhelper.showFailMsg(_("Your ship has been disabled."))
      misn.osdDestroy()
      player.pilot():hookClear()
      loss_timer = hook.timer(2, "timer_loss")
      hook.pilot(player.pilot(), "attacked", "player_post_attacked")
   end
end


function player_post_attacked(plt)
   -- Reset the loss hook if the player is hit by another bullet. This
   -- presents things like losing to a beam that's still firing.
   hook.rm(loss_timer)
   loss_timer = hook.timer(2, "timer_loss")
end


function exit()
   if started then
      remove_safety()
      misnhelper.showFailMsg(_("You ran away from the practice fight, thus aborting it."))
      misn.finish(false)
   end
end


function timer_loss()
   remove_safety()
   misn.finish(false)
end


function remove_safety()
   if started then
      pilot.toggleSpawn(true)
      player.pilot():setNoDeath(false)
      player.pilot():setVisible(false)
      local armor, shield, stress = player.pilot():health()
      player.pilot():setHealth(100, 100, stress)
      for i, p in ipairs(player.pilot():followers()) do
         p:setNoDeath(false)
         local armor, shield, stress = p:health()
         p:setHealth(100, 100, stress)
      end

      for i, p in ipairs(drones) do
         if p:exists() then
            p:setHostile(false)
            p:setHilight(false)
            p:setInvincible()
            p:setFuel(true)
            p:control()
            p:hyperspace()
         end
         for j, f in ipairs(p:followers()) do
            if f:exists() then
               f:setHostile(false)
               f:setInvincible()
               f:setFuel(true)
               f:control()
               f:hyperspace()
            end
         end
      end
   end
end


function abort()
   remove_safety()
   misn.finish(false)
end
