--[[

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 3 as
   published by the Free Software Foundation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

--]]


require "factions/standing/skel"


_fdelta_distress = {-1, 0} -- Maximum change constraints
_fdelta_kill = {-10, 5} -- Maximum change constraints


function faction_hit(current, amount, source, secondary, fac)
    return default_hit(current, amount, source, secondary, fac)
end
