--[[--
Generic mission-helping functions.

@usage local mh = require "misnhelper"

@module misnhelper
--]]

local fmt = require "fmt"

local misnhelper = {}


--[[--
Wrapper for player.misnActive that works on a table of missions.

@usage if mh.anyMissionActive({"Cargo", "Cargo Rush"}) then
   @tparam table names Table of names of missions to check
   @treturn boolean true if any of the listed missions are active,
      or false otherwise.
--]]
function misnhelper.anyMissionActive(names)
   for i, name in ipairs(names) do
      if player.misnActive(name) then
         return true
      end
   end
   return false
end


--[[--
Shows a player message informing of a mission success.

Note: this does not actually end the mission. It should be followed
up with a misn.finish(true) call.

@usage mh.showWinMsg(_("You delivered the cake!"))
   @tparam[opt] string congrats Congratulation message for winning.
--]]
function misnhelper.showWinMsg(congrats)
   if congrats ~= nil then
      local message = fmt.f(_("MISSION SUCCESSFUL! {congrats}"),
            {congrats=congrats})
      player.msg("#g" .. message .. "#0")
   else
      player.msg("#g" .. _("MISSION SUCCESSFUL!") .. "#0")
   end
end


--[[--
Shows a player message informing of a mission failure.

Note: this does not actually end the mission. It should be followed
up with a misn.finish(false) call.

@usage showFailMsg(_("You failed to deliver the cake!"))
   @tparam[opt] string reason The reason the player failed the mission.
--]]
function misnhelper.showFailMsg(reason)
   if reason ~= nil then
      local message = fmt.f(_("MISSION FAILED: {reason}"), {reason=reason})
      player.msg("#r" .. message .. "#0")
   else
      player.msg("#r" .. _("MISSION FAILED!") .. "#0")
   end
end


--[[--
Sets a mission bartender hint message.

Must be called from the custom "bartender_mission" hook. The code which
triggers that hook is in dat/events/control/npc.lua.

@usage setBarHint(_("Mission Name"), _("Advice for the mission"))
   @tparam string name The name of the mission.
   @tparam string hint The full text of the hint message given by the
      bartender for the mission. This is displayed as-is and should be
      formatted just like any other dialog, including quotation marks.
--]]
function misnhelper.setBarHint(name, hint)
   local count = var.peek("_bartender_mission_count")
   if count == nil then
      error(string.format(
            _("'%s' attempted bar hint outside bartender_mission hook"), name))
      return
   end
   if name == nil then
      error(_("name parameter not set for bar hint"))
      return
   end
   if hint == nil then
      error(string.format(_("hint paramater not set for '%s' bar hint"), name))
      return
   end

   -- Increment the number of bartender missions.
   count = count + 1
   var.push("_bartender_mission_count", count)

   -- Store the mission bartender hint.
   var.push(string.format("_bartender_mission_name_%d", count), name)
   var.push(string.format("_bartender_mission_hint_%d", count), hint)
end


return misnhelper
