require "factions/standing/skel"


_fdelta_distress = {-0.5, 0} -- Maximum change constraints
_fdelta_kill = {-10, 10} -- Maximum change constraints


function faction_hit(current, amount, source, secondary, fac)
    return default_hit(current, amount, source, secondary, fac)
end
