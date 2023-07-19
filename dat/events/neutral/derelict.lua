--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Derelict Event">
 <priority>100</priority>
 <trigger>enter</trigger>
 <chance>520</chance>
</event>
--]]
--[[
   Derelict Event

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

   Event which turns random natural pilots into a derelict.

--]]

local fmt = require "fmt"


function create()
   hook.safe("safe_disable")
end


function safe_disable()
   local pilots = pilot.get()
   local p = pilots[rnd.rnd(1, #pilots)]
   if p:exists() and p:memory().natural then
      p:memory().natural = false
      p:disable()
      p:rename(fmt.f(_("Derelict {pilot}"), {pilot=p:name()}))
   end

   evt.finish()
end
