--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Shadow Vigil">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <chance>100</chance>
  <location>None</location>
 </avail>
 <notes>
  <done_evt name="Shadowcomm">Triggers</done_evt>
  <campaign>Shadow</campaign>
 </notes>
</mission>
--]]
--[
-- This is the second mission in the "shadow" series.
--]]

local fmt = require "fmt"
local fleet = require "fleet"
require "proximity"
require "nextjump"
require "selectiveclear"
require "missions/shadow/common"


ask_text = _([["Greetings, {player}," the pilot of the Vendetta says to you as soon as you answer his hail. "I have been looking for you on behalf of an acquaintance of yours. She wishes to meet with you at a place of her choosing, and a time of yours. It involves a proposition that you might find interesting if you don't mind sticking your neck out." You frown at that, but ask the pilot where this acquaintance wishes you to go anyway.

"Fly to the {system} system," he replies. "She will meet you there. There's no rush, but I suggest you go see her at the earliest opportunity." The screen blinks out and the Vendetta goes about its business, paying you no more attention. It seems there's someone out there who wants to see you, and there's only one way to find out what about. Will you respond to the invitation?]])

noclaim_text = _([["Oh! Sorry, I mistook you for somebody else. Here, I know you're busy and I've interrupted you, so as an apology I've deposited a small sum of credits into your account." The strange pilot ceases communication, leaving you stunned, but not as stunned as when you find that a small sum of credits has indeed been deposited into your account from an unknown source. Odd, how did they know your account details?…]])

dock_text = _([[You dock with the Seiryuu and shut down your engines, now knowing that the person you're meeting is in fact Rebina, the mysterious woman you had met before near Klantar. At the airlock, you are welcomed by two nondescript crewmen in gray uniforms who tell you to follow them into the ship. They lead you thru corridors and passages that seem to lead to the bridge, allowing you to get a good view at the ship's interior. You can't help but look around in wonder. The ship isn't anything you're used to seeing. While some parts can be identified as such common features as doors and viewports, a lot of the equipment in the compartments and niches seems strange, almost alien to you. Clearly the Seiryuu is no ordinary ship.

At the bridge, you immediately spot the Seiryuu's captain, Rebina, seated in the captain's chair. The chair, too, is designed in the strange fashion that you've been seeing all over the ship. It sports several controls that you can't place, despite the fact that you're an experienced pilot yourself. The rest of the bridge is no different. All the regular stations and consoles seem to be there, but there are some others whose purpose you can only guess.

Rebina swivels the chair around and smiles when she sees you. "Ah, {player}," she says. "How good of you to come. I was hoping you'd get my invitation, since I was quite pleased with your performance last time. And I'm not the only one. As it turns out, Jorek seems to have taken a liking to you as well. He may seem rough, but he's a good man at heart."]])

dock2_text = _([[You choose not to say anything, but Rebina seems to have no trouble reading what's on your mind. "Ah yes, the ship. It's understandable that you're surprised at how it looks. I can't divulge too much about this technology or how we came to possess it, but suffice to say that we don't buy from the regular outlets. We have need for… an edge in our line of business." Grateful for the opening, you ask Rebina what exactly this line of business is. Rebina flashes you a quick smile and settles into the chair for the explanation.

"The organization I'm part of is known as the Four Winds, or rather, not known as the Four Winds." She gestures dismissively. "We keep a low profile. You won't have heard of us before, I'm sure. At this point I should add that many who do know us refer to us as the 'Shadows', but this is purely a colloquial name. It doesn't cover what we do, certainly. In any event, you can think of us as a private operation with highly specific objectives. At this point that is all I can tell you." She leans forward and fixes you with a level stare. "Speaking of specific objectives, I have one such objective for you.]])

dock3_text = _([["You may not know this, but there are tensions between the Imperial and Dvaered militaries. For some time now there have been incidents on the border, conflicts about customs, pilots disrespecting each other's flight trajectories, that sort of thing. It hasn't become a public affair yet, and the respective authorities don't want it to come to that. This is why they've arranged a secret diplomatic meeting to smooth things over and make arrangements to deëscalate the situation.

"This is where we come in. Without going into the details, suffice to say we have an interest in making sure that this meeting does not meet with any unfortunate accidents. However, for reasons I can't explain to you now, we can't become involved directly. That's why I want you to go on our behalf. You will essentially be flying an escort mission. You will rendezvous with a small wing of private fighters, who will take you to your charge, the Imperial representative. Once there, you will protect him from any threats you might encounter, and see him safely to Dvaered space. As soon as the Imperial representative has joined his Dvaered colleague, your mission will be complete and you will report back here.

"That will be all. I offer you a suitable monetary reward should you choose to accept. Can I count on you to undertake this task?"]])

refusetext = _([[Captain Rebina sighs. "I see. I don't mind admitting that I hoped you would accept, but it's your decision. I won't force you to do anything you feel uncomfortable with. My agents will be in touch in case you change your mind." Mere minutes later you find yourself back in your cockpit, and the Seiryuu is leaving. It doesn't really come as a surprise that you can't find any reference to your rendezvous with the Seiryuu in your flight logs.

Suddenly, you feel a strange headache. What were you doing just now?… You take a look at your flight logs, which say you were running away from pirates and narrowly escaped. You figure you must have hit your head during the encounter and carry on with your business, whatever that may be.]])

accepttext = _([["Excellent, {player}." Rebina smiles at you. "I've told my crew to provide your ship's computer with the necessary navigation data. Also, note that I've taken the liberty of installing a specialized IFF transponder onto your ship. Don't pay it any heed, it will only serve to identify you as one of the escorts. For various reasons, it is best that you refrain from communication with the other escorts as much as possible.

"That will be all for now, {player}. You have your assignment; I suggest you go about it." You are politely but efficiently escorted off the Seiryuu's bridge. Soon you settle back in your own cockpit chair, ready to do what was asked of you.]])

brief_text = _([[After finishing docking procedures, you locate and meet up with the Four Winds pilots you will be working with, and the diplomat you will be escorting. The Four Winds pilots mostly keep to themselves and curtly but politely inform you that they will meet you out in space.]])

diplomat_death_text = _([[Before you can even react, the other Four Winds escorts open fire on the diplomat. By the time you've processed what's happened, the traitorous pilots are already making their escape. You wonder if you should try to capture one of the traitors and interrogate them. In any case, you will need to report what happened to Rebina.]])

pay_text = _([[Captain Rebina angrily drums her fingers on her captain's chair as she watches the reconstruction made from your sensor logs. Her eyes narrow when the escorts suddenly open fire on the diplomatic vessel they were meant to protect. "This is bad, {player}," she says when the replay shuts down. "Worse than I had even thought possible. The death of the Imperial diplomat is going to spark a political incident, with the Empire accusing the Dvaered of treachery and the Dvaered accusing the Empire of a false-flag operation." She stands up and begins pacing up and down the Seiryuu's bridge. "But that's not the worst of it. You saw what happened. The diplomat was killed by their own escorts, by Four Winds operatives! This is an outrage!"

Captain Rebina brings herself back under control thru an effort of will. "{player}, this does not bode well. We have a problem, and I fear I'm going to need your help again before the end. But not yet. I have a lot to do. I have to get to the bottom of this, and I have to try to keep this situation from escalating into a disaster. I will contact you again when I know more. In the meantime, you will have plenty of time to spend your reward; it's already in your account."

Following this, you are swiftly escorted off the Seiryuu. Back in your cockpit, you can't help but feel a little anxious about this Four Winds. Who are they, what do they want, and what is your role in all of it? Only time will tell.]])

disable_text = _([[After managing to bypass the ship's security system, you enter the cockpit and notice that the fighter has been sabotaged and might soon explode. You also see the pilot unconscious on the floor. After verifying by checking his vitals that he is already dead, you make a run for it so you don't get caught in the ensuing explosion.]])

disable_again_text = _([[You try to board another one of the Four Winds escorts hoping for a more successful interrogation, but the ship begins self-destructing before you can complete docking procedures.]])

landfailtext = _("You have landed when you were supposed to escort the diplomat, failing your mission with the Four Winds.")

osd_title = _("Shadow Vigil")


misn_desc = _([[Captain Rebina of the Four Winds has asked you to help Four Winds agents protect an Imperial diplomat.]])
misn_reward = _("A sum of credits")

osd_title0 = _("Mysterious Meeting")
misn_desc0 = _("You have been invited to a meeting in the {system} system, thô you don't know with whom.")
misn_reward0 = _("Unknown")

log_text_intro = _([[Captain Rebina has revealed some information about the organization she works for. "The organization I'm part of is known as the Four Winds, or rather, not known as the Four Winds. We keep a low profile. You won't have heard of us before, I'm sure. At this point I should add that many who do know us refer to us as the 'Shadows', but this is purely a colloquial name. It doesn't cover what we do, certainly. In any event, you can think of us as a private operation with highly specific objectives. At this point that is all I can tell you."]])
log_text_success = _([[Your attempt to escort a diplomat for the Four Winds was thwarted by traitors on the inside. Other Four Winds escorts opened fire on the diplomat, killing him. Captain Rebina has said that she may need your help again at a later date.]])


-- After having accepted the mission from the hailing Vendetta
function create()
    stage = 0
    rebinasys = system.get("Pas")
    startpla, startsys = planet.get("Amphion")
    destpla, destsys = planet.get("Praxis")

    local claimsys = {startsys}
    for i, jp in ipairs(startsys:jumpPath(destsys)) do
        claimsys[#claimsys + 1] = jp:dest()
    end
    if not misn.claim(claimsys) then
        tk.msg("", noclaim_text)
        -- Small consolation pay
        player.pay(10000)
        misn.finish(false)
    end

    if not tk.yesno("", fmt.f(ask_text,
            {player=player.name(), system=rebinasys:name()})) then
        misn.finish(false)
    end

    misn.accept()

    misn.setTitle(osd_title0)
    misn.setDesc(fmt.f(misn_desc0, {system=rebinasys:name()}))
    misn.setReward(misn_reward0)

    marker = misn.markerAdd(rebinasys, "high")
    local osd_msg = {
        fmt.f(_("Fly to the {system} system and dock with (board) Seiryuu"),
            {system=rebinasys:name()}),
    }
    misn.osdCreate(osd_title0, osd_msg)

    hook.enter("enter")
end


function meeting()
    tk.msg("", fmt.f(dock_text, {player=player.name()}))
    tk.msg("", dock2_text)
    if tk.yesno("", dock3_text) then
        accept_m()
    else
        tk.msg("", refusetext)
        misn.finish(false)
    end
end


function accept_m()
    stage = 1
    nextsys = getNextSystem(system.cur(), destsys)
    
    accepted = false
    missend = false
    landfail = false

    tk.msg("", fmt.f(accepttext, {player=player.name()}))

    misn.setTitle(osd_title)
    misn.setDesc(misn_desc)
    misn.setReward(misn_reward)

    marker = misn.markerAdd(startsys, "low", startpla)
    local osd_msg = {
        fmt.f(_("Land on {planet} ({system} system)"),
                {planet=startpla:name(), system=startsys:name()}),
        fmt.f(_("Escort the diplomat to {planet} ({system} system)"),
                {planet=destpla:name(), system=destsys:name()}),
    }
    misn.osdCreate(osd_title, osd_msg)
    
    hook.land("land")
    hook.jumpout("jumpout")
end


function update_osd()
    if system.cur() == destsys then
        local osd_desc = {
            fmt.f(_("Protect the diplomat and wait for them to land on {planet}"),
                {planet=destpla:name()}),
            fmt.f(_("Land on {planet}"), {planet=destpla:name()}),
        }
        misn.osdCreate(osd_title, osd_desc)
    else
        local sys = getNextSystem(system.cur(), destsys)
        local jumps = system.cur():jumpDist(destsys)
        local osd_desc = {
            fmt.f(_("Protect the diplomat and wait for them to jump to {system}"),
                {system=sys:name()}),
            fmt.f(_("Jump to {system}"), {system=sys:name()}),
        }
        if jumps > 1 then
            osd_desc[3] = fmt.f(
                    n_("{remaining} more jump after this one",
                        "{remaining} more jumps after this one", jumps - 1),
                    {remaining=fmt.number(jumps - 1)})
        end
        misn.osdCreate(osd_title, osd_desc)
    end
end


function jumpout()
    origin = system.cur()
    nextsys = getNextSystem(system.cur(), destsys)
end


function land()
    if stage == 2 then
        tk.msg("", landfailtext)
        misn.finish(false)
    elseif planet.cur() == startpla and stage == 1 then
        tk.msg("", brief_text)

        stage = 2
        origin = planet.cur()
        nextsys = system.cur()
        jumped = true

        misn.markerRm(marker)
        update_osd()
    end
end


function enter()
    if stage == 2 then
        if jumped and system.cur() == nextsys then
            if system.cur() == destsys then
                pilot.toggleSpawn(false)
                pilot.clear()
            end
            spawnDiplomat()
        else
            fail(_("MISSION FAILED: You abandoned the diplomat."))
        end
    elseif system.cur() == rebinasys and (stage == 0 or stage == 3) then
        pilot.toggleSpawn(false)
        pilot.clear()

        local f = faction.dynAdd("Mercenary", N_("Four Winds"))
        seiryuu = pilot.add("Starbridge", f, vec2.new(1500, -2000),
                _("Seiryuu"), {ai="trader", noequip=true})
        seiryuu:control()
        seiryuu:setActiveBoard()
        seiryuu:setInvincible()
        seiryuu:setHilight()
        seiryuu:setVisplayer()
        seiryuu:setNoClear()
        hook.pilot(seiryuu, "board", "board")
    end
end


function spawnDiplomat()
    local diplomat = pilot.add("Gawain", "Civilian", origin,
            _("Imperial Diplomat"), {naked=true})

    local f = faction.dynAdd("Mercenary", N_("Four Winds"))
    f:dynEnemy(faction.get("Pirate"))
    local escorts = fleet.add(3, "Vendetta", f, origin,
            _("Four Winds Escort"), {ai="escort"}, diplomat)
    for i, p in ipairs(escorts) do
        p:setInvincible()
        p:setVisplayer()
        p:setNoClear()
    end

    diplomat:control()
    diplomat:outfitAdd("Beat Up Small Engine")

    if system.cur() == destsys then
        diplomat:outfitAdd("Previous Generation Small Systems")
        diplomat:outfitAdd("Patchwork Light Plating")
        diplomat:setNoJump()
        diplomat:setNoLand()

        diplomat:land(destpla)
        hook.timer(5, "traitor_timer", diplomat)
    else
        diplomat:outfitAdd("Milspec Aegis 3601 Core System")
        diplomat:outfitAdd("S&K Light Combat Plating")
        diplomat:outfitAdd("Small Shield Booster")
        diplomat:outfitAdd("Reverse Thrusters")
        diplomat:outfitAdd("Milspec Scrambler")
        diplomat:outfitAdd("Shield Capacitor", 2)

        diplomat:hyperspace(getNextSystem(system.cur(), destsys))
        hook.pilot(diplomat, "attacked", "diplomat_attacked", escorts)
    end

    diplomat:setHealth(100, 100)
    diplomat:setEnergy(100)
    diplomat:setFuel(true)
    diplomat:setSpeedLimit(130)
    -- Unset invincibility meant for the escorts
    diplomat:setInvincible(false)
    diplomat:setInvincPlayer()
    diplomat:setVisible()
    diplomat:setHilight()
    diplomat:setNoClear()
    diplomat:setFriendly()

    jumped = false
    diplomat_shutup = false

    hook.pilot(diplomat, "death", "diplomat_death", escorts)
    hook.pilot(diplomat, "jump", "diplomat_jump", escorts)
    update_osd()
end


function traitor_timer(leader)
    player.pilot():setInvincible()
    player.pilot():control()
    player.cinematics()
    camera.set(leader, true)
    leader:control(false)
    for i, p in ipairs(leader:followers()) do
        if p:exists() then
            p:setLeader(nil)
            p:changeAI("baddie_norun")
            p:control()
            p:attack(leader)
        end
    end
end


function diplomat_attacked(leader, attacker, damage, escorts)
    if diplomat_shutup then
        return
    end

    leader:broadcast(_("Diplomatic vessel under attack! Requesting assistance!"))
    for i, p in ipairs(escorts) do
        leader:msg(p, "e_attack", attacker)
    end

    diplomat_shutup = true
    hook.timer(5, "diplomat_shutup_timer")
end


function diplomat_shutup_timer()
    diplomat_shutup = false
end


function diplomat_death(leader, attacker, escorts)
    for i, p in ipairs(escorts) do
        if p:exists() then
            p:setInvincible(false)
            p:setVisplayer(false)
            p:control()
            p:hyperspace()
            hook.pilot(p, "board", "board_escort")
        end
    end

    if system.cur() == destsys then
        hook.timer(3, "diplomat_death_timer")
    else
        fail(_("MISSION FAILED: Imperial Diplomat died."))
    end
end


function diplomat_death_timer()
    player.pilot():setInvincible(false)
    player.pilot():control(false)
    player.cinematics(false)
    camera.set()

    stage = 3
    pilot.toggleSpawn(true)
    misn.markerAdd(rebinasys, "low")
    local osd_msg = {
        fmt.f(_("Fly to the {system} system and dock with (board) Seiryuu"),
            {system=rebinasys:name()}),
    }
    misn.osdCreate(osd_title, osd_msg)

    tk.msg("", diplomat_death_text)
end


function diplomat_jump(leader, jp, escorts)
    for i, p in ipairs(escorts) do
        if p:exists() then
            p:setLeader(nil)
            p:control()
            p:hyperspace(getNextSystem(system.cur(), destsys))
        end
    end

    jumped = true
    misn.osdActive(2)
end


function board(p, boarder)
    if boarder ~= player.pilot() then
        return
    end
    player.unboard()

    pilot.toggleSpawn(true)

    seiryuu:changeAI("flee")
    seiryuu:setHilight(false)
    seiryuu:setActiveBoard(false)
    seiryuu:control(false)

    if stage == 0 then
        misn.markerRm(marker)
        meeting()
    elseif stage == 3 then
        tk.msg("", fmt.f(pay_text, {player=player.name()}))
        player.pay(700000)
        shadow_addLog(log_text_intro)
        shadow_addLog(log_text_success)
        misn.finish(true)
    end
end


function board_escort(p, boarder)
    if boarder ~= player.pilot() then
        return
    end
    player.unboard()
    if not boarded_escort then
        tk.msg("", disable_text)
    else
        tk.msg("", disable_again_text)
    end
    p:setHealth(0, 0) -- Make ship explode
    boarded_escort = true
end


function fail(message)
   if message ~= nil then
      -- Pre-colourized, do nothing.
      if message:find("#") then
         player.msg(message)
      -- Colourize in red.
      else
         player.msg("#r" .. message .. "#0")
      end
   end
   misn.finish(false)
end
