require "factions/standing/skel"


_fdelta_distress = {-0.5, 0} -- Maximum change constraints
_fdelta_kill = {-5, 0} -- Maximum change constraints

_fthis = faction.get("FLF")


function faction_hit(current, amount, source, secondary)
    return default_hit(current, amount, source, secondary)
end
