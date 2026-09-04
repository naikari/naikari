require "factions/standing/skel"


_fdelta_distress = {-0.5, 0} -- Maximum change constraints
_fdelta_kill = {-10, 0.2} -- Maximum change constraints


function faction_hit(current, amount, source, secondary, fac)
    local new = default_hit(current, amount, source, secondary, fac)

    local federation_rep = faction.get("Federation"):playerStanding()
    if federation_rep < 0 then
        -- If you've made enemies of the Federation, the FLF will not
        -- forgive you until the Federation does.
        new = math.min(new, federation_rep)
    end

    return new
end
