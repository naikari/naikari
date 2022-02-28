--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Land Tutorial Event">
 <trigger>land</trigger>
 <chance>100</chance>
 <flags>
  <unique />
 </flags>
 <notes>
  <requires name="Continued Tutorial"/>
 </notes>
</event>
--]]
--[[

   Tutorial Event

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

require "events/tutorial/tutorial_common"


function create ()
   hook.takeoff("takeoff")
end


function takeoff ()
   evt.finish()
end

