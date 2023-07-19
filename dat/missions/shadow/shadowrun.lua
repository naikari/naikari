--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Shadowrun">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <chance>80</chance>
  <location>Bar</location>
  <cond>
   player.numOutfit("Mercenary License") &gt; 0
   and system.get("Klantar"):jumpDist() ~= nil
   and system.get("Klantar"):jumpDist() &lt; 3
  </cond>
 </avail>
 <notes>
  <campaign>Shadow</campaign>
 </notes>
</mission>
--]]
--[[
-- This is the main script for the Shadowrun mission. It's started from the spaceport bar and tries to emulate spaceport bar conversation as part of the mission.
-- "shadowrun" stack variable:
-- 1 = player has met Rebina, but hasn't accepted the mission
-- 2 = player has accepted Rebina's mission, but has not talked to SHITMAN
-- 3 = player has talked to SHITMAN
--]]

local fmt = require "fmt"
local portrait = require "portrait"
local fleet = require "fleet"
require "missions/shadow/common"


ask_text = _([[The woman calmly watches you as you approach her, seemingly not at all surprised to see you. Clad in a plain yet expensive-looking black dress and sipping from her martini, she emits an aura of class that is almost intimidating.

"Hello," she greets. "I had a feeling you might want to talk to me. You are different from most…" She gestures at the other patrons of the bar. "And so am I. But where are my manners? I haven't introduced myself. My name is Rebina. I am what you might call a talent hunter. I visit places such as these to find people of exceptional talent. People such as you."

You begin to introduce yourself, but Rebina waves it away, perhaps because your name doesn't interest her, or possibly because she already knows who you are. "Let's not waste words on idle formalities," she says. "I am here to talk business, and I've got a proposition for you, if you're interested."]])

ask_again_text = _([[Rebina nods at you to acknowledge your existence. "We meet again. I'm glad to see you've not gotten yourself killed yet." She smiles meaningfully. "As it happens I haven't found anyone to take care of my business yet. Perhaps you would reconsider? Allow me to remind you what this is about."]])

explain_text = _([["What I need is a pilot and a ship. Specifically, I need a skilled pilot and a capable ship. You see, what I am about to suggest you do is both profitable and dangerous." Rebina takes another sip of her drink before continuing, allowing what she just said to fully register. "I will not lie to you. There are… rivalries out there, and working for me will mean you'll take sides in some of them. People will take notice of you, and some of them will try to kill you."

You explain that taking risks comes with being an independent pilot and that you took the captain's chair with appropriate resolve, but Rebina pins you with a piercing gaze. "These are no ordinary pirate raids we're talking about," she admonishes you. "If you take this assignment, you will be a painted target. I want you to be well aware of this." There is another pause, but then she continues in a milder tone of voice. "That being said, I can assure you that the reward is well worth the risk. Pull this off, and you'll walk away considerably richer than you were."

Rebina leans back, levelly meeting your gaze. "That's all I can tell you at this point. You'll get more details once you accept the job. If you accept this job. What say you?"]])

accept_text = _([["Wonderful!" Rebina gives you a warm, sincere smile. "I don't mind admitting that it isn't easy finding pilots who measure up to my expectations, and finding ones willing to take a risk is more difficult still. I am pleased indeed." Rebina's expression changes to that of a businesswoman about to ply her trade. "Now, listen up. Contrary to what you may have thought, this assignment isn't about me. It's about a man who goes by the name of Jorek McArthy. The current state of affairs is that Jorek is staying on {planet} in the {system} system, and this is not where I and my associates want him to be. Unfortunately, Jorek has attracted some unwanted attention, and we don't want him to focus that attention to us."

Rebina takes a moment to sip from her drink. "I think you can see where this is going. You are to rendezvous with Jorek, take him aboard your ship, lose whoever's tailing him, then bring him to the {destsys} system. There you will dock with one of our ships, the Seiryuu, which will take Jorek to his final destination. You will receive your reward from her captain once Jorek is aboard.

"It's a simple objective, but accomplishing it might require considerable skill." She leans back and smiles. "Still, I have utmost confidence that you can do it. I seldom misjudge those I choose to trust.]])

accept_text2 = _([["You will find Jorek in the spaceport bar on {planet}. When you see him, tell him you've come to 'see to his special needs'. Oh, and please be discreet. Don't talk about things you don't need to; the walls have ears in that place. In particular, don't mention any names.

If you are prevented from taking Jorek offworld for any reason, make your way to the Seiryuu and report what happened. We'll take it from there."

Rebina empties her glass and places it on the bar before rising to her feet. "That will be all. Good luck, and keep your wits about you." Rebina takes her leave from you and gracefully departs the spaceport bar. You order yourself another drink. You've got a feeling you're going to need it.]])

refusal_text = _([["I see. What a shame." Rebina's demeanor conveys that she's disappointed but not upset. "I can understand your decision. One should not bite off more than one can chew, after all. It seems I will have to try to find another candidate." She tilts her head slightly. Then, "Althô if you change your mind before I do, you're welcome to accept the mission."]])

fail_noattempt_text = _([[You complete docking operations with the Seiryuu, well aware that you didn't even attempt to pick up the man they were expecting. At the airlock, you are greeted by a pair of crewmen in grey uniforms. You explain to them that you were unable to bring Jorek to them, and they receive your report in a dry, businesslike manner. The meeting is short. The crewmen disappear back into their ship, closing the airlock behind them, and you return to your bridge.

You prepare to undock from the Seiryuu, but before you complete the procedures there is a sudden power spike in your primary systems. All panels go black. In the darkness, the only thing that disturbs the silence is the sound of the Seiryuu dislodging itself from your docking clamp. Seconds later, the computer core reboots itself and your controls come back online, but you find to your dismay that your OS has been reset to factory defaults. All custom content has been lost, including your logs of meeting the Seiryuu.]])

succeed_text = _([[You complete docking operations with the Seiryuu, well aware that your ship isn't carrying the man they were expecting but content in the knowledge that this contingency was planned for. When the airlock opens, you find yourself face to face with a woman and two crewmen, all wearing gray, featureless uniforms. It takes you a few moments to realize that the woman is in fact Rebina. This is not the elegant, feminine figure you met in the spaceport bar not too long ago. This woman emits an aura of authority, and you immediately understand that Rebina is in fact captain of the Seiryuu.

"Well met, {player}," she says. At the same time, the two crewmen that accompanied her push their way past you and disappear in the direction of your cargo hold. You open your mouth to protest, but Rebina raises a hand to forestall you. "There is no cause for concern," she says. "My men are only retrieving that which we sent you to fetch. I assure you that your ship and its cargo will be left undisturbed."

You explain to Rebina that althô you met Jorek, he didn't accompany you on your way here. Rebina gives you an assured smile in return. "Oh, I know that. I never expected you to bring him to us in the first place. You see, it's not Jorek we wanted you to get. It was… that."]])
succeed_text2 = _([[You follow her gaze, and spot the crewmen making their way back to the airlock, carrying between them a small but apparently rather heavy crate. You are absolutely certain you've never seen it before. "That is what Jorek was keeping for us on {planet}, and that is what we need," Rebina explains. "Jorek is nothing but a decoy to draw the Empire's attention away from our real operations. While you were talking to him, his subordinates secured our cargo aboard your ship. We chose not to inform you about this because, well… It's best you didn't know what was in that crate. I'm sure we understand each other."

Rebina turns to follow her men back into the ship, but before she closes the airlock hatch she looks back at you over her shoulder, shooting you a casual glance that nevertheless seems to see right thrû you. "I'm glad to see my trust in you was not misplaced," she remarks. "Perhaps we'll see each other again someday, and when we do, perhaps we can do some more business."

The airlock hatch closes. You stare at it, then look down at the credit chip in your hand, first marveling at the wealth it represents and then astonished to realize you can't remember how it got there.]])

-- Mission details
misn_title = _("Shadow Run")
misn_reward = _("Unspecified riches")
bar_desc = _("You spot a dark-haired woman sitting at the bar. Her elegant features and dress make her stand out, yet her presence here seems almost natural, as if she's in the right place at the right time, waiting for the right person. You wonder why she's all by herself.")
misn_desc = _("You have been tasked with picking up a man named Jorek by a woman named Rebina. The exact nature of the mission has not been explained to you.")

-- NPC stuff
jorek_npc = {}
jorek_npc["name"] = _("An unpleasant man.")
jorek_npc["portrait"] = "neutral/unique/jorek.png"
jorek_npc["desc"] = _("A middle-aged, cranky looking man is sitting at a table by himself. You are fairly certain that this is the fellow you're looking for.")

jorek_text = {}
jorek_text[1] = _([[You join the man at his table. He doesn't particularly seem to welcome your company, thô, because he gives you a look most people would reserve for particularly unwelcome guests. Determined not to let that get to you, you ask him if his name is indeed Jorek. "Yeah, that's me," he replies. "What'o ya want, kid?"

You explain to him that you've come to see to his special needs. This earns you a sneer from Jorek. "Ha! So you're running errands for the little lady, are you? Oh don't tell me, I've got a pretty good ideä what it is you want from me." He leans onto the table, bringing his face closer to yours. "Listen, buddy. I don't know if you noticed, but people are watchin' me. And you too, now that you're talkin' to me. Those goons over there? Yeah, they're here for me. Used to be fancy undercover agents, but I've been sittin' on my ass here for a long time and they figured out I was on to them, so they replaced 'em with a bunch of grunts. Cheaper, see.

"And it's not just them. On your way here, did you see the flotilla of 'patrol ships' hangin' around? You guessed it, they're waitin' for me to split this joint. I'm HOT, kid. If I step onto your ship, you'll be hot too. And you have absolutely no problem with that, is that what you're tellin' me?"]])
jorek_text[2] = _([[Jorek roars with laughter. "Hah! Yeah, I'm sure you don't! I know what you're thinkin', I do. You'll take me outta here, pull a heroic bust past them Empire ships, save me, and the day while you're at it, then earn your stripes with the lady, am I right? S'yeah, I bet you'd take on the world for a pretty face and a coy smile." He doesn't so much as make an attempt to keep the mocking tone out of his voice. "Well, good for you. You're a real hero, right enough. But you know what? I'm stayin' put. I don't care if you have the vixen's approval. I'm not gettin' on some random stranger's boat just so they can get us both blasted to smithereens."

Your patience with Jorek's tirade is finally at an end, and you heatedly make it clear to him that your abilities as a pilot aren't deserving of this treatment. Jorek, however, seems unimpressed. He tells you to stick it where the sun doesn't shine, gets up from his chair and squarely deposits himself at another table. Unwilling to stoop to his level, you choose not to follow him.]])
jorek_text[3] = _([[Jorek exhales derisively. "No, I thought not. Probably thought this was going to be a walk in the park, didn't you? But when the chips are down, you back out. Wouldn't want to mess with be big scary Empire, would we?" He raises his voice for this, taunting the military personnel in the bar. They don't show any sign of having even heard Jorek speak.

Jorek snorts, then focuses his attention back on you. "I've got no use for wusses like yourself. Go on, get out of here. Go back to your ship and beat it off this rock. Maybe you should consider gettin' yourself a desk job, eh?" With that, Jorek leaves your table and sits down at a nearby empty one. Clearly this conversation is over, and you're not going to get anything more out of him.]])
jorek_text[4] = _([[Jorek pointedly ignores you. It doesn't seem like he's willing to give you the time of day any longer. You decide not to push your luck.]])

off_npc = {}
off_npc["name"] = _("Officer at the bar")
off_npc["desc"] = _("You see a military officer with a drink at the bar. He doesn't seem to be very interested in it, thô.…")
off_text = { _("You try to strike a conversation with the officer, but he doesn't seem interested what you have to say, so you give up.") }

sol1_npc = {}
sol1_npc["name"] = _("Soldier at the news kiosk")
sol1_npc["desc"] = _("You see a soldier at a news kiosk. For some reason, he keeps reading the same articles over and over again.")
sol1_text = { _("Leave me alone. Can't you see I'm busy?") }

sol2_npc = {}
sol2_npc["name"] = _("Card-playing soldier")
sol2_npc["desc"] = _("Two soldiers are sharing a table near the exit, playing cards. Neither of them seems very into the game.")
sol2_text = { _("They don't seem to appreciate your company. You decide to leave them to their game.") }

log_text = _([[You participated in an operation for Captain Rebina. You thought you were rescuing a man named Jorek, but it turns out that you were actually helping smuggle something onto Captain Rebina's ship, the Seiryuu. You know next to nothing about Captain Rebina or who she works for.]])


function create()
    pnt, sys = planet.get("Durea")
    sys2 = system.get("Uhriabi")

    if not misn.claim({sys, sys2}) then
        misn.finish(false)
    end

    credits = 700000
    talked = false
    
    misn.setNPC( _("A dark-haired woman"), "neutral/unique/rebina_casual.png", bar_desc )
end

function accept()
    if talked then
        tk.msg("", ask_again_text)
    else
        tk.msg("", ask_text)
    end
    if tk.yesno("", explain_text) then 
        misn.accept()
        tk.msg("", fmt.f(accept_text,
                {planet=pnt:name(), system=sys:name(), destsys=sys2:name()}))
        tk.msg("", fmt.f(accept_text2, {planet=pnt:name()}))
        
        misn.setTitle(misn_title)
        misn.setReward(misn_reward)
        misn.setDesc(misn_desc)

        shadowrun = 2

        local osd_desc = {
            fmt.f(_("Talk to Jorek at the bar on {planet} ({system} system)"),
               {planet=pnt:name(), system=sys:name()}),
            fmt.f(_("Fly to the {system} system and dock with (board) Seiryuu"),
               {system=sys2:name()}),
        }
        misn.osdCreate(_("Shadow Run"), osd_desc)

        misn_marker = misn.markerAdd(sys, "high")

        hook.land("land")
        hook.enter("enter")
    else
        tk.msg("", refusal_text)
        talked = true
        misn.finish()
    end
end

function land()
    local landed = planet.cur()
    if pnt == landed then
        misn.npcAdd("jorek", jorek_npc["name"], jorek_npc["portrait"], jorek_npc["desc"])
        misn.npcAdd("officer", off_npc["name"], portrait.getMaleMil("Empire"), off_npc["desc"])
        misn.npcAdd("soldier1", sol1_npc["name"], portrait.getMaleMil("Empire"), sol1_npc["desc"])
        misn.npcAdd("soldier2", sol2_npc["name"], portrait.getMil("Empire"), sol2_npc["desc"])
        misn.npcAdd("soldier2", sol2_npc["name"], portrait.getMil("Empire"), sol2_npc["desc"])
    end
end

-- Talking to Jorek
function jorek()
    if shadowrun == 2 then
        if tk.yesno("", jorek_text[1]) then
            tk.msg("", jorek_text[2])
        else
            tk.msg("", jorek_text[3])
        end
        shadowrun = 3
        misn.osdActive(2)
        misn.markerMove(misn_marker, sys2)
    else
        tk.msg("", jorek_text[4])
    end
end

function officer()
    tk.msg("", off_text[1])
end
function soldier1()
    tk.msg("", sol1_text[1])
end
function soldier2()
    tk.msg("", sol2_text[1])
end


function enter()
    -- Empire ships around planet
    if system.cur() == sys then
        pilot.clear()
        pilot.toggleSpawn(false)
        planetpos = pnt:pos()
        pilot.add( "Empire Pacifier", "Empire", planetpos + vec2.new(200,0), nil, {ai="empire_idle"} )
        pilot.add( "Empire Pacifier", "Empire", planetpos + vec2.new(130,130), nil, {ai="empire_idle"} )
        pilot.add( "Empire Pacifier", "Empire", planetpos + vec2.new(0,200), nil, {ai="empire_idle"} )
        pilot.add( "Empire Pacifier", "Empire", planetpos + vec2.new(-130,130), nil, {ai="empire_idle"} )
        pilot.add( "Empire Pacifier", "Empire", planetpos + vec2.new(-200,0), nil, {ai="empire_idle"} )
        pilot.add( "Empire Pacifier", "Empire", planetpos + vec2.new(-130,-130), nil, {ai="empire_idle"} )
        pilot.add( "Empire Pacifier", "Empire", planetpos + vec2.new(0,-200), nil, {ai="empire_idle"} )
        pilot.add( "Empire Pacifier", "Empire", planetpos + vec2.new(130,-130), nil, {ai="empire_idle"} )
    end

    -- Handle the Seiryuu, the last stop on this mission
    if shadowrun >= 2 and system.cur() == sys2 then
        local mypos = vec2.new(-1500, 600)
        local f = faction.dynAdd("Mercenary", N_("Four Winds"))
        seiryuu = pilot.add("Starbridge", f, mypos, _("Seiryuu"),
                {ai="trader", noequip=true})

        seiryuu:setActiveBoard()
        seiryuu:control()
        seiryuu:setInvincible()
        seiryuu:setHilight()
        seiryuu:setVisplayer()
        seiryuu:setNoClear()
        
        hook.pilot(seiryuu, "board", "board")
        hook.pilot(seiryuu, "death", "seiryuu_death")
    end
end

function board(p, boarder)
    if boarder ~= player.pilot() then
        return
    end
    player.unboard()
    seiryuu:changeAI("flee")
    seiryuu:setHilight(false)
    seiryuu:setActiveBoard(false)
    seiryuu:control(false)

    if shadowrun == 2 then
        -- player reports in without SHITMAN
        tk.msg("", fail_noattempt_text)
        misn.finish(false)
    else
        -- player reports in with SHITMAN
        tk.msg("", fmt.f(succeed_text, {player=player.name()}))
        tk.msg("", fmt.f(succeed_text2, {planet=pnt:name()}))
        player.pay(credits)
        shadow_addLog(log_text)
        misn.finish(true)
    end
end

function seiryuu_death()
    misn.finish(false)
end
