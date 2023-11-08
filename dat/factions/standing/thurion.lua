require "factions/standing/skel"


_fdelta_distress = {-1, 0} -- Maximum change constraints
_fdelta_kill = {-10, 2} -- Maximum change constraints

_fmod_kill_enemy = 0.01


function faction_hit(current, amount, source, secondary, fac)
    return default_hit(current, amount, source, secondary, fac)
end
