--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Preacher">
 <trigger>enter</trigger>
 <chance>1</chance>
 <cond>system.cur():presence(faction.get("Sirius")) &gt; 50</cond>
 <flags>
  <unique />
 </flags>
</event>
--]]
-- Event where the player meets one of the Touchèd, who tries to convert them
-- Sudarshan S <ssoxygen@users.sf.net>

local fleet = require "fleet"


commtext = _([[A Siriusite appears on your viewscreen. He seems different than most Siriusites you've met. He regards you with a neutral yet intense gaze.

"Humankind is cruel and deceptive," he says. "You deserve more than you shall ever get from humanity. Your only hope is to follow the Holy One, Sirichana. He shall guide you to peace and wisdom. He is the sole refuge for humans like you and me. You MUST follow him!"
 
You feel a brief but overpowering urge to follow him, but it passes and your head clears. The Sirius ship makes no further attempt to communicate with you.]])

althoEnemy = {
   _("%s, althô you are an enemy of House Sirius, I shall not attack unless provoked, for I abhor violence!"),
   _("%s, althô you are an enemy of House Sirius, I shall not attack unless provoked, for I believe mercy is a great Truth!"),
   _("%s, althô you are an enemy of House Sirius, I shall not attack unless provoked, for you too are Sirichana's child!"),
}

friend = {
   _("%s, I foresee in you a great Sirius citizen, and I look forward to your friendship!"),
   _("%s, I foresee a bright future for you, illuminated by Sirichana's light!"),
   _("%s, may Sirichana's light illuminate your path!"),
}

followSirichana = {
   _("You shall all follow Sirichana henceforth!"),
   _("Sirichana shall lead you to peace and wisdom!"),
   _("Sirichana is the Father of you all!"),
   _("Sirichana's grace shall liberate you!"),
   _("May Sirichana's light shine on you henceforth!"),
}

praiseSirichana = {
   _("We shall all follow Sirichana now!"),
   _("We have been liberated from our evil ways!"),
   _("No more shall we tread the path of evil!"),
   _("We see the True path now!"),
   _("No more shall we commit sins!"),
}

attackerPunished = {
   _("Serves you right for attacking a Touchèd!"),
   _("Fry in hell, demon!"),
   _("May you suffer eternal torment!"),
   _("Your doom is Sirichana's curse!"),
}

attackersDead = {
   _("All the attackers are dead!"),
   _("We can resume our Quest now!"),
   _("The glory of Sirichana remains unblemished!"),
   _("All heretics have been destroyed!"),
}

whatHappened = {
   _("Do you think everyone can be brainwashed?"),
   _("You shall convert no more of us!"),
   _("Some of us shall not be converted, fool!"),
   _("You'll never convert me!"),
   _("I shall never be converted!"),
}

presence = {
   _("You feel an overwhelming presence nearby!"),
   _("Something compels you to stop"),
   _("You are jerked awake by a mysterious but compelling urge"),
   _("You feel… touched… by a magical power"),
}

startCombat = {
   _("Die, heretics!"),
   _("Those who insult the Sirichana shall die!"),
   _("You've committed an unpardonable sin!"),
   _("Hell awaits, fools!"),
}

preacherDead = {
   _("Oh no! The Touchèd One is dead!"),
   _("Sirichana save our souls!"),
   _("We shall never forget You, O Touchèd One!"),
   _("We swear eternal revenge!"),
}

urge = {
   _("You feel an overwhelming urge to hear him out!"),
   _("A mysterious force forces you to listen!"),
   _("You feel compelled to listen!"),
}

dyingMessage = {
   _("With my dying breath, I curse you!"),
   _("Sirichana speed you to hell!"),
   _("Sirichana, I did my best!"),
}

dead = {
   _("The Reverence is dead!"),
   _("Someone killed the preacher!")
}

--initialize the event
function create()
   curr=system.cur() --save the current system

   --start the fun when the player jumps
   hook.jumpin("funStartsSoon")
   hook.land("cleanup") --oops he landed
end

--Start the real mission after a short delay
function funStartsSoon()
   playerP = player.pilot() --save player's pilot
   rep = faction.playerStanding(faction.get("Sirius"))
   hook.timer(5, "theFunBegins") --for effect, so that we can see them jumping in!
end

--the preaching's about to begin!
function theFunBegins()
   if not evt.claim(system.cur()) then
      evt.finish(false)
   end

   if rep < 0 then
      local dist = vec2.dist(jump.get(system.cur(),curr):pos(),player.pos()) --please note the order of system.cur() and curr matters!
      if dist < 6000 then
         hook.timer(5, "theFunBegins") --wait some more time
         return
      end
   end
   --summon a preacher from the jump point and highlight him and take control and focus on him
   preacher = pilot.add(
         "Sirius Reverence", "Sirius", curr, nil, {ai="sirius_norun"})
   preacher:setHilight()
   preacher:setVisplayer()
   preacher:control()
   preacher:broadcast(followSirichana[rnd.rnd(1, #followSirichana)], true)
   preacher:hailPlayer()
   playerP:setInvincible()

   --set needed hooks
   hook.pilot(preacher,"attacked", "violence")
   hook.pilot(preacher,"death", "badCleanup")
   hook.pilot(preacher,"land", "landCleanup")
   hook.pilot(preacher,"jump", "jumpCleanup")
   hook.jumpout("cleanup")

   camera.set(preacher, true)
   player.cinematics(true,{gui=true, abort=presence[rnd.rnd(1,#presence)]})

   --you're hooked till you hear him out!
   playerP:control()
   player.msg(urge[rnd.rnd(1, #urge)])

   --create a random band of converted pirate followers
   local followerShips = {"Pirate Kestrel", "Pirate Admonisher", "Pirate Shark", "Pirate Vendetta", "Pirate Rhino"} --the types of followers allowed
   followers = {}
   local numships = rnd.rnd(2, 6) -- This is the total number of converted follower ships.

   for num=1, numships, 1 do
      followers[num] = followerShips[rnd.rnd(1, #followerShips)] -- Pick a follower ship at random.
   end

   followers = fleet.add(1, followers, "Sirius", curr, nil, {ai="sirius_norun"}) -- The table now contains pilots, not ship names.
   for k,j in ipairs(followers) do
      j:rename(string.format(_("Converted %s"), j:name()))
   end

   --pick a random converted pirate and have him praise the Sirichana
   praiser = followers[rnd.rnd(1,#followers)]

   --add some sirius escorts too
   local siriusFollowers = {"Sirius Fidelity", "Sirius Shaman"} --the types of followers allowed
   local siriusFollowerList = {}

   numships = rnd.rnd(2, 6) -- This is the total number of sirius escort ships.
   for num=1, numships, 1 do
      siriusFollowerList[num] = siriusFollowers[rnd.rnd(1, #siriusFollowers)] -- Pick a follower ship at random.
   end

   siriusFollowers = fleet.add(1, siriusFollowerList, "Sirius", curr, nil, {ai="sirius_norun"}) -- The table now contains pilots, not ship names.

   for i, p in ipairs(siriusFollowers) do
      followers[#followers + 1] = p
   end

   --set up a table to store attackers
   attackers={}

   --make these followers follow the Touchèd one
   --if Sirius is an enemy still keep these guys neutral... at first
   for i, p in ipairs(followers) do
      p:setFriendly()
      p:control()
      p:follow(preacher)
      hook.pilot(p, "attacked", "violence")
   end
   preacher:setFriendly()

   --pick a random follower and have him praise Sirichana, after a delay
   hook.timer(4, "praise")

   --have the preacher say something cool
   hook.timer(8, "preacherSpeak")

   --add some normal pirates for fun :)
   hook.timer(12.5, "pirateSpawn")

   --hook up timers for releasing cinematics (and you of course :P)
   hook.timer(17.5, "release")

   --hook up timer for re-hailing player
   hailHook = hook.timer(5, "reHail")

   --when hailed, the preacher preaches to you
   answerHook = hook.pilot(preacher, "hail", "hail")
end

function preacherSpeak()
   camera.set(preacher, true)
   if rep < 0 then
      preacher:comm(string.format(
               althoEnemy[rnd.rnd(1, #althoEnemy)], player.name()), true)
   else
      preacher:comm(string.format(
               friend[rnd.rnd(1, #friend)], player.name()), true)
   end
end

--re-hail the player
function reHail()
   if preacher:exists() then
      preacher:hailPlayer()
      hailHook = hook.timer(5, "reHail")
   end
end

--random praise for the Sirichana
function praise()
   camera.set(praiser, true)
   praiser:broadcast(praiseSirichana[rnd.rnd(1, #praiseSirichana)], true)
end

--spawn some enemy pirates for fun :P
--to add even more fun have them say something cool
function pirateSpawn()
   local numships = rnd.rnd(2, 5)
   local curiousNumber = rnd.rnd(1, numships)
   local shiptype = {"Pirate Shark", "Pirate Vendetta"}
   local thepilot
   for num=1,numships,1 do
      thepilot = pilot.add(shiptype[rnd.rnd(1, #shiptype)], "Pirate", curr)
      if num == curiousNumber then
         thepilot:broadcast(whatHappened[rnd.rnd(1, #whatHappened)], true)
         camera.set(thepilot, true)
      end
      thepilot:control()
      thepilot:attack(followers[rnd.rnd(1, #followers)])
   end
end

--called when a new attack happens
function violence(attacked,attacker)
   if #attackers == 0 then --we have to change the group to battle mode
      attacked:broadcast(startCombat[rnd.rnd(1, #startCombat)], true)
      preacher:control(false)
      for i, p in ipairs(followers) do
         if p:exists() then
            p:control(false)
         end
      end
   end
   local found=false
   for i, p in ipairs(attackers) do
      if p == attacker then
         found=true
         break
      end
   end
   if not found then --new attacker
      attackers[#attackers+1]=attacker
      hook.pilot(attacker,"exploded","anotherdead")
      hook.pilot(attacker,"land","anotherdead")
      hook.pilot(attacker,"jump","anotherdead")
   end
end

-- another enemy is dead
function anotherdead(enemy, attacker)

   if attacker == nil then --in case the pilot was blown up by an explosion
      attacker = preacher
   end

   if attacker:exists() then --in case the attacker was killed in parallel
      attacker:broadcast(attackerPunished[rnd.rnd(1, #attackerPunished)], true)
   end

   -- find and remove the enemy
   for i, p in ipairs(attackers) do
      if p == enemy then
         table.remove(attackers, i)
         break
      end
   end

   if #attackers == 0 then --last one was killed, restore idle mode
      attacker:broadcast(attackersDead[rnd.rnd(1, #attackersDead)], true)
      restoreControl()
   end
end

-- finds and set a new target for the preacher, when he is outta battle mode
function getPreacherTarget()
   local sirius = faction.get("Sirius")

   --look for nearby landable Sirius planet to land
   for key, planet in ipairs(system.cur():planets()) do
      if planet:faction() == sirius and planet:services()["land"]  then
         target = planet
         break
      end
   end

   --if no landable Sirius planets found, jump to random system
   --TODO: prevent jump back thrû the entry point
   if target then
      preacher:land(target)
   else
      preacher:hyperspace()
   end
end

--restores control to the idle mode
function restoreControl()
   preacher:control()
   for i, p in ipairs(followers) do
      if p:exists() then
         p:control()
         p:follow(preacher)
      end
   end
   getPreacherTarget()
end

--releases the player after the cutscene
function release()
   camera.set(nil, true)
   player.cinematics(false)
   playerP:setInvincible(false)
   playerP:control(false)
   --if the attacks have already started, we shouldn't set a target yet
   if #attackers == 0 then
      getPreacherTarget()
   end
end

--when hailed back, show the message
function hail()
   tk.msg("", commtext)
   player.commClose()
   hook.rm(hailHook)
   hook.rm(answerHook)
end

--everything is done
function cleanup()
   player.pilot():setInvincible(false)
   player.pilot():control(false)
   camera.set()
   player.cinematics(false)
   evt.finish(true)
end

--oops, it seems the preacher died. End gracefully
function badCleanup()
   playerP:setInvincible(false)
   player.msg(dead[rnd.rnd(1, #dead)])
   preacher:broadcast(dyingMessage[rnd.rnd(1, #dyingMessage)])
   local survivors={}
   for i, p in ipairs(followers) do
      if p:exists() then
         p:control(false)
         survivors[#survivors+1] = p
      end
   end
   if #survivors > 0 then
      follower = survivors[rnd.rnd(1, #survivors)]
      follower:broadcast(preacherDead[rnd.rnd(1, #preacherDead)], true)
   end
   evt.finish(false)
end

--the preacher has landed. Land all his followers too
function landCleanup()
   playerP:setInvincible(false)
   for i, p in ipairs(followers) do
      if p:exists() then
         p:taskClear()
         p:land(target)
      end
   end
   evt.finish(true)
end

--the preacher has jumped. Jump all his followers too
function jumpCleanup()
   playerP:setInvincible(false)
   for i, p in ipairs(followers) do
      if p:exists() then
         p:taskClear()
         p:control()
         p:hyperspace(target,true) --attack back as they move away?
      end
   end
   evt.finish(true)
end
