require "factions/standing/skel"


_fdelta_distress = {-0.5, 0} -- Maximum change constraints
_fdelta_kill = {-9, 7} -- Maximum change constraints

_fthis = faction.get("Dvaered")

_fmod_misn_friend = 0


function faction_hit(current, amount, source, secondary)
    return default_hit(current, amount, source, secondary)
end
