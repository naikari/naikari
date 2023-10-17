require "factions/standing/skel"


_fdelta_distress = {-1, 0} -- Maximum change constraints
_fdelta_kill = {-10, 5} -- Maximum change constraints

_fthis = faction.get("Soromid")


function faction_hit(current, amount, source, secondary)
    return default_hit(current, amount, source, secondary)
end
