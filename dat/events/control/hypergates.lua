--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Hypergate Handler">
 <trigger>land</trigger>
 <chance>20</chance>
 <cond>system.get("Sol"):known()</cond>
</event>
--]]
--[[

   Hypergate Handler Event

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

   This event activates hypergates when conditions for them are met.

--]]

local fmt = require "fmt"


function create()
   if diff.isApplied("hypergate_empire") then
   else
      local standing = faction.get("Empire"):playerStanding()
      if standing >= 20 or standing <= -20 then
         diff.apply("hypergate_empire")
         news.add("Generic", _("Empire Announces Hypergate Network"),
               _([[The Emperor has announced the creation of a new system of mass transit: hypergates. "Unlike regular jump gates, hypergates operate through a central hub called the Hypergate Zone," a leading researcher in charge of the project explained. Currently, the only working hypergate is found in Gamma Polaris. Imperial officials state that they are working with the Great Houses to finish construction of the hypergate network.]]),
               time.get() + time.create(0, 250, 0))
      end
   end

   evt.finish()
end
