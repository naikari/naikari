--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Animal transport">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>29</priority>
  <chance>10</chance>
  <location>Bar</location>
  <faction>Sirius</faction>
  <cond>planet.cur():class() ~= "0" and planet.cur():class() ~= "1" and planet.cur():class() ~= "2" and planet.cur():class() ~= "3"</cond>
 </avail>
</mission>
--]]
--[[
--
-- MISSION: Animal transport
-- DESCRIPTION: A man asks you to transport a crate of specially bred creatures for
-- his in-law's exotic pet store on another planet. It's a standard fare A-to-B mission,
-- but doing this mission infests the player's current ship with the creatures.
--
--]]

local fmt = require "fmt"
require "jumpdist"
require "missions/neutral/common"


ask_text = _([["Good day to you, captain. I'm looking for someone with a ship who can take this crate here to planet {planet} in the {system} system. The crate contains a colony of rodents I've bred myself, and my in-law has a pet shop on {planet} where I hope to sell them. Upon delivery, you will be paid 200 k¢. Are you interested in the job?"]])

yes_text = _([["Excellent! My in-law will send someone to meet you at the spaceport to take the crate off your hands, and you'll be paid immediately on delivery. Thanks again!"]])

pay_text = _([[As promised, there's someone at the spaceport who accepts the crate. In return, you receive a number of credit chips worth 200 k¢, as per the arrangement. You go back into your ship to put the chips away before heading off to check in with the local authorities. But did you just hear something squeak...?]])

NPCname = _("A Fyrra civilian")
NPCdesc = _("There's a civilian here, from the Fyrra echelon by the looks of him. He's got some kind of crate with him.")

misndesc = _("You've been hired to transport a crate of specially engineered rodents to {planet} in the {system} system.")
misnreward = _("200 k¢")

OSDtitle = _("Animal transport")
OSD = {}
OSD[1] = _("Land on {planet} ({system} system)")

log_text = _([[You successfully transported a crate of rodents for a Fyrra civilian. You could have swore you heard something squeak.]])


function create ()
    -- Get an M-class Sirius planet at least 2 and at most 4 jumps away. If not found, don't spawn the mission.
    local planets = {}
    getsysatdistance( system.cur(), 2, 4,
        function(s)
            for i, v in ipairs(s:planets()) do
                if v:faction() == faction.get("Sirius") and v:class() == "M"
                        and v:canLand() then
                    planets[#planets + 1] = {v, s}
                end
            end
            return false
        end )

    if #planets == 0 then
        misn.finish(false)
    end

    index = rnd.rnd(1, #planets)
    destplanet = planets[index][1]
    destsys = planets[index][2]

    misndesc = fmt.f(misndesc,
            {planet=destplanet:name(), system=destsys:name()})
    OSD[1] = fmt.f(OSD[1], {planet=destplanet:name(), system=destsys:name()})

    misn.setNPC(NPCname, "sirius/unique/rodentman.png", NPCdesc)
end


function accept ()
    if tk.yesno("", fmt.f(ask_text,
            {planet=destplanet:name(), system=destsys:name()})) then
        misn.accept()
        misn.setDesc(misndesc)
        misn.setReward(misnreward)
        misn.osdCreate(OSDtitle, OSD)
        tk.msg("", yes_text)
        misn.markerAdd(destsys, "high")
        hook.land("land")
    else
        misn.finish()
    end
end

function land()
    if planet.cur() == destplanet then
        tk.msg("", pay_text)
        player.pay(200000) -- 200K
        var.push("shipinfested", true)
        addMiscLog( log_text )
        misn.finish(true)
    end
end
