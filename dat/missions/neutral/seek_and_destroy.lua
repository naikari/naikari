--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Seek And Destroy">
 <avail>
  <priority>41</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>875</chance>
  <location>Computer</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[

   The player searches for an outlaw across several systems

   Stages :
   0) Next system will give a clue
   2) Next system will contain the target
   4) Target was killed

--]]

local fmt = require "fmt"
local mh = require "misnhelper"
local portrait = require "portrait"
require "jumpdist"
require "pilot/generic"
require "pilot/pirate"


clue_text = {
   _("The pilot tells you that {pilot} is supposed to have business in {system} soon."),
   _([["I've heard that {pilot} likes to hang around in {system}."]]),
   _([["You can probably catch {pilot} in {system}."]]),
   _([["I would suggest going to {system} and taking a look there. That's where {pilot} was last time I heard."]]),
   _([["If I was looking for {pilot}, I would look in the {system} system. That's probably a good bet."]]),
   _([["Oh, I know that scum. Bad memories. If I were you, I'd check the {system} system. Good luck!"]]),
}

noclue_text = {
   _("This person has never heard of {pilot}. It seems you will have to ask someone else."),
   _("This pilot is also looking for {pilot}, but doesn't seem to know anything you don't."),
   _([["{pilot}? Nope, I haven't seen that person in years at this point."]]),
   _([["Sorry, I have no idea where {pilot} is."]]),
   _([["Oh, hell no, I stay as far away from {pilot} as I possibly can."]]),
   _([["I haven't a clue where {pilot} is."]]),
   _([["I don't give a damn about {pilot}. Go away."]]),
   _([["{pilot}? Don't know, don't care."]]),
   _("When you ask about {pilot}, you are promptly told to get lost."),
   _([["I'd love to get back at {pilot} for what they did last year, but I haven't seen them in quite some time now."]]),
   _([["I've not seen {pilot}, but good luck in your search."]]),
   _([["I'd love to help, but unfortunately I haven't a clue where {pilot} is. Sorry."]]),
   _([["I used to work with {pilot}. We haven't seen each other since they stole my favorite ship, though."]]),
   _([["{pilot} has owed me 500 k¢ for over a decade and never paid me back! I have no clue where they are, though."]]),
}

money_text = {
   _([["Well, I don't offer my services for free. Pay me {credits} and I'll tell you where to look for {pilot}"]]),
   _([["Ah, yes, I think I know where {pilot} is. I'll tell you for just {credits}. A good deal, don't you think?"]]),
   _([["{pilot}? Yes, I know {pilot}. I can tell you where they were last heading, but it'll cost you. {credits}. Deal?"]]),
   _([["Ha ha ha! Yes, I've seen {pilot} around! Will I tell you where? Heck no! Not unless you pay me, of course. Let's see… {credits} should be sufficient."]]),
   _([["I tell you what: give me {credits} and I'll tell you where {pilot} is. Otherwise, get lost!"]]),
}

payclue_text = {
   _("The pilot tells you that {pilot} is supposed to have business in {system} soon."),
   _([["{pilot} likes to hang around in {system}. Go there and I'm sure you'll find them. Whether or not you can actually defeat {pilot}, on the other hand… heh, not my problem!"]]),
   _([["{system} is definitely your best bet. {pilot} spends a lot of time there."]]),
   _([["{system} is the last place {pilot} was heading to. Go quickly and you just might catch up."]]),
   _([["Heh, thanks for the business! {system} is where you can find {pilot}."]]),
}

pay_choice = _("Pay the sum")
backoff_choice = _("Back off")
threaten_choice = _("Threaten the pilot")

poor_text  = _("You don't have enough money.")

not_scared_text = {
   _([["As if the likes of you would ever try to fight me!"]]),
   _("The pilot simply sighs and cuts the connection."),
   _([["What a lousy attempt to scare me."]]),
   _([["Was I not clear enough the first time? Piss off!"]]),
}

scared_text = {
   _([["OK, OK, I'll tell you! You can find {pilot} in the {system} system. Don't shoot at me, please!"]]),
   _([["D-dont shoot, please! OK, I'll tell you. I heard that {pilot} is in the {system} system. Honest!"]]),
   _([[The pilot's eyes widen as you threaten their life, and they immediately comply, telling you that {pilot} can be found in the {system} system.]]),
}

intimidated_text = {
   _([["Stop shooting, please! I'll tell you! {pilot} is in the {system} system! I swear!"]]),
   _([[As you make it clear that you have no problem with blasting them to smithereens, the pilot begs you to let them live and tells you that {pilot} is supposed to have business in {system} soon.]]),
   _([["OK, OK, I get the message! The {system} system! {pilot} is in the {system} system! Just leave me alone!"]]),
}

cold_text = {
   _("When you ask for information about {pilot}, they tell you that this pirate has already been killed by someone else."),
   _([["Didn't you hear? That pirate's dead. Got blown up in an asteroid field is what I heard."]]),
   _([["Ha ha, you're still looking for {pilot}? You're wasting your time; that outlaw's already been taken care of."]]),
   _([["Ah, sorry, that target's already dead. Blown to smithereens by a mercenary. I saw the scene, though! It was glorious."]]),
   _([["Er, someone else already killed {pilot}, but if you like, I could show you a picture of their ship exploding! It was quite a sight to behold."]]),
}

noinfo_text = {
   _([[The pilot asks you to give them one good reason to give you that information.]]),
   _([["What if I know where your target is and I don't want to tell you, eh?"]]),
   _([["Piss off! I won't tell anything to the likes of you!"]]),
   _([["And why exactly should I give you that information?"]]),
   _([["And why should I help you, eh? Get lost!"]]),
   _([["Piss off and stop asking questions about {pilot}, you nosey little snob!"]]),
}

advice_text  = _([["Hi there", says the pilot. "You seem to be lost." As you explain that you're looking for an outlaw pilot and have no idea where to find your target, the pilot laughs. "So, you've taken a Seek and Destroy job, but you have no idea how it works. Well, there are two ways to get information on an outlaw: first way is to land on a planet and ask questions at the bar. The second way is to ask pilots in space. By the way, pilots of the same faction of your target are most likely to have information, but won't give it easily. Good luck with your search!"]])

brief_text = _("{pilot} is a notorious pirate who is wanted by the authorities, dead or alive. Any citizen who can find and neutralize {pilot} by any means necessary will be given {credits} as a reward. {faction} authorities have lost track of this pilot in the {system} system. It is very likely that the target is no longer there, but this system may be a good place to start an investigation.")

flee_text = _("You had a chance to neutralize {pilot}, and you wasted it! Now you have to start all over. Maybe some other pilots in {system} know where {pilot} is going.")

Tflee_text = _("That was close, but unfortunately, {pilot} ran away. Maybe some other pilots in this system know where your target is heading.")

pay_text    = {}
pay_text[1] = _("An officer hands you your pay.")
pay_text[2] = _("No one will miss this outlaw pilot! The bounty has been deposited into your account.")

osd_title = _("Seek and Destroy")
osd_msg = {}
osd_msg1_r = _("Fly to {system} and search for clues")
osd_msg[1] = " "
osd_msg[2] = _("Kill {pilot}")
osd_msg["__save"] = true

npc_desc = _("Shifty Person")
bar_desc = _("This person might be an outlaw, a pirate, or even worse, a bounty hunter. You normally wouldn't want to get close to this kind of person, but they may be a useful source of information.")

misn_desc = _("A pirate known as {pilot} is wanted dead or alive by {faction} authorities. {pilot} was last seen in the {system} system. Any mercenary who can track down and eliminate this pirate will be awarded substantially.")

misn_title = {
   _("Seek and Destroy: Small Pirate Bounty ({system} system)"),
   _("Seek and Destroy: Moderate Pirate Bounty ({system} system)"),
   _("Seek and Destroy: Difficult Pirate Bounty ({system} system)"),
   _("Seek and Destroy: Dangerous Pirate Bounty ({system} system)"),
}
ship_choices = {
   {"Pirate Vendetta", "Pirate Ancestor"},
   {"Pirate Admonisher", "Pirate Phalanx"},
   {"Pirate Rhino"},
   {"Pirate Kestrel"},
}
base_reward = {
   750000,
   1100000,
   2100000,
   6300000,
}

target_faction = faction.get("Pirate")
name_func = pirate_name


function create ()
   paying_faction = planet.cur():faction()
   if not paying_faction:areEnemies(target_faction) then
      misn.finish(false)
   end

   local systems = getsysatdistance(system.cur(), 1, 5,
      function(s)
         local p = s:presences()[target_faction:nameRaw()]
         return p ~= nil and p > 0
      end)

   -- Create the table of system the player will visit now (to claim)
   nbsys = rnd.rnd(5, 9) -- Total number of available systems (in case the player misses the target first time)
   pisys = rnd.rnd(2, 4) -- System where the target will be
   mysys = {}

   if #systems <= nbsys then
      -- Not enough systems
      misn.finish(false)
   end

   mysys[1] = systems[ rnd.rnd(1, #systems) ]

   -- There will probably be lot of failure in this loop.
   -- Just increase the mission probability to compensate.
   for i = 2, nbsys do
      thesys = systems[ rnd.rnd(1, #systems) ]
      -- Don't re-use the previous system
      if thesys == mysys[i-1] then
         misn.finish(false)
      end
      mysys[i] = thesys
   end

   if not misn.claim(mysys) then
      misn.finish(false)
   end

   difficulty = rnd.rnd(1, #misn_title)
   local ships = ship_choices[difficulty]
   ship = ships[rnd.rnd(1, #ships)]
   name = name_func()
   credits = base_reward[difficulty]
   credits = credits + 0.1*credits*rnd.sigma()
   cursys = 1

   -- Set mission details
   misn.setTitle(fmt.f(misn_title[difficulty], {system=mysys[1]:name()}))
   misn.setDesc(fmt.f(misn_desc,
         {pilot=name, faction=paying_faction:name(), system=mysys[1]:name()}))
   misn.setReward(fmt.credits(credits))
   marker = misn.markerAdd(mysys[1], "computer")

   -- Store the table
   mysys["__save"] = true
end

-- Test if an element is in a list
function elt_inlist(elt, list)
   for i, elti in ipairs(list) do
      if elti == elt then
         return true
      end
   end
   return false
end

function accept ()
   misn.accept()

   stage = 0
   increment = false
   last_sys = system.cur()
   tk.msg("", fmt.f(brief_text,
         {pilot=name, credits=fmt.credits(credits),
            faction=paying_faction:name(), system=mysys[1]:name()}))
   jumphook = hook.enter("enter")
   hailhook = hook.hail("hail")
   landhook = hook.land("land")

   osd_msg[1] = fmt.f(osd_msg1_r, {system=mysys[1]:name()})
   osd_msg[2] = fmt.f(osd_msg[2], {pilot=name})
   misn.osdCreate(osd_title, osd_msg)
end

function enter ()
   hailed = {}

   -- Increment the target if needed
   if increment then
      increment = false
      cursys = cursys + 1
   end

   if stage <= 2 and system.cur() == mysys[cursys] then
      -- This system will contain the pirate
      -- cursys > pisys means the player has failed once (or more).
      if cursys == pisys or (cursys > pisys and rnd.rnd() < 0.5) then
         stage = 2
      end

      if stage == 0 then  -- Clue system
         if not var.peek("got_advice") then -- A bounty hunter who explains how it works
            var.push("got_advice", true)
            spawn_advisor ()
         end
      elseif stage == 2 then  -- Target system
         misn.osdActive(2)
         
         -- Get the position of the target
         jp  = jump.get(system.cur(), last_sys)
         if jp ~= nil then
            x = 8000 * rnd.rnd() - 4000
            y = 8000 * rnd.rnd() - 4000
            pos = jp:pos() + vec2.new(x,y)
         else
            pos = nil
         end

         -- Spawn the target
         pilot.toggleSpawn(false)
         pilot.clear()

         target_ship = pilot.add(ship, target_faction, pos)
         target_ship:rename(name)
         target_ship:setHilight(true)
         target_ship:setVisplayer()
         target_ship:setHostile()

         -- We're overriding the kill reward.
         target_ship:memory().kill_reward = nil

         death_hook = hook.pilot(target_ship, "death", "target_death")
         pir_jump_hook = hook.pilot(target_ship, "jump", "target_flee")
         pir_land_hook = hook.pilot(target_ship, "land", "target_land")
         jumpout = hook.jumpout("player_flee")
      end
   end
   last_sys = system.cur()
end

function spawn_advisor ()
   jp     = jump.get(system.cur(), last_sys)
   x = 4000 * rnd.rnd() - 2000
   y = 4000 * rnd.rnd() - 2000
   pos = jp:pos() + vec2.new(x,y)

   advisor = pilot.add("Lancelot", "Mercenary", pos, nil, {ai="baddie_norun"})
   hailie = hook.timer(2, "hailme")

   hailed[#hailed+1] = advisor
end

function hailme()
    advisor:hailPlayer()
    hailie2 = hook.pilot(advisor, "hail", "hail_ad")
end

function hail_ad()
   hook.rm(hailie)
   hook.rm(hailie2)
   tk.msg("", advice_text) -- Give advice to the player
end

-- Player hails a ship for info
function hail(p)
   if p:leader() == player.pilot() then
      -- Don't want the player hailing their own escorts.
      return
   end

   if system.cur() == mysys[cursys] and stage == 0
         and not elt_inlist(p, hailed) then
      hailed[#hailed+1] = p -- A pilot can be hailed only once

      if cursys+1 >= nbsys then -- No more claimed system : need to finish the mission
         tk.msg("", fmt.f(cold_text[rnd.rnd(1, #cold_text)], {pilot=name}))
         misn.finish(false)
      else
         -- If hailed pilot is enemy to the target, there is less chance he knows
         if target_faction:areEnemies(p:faction()) then
            know = (rnd.rnd() < 0.1)
         else
            know = (rnd.rnd() < 0.7)
         end

         -- If hailed pilot is enemy to the player, there is less chance he tells
         if p:hostile() then
            tells = (rnd.rnd() < 0.05)
         else
            tells = (rnd.rnd() < 0.5)
         end

         if not know then -- NPC does not know the target
            tk.msg("", fmt.f(noclue_text[rnd.rnd(1, #noclue_text)],
                  {pilot=name}))
         elseif tells then
            local s = clue_text[rnd.rnd(1, #clue_text)]
            tk.msg("", fmt.f(s, {pilot=name, system=mysys[cursys+1]:name()}))
            next_sys()
            p:setHostile(false)
         else
            space_clue(p)
         end
      end

      player.commClose()
   end
end

-- The NPC knows the target. The player has to convince him to give info
function space_clue(p)
   -- FLF are loyal to each other.
   local loyal = false
   local flf = faction.get("FLF")
   if target_faction == flf and p:faction() == flf then
      loyal = true
   end

   if loyal or p:hostile() then
      local s = noinfo_text[rnd.rnd(1, #noinfo_text)]
      local choice = tk.choice("", fmt.f(s, {pilot=name}),
            backoff_choice, threaten_choice)
      if choice == 1 then
         return
      else -- Threaten the pilot
         if isScared(p) and rnd.rnd() < .5 then
            local s = scared_text[rnd.rnd(1, #scared_text)]
            tk.msg("", fmt.f(s, {pilot=name, system=mysys[cursys+1]:name()}))
            next_sys()
            p:control()
            p:runaway(player.pilot())
         else
            tk.msg("", not_scared_text[rnd.rnd(1, #not_scared_text)])

            -- Clean the previous hook if it exists
            if attack then
               hook.rm(attack)
            end
            attack = hook.pilot(p, "attacked", "clue_attacked")
         end
      end
   else -- Pilot wants payment
      price = (5 + 5*rnd.rnd()) * 1000
      local s = money_text[rnd.rnd(1, #money_text)]
      choice = tk.choice("",
            fmt.f(s, {pilot=name, credits=fmt.credits(price)}),
            pay_choice, backoff_choice, threaten_choice)

      if choice == 1 then
         if player.credits() >= price then
            player.pay(-price, "adjust")
            tk.msg("", fmt.f(payclue_text[rnd.rnd(1, #payclue_text)],
                  {pilot=name, system=mysys[cursys+1]:name()}))
            next_sys()
            p:setHostile(false)
         else
            tk.msg("", poor_text)
         end
      elseif choice == 2 then
         return
      else -- Threaten the pilot
         -- Everybody except the pirates takes offence if you threaten them
         if p:faction() ~= faction.get("Pirate") then
            faction.modPlayerSingle(p:faction(), -1)
         end

         if isScared(p) then
            local s = scared_text[rnd.rnd(1, #scared_text)]
            tk.msg("", s:format(name, mysys[cursys+1]:name()))
            next_sys()
            p:control()
            p:runaway(player.pilot())
         else
            tk.msg("", not_scared_text[rnd.rnd(1, #not_scared_text)])

            -- Clean the previous hook if it exists
            if attack then
               hook.rm(attack)
            end
            attack = hook.pilot(p, "attacked", "clue_attacked")
         end
      end
   end
end

-- Player attacks an informant who has refused to give info
function clue_attacked(p, attacker)
   -- FLF has no fear.
   local flf = faction.get("FLF")
   if target_faction == flf and p:faction() == flf then
      hook.rm(attack)
      return
   end

   -- Target was hit sufficiently to get more talkative
   if (attacker == player.pilot() or attacker:leader() == player.pilot())
         and p:health() < 100 then
      p:control()
      p:runaway(player.pilot())
      local s = intimidated_text[rnd.rnd(1, #intimidated_text)]
      tk.msg("", fmt.f(s, {pilot=name, system=mysys[cursys+1]:name()}))
      next_sys()
      hook.rm(attack)
   end
end

-- Decides if the pilot is scared by the player
function isScared(t)
   -- FLF has no fear.
   local flf = faction.get("FLF")
   if target_faction == flf and t:faction() == flf then
      return false
   end

   local pstat = player.pilot():stats()
   local tstat = t:stats()

   -- If target is stronger, no fear
   if tstat.armour+tstat.shield > 1.1 * (pstat.armour+pstat.shield)
         and rnd.rnd() < 0.95 then
      return false
   end

   -- If target is quicker, no fear
   if tstat.speed_max > pstat.speed_max and rnd.rnd() < 0.95 then
      if t:hostile() then
         t:control()
         t:runaway(player.pilot())
      end
      return false
   end

   if rnd.rnd() < 0.2 then
      return false
   end

   return true
end

-- Spawn NPCs at bar, that give info
function land ()
   -- Player flees from combat
   if stage == 2 then
      player_flee()

   -- Player seek for a clue
   elseif system.cur() == mysys[cursys] and stage == 0 then
      if rnd.rnd() < .3 then -- NPC does not know the target
         know = 0
      elseif rnd.rnd() < .5 then -- NPC wants money
         know = 1
         price = (5 + 5*rnd.rnd()) * 1000
      else -- NPC tells the clue
         know = 2
      end
      mynpc = misn.npcAdd("clue_bar", npc_desc, portrait.get("Pirate"), bar_desc)

   -- Player wants to be paid
   elseif planet.cur():faction() == paying_faction and stage == 4 then
      tk.msg("", pay_text[rnd.rnd(1,#pay_text)])
      player.pay(credits)
      paying_faction:modPlayer(rnd.rnd(1,2))
      misn.finish(true)
   end
end

-- The player ask for clues in the bar
function clue_bar()
   if cursys+1 >= nbsys then
      tk.msg("", cold_text[rnd.rnd(1, #cold_text)]:format(name))
      misn.finish(false)
   else

      if know == 0 then -- NPC does not know the target
         tk.msg("", fmt.f(noclue_text[rnd.rnd(1, #noclue_text)], {pilot=name}))
      elseif know == 1 then -- NPC wants money
         local s = money_text[rnd.rnd(1,#money_text)]
         choice = tk.choice("",
               fmt.f(s, {pilot=name, credits=fmt.credits(price)}),
               pay_choice, backoff_choice)

         if choice == 1 then
            if player.credits() >= price then
               player.pay(-price, "adjust")
               tk.msg("", fmt.f(payclue_text[rnd.rnd(1, #payclue_text)],
                     {pilot=name, system=mysys[cursys+1]:name()}))
               next_sys()
            else
               tk.msg("", poor_text)
            end
         else
            -- End of function
         end

      else -- NPC tells the clue
         local s = clue_text[rnd.rnd(1, #clue_text)]
         tk.msg("", fmt.f(s, {pilot=name, system=mysys[cursys+1]:name()}))
         next_sys()
      end

   end
   misn.npcRm(mynpc)
end

function next_sys ()
   misn.markerMove (marker, mysys[cursys+1])
   osd_msg[1] = fmt.f(osd_msg1_r, {system=mysys[cursys+1]:name()})
   misn.osdCreate(osd_title, osd_msg)
   increment = true
end

function player_flee ()
   tk.msg("", fmt.f(flee_text, {pilot=name, system=system.cur():name()}))
   stage = 0
   misn.osdActive(1)

   hook.rm(death_hook)
   hook.rm(pir_jump_hook)
   hook.rm(pir_land_hook)
   hook.rm(jumpout)
end

function target_flee ()
   -- Target ran away. Unfortunately, we cannot continue the mission
   -- on the other side because the system has not been claimed...
   tk.msg("", fmt.f(Tflee_text, {pilot=name}))
   pilot.toggleSpawn(true)
   stage = 0
   misn.osdActive(1)

   hook.rm(death_hook)
   hook.rm(pir_jump_hook)
   hook.rm(pir_land_hook)
   hook.rm(jumpout)
end

function target_death ()
   pilot.toggleSpawn(true)

   local s = _("{credits} awarded for successfully hunting down {pilot}.")
   mh.showWinMsg(fmt.f(s, {credits=fmt.credits(credits), pilot=name}))
   player.pay(credits)
   paying_faction:modPlayer(rnd.uniform(0.2, 2))
end
