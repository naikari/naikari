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


return misnhelper
