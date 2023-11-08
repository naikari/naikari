require "factions/standing/skel"


_fdelta_distress = {-0.5, 0} -- Maximum change constraints
_fdelta_kill = {-10, 0.2} -- Maximum change constraints


function faction_hit(current, amount, source, secondary, fac)
    local new = default_hit(current, amount, source, secondary, fac)

    local frontier_rep = faction.get("Frontier"):playerStanding()
    if frontier_rep < 0 then
        -- If you've made enemies of the Frontier, the FLF will not
        -- forgive you until the Frontier does.
        new = math.min(new, frontier_rep)
    end

    return new
end
