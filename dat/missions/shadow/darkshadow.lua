--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Dark Shadow">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <chance>100</chance>
  <location>None</location>
 </avail>
 <notes>
  <done_evt name="Shadowcomm2">Triggers</done_evt>
  <campaign>Shadow</campaign>
 </notes>
</mission>
--]]
--[[
-- This is the third mission in the "shadow" series, featuring the return of SHITMAN.
--]]

local fmt = require "fmt"
local fleet = require "fleet"
require "proximity"
require "missions/shadow/common"


text = {}

start_text = _([[Suddenly, out of nowhere, one of the dormant panels in your cockpit springs to life. It shows you a face you've never seen before in your life, but you recognize the plain grey uniform as belonging to the Four Winds.

"Hello {player}," the face says. "You must be wondering who I am and how it is I'm talking to you like this. Neither question is important. What is important is that Captain Rebina has urgent need of your services. You are to meet her on the Seiryuu, which is currently near {planet} in the {system} system. Please don't ask any questions now. We expect to see you as quickly as you can make your way here."

The screen goes dead again. You decide to make a note of this in your log. Perhaps it would be a good ideä to visit the Seiryuu once more, if only to find out how they got a private line to your ship.]])

explain_text = _([[You make your way thru the now familiar corridors of the Seiryuu. You barely notice the strange environment anymore. It seems unimportant compared to the strange events that surround your every encounter with these Four Winds.

You step onto the bridge, where Captain Rebina is waiting for you. "Welcome back, {player}," she says. "I'm pleased to see that you decided to respond to our communication. I doubt you would have come here if you weren't willing to continue to aid us. Your presence here confirms that you are a reliable partner, so I will treat you accordingly."

The captain motions you to take a seat at what looks like a holotable in the center of the bridge. "Before I tell you what I've called you here for, I feel I should explain to you in full who we are, what we do and what your part in all this is." She takes a seat opposite from yours, and leans on the holotable. "As I've said before, we are the Four Winds. Our organization is a very secretive one, as you've experienced firsthand. Very few outside our ranks know of our existence, and now you're one of those few.]])

-- Note: Rebina wrongly believing that nuclear weapons were never used
-- is intentional. She has been lied to; the Four Winds are actually an
-- elaborate Proteron espionage scheme which has had a breakdown in
-- command since the Proteron are cut off.
fourwinds_origin_text = _([["The Four Winds are old, {player}. Ancient, even. The movement dates back to old Earth. We have been with human civilization thruout the ages, at first only in the Eastern nations, later establishing a foothold worldwide. Our purpose was to guide humanity, prevent it from making mistakes it could not afford to make. We never came out in the open, we always worked behind the scenes, from the shadows. We were diplomats, scientists, journalists, politicians' spouses, sometimes even assassins. We used any means necessary to gather information and avert disaster, when we could.

"We accomplished a lot, but no one would know since they don't know how history could have turned out. We prevented nuclear weapons from ever being used on Earth when humanity discovered them in ancient times. We foiled the sabotage attempts on several of the colony ships launched during the First Growth. We ensured the Empire's success in the faction wars. That said, we had our first major failure with the Incident, which took us by surprise."]])

fourwinds_info_text = _([[Captain Rebina sits back in her chair and heaves a sigh. "I think that may have been when things started to change. We used to be committed to our purpose, but apparently things are different now. No doubt you remember what happened to the diplomatic exchange between the Empire and the Dvaered some time ago. Well, suffice to say that increasing the tension between the two is definitely not part of our mandate. In fact, it's completely at odds with what we stand for. And that was not just an isolated incident either. Things have been happening that suggest Four Winds involvement, things that bode ill."

She activates the holotable, and it displays four cruisers, all seemingly identical to the Seiryuu, thô you notice subtle differences in the hull designs. "These are our flagships. Including this ship, they are the Seiryuu, Suzaku, Byakko and Genbu. I'm given to understand that these names, as well as our collective name, have their roots in ancient Asian mythology." The captain touches another control and four portraits appear, superimposed over the ships. "These are the four captains of the flagships, which by extension makes them the highest level of authority within the Four Winds which acts in a direct capacity. You know me. The other three are called Giornio, Zurike and Farett. We all take orders from a secret operational organizer who we are not allowed to know the identity of, for reasons of security.]])

objective_text = _([["It is my belief that one or more of my fellow captains have abandoned their mission, and are misusing their resources for a different agenda. I have been unable to find out the details of Four Winds missions that I did not command myself, which is a bad sign. I am being stonewalled, and I don't like it. I want to know what's going on, {player}, and you're going to help me do it.

"I have sent Jorek on a recon mission to {planet} in the {system} system. He hasn't reported back to me so far, and that's bad news. Jorek is a reliable agent. If he fails to meet a deadline, then it means he is tied down by factors outside of his control, or worse. I want you to find him. Your position as an outsider will help you fly below the radar of potentially hostile Four Winds operatives. You must go to {planet} and contact Jorek if you can, or find out where he is if you can't."

Captain Rebina turns off the holotable and stands up, a signal that this briefing is over. You are seen to your ship by a gray-uniformed crewman. You sit in your cockpit for a few minutes before disengaging the docking clamp. What Captain Rebina has told you is a lot to take in. A shadowy organization that guides humanity behind the scenes? And parts of that organization going rogue? The road ahead could well be a bumpy one.]])

barman_text = _([[You meet the barman's stare. He hesitates for a moment, then speaks up. "Hey… are you {player} by any chance?" You tell him that yes, that's you, and ask how he knows your name. "Well," he answers, "your description was given to me by an old friend of mine. His name is Jarek. Do you know him?" You tell him that you don't know anyone by the name of Jarek, but you do know a man named Jorek. The barman visibly relaxes when he hears that name.

"Ah, good. You're the real deal then. Can't be too careful in times like these, you know. Anyway, old Jorek was here, but he couldn't stay. He told me to keep an eye out for you, said you'd be coming to look for him." The barman glances around to make sure nobody is within earshot, even thô the bar's music makes it difficult to overhear anyone who isn't standing right next to you. "I have a message for you. Go to the {system} system and land on {planet}. Jorek will be waiting for you there. But you better be ready for some trouble. I don't know what kind of trouble it is, but Jorek is never in any kind of minor trouble. Don't say I didn't warn you." You thank the barman, pay for your drink and prepare to head back to your ship, wondering whether your armaments will be enough to deal with whatever trouble Jorek is in.]])

jorek_text = _([["Well hello there {player}," Jorek says when you approach his table. "It's about damn time you showed up. I've been wastin' credits on this awful swill for days now." Not at all surprised that Jorek is still as disagreeable as the last time you encountered him, you decide to ask him to explain the situation, beginning with how he knew that it was you who would be coming for him. Jorek laughs heartily at that. "Ha! Of course it was going to be you. Who else would that lass Rebina send? She's tough as nails, that girl, but I know how her mind works. She's cornered, potential enemies behind every door in the organization. And you have done us a couple of favors already. In fact, you're the only one she can trust outside her own little circle of friends, and right now I'm not too sure how far she trusts those. Plus, she really has a keen nose when it comes to sniffin' out reliable people, and she knows it. Yeah, I knew she'd send you to find me."

That answers one question. But you still don't know why Jorek hasn't been reporting in like he should have. Jorek answers your question as if reading your mind. "Yeah, right, about that. You know about the deal with the other branches getting too big for their britches? Good. Well, I've been lookin' into that, pokin' my nose into their business. Since I'm dealin' with my fellow Shadows here, I couldn't afford to give myself away. So that's that. But there's more.]])

jorek2_text = _([["I dunno if you've seen them on your way here, but there's guys of ours hangin' around in the system. And when I say guys of ours, I mean guys of theirs, since they sure ain't our guys any more. They've been on my ass ever since I left Manis, so I think I know what they want. They want to get me and see what I know, or maybe they just want to blow me into space dust. Either way, I need you to help me get out of this rat hole."

You ask Jorek why he didn't just lie low on some world until the coast was clear, instead of coming to this station. "It ain't that simple," Jorek sighs. "See, I got an inside man. A guy in their ranks who wants out. I need to get him back to the old girl so he can tell her what he knows firsthand. He's out there now, with the pack, so we need to pick him up on our way out. Now, there's two ways we can do this. We can either go in fast, grab the guy, get out fast before the wolves get us. Or we can try to fight our way thru. Let me warn you thô, these guys mean business, and they're not your average pirates. Unless you got a really tough ship, I recommend you run.

"Well, there you have it. I'll fill you in on the details once we're spaceborne. Show me to your ship, buddy, and let's get rollin'. I've had enough of this damn place."]])

board_text = _([[You board the Four Winds vessel, and as soon as the airlock opens a nervous looking man enters your ship. He eyes you warily, but when he sees that Jorek is with you his tension fades. "Come on, {player}," Jorek says. "Let's not waste any more time here. We got what we came for. Now let's give these damn vultures the slip, eh?"]])

ambush_text = _([[Suddenly, your long range sensors pick up a ship jumping in. Jorek checks the telemetry beside you. Suddenly, his eyes go wide and he groans. The Four Winds informant turns pale.

"Oh, damn it all," Jorek curses. "{player}, that's the Genbu, Giornio's flagship. I never expected him to take an interest in me personally! Damn, this is bad. Listen, if you have anything to boost our speed, now would be the time. We got to get outta here as if all hell was hot on our heels, which it kinda is! If that thing catches us, we're toast. I really mean it, you don't wanna get into a fight against her, not on your own. Get your ass movin' to Sirius space. Giornio ain't gonna risk getting into a scrap with the Sirius military, so we'll be safe once we get there. Come on, what are you waitin' for? Step on it!"]])

pay_text = _([[You find yourself back on the Seiryuu, in the company of Jorek and the Four Winds informant. The informant is escorted deeper into the ship by gray-uniformed crew members, while Jorek takes you up to the bridge for a meeting with Captain Rebina. "Welcome back, Jorek, {player}," Rebina greets on your arrival. "I've already got a preliminary report on the situation, but let's have ourselves a proper debriefing. Have a seat."

You and Jorek sit down at the holotable in the middle of the bridge and report on the events surrounding Jorek's retrieval. When you're done, Captain Rebina calls up a schematic view of the Genbu from the holotable. "It would seem that Giornio and his comrades have a vested interest in keeping me away from the truth. It's a good thing you managed to get out of that ambush and bring me that informant. I do hope he'll be able to shed more light on the situation. I've got a bad premonition, a hunch that we're going to have to act soon if we're going to avert disaster, whatever that may be. I trust that you will be willing to aid us again when that time comes, {player}. We're going to need all the help we can get. For now, you will find a generous amount of credits in your account. I will be in touch when things are clearer."

You return to your ship and undock from the Seiryuu. You reflect that you had to run for your life this time around, and by all accounts, things will only get worse with the Four Winds in the future. Many people would be nervous in your position.]])

joefailtext = _([[Jorek is enraged. "Dammit, {player}! I told you to pick up that informant on the way! Too late to go back now. I'll have to think of somethin' else. I'm disembarkin' at the next spaceport, don't bother taking me back to the Seiryuu."]])

patrolcomm = _("All pilots, we've detected McArthy on that ship! Break and intercept!")

NPCdesc = _("The barman seems to be eyeing you in particular.")

Jordesc = _("There he is, Jorek McArthy, the man you've been chasing across half the galaxy. What he's doing on this piece of junk is unclear.")

-- Mission info stuff
osd_title = _("Dark Shadow")
osd_msg_0 = _("Fly to the {system} system and dock with (board) Seiryuu by double-clicking on it")
osd_msg_1 = _("Land on {planet} ({system} system) and look for Jorek at the bar")
osd_msg_2 = _("Board the Four Winds Informant's ship without getting spotted")

misn_desc1 = _([[You have been summoned to the {system} system, where the Seiryuu is supposedly waiting for you.]])
misn_desc2 = _([[You have been tasked by Captain Rebina of the Four Winds to assist Jorek McArthy.]])
misn_reward = _("A sum of money")

log_text_intro = _([[Captain Rebina has further explained the organization she works for. "As I've said before, we are the Four Winds. Our organization is a very secretive one, as you've experienced firsthand. Very few outside our ranks know of our existence, and now you're one of those few.

"The Four Winds are old, {player}. Ancient, even. The movement dates back to old Earth. We have been with human civilization thruout the ages, at first only in the Eastern nations, later establishing a foothold worldwide. Our purpose was to guide humanity, prevent it from making mistakes it could not afford to make. We never came out in the open, we always worked behind the scenes, from the shadows. We were diplomats, scientists, journalists, politicians' spouses, sometimes even assassins. We used any means necessary to gather information and avert disaster, when we could.

"We accomplished a lot, but no one would know since they don't know how history could have turned out. We prevented nuclear weapons from ever being used on Earth when humanity discovered them in ancient times. We foiled the sabotage attempts on several of the colony ships launched during the First Growth. We ensured the Empire's success in the faction wars. That said, we had our first major failure with the Incident, which took us by surprise."]])

log_text_suspicion = _([[Rebina has reported that she suspects there are traitors among the four Four Winds captains. "These are our flagships. Including this ship, they are the Seiryuu, Suzaku, Byakko and Genbu. I'm given to understand that these names, as well as our collective name, have their roots in ancient Asian mythology. These are the four captains of the flagships, which by extension makes them the highest level of authority within the Four Winds which acts in a direct capacity. You know me. The other three are called Giornio, Zurike and Farett. We all take orders from a secret operational organizer who we are not allowed to know the identity of, for reasons of security.

"It is my belief that one or more of my fellow captains have abandoned their mission, and are misusing their resources for a different agenda. I have been unable to find out the details of Four Winds missions that I did not command myself, which is a bad sign. I am being stonewalled, and I don't like it."]])

log_text_succeed = _([[You found Jorek and successfully retrieved his informant on behalf of Captain Rebina. The Genbu ambushed you, but you managed to get away and dock the Seiryuu. Captain Rebina remarked on the situation. "I've got a bad premonition, a hunch that we're going to have to act soon if we're going to avert disaster, whatever that may be. I trust that you will be willing to aid us again when that time comes, {player}. We're going to need all the help we can get. For now, you will find a modest amount of credits in your account. I will be in touch when things are clearer."

She said she may need your services again in the future.]])


function create()
    seirplanet, seirsys = planet.get("Edergast")
    jorekplanet1, joreksys1 = planet.get("Manis")
    jorekplanet2, joreksys2 = planet.get("The Wringer")
    ambushsys = system.get("Herakin")
    genbusys = system.get("Anrique")

    if not misn.claim({joreksys2, ambushsys, genbusys}) then
        misn.finish(false)
    end

    -- Avoid weirdness of telling the player to go to current system.
    if system.cur() == seirsys then
        misn.finish(false)
    end

    misn.accept()

    tk.msg("", fmt.f(start_text,
            {player=player.name(), planet=seirplanet:name(),
                system=seirsys:name()}))

    misn.setTitle(osd_title)
    misn.setDesc(fmt.f(misn_desc1, {system=seirsys:name()}))
    misn.setReward(_("Unknown"))

    local osd_msg = {
        fmt.f(osd_msg_0, {system=seirsys:name()})
    }
    misn.osdCreate(osd_title, osd_msg)

    stage = 1

    marker = misn.markerAdd(seirsys, "high")

    hook.enter("enter")
end


function accept2()
    misn.setDesc(misn_desc2)
    misn.setReward(misn_reward)

    local osd_msg = {
        fmt.f(osd_msg_1, {planet=jorekplanet1:name(), system=joreksys1:name()})
    }
    misn.osdCreate(osd_title, osd_msg)

    stage = 2
    tick = {false, false, false, false, false}
    tick["__save"] = true

    misn.markerMove(marker, joreksys1)

    hook.land("land")
    hook.load("land")
    hook.jumpout("jumpout")
end


function seiryuuBoard(p, boarder)
    if boarder ~= player.pilot() then
        return
    end
    seiryuu:setActiveBoard(false)
    seiryuu:setHilight(false)
    player.unboard()
    if stage == 1 then
        tk.msg("", fmt.f(explain_text, {player=player.name()}))
        tk.msg("", fmt.f(fourwinds_origin_text, {player=player.name()}))
        tk.msg("", fourwinds_info_text)
        tk.msg("", fmt.f(objective_text,
                {player=player.name(), planet=jorekplanet1:name(),
                    system=joreksys1:name()}))
        accept2()
    elseif stage == 6 then
        tk.msg("", fmt.f(pay_text, {player=player.name()}))
        player.pay(1000000) -- 1M
        seiryuu:control()
        seiryuu:hyperspace()
        shadow_addLog(fmt.f(log_text_intro, {player=player.name()}))
        shadow_addLog(log_text_suspicion)
        shadow_addLog(fmt.f(log_text_succeed, {player=player.name()}))
        misn.finish(true)
    end
end


function joeBoard(p, boarder)
    if boarder ~= player.pilot() then
        return
    end
    player.unboard()
    tk.msg("", fmt.f(board_text, {player=player.name()}))
    misn.markerMove(marker, seirsys)
    misn.osdActive(2)
    stage = 5
    if p:exists() then
        p:hookClear()
        p:setHilight(false)
        p:setVisplayer(false)
        p:setActiveBoard(false)
        p:disable()
        p:setNoBoard()
    end
end


function jumpout()
    playerlastsys = system.cur()
    hook.rm(poller)
    hook.rm(spinter)
    player.pilot():setVisible(false)
end


function enter()
    if system.cur() == seirsys then
        local f = faction.dynAdd("Mercenary", N_("Four Winds"))
        seiryuu = pilot.add("Starbridge", f,
                vec2.new(300, 300) + seirplanet:pos(), _("Seiryuu"),
                {ai="trader", noequip=true})
        seiryuu:setInvincible(true)
        seiryuu:setNoClear()
        seiryuu:control()
        if stage == 1 or stage == 6 then
            seiryuu:setActiveBoard(true)
            seiryuu:setHilight(true)
            hook.pilot(seiryuu, "board", "seiryuuBoard")
        else
            seiryuu:setNoBoard(true)
        end
    elseif system.cur() == joreksys2 and stage == 3 then
        pilot.clear()
        pilot.toggleSpawn(false)
        spawnSquads(false)
    elseif stage == 4 then
        if system.cur() == joreksys2 then
            pilot.clear()
            pilot.toggleSpawn(false)
            player.allowLand(false, _("It's not safe to land right now."))
            -- Meet Joe, our informant.
            local f = faction.dynAdd("Mercenary", N_("Four Winds"))
            joe = pilot.add("Vendetta", f, vec2.new(-1000, -8000),
                    _("Four Winds Informant"), {ai="trader"})
            joe:control()
            joe:setHilight()
            joe:setVisplayer()
            joe:setInvincible()
            joe:setActiveBoard()
            joe:setNoClear()
            spawnSquads(true)

            hook.pilot(joe, "board", "joeBoard")
            poller = hook.timer(0.5, "patrolPoll")
        else
            hook.timer(3, "failtimer")
        end
    elseif stage == 5 then
        local adjacent = false
        if playerlastsys ~= nil then
            for i, s in ipairs(playerlastsys:adjacentSystems()) do
                if thissystem == s then
                    adjacent = true
                    break
                end
            end
        end
        if not adjacent or system.cur():faction() == faction.get("Sirius") then
            stage = 6
        elseif genbuspawned then
            if system.cur() == joreksys2 then
                player.allowLand(false, _("It's not safe to land right now."))
            end
            spawnGenbu(playerlastsys)
            continueAmbush()
            player.pilot():setVisible()
        elseif system.cur() == ambushsys then
            player.pilot():setVisible()
            hook.timer(3, "startAmbush")
        end
    end
end


function spawnSquads(highlight)
    -- Start positions for the leaders
    leaderstart = {
        vec2.new(-5000, -3000),
        vec2.new(5000, 2000),
        vec2.new(-7000, -9000),
        vec2.new(5000, -5000),
        vec2.new(-5000, -13000),
    }

    -- Leaders will patrol between their start position and this one
    leaderdest = {
        vec2.new(5000, -2000),
        vec2.new(-1000, 3000),
        vec2.new(-9000, -3000),
        vec2.new(4000, -12000),
        vec2.new(2000, -3000),
    }

    squads = {}
    for i, start in ipairs(leaderstart) do
        local f = faction.dynAdd("Mercenary", N_("Rogue Four Winds"),
                N_("Four Winds"))
        squads[i] = fleet.add(4, "Vendetta", f, start,
            _("Four Winds Patrol"), {ai="baddie_norun"}, true)
    end

    for i, squad in ipairs(squads) do
        for j, p in ipairs(squad) do
            p:setNoClear()
            hook.pilot(p, "attacked", "attacked")
        end
    end
    
    leader = {}
    for i, t in ipairs(squads) do
        leader[i] = t[1]
    end

    for i, p in ipairs(leader) do
        p:setHilight(highlight)
        p:setVisible(highlight)
        p:control()
        p:moveto(leaderdest[i], false)
        hook.pilot(p, "idle", "leaderIdle")
    end
end


function attacked()
    hook.rm(poller)
    player.pilot():setVisible()
    for i, squad in ipairs(squads) do
        for j, p in ipairs(squad) do
            if p:exists() then
                p:hookClear()
                p:taskClear()
                p:control(false)
                p:setHilight(false)
                p:setVisible(false)
                p:setHostile()
                p:setLeader(nil)
            end
        end
    end
end


function leaderIdle(plt)
    for i, j in ipairs(leader) do
        if j == plt then
            if tick[i] then
                plt:moveto(leaderdest[i], false)
            else
                plt:moveto(leaderstart[i], false)
            end
            tick[i] = not tick[i]
            return
        end
    end
end


function patrolPoll()
    for i, patroller in ipairs(leader) do
        if patroller:exists() then
            for j, p in ipairs(patroller:getVisible()) do
                if (p == player.pilot() or p:leader(true) == player.pilot())
                        and patroller:pos():dist(p:pos()) < 7000 then
                    patroller:broadcast(patrolcomm)
                    attacked()
                    return
                end
            end
        end
    end
    poller = hook.timer(0.5, "patrolPoll")
end


function failtimer()
    tk.msg("", fmt.f(joefailtext, {player=player.name()}))
    misn.finish(false)
end


function spawnGenbu(sys)
    local f = faction.dynAdd("Mercenary", N_("Rogue Four Winds"),
            N_("Four Winds"))
    genbu = pilot.add("Starbridge", f, sys, _("Genbu"),
            {ai="baddie_norun", noequip=true})
    genbu:setHostile()
    genbu:setVisplayer()
    genbu:setNoDeath()
    genbu:setNoDisable()
    genbu:setNoBoard()
    genbu:setNoClear()
    genbuspawned = true
end


function startAmbush()
    spawnGenbu(genbusys)
    tk.msg("", fmt.f(ambush_text, {player=player.name()}))
    continueAmbush()
end


function continueAmbush()
    waves = 0
    maxwaves = 5
    spinter = hook.timer(5.0, "spawnInterceptors")
end


function spawnInterceptors()
    local po
    local f = faction.dynAdd("Mercenary", N_("Rogue Four Winds"),
            N_("Four Winds"))
    inters = fleet.add(3, "Lancelot", f, genbu:pos(),
            _("Four Winds Lancelot"), {ai="baddie_norun"})
    for i, p in ipairs(inters) do
        p:setHostile()
    end
    if waves < maxwaves then 
       waves = waves + 1
       spinter = hook.timer(25.0, "spawnInterceptors")
    end
end


function land()
    if planet.cur() == jorekplanet1 and stage == 2 then
        -- Thank you player, but our SHITMAN is in another castle.
        barmanNPC = misn.npcAdd("barman", _("Barman"),
                "neutral/unique/barman.png",
                NPCdesc, 20)
    elseif planet.cur() == jorekplanet2 and stage == 3 then
        joreknpc = misn.npcAdd("jorek", "Jorek", "neutral/unique/jorek.png", Jordesc, 4)
    end
end


function barman()
    tk.msg("", fmt.f(barman_text,
            {player=player.name(), planet=jorekplanet2:name(),
                system=joreksys2:name()}))

    local osd_msg = {
        fmt.f(osd_msg_1, {planet=jorekplanet2:name(), system=joreksys2:name()})
    }
    misn.osdCreate(osd_title, osd_msg)

    misn.markerMove(marker, joreksys2)
    misn.npcRm(barmanNPC)

    stage = 3
end


function jorek()
    tk.msg("", fmt.f(jorek_text, {player=player.name()}))
    tk.msg("", jorek2_text)
    misn.npcRm(joreknpc)

    local osd_msg = {osd_msg_2, fmt.f(osd_msg_0, {system=seirsys:name()})}
    misn.osdCreate(osd_title, osd_msg)

    stage = 4
end


function abort()
    if system.cur() == joreksys2 or system.cur() == ambushsys
            or system.cur() == genbusys then
        -- Try to blend any spawned pilots in as reasonably as possible.
        player.allowLand(true)
        pilot.toggleSpawn(true)
        player.pilot():setVisible(false)
        if squads ~= nil then
            for i, p in ipairs(leader) do
                if p:exists() then
                    p:hookClear()
                    p:taskClear()
                    p:control(false)
                    p:setHilight(false)
                    p:setVisible(false)
                end
            end
        end
        if joe ~= nil and joe:exists() then
            joe:control(false)
            joe:setHilight(false)
            joe:setVisplayer(false)
            joe:setInvincible(false)
            joe:setActiveBoard(false)
        end
        if genbu ~= nil and genbu:exists() then
            genbu:setVisplayer(false)
        end
    end
    misn.finish(false)
end
