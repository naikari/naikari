--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Invincibility">
 <trigger>land</trigger>
 <chance>100</chance>
</event>
--]]
--[[

   Invincibility Event

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

   This event triggers a short invincibility period on takeoff so you
   don't immediately get killed by something. Can be overridden by
   setting the "invincibility_override" var to true.

--]]


function create()
   hook.takeoff("takeoff")
   hook.land("reset")
end


function takeoff()
   -- Allow missions to override the invincibility period if they want
   -- to (only necessary if for some reason the mission starts the
   -- player out invincible).
   if var.peek("invincibility_override") then
      var.pop("invincibility_override")
      evt.finish()
   end

   player.pilot():setInvincible(true)
   hook.timer(3, "reset")
end


function reset()
   player.pilot():setInvincible(false)
   evt.finish()
end

