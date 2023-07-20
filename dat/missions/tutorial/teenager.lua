--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="The macho teenager">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <chance>100</chance>
  <done>Outfitter Tutorial</done>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <cond>
   player.numOutfit("Mercenary License") &gt; 0
   and planet.cur():class() ~= "0" and planet.cur():class() ~= "1"
   and planet.cur():class() ~= "2" and planet.cur():class() ~= "3"
  </cond>
 </avail>
 <notes>
  <campaign>Tutorial</campaign>
 </notes>
</mission>
--]]
--[[
--
-- MISSION: The macho teenager
-- DESCRIPTION: A man tells you that his son has taken one of his yachts without permission and
-- is joyriding it with his girlfriend to impress her. Disable the yacht and board it, then take
-- the couple back to the planet (destroying the yacht incurs a penalty)
--
--]]

-- Localization, choosing a language if Naev is translated for non-english-speaking locales.

local fmt = require "fmt"
local mh = require "misnhelper"
require "events/tutorial/tutorial_common"


ask_text = _([["Ah, {player}! Well met, and what perfect timing! Perhaps you can help me resolve another matter.

"You see, it's my son. He's taken a client's yacht to space without their permission, taking along his girlfriend. That boy is such a handful. I'm sure he's trying to show off his piloting skills to impress her, but like myself, he doesn't even have a pilot's license! The nerve, right? I need you to get out there, disable the yacht, and take them both back here. Can you do this for me? I'll pay you {credits} for the trouble."]])

yes_text = _([["Thank you! He doesn't know how to work the hyperdrive, so they won't have left the system. It's a Gawain named Credence.

"It should go without saying, but whatever you do, don't destroy the ship. I don't want to lose my son over this, so make sure you equip some non-lethal weapons, like ion cannons or Medusa missiles, or maybe a weapons ionizer. You should be able to find something suitable at the outfitter; I checked earlier. Use those non-lethal weapons to disable the Credence, then you can retrieve my disobedient son and his girlfriend by either #bdouble-clicking#0 it or by pressing {board_key}. You can just leave the Credence where you find it; I'll have it recovered later.

"Well then, I hope to see you again soon!"]])

board_text = _([[You board the Gawain and find an enraged teenage boy and a disillusioned teenage girl. The boy is furious that you attacked and disabled "his" ship, but when you mention that his mother is quite upset and wants him to come back right now, he quickly pipes down. You march the young couple onto your ship and seal the airlock behind you.]])

pay_text = _([[Terra awaits you at the spaceport. She gives her son and the young lady a stern look and curtly commands them to wait for her in the spaceport hall. The couple droops off, and Terra turns to face you with a smile.

"You've done fantastic work once again, {player}," she says. "As promised, I have deposited your payment into your account. I'm going to give my son a reprimand he'll not soon forget, so hopefully he won't repeat this little stunt anytime soon. Well then, I must be going. Thank you again, and I hope to see you again in the future!"]])

misndesc = _("Terra has asked you to fetch her son and her son's girlfriend, who have taken her client's yacht, the Credence, and are joyriding it in the {system} system. To fetch them, you must use non-lethal weaponry (such as ion cannons, Medusa missiles, or a weapons ionizer) to disable the Credence, then board the Credence by either #bdouble-clicking#0 it or by targeting it and pressing {board_key}.")


function create ()
    curplanet, cursys = planet.cur()

    if not misn.claim(cursys) then
        misn.finish(false)
    end

    if not planet.cur():services()["outfits"] then
        misn.finish(false)
    end

    local ion_available = false
    for i, o in ipairs(planet.cur():outfitsSold()) do
        if o == outfit.get("Ion Cannon")
                or o == outfit.get("Weapons Ionizer") then
            ion_available = true
            break
        end
    end
    if not ion_available then
        misn.finish(false)
    end

    credits = 300000

    misn.setNPC(_("Terra"), "neutral/unique/terra.png",
        _("You see an acquaintance of yours, Terra, looking around for a suitable pilot."))
end


function accept ()
    if tk.yesno("", fmt.f(ask_text,
            {player=player.name(), credits=fmt.credits(credits)})) then
        misn.accept()

        misn.setTitle(_("Teenager's Joyride"))
        misn.setDesc(fmt.f(misndesc,
            {system=cursys:name(), board_key=tutGetKey("board")}))
        misn.setReward(fmt.credits(credits))

        local osd_msg = {
            fmt.f(_("Fly to the {system} system"), {system=cursys:name()}),
            _("Disable Gawain Credence by using non-lethal weaponry (such as ion cannons, Medusa missiles, or a weapons ionizer)"),
            fmt.f(_("Board Gawain Credence by double-clicking on it or by targeting it and pressing {board_key}"),
                {board_key=naev.keyGet("board")}),
            fmt.f(_("Land on {planet} ({system} system)"),
                {planet=curplanet:name(), system=cursys:name()}),
        }
        misn.osdCreate(_("Teenager's Joyride"), osd_msg)

        tk.msg("", fmt.f(yes_text, {board_key=tutGetKey("board")}))

        hook.enter("enter")

        targetlive = true
    else
        misn.finish()
    end
end

function enter()
    if not targetlive then
        return
    end

    if system.cur() == cursys then
        misn.osdActive(2)

        -- Disable spawning of pirates and hostiles.
        pilot.clear()
        pilot.toggleSpawn("Pirate", false)
        for fname, presence in pairs(system.cur():presences()) do
            local f = faction.get(fname)
            if f:playerStanding() < 0 then
                pilot.toggleSpawn(f, false)
            end
        end

        local dist = rnd.rnd() * system.cur():radius() * 0.8
        local angle = rnd.rnd() * 2 * math.pi
        local location = vec2.new(dist * math.cos(angle), dist * math.sin(angle))
        target = pilot.add("Gawain", "Civilian", location, _("Credence"))
        target:outfitRm("all")
        target:outfitAdd("Milspec Aegis 3601 Core System")
        target:outfitAdd("Beat Up Small Engine")
        target:outfitAdd("Unicorp X-2 Light Plating")
        target:outfitAdd("Small Shield Booster")
        target:outfitAdd("Emergency Shield Booster")
        target:outfitAdd("Reactor Class I")
        target:outfitAdd("Shield Capacitor", 2)
        target:control()
        target:memory().aggressive = true
        target:setHilight()
        target:setVisplayer()
        target:setNoClear()

        hook.pilot(target, "idle", "targetIdle")
        hook.pilot(target, "disable", "targetDisabled")
        hook.pilot(target, "undisable", "targetUndisabled")
        hook.pilot(target, "exploded", "targetExploded")
        hook.pilot(target, "board", "targetBoard")
    else
        misn.osdActive(1)
    end
end


function targetIdle(p)
    local location = p:pos()
    local dist = 750
    local angle = rnd.rnd() * 2 * math.pi
    local newlocation = vec2.new(dist * math.cos(angle), dist * math.sin(angle))
    p:taskClear()
    p:moveto(location + newlocation, false, false)
end


function targetDisabled()
    if targetlive then
        misn.osdActive(3)
    end
end


function targetUndisabled()
    if targetlive then
        misn.osdActive(2)
    end
end


function targetExploded()
    mh.showFailMsg(_("The Credence has been destroyed!"))
    misn.finish(false)
end


function targetBoard(p, boarder)
    if boarder ~= player.pilot() then
        return
    end
    player.unboard()

    targetlive = false

    tk.msg("", board_text)

    p:setHilight(false)
    p:setVisplayer(false)
    p:disable()
    p:hookClear()

    local c = misn.cargoNew(N_("Teenagers"), N_("Disillusioned teenagers."))
    cargoID = misn.cargoAdd(c, 0)

    misn.osdActive(4)

    hook.land("land")
end


function land()
    if planet.cur() == curplanet and not targetlive then
        tk.msg("", fmt.f(pay_text, {player=player.name()}))
        player.pay(credits)
        misn.finish(true)
    end
end


function abort()
    if target ~= nil and target:exists() then
        target:control(false)
        target:setHilight(false)
        target:setVisplayer(false)
    end
    misn.finish(false)
end
