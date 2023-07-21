--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Prince">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>25</priority>
  <done>Baron</done>
  <chance>2</chance>
  <location>Bar</location>
  <faction>Empire</faction>
  <faction>Dvaered</faction>
  <faction>Goddard</faction>
  <faction>Sirius</faction>
 </avail>
 <notes>
  <campaign>Baron Sauterfeldt</campaign>
 </notes>
</mission>
--]]
--[[
-- This is the second mission in the baron string.
--]]

local fmt = require "fmt"
local fleet = require "fleet"
local portrait = require "portrait"
require "missions/baron/common"


text = {}
misn_desc = {}

ask_text = _([[As you approach the stranger, he extends his hand in greeting. He introduces himself as an associate of Baron Sauterfeldt, the man you helped to "acquire" a holopainting not too long ago.

"The Baron was quite pleased with your performance in that matter," he confides. "He has asked me to try to find you again for another job not unlike the last one. The Baron is a collector, you see, and his hunger for new possessions is a hard one to satiate." He makes a face. "Of course, his methods aren't always completely respectable, as you've experienced for yourself. But I assure you that the Baron is not a bad man, he is simply very enthusiastic."

You decide to keep your opinion of the aristocrat to yourself. Instead you inquire as to what the man wants from you this time. "To tell the truth, I don't actually know," the man says. "The Baron wants you to meet him so he can brief you in person. You will find his ship in the {system} system. Shall I inform his lordship that you will be paying him a visit?"]])

accept_text = _([["Splendid. Please go see his lordship at the earliest opportunity. He doesn't like to be kept waiting. I will send word that you will be coming, so contact the Pinnacle when you arrive at {system}, and they will allow you to board."]])

hail_text = _([[Your comm is answered by a communications officer on the bridge of the Pinnacle. You tell her you've got a delivery for the baron. She runs a few checks on a console off the screen, then tells you you've been cleared for docking and that the Pinnacle will be brought to a halt.]])

-- Translation note: this text intentionally refers to the player by
-- the name of the ship they are flying and vice-versa. By all means,
-- include as many mentions of the player and ship names as you can to
-- really hammer home the joke.
brief1_text = _([[You find yourself once again aboard the Pinnacle, Baron Sauterfeldt's flag ship. After a short time, an attendant ushers you into the Baron's personal quarters, which are as extravagant as you remember them. You notice the holopainting is now firmly fixed on one of the walls.

Baron Dovai Sauterfeldt greets you with a pompous wave of his hand. "Ahh yes, there you are at last. {player}, piloting the ship called {ship}, right? Do have a seat." He then offers you a drink, but you decline on the basis that you still have to drive. "Now then, {player}, I assume you're wondering why I've called you here. As you've no doubt heard, I have an interest in the unique, the exquisite." The Baron gestures around the room. "I have built up quite an impressive collection, as you can see, but it is still lacking something. Fortunately, news has reached me about a priceless artifact from Earth itself, dating back to before the Faction Wars. I must have it. It belongs in the hands of a connoisseur like myself."]])

brief2_text = _([["Unfortunately, {player}, news of this artifact has reached more ears than just mine. All over the galaxy there are people who will try to sell you 'ancient artifacts', which always turn out to be imitations at best and worthless scrap they picked up from the streets at worst." The Baron snorts derisively. "Even the contacts who usually fenc– ah, I mean, supply me with new items for my collection are in on the frenzy.

"I've narrowed down my search to three of these people. I'm confident that one of them is selling the genuine article, while the other two are shams. And this is where you come in, {player}. I want you to visit these vendors, buy their wares off them and bring me the authentic artifact. You will have the help of a man named Flintley, who is a history buff or some such rot. You will find him on {planet} in the {system} system. Simply tell him you're working for me and show him any artifacts in your possession. He will tell you which are authentic and which are fake.

"I should warn you, {player}. Some of my, ah, colleagues have also set their sights on this item, and so you can expect their henchmen to try to take it off you. I trust the {ship} is equipped to defend you against their despicable sort."]])

brief3_text = _([[You are swiftly escorted back to your ship. You didn't really get the chance to ask the Baron any questions, such as who these potential attackers are, how you're supposed to pay for the artifacts once you locate the sellers, or what you will get out of all this. You do, however, find an update to your galaxy map that shows the location of the sellers, as well as a list of names and portraits. It would seem that the only way to find out what you're dealing with is the hard way.]])

not_done_text = _([[You are swiftly informed that you have not yet collected and identified the genuine artifact and dismissed.]])

flint_intro = _([[You approach the nervous-looking man and inquire if he is Flintley, the historian in Baron Sauterfeldt's employ.

"Oh, yes. Yes! That is me! I'm Flintley," the man responds. "And you must be {player}. I know what's going on, the people from the Pinnacle have informed me. Oh, but where are my manners. Let me properly introduce myself. My name is Flintley, and I'm an archaeologist and historian. The best in the galaxy, some might say, ha-ha!" He gives you a look. "Well, maybe not. But I'm quite knowledgeable about the history of the galaxy. Too bad not too many people seem interested in that these days. The only work I can really get is the occasional appraisal, like I'm doing now for his lordship. I wish I didn't have to take jobs like this, but there you have it."

Flintley sighs. "Well, that's that. Come to me with any artifacts you manage to procure, and I'll analyze them to the best of my ability."]])

sellerA_text = _([["Hello there," the seller says to you when you approach. "Can I interest you in this bona fide relic from an ancient past? Unlike all those scammers out there, I offer you the real deal, no fakes here!"]])

sellerB_text = _([[The seller grins at you. "Ah, I can tell you have the eye of a connoisseur! I deal only in the finest, counterfeit-free antiques. If you're smart, and I can see that you are, you won't trust all those opportunists who will try to sell you fakes! How about it?"]])

sellerC_text = _([[The seller beckons you over to the bar. "Listen, friend. I have here a unique, extremely rare remnant of prehistoric times. This is the genuine article, trust me on that. 100% legit! And you wouldn't want to spend good credits on a fake, right?"]])

flint_artifact_textA = _([["Let's see what we have here," Flintley says as you hand him the artifact you bought on {planet}. "Ah, I know what this is without even looking anything up. It's a piece of an old-fashioned airlock mechanism, as used on most ships during the Faction Wars. That makes it rather old, but that also makes it worthless, I'm afraid. This is just old scrap." He gives you an apologetic look. "Don't let it get you down. Not many people would know this on first sight. Those scammers can be pretty clever."

You feel disappointed and frustrated, but you have no choice but to deposit the "artifact" into the nearest disintegrator inlet.]])

flint_artifact_textB = _([[You hand Flintley the artifact you bought on {planet}. He examines it for a few moments, then enters a few queries in the info terminal in his table. Once he has found what he was looking for, he heaves a sigh. "I'm sorry, {player}. It seems you've been had. What you've got here is little more than a trinket. It's a piece of 'art' creäted by a third-rank sculptress named Biena Gharibri who lives on Lapra. She's not very talented, I'm afraid. Her creätions have been called 'worse than Dvaered opera' by a leading art critic. I really don't think you want to present his lordship with this."

You promptly decide to dispose of the thing, unwilling to carry it around with you a moment longer than necessary.]])

flint_artifact_textC = _([[Flintley studies the object on the table for a while, checking the online database a number of times in the process. Then, finally, he turns to you. "I hate to say this, but it seems you've bought a counterfeit. It's a good one, thô! That seller on {planet} must have known their stuff. You see, this is very similar to a number plate used by hovercars on Mars at the time of the Second Growth. However, it's missing a number of vital characteristics, and some details betray its recent manufacture. Close, {player}, but no cigar."

You dispose of the counterfeit artifact. Hopefully the next one will be what Sauterfeldt is looking for.…]])

flintdeftext = _([[Flintley greets you. "Do you have any objects for me to look at, {player}? No? Well, alright. I'll be here if you need me. Good luck out there."]])

realartifact_text = _([[Flintley carefully studies the object in front of him, turning it around and consulting the online database via the bar table's terminal. After several minutes he leans back and whistles. "Well I never. This has to be it, {player}. I'd do a carbon dating if I could, but even without I'm positive. This object dates back to pre-Growth Earth. And it's in an amazingly good condition!"

You take another look at the thing. It resembles a small flat surface, apart from the crook at one end. On one side, there are cylindrical, solid protrusions that don't seem to serve any useful purpose at all. You are at a loss as to the artifact's purpose.

"It's called a skate-board," Flintley continues. "The records about it are a bit sketchy and a lot is nothing but conjecture, but it appears it was once used in primitive communal rituals. The exact nature of these rituals is unknown, but they may have been tribal initiations or even mating rituals. The patterns in the board itself are thought to have a spiritual or mystical meaning. Also, according to some theories, people used to stand on top of the skate-board, with the cylinder wheels facing the ground. This has led some historians to believe that the feet were once central to human psychology."

Flintley seems to have a lot more to say on the subject, but you're not that interested, so you thank him and return to your ship with the ancient artifact. You can only hope that the Baron is as enthusiastic about this skate-board as his historian!]])

pay_text = _([[Baron Dovai Sauterfeldt turns the skate-board over in his hands, inspecting every nick, every scratch on the surface. His eyes are gleaming with delight.

"Oh, this is marvelous, marvelous indeed, {player}! A piece of pre-Growth history, right here in my hands! I can almost hear the echoes of that ancient civilization when I put my ear close to it! This is going to be the centerpiece in my collection of relics and artifacts. Yes indeed!

"I was right to send you, {player}. You and the {ship} have beautifully lived up to my expectations. And I'm a man of my word, I will reward you as promised. What was it we agreed on again? What, I never promised you anything? Well, that won't do. I'll have my assistant place a suitable amount of money in your account. You will not find me ungrateful! Ah, but you must excuse me. I need time to revel in this fantastic piece of art! Goodbye, {player}, I will call on you when I have need of you again."

You are seen out of the Baron's quarters, so you head back thrû the airlock and back into your own ship. The first thing you do is check your balance, and to your relief, it has indeed been upgraded by a substantial amount. As you undock, you wonder what kind of wild goose chase the man will send you on next time.]])

-- Mission details
misn_title = _("Prince")
misn_reward = _("You weren't told!")
misn_desc[1] = _("Baron Sauterfeldt has summoned you to his ship, which is in the %s system.")
misn_desc[2] = _("Baron Sauterfeldt has tasked you with finding an ancient artifact, but he doesn't know exactly where to get it.")

-- NPC stuff
npc_desc = _("An unfamiliar man")
bar_desc = _("A man you've never seen before makes eye contact with you. It seems he knows who you are.")

flint_npc1 = _("A reedy-looking man")
flint_bar1 = _("You spot a thin, nervous looking individual. He does not seem to want to be here. This could be that Flintley fellow the Baron told you about.")

flint_npc2 = _("Flintley")
flint_bar2 = _("Flintley is here. He nervously sips from his drink, clearly uncomfortable in this environment.")

sellerdesc = _("You spot a dodgy individual who matches one of the portraits in your ship's database. This must be one of the artifact sellers.")

buy = _("Buy the artifact (%s)")
nobuy = _("Don't buy the artifact")

nomoneytext = _("You can't currently afford to buy this artifact. You need %s.")

-- OSD stuff
osd_msg_baron1 = _("Fly to the {system} system")
osd_msg_baron2 = _("Hail and then dock with (board) Kahan Pinnacle (orbiting {planet})")

log_text = _([[Baron Sauterfeldt sent you on a wild goose chase to find some ancient artifact known as a "skate-board", which you found for him.]])


function create ()
   baronpla, baronsys = planet.get("Ulios")
   artifactplanetA, artifactsysA = planet.getLandable("Varaati")
   artifactplanetB, artifactsysB = planet.getLandable("Sinclair")
   artifactplanetC, artifactsysC = planet.getLandable("Hurada")
   flintplanet, flintsys = planet.getLandable("Tau Station")
   if artifactplanetA == nil or artifactplanetB == nil
         or artifactplanetC == nil or flintplanet == nil then
      misn.finish(false)
   end

   misn.setNPC(npc_desc, "neutral/unique/unfamiliarman.png", bar_desc)

   stage = 1

   flintleyfirst = true
   artifactsfound = 0
   artifactAfound = false
   artifactBfound = false
   artifactCfound = false

   -- The price of each artifact will always be 15% of this, so at most
   -- the player will be paid 85% and at least 55%.
   reward = 600000
end


function accept()
   if tk.yesno("", fmt.f(ask_text, {system=baronsys:name()})) then
      misn.accept()
      tk.msg("", fmt.f(accept_text, {system=baronsys:name()}))

      misn.setTitle(misn_title)
      misn.setReward(misn_reward)
      misn.setDesc(misn_desc[1]:format(baronsys:name()))

      osd_msg_baron1 = fmt.f(osd_msg_baron1, {system=baronsys:name()})
      osd_msg_baron2 = fmt.f(osd_msg_baron2, {planet=baronpla:name()})
      local osd_msg = {osd_msg_baron1, osd_msg_baron2}
      misn.osdCreate(misn_title, osd_msg)
      marker = misn.markerAdd(baronsys, "low")

      hook.enter("enter")
      hook.takeoff("exit")
      hook.jumpout("exit")
   else
      misn.finish()
   end
end


function set_osd()
   misn.markerRm(markerA)
   misn.markerRm(markerB)
   misn.markerRm(markerC)
   misn.markerRm(flintmarker)

   local artifact_osd = _("Approach artifact seller at one of the following locations and buy the artifact:")
   if not artifactAfound then
      artifact_osd = artifact_osd .. "\n"
            .. fmt.f(_("{planet} ({system} system)"),
               {planet=artifactplanetA:name(), system=artifactsysA:name()})
      markerA = misn.markerAdd(artifactsysA, "low")
   end
   if not artifactBfound then
      artifact_osd = artifact_osd .. "\n"
            .. fmt.f(_("{planet} ({system} system)"),
               {planet=artifactplanetB:name(), system=artifactsysB:name()})
      markerB = misn.markerAdd(artifactsysB, "low")
   end
   if not artifactCfound then
      artifact_osd = artifact_osd .. "\n"
            .. fmt.f(_("{planet} ({system} system)"),
               {planet=artifactplanetC:name(), system=artifactsysC:name()})
      markerC = misn.markerAdd(artifactsysC, "low")
   end

   local osd_msg = {
      artifact_osd,
      fmt.f(_("Take artifact to Flintley on {planet} ({system} system)"),
            {planet=flintplanet:name(), system=flintsys:name()}),
      osd_msg_baron1,
      osd_msg_baron2,
   }
   misn.osdCreate(misn_title, osd_msg)
end


function osd_toflintley()
   misn.markerRm(markerA)
   misn.markerRm(markerB)
   misn.markerRm(markerC)
   flintmarker = misn.markerAdd(flintsys, "high")
   misn.osdActive(2)
end


function board(p, boarder)
   if boarder ~= player.pilot() then
      return
   end
   player.unboard()
   pinnacle:setHilight(false)
   pinnacle:setActiveBoard(false)

   if stage == 1 then
      local pname = player.name()
      local sname = player.pilot():name()
      tk.msg("", fmt.f(brief1_text, {player=sname, ship=pname}))
      tk.msg("", fmt.f(brief2_text,
            {player=sname, ship=pname, planet=flintplanet:name(),
               system=flintsys:name()}))
      tk.msg("", brief3_text)
      misn.setDesc(misn_desc[2])

      stage = 2

      misn.markerRm(marker)
      set_osd()

      hook.land("land")
      hook.load("land")

      idle()
   elseif stage == 2 then
      tk.msg("", not_done_text)
      idle()
   elseif stage == 3 then
      local pname = player.name()
      local sname = player.pilot():name()
      tk.msg("", fmt.f(pay_text, {player=sname, ship=pname}))
      pinnacle:taskClear()
      pinnacle:land()
      player.pay(reward)
      misn.finish(true)
   end
end


function land()
   if planet.cur() == artifactplanetA and not artifactAfound then
      sellnpc = misn.npcAdd("seller", _("Artifact seller"),
            portrait.get("Thief"), sellerdesc, 4)
   elseif planet.cur() == artifactplanetB and not artifactBfound then
      sellnpc = misn.npcAdd("seller", _("Artifact seller"),
            portrait.get("Thief"), sellerdesc, 4)
   elseif planet.cur() == artifactplanetC and not artifactCfound then
      sellnpc = misn.npcAdd("seller", _("Artifact seller"),
            portrait.get("Thief"), sellerdesc, 4)
   elseif planet.cur() == flintplanet then
      if flintleyfirst then
         flintnpc = misn.npcAdd("flintley", flint_npc1,
               "neutral/unique/flintley.png", flint_bar1, 4)
      else
         flintnpc = misn.npcAdd("flintley", flint_npc2,
               "neutral/unique/flintley.png", flint_bar2, 4)
      end
   end
end


function flintley()
   local bingo = false

   if flintleyfirst then
      flintleyfirst = false
      tk.msg("", fmt.f(flint_intro, {player=player.name()}))
   elseif artifactA == nil and artifactB == nil and artifactC == nil then
      tk.msg("", fmt.f(flintdeftext, {player=player.name()}))
   end

   if artifactA ~= nil then
      if rnd.rnd(1, 3 - artifactsfound) == 1 then
         bingo = true
      else
         tk.msg("", fmt.f(flint_artifact_textA,
               {planet=artifactplanetA:name()}))
         artifactsfound = artifactsfound + 1
      end
      misn.cargoRm(artifactA)
      artifactA = nil
   end
   if artifactB ~= nil then
      if rnd.rnd(1, 3 - artifactsfound) == 1 then
         bingo = true
      else
         tk.msg("", fmt.f(flint_artifact_textB,
               {planet=artifactplanetB:name(), player=player.name()}))
         artifactsfound = artifactsfound + 1
      end
      misn.cargoRm(artifactB)
      artifactB = nil
   end
   if artifactC ~= nil then
      if rnd.rnd(1, 3 - artifactsfound) == 1 then
         bingo = true
      else
         tk.msg("", fmt.f(flint_artifact_textC,
               {planet=artifactplanetC:name(), player=player.name()}))
         artifactsfound = artifactsfound + 1
      end
      misn.cargoRm(artifactC)
      artifactC = nil
   end

   if bingo then
      tk.msg("", fmt.f(realartifact_text, {player=player.name()}))
      stage = 3

      local c = misn.cargoNew(N_("Skate-board"),
            N_("A seemingly ancient artifact."))
      artifactReal = misn.cargoAdd(c, 0)

      misn.markerRm(markerA)
      misn.markerRm(markerB)
      misn.markerRm(markerC)
      misn.markerRm(flintmarker)
      marker = misn.markerAdd(baronsys, "high")
      misn.osdActive(3)
   else
      set_osd()
   end
end


function seller()
   if planet.cur() == artifactplanetA then
      if tk.choice("", sellerA_text,
            buy:format(fmt.credits(reward * 0.15)), nobuy) == 1 then
         if player.credits() >= reward * 0.15 then
            misn.npcRm(sellnpc)
            player.pay(-reward * 0.15, "adjust")
            local c = misn.cargoNew(N_("Artifact? A"),
                  N_("An ancient artifact?"))
            artifactA = misn.cargoAdd(c, 0)
            artifactAfound = true
            osd_toflintley()
         else
            tk.msg("", nomoneytext:format(fmt.credits(reward * 0.15)))
         end
      end
   elseif planet.cur() == artifactplanetB then
      if tk.choice("", sellerB_text,
            buy:format(fmt.credits(reward * 0.15)), nobuy) == 1 then
         if player.credits() >= reward * 0.15 then
            misn.npcRm(sellnpc)
            player.pay(-reward * 0.15, "adjust")
            local c = misn.cargoNew(N_("Artifact? B"),
                  N_("An ancient artifact?"))
            artifactB = misn.cargoAdd(c, 0)
            artifactBfound = true
            osd_toflintley()
         else
            tk.msg("", nomoneytext:format(fmt.credits(reward * 0.15)))
         end
      end
   elseif planet.cur() == artifactplanetC then
      if tk.choice("", sellerC_text,
            buy:format(fmt.credits(reward * 0.15)), nobuy) == 1 then
         if player.credits() >= reward * 0.15 then
            misn.npcRm(sellnpc)
            player.pay(-reward * 0.15, "adjust")
            local c = misn.cargoNew(N_("Artifact? C"),
                  N_("An ancient artifact?"))
            artifactC = misn.cargoAdd(c, 0)
            artifactCfound = true
            osd_toflintley()
         else
            tk.msg("", nomoneytext:format(fmt.credits(reward * 0.15)))
         end
      end
   end
end


function enter()
   if system.cur() == baronsys then
      if stage == 1 then
         misn.osdActive(2)
      elseif stage == 3 then
         misn.osdActive(4)
      end

      pinnacle = pilot.add("Proteron Kahan", "Civilian",
            baronpla:pos() + vec2.new(-400,-400), _("Pinnacle"), {ai="trader"})
      pinnacle:setInvincible(true)
      pinnacle:setFriendly()
      pinnacle:setSpeedLimit(100)
      pinnacle:control()
      pinnacle:setHilight(true)
      pinnacle:setNoClear()
      pinnacle:moveto(baronpla:pos() + vec2.new(500, -500), false, false)
      idlehook = hook.pilot(pinnacle, "idle", "idle")
      hhail = hook.pilot(pinnacle, "hail", "hail")
   elseif stage == 1 then
      misn.osdActive(1)
   elseif stage == 3 then
      misn.osdActive(3)
   elseif artifactA ~= nil or artifactB ~= nil or artifactC ~= nil
         or artifactReal ~= nil then
      if rnd.rnd() < 0.75 then
         hunterhooks = {}
         local choices = {"Llama", "Hyena", "Shark", "Lancelot", "Vendetta"}
         for i=1,10 do
            if rnd.rnd() < 0.6 then
               hunterhooks[i] = hook.timer(rnd.uniform(1, 60), "spawn_hunter",
                     choices[rnd.rnd(1, #choices)])
            end
         end
      end
   end
end


function exit()
   if hunterhooks ~= nil then
      for i, h in ipairs(hunterhooks) do
         hook.rm(h)
      end
      hunterhooks = nil
   end
end


function spawn_hunter(shiptype)
   local f = faction.dynAdd("Mercenary", N_("Artifact Hunter"))
   local pn = fmt.f(_("Artifact Hunter {shiptype}"), {shiptype=shiptype})
   local p = pilot.add(shiptype, f, nil, pn, {ai="baddie_norun"})
   p:setHostile()
   p:setNoClear()
end


function idle()
   pinnacle:moveto(baronpla:pos() + vec2.new(500,  500), false)
   pinnacle:moveto(baronpla:pos() + vec2.new(-500,  500), false)
   pinnacle:moveto(baronpla:pos() + vec2.new(-500, -500), false)
   pinnacle:moveto(baronpla:pos() + vec2.new(500, -500), false)
end


function hail()
   player.commClose()
   tk.msg("", hail_text)
   pinnacle:taskClear()
   pinnacle:brake()
   pinnacle:setActiveBoard(true)
   boardhook = hook.pilot(pinnacle, "board", "board")
   hook.rm(idlehook)
   hook.rm(hhail)
end
