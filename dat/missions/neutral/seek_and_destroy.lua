--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Seek And Destroy">
 <avail>
  <priority>41</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>450</chance>
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

--]]

local fmt = require "fmt"
local mh = require "misnhelper"
local pilotname = require "pilotname"
local portrait = require "portrait"
require "jumpdist"
require "proximity"


clue_text = {
   _([[You are told that {pilot} is supposed to have business in {system} soon.]]),
   _([["I've heard that {pilot} likes to hang around in {system}."]]),
   _([["You can probably catch {pilot} in {system}."]]),
   _([["I would suggest going to {system} and taking a look there. That's where {pilot} was last time I heard."]]),
   _([["If I was looking for {pilot}, I would look in the {system} system. That's probably a good bet."]]),
   _([["Oh, I know that scum. Bad memories. If I were you, I'd check the {system} system. Good luck!"]]),
   _([["{pilot} is the asshole who borrowed a bunch of credits from me and never paid me back! Yeah, I know where you can find them. {system} system. Good luck."]]),
}

clue_here_text = {
   _([["I'm pretty sure I saw {pilot} right here in {system} just a moment ago."]]),
   _([["{pilot}? I think I just saw them right here in this system."]]),
   _([[The pilot tells you that they saw {pilot} right here in the {system} system.]]),
   _([["Oh, shit, {pilot} is wanted? I just passed right by {pilot} right here in the {system} system! Can you believe it?"]]),
   _([["Oh, I just saw {pilot} passing by. You might still be able to catch them in this system. Good luck!"]]),
}

noclue_text = {
   _([[This person has never heard of {pilot}. It seems you will have to ask someone else.]]),
   _([[This person is also looking for {pilot}, but doesn't seem to know anything you don't.]]),
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
   _([["I used to work with {pilot}. We haven't seen each other since they stole my favorite ship, thô."]]),
   _([["{pilot} has owed me 500 k¢ for over a decade and never paid me back! I have no clue where they are, thô."]]),
}

money_text = {
   _([["Well, I don't offer my services for free. Pay me {credits} and I'll tell you where to look for {pilot}"]]),
   _([["Ah, yes, I think I know where {pilot} is. I'll tell you for just {credits}. A good deal, don't you think?"]]),
   _([["{pilot}? Yes, I know {pilot}. I can tell you where they were last heading, but it'll cost you. {credits}. Deal?"]]),
   _([["Ha ha ha! Yes, I've seen {pilot} around! Will I tell you where? Heck no! Not unless you pay me, of course. Let's see… {credits} should be sufficient."]]),
   _([["I tell you what: give me {credits} and I'll tell you where {pilot} is. Otherwise, get lost!"]]),
}

payclue_text = {
   _([[You are told that {pilot} is supposed to have business in {system} soon.]]),
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
   _([[The pilot simply sighs and cuts the connection.]]),
   _([["What a lousy attempt to scare me."]]),
   _([["Was I not clear enough the first time? Piss off!"]]),
   _([["You're kidding, right? You think you can threaten me?"]]),
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
   _([[When you ask for information about {pilot}, they tell you that this pirate has already been killed by someone else.]]),
   _([["Didn't you hear? That pirate's dead. Got blown up in an asteroid field is what I heard."]]),
   _([["Ha ha, you're still looking for {pilot}? You're wasting your time; that outlaw's already been taken care of."]]),
   _([["Ah, sorry, that target's already dead. Blown to smithereens by a mercenary. I saw the scene, thô! It was glorious."]]),
   _([["Er, someone else already killed {pilot}, but if you like, I could show you a picture of their ship exploding! It was quite a sight to behold."]]),
}
enemy_cold_text = {
   _([["Didn't you hear? {pilot} is dead! Got blown up in an asteroid field is what I heard."]]),
   _([["Ha ha, you're still looking for {pilot}? You're wasting your time; another bounty hunter beat you to it!"]]),
   _([["Imagine going up to an outlaw trying to find another outlaw who's already dead! Ha! Are you trying to join {pilot} in hell?"]]),
}

noinfo_text = {
   _([[The pilot tells you to give them one good reason to give you that information.]]),
   _([["What if I know where your target is and I don't want to tell you, eh?"]]),
   _([["Piss off! I won't tell anything to the likes of you!"]]),
   _([["And why exactly should I give you that information?"]]),
   _([["And why should I help you, eh? Get lost!"]]),
   _([["Piss off and stop asking questions about {pilot}, you nosey little snob!"]]),
}

found_msg = _("Target presence detected. Prepare to engage.")
flee_msg = _("OBJECTIVE FAILED: You ran away from target. Resume search for {pilot} in {system}.")
Tflee_msg = _("OBJECTIVE FAILED: Target ran away. Resume search for {pilot} in {system}.")

osd_title = _("Seek and Destroy")
osd_msg = {}
osd_msg1_r = _("Fly to the {system} system and search for clues")
osd_msg[1] = " "
osd_msg[2] = _("Kill {pilot}")
osd_msg["__save"] = true

local npc_name = _("Shifty Individual")
local npc_desc = _("This person might be an outlaw, a pirate, or even worse, a bounty hunter. You normally wouldn't want to get close to this kind of person, but they may be a useful source of information.")

misn_desc = _([[A notorious pirate known as {pilot} is wanted dead or alive by {faction} authorities, last seen in the {system} system. Any mercenary who can track down and eliminate this pirate will be awarded substantially.

Mercenaries who accept this mission are advised to go to the indicated system and talk to others in the area, either by hailing pilots while out in space or by talking to people on planets in the system, if applicable. Pirates are more likely to know where {pilot} is, so interrogating pirates in the system is highly recommended.]])

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
name_func = pilotname.pirate

virtual_allies = {}

enemy_know_chance = 0.1
enemy_tell_chance = 0.5
neutral_know_chance = 0.1
neutral_tell_chance = 0.5
ally_know_chance = 0.7
ally_tell_chance = 0.05

fearless_factions = {}
loyal_factions = {}


function create ()
   paying_faction = planet.cur():faction()
   if not paying_faction:areEnemies(target_faction) then
      misn.finish(false)
   end

   systems = getsysatdistance(system.cur(), 1, 5,
      function(s)
         return s:presence(target_faction) > 0
      end)

   if #systems < 4 then
      -- Not enough systems
      misn.finish(false)
   end

   systems.__save = true

   next_system = systems[rnd.rnd(1, #systems)]
   choose_next_system()
   if rnd.rnd() < 0.9 then
      target_present = false
   end

   difficulty = rnd.rnd(1, #misn_title)
   local ships = ship_choices[difficulty]
   shiptype = ships[rnd.rnd(1, #ships)]
   name = name_func()
   credits = base_reward[difficulty]
   credits = credits + 0.1*credits*rnd.sigma()

   -- Set mission details
   misn.setTitle(fmt.f(misn_title[difficulty], {system=current_system:name()}))
   misn.setDesc(fmt.f(misn_desc,
         {pilot=name, faction=paying_faction:name(),
            system=current_system:name()}))
   misn.setReward(fmt.credits(credits))
   marker = misn.markerAdd(current_system, "computer")
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


function accept()
   misn.accept()

   stage = 0
   hook.enter("enter")
   hook.hail("hail")
   hook.land("land")
   hook.load("land")

   osd_msg[1] = fmt.f(osd_msg1_r, {system=current_system:name()})
   osd_msg[2] = fmt.f(osd_msg[2], {pilot=name})
   misn.osdCreate(osd_title, osd_msg)
end


function enter()
   if stage <= 2 and target_present and system.cur() == current_system then
      stage = 2

      -- Get the position of the target
      local rad = system.cur():radius()
      local pos = vec2.new(rnd.uniform(-rad, rad), rnd.uniform(-rad, rad))

      -- Spawn the target
      local f = faction.dynAdd(target_faction,
            "bounty_target_" .. target_faction:nameRaw(),
            target_faction:nameRaw(),
            {clear_enemies=true})
      faction.dynAlly(f, target_faction)
      target_ship = pilot.add(shiptype, f, pos)
      target_ship:rename(name)
      target_ship:setHilight()
      target_ship:setNoClear()

      -- Target cannot be killed until the player gets a shot in.
      target_ship:setNoDeath()
      target_ship:setNoDisable()

      local mem = target_ship:memory()
      mem.noleave = true
      -- We're overriding the kill reward.
      mem.kill_reward = nil

      -- Record that we haven't found or learned about the target yet.
      target_found = false
      target_learned = false

      hook.timer(0.5, "proximityScan",
            {focus=target_ship, funcname="prox_found_target"})

      hook.pilot(target_ship, "attacked", "target_attacked")
      hook.pilot(target_ship, "death", "target_death")
      hook.pilot(target_ship, "jump", "target_flee")
      hook.pilot(target_ship, "land", "target_land")
   end
end


function choose_next_system()
   current_system = next_system
   repeat
      next_system = systems[rnd.rnd(1, #systems)]
   until next_system ~= current_system

   target_present = (rnd.rnd() < 0.3)
end


function prox_found_target()
   target_found = true
   misn.osdActive(2)
   player.msg(found_msg)
   jumpout = hook.jumpout("player_flee")
end


function is_target_ally(f)
   -- See if it's the same faction
   if target_faction == f then
      return true
   end

   -- See if it's a real ally
   if target_faction:areAllies(f) then
      return true
   end

   -- See if it's a virtual ally
   for i, fn in ipairs(virtual_allies) do
      if f == faction.get(fn) then
         return true
      end
   end

   return false
end


-- Player hails a ship for info
function hail(p)
   if p:leader(true) == player.pilot() then
      -- Don't want the player hailing their own escorts.
      return
   end
   if p:faction() == faction.get("Collective") then
      -- Don't want Collective drones to participate even if the player
      -- is allied with them.
      return
   end
   if not p:memory().natural then
      -- Only want natural pilots.
      return
   end
   if target_present and (target_found or target_learned) then
      -- Don't attempt to get clues if we know the target is here.
      return
   end

   if system.cur() == current_system and stage <= 2 then
      -- A pilot can be hailed only once
      p:memory().natural = false

      local know, tells
      if target_faction:areEnemies(p:faction()) then
         know = (rnd.rnd() < enemy_know_chance)
         tells = (rnd.rnd() < enemy_tell_chance)
      elseif is_target_ally(p:faction()) then
         know = (rnd.rnd() < ally_know_chance)
         tells = (rnd.rnd() < ally_tell_chance)
      else
         know = (rnd.rnd() < neutral_know_chance)
         tells = (rnd.rnd() < neutral_tell_chance)
      end

      -- Hostile ships automatically are less inclined to tell
      -- regardless of affiliation.
      if p:hostile() and rnd.rnd() < 0.95 then
         tells = false
      end

      if not know then -- NPC does not know the target
         tk.msg("", fmt.f(noclue_text[rnd.rnd(1, #noclue_text)],
               {pilot=name}))
      elseif tells then
         if target_present then
            local s = clue_here_text[rnd.rnd(1, #clue_here_text)]
            tk.msg("", fmt.f(s, {pilot=name, system=current_system:name()}))
            target_learned = true
         else
            local s = clue_text[rnd.rnd(1, #clue_text)]
            tk.msg("", fmt.f(s, {pilot=name, system=next_system:name()}))
            next_sys()
         end
         p:setHostile(false)
      else
         space_clue(p)
      end

      player.commClose()
   end
end

-- The NPC knows the target. The player has to convince him to give info
function space_clue(p)
   -- Some factions are loyal to each other
   local loyal = false
   for i, fn in ipairs(loyal_factions) do
      local f = faction.get(fn)
      if p:faction() == f and is_target_ally(f) then
         loyal = true
         break
      end
   end

   if loyal or p:hostile() or target_present then
      local s = noinfo_text[rnd.rnd(1, #noinfo_text)]
      local choice = tk.choice("", fmt.f(s, {pilot=name}),
            backoff_choice, threaten_choice)
      if choice == 1 then
         return
      else -- Threaten the pilot
         if isScared(p) and rnd.rnd() < .5 then
            local s = scared_text[rnd.rnd(1, #scared_text)]
            if target_present then
               tk.msg("", fmt.f(s, {pilot=name, system=current_system:name()}))
               target_learned = true
            else
               tk.msg("", fmt.f(s, {pilot=name, system=next_system:name()}))
               next_sys()
            end
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
      local price = (5 + 5*rnd.rnd()) * 1000
      local s = money_text[rnd.rnd(1, #money_text)]
      choice = tk.choice("",
            fmt.f(s, {pilot=name, credits=fmt.credits(price)}),
            pay_choice, backoff_choice, threaten_choice)

      if choice == 1 then
         if player.credits() >= price then
            player.pay(-price, "adjust")
            tk.msg("", fmt.f(payclue_text[rnd.rnd(1, #payclue_text)],
                  {pilot=name, system=next_system:name()}))
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
            faction.modPlayerSingle(p:faction(), -0.5)
         end

         if isScared(p) then
            local s = scared_text[rnd.rnd(1, #scared_text)]
            tk.msg("", fmt.f(s, {pilot=name, system=next_system:name()}))
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
   -- Some factions have no fear.
   for i, fn in ipairs(fearless_factions) do
      local f = faction.get(fn)
      if p:faction() == f and is_target_ally(f) then
         hook.rm(attack)
         return
      end
   end

   -- Target was hit sufficiently to get more talkative
   if (attacker == player.pilot() or attacker:leader(true) == player.pilot())
         and p:health() < 100 then
      p:control()
      p:runaway(player.pilot())
      local s = intimidated_text[rnd.rnd(1, #intimidated_text)]
      if target_present then
         tk.msg("", fmt.f(s, {pilot=name, system=current_system:name()}))
         target_learned = true
      else
         tk.msg("", fmt.f(s, {pilot=name, system=next_system:name()}))
         next_sys()
      end
      hook.rm(attack)
   end
end

-- Decides if the pilot is scared by the player
function isScared(t)
   -- Some factions have no fear.
   for i, fn in ipairs(fearless_factions) do
      local f = faction.get(fn)
      if t:faction() == f and is_target_ally(f) then
         return false
      end
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
      return false
   end

   if rnd.rnd() < 0.2 then
      return false
   end

   return true
end

-- Spawn NPCs at bar, that give info
function land ()
   if stage == 2 and target_found then
      player_flee()
   elseif system.cur() == current_system and stage == 0
         and planet.cur():class() ~= "1" then
      know = (rnd.rnd() < 0.7)
      tells = (rnd.rnd() < 0.2)
      mynpc = misn.npcAdd("clue_bar", npc_name, portrait.get("Thief"), npc_desc)
   end
end

-- The player ask for clues in the bar
function clue_bar()
   if not know then
      tk.msg("", fmt.f(noclue_text[rnd.rnd(1, #noclue_text)], {pilot=name}))
   elseif tells then
      local s = clue_text[rnd.rnd(1, #clue_text)]
      tk.msg("", fmt.f(s, {pilot=name, system=next_system:name()}))
      next_sys()
   else
      local price = rnd.rnd(7500, 15000)
      local s = money_text[rnd.rnd(1,#money_text)]
      choice = tk.choice("",
            fmt.f(s, {pilot=name, credits=fmt.credits(price)}),
            pay_choice, backoff_choice)

      if choice == 1 then
         if player.credits() >= price then
            player.pay(-price, "adjust")
            tk.msg("", fmt.f(payclue_text[rnd.rnd(1, #payclue_text)],
                  {pilot=name, system=next_system:name()}))
            next_sys()
         else
            tk.msg("", poor_text)
         end
      end
   end
   misn.npcRm(mynpc)
end

function next_sys()
   choose_next_system()
   misn.markerMove (marker, current_system)
   osd_msg[1] = fmt.f(osd_msg1_r, {system=current_system:name()})
   misn.osdCreate(osd_title, osd_msg)
end

function player_flee ()
   player.msg(fmt.f("#r" .. flee_msg .. "#0",
         {pilot=name, system=system.cur():name()}))
   stage = 0
   misn.osdActive(1)

   hook.rm(jumpout)
end

function target_flee ()
   if target_found then
      player.msg(fmt.f("#r" .. Tflee_msg .. "#0",
            {pilot=name, system=system.cur():name()}))
   end
   stage = 0
   misn.osdActive(1)
   hook.rm(jumpout)
end


function target_attacked(p, attacker)
   local pp = player.pilot()
   if attacker == pp or attacker:leader(true) == pp then
      p:setNoDeath(false)
      p:setNoDisable(false)
   end
end


function target_death ()
   local s = _("{credits} awarded for successfully hunting down {pilot}.")
   mh.showWinMsg(fmt.f(s, {credits=fmt.credits(credits), pilot=name}))
   player.pay(credits)
   paying_faction:modPlayer(rnd.uniform(0.2, 2))

   misn.finish(true)
end
