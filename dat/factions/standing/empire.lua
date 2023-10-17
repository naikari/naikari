require "factions/standing/skel"


_fdelta_distress = {-1, 0} -- Maximum change constraints
_fdelta_kill = {-10, 5} -- Maximum change constraints

_fthis = faction.get("Empire")

sec_hit_min = 10


function faction_hit(current, amount, source, secondary)
   local start_standing = _fthis:playerStanding()
   local f = default_hit(current, amount, source, secondary)
   if (secondary and amount < 0 and f < sec_hit_min) then
      f = math.min(start_standing, sec_hit_min)
   end
   return f
end
