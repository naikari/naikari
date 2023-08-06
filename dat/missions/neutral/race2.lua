--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Racing Skills 2">
 <avail>
  <priority>50</priority>
  <cond>
   planet.cur():class() ~= "1"
   and planet.cur():class() ~= "2"
   and planet.cur():class() ~= "3"
   and system.cur():presence("Civilian") &gt; 0
   and system.cur():presence("Pirate") &lt;= 0
   and (player.misnDone("Empire Recruitment")
      or (system.cur() ~= system.get("Hakoi")
         and system.cur() ~= system.get("Eneguoz")))
  </cond>
  <done>Racing Skills 1</done>
  <chance>20</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[
   --
   -- MISSION: Racing Skills 2
   -- DESCRIPTION: A person asks you to join a race, where you fly to various checkpoints and board them before landing back at the starting planet
   --
--]]

local fmt = require "fmt"
local mh = require "misnhelper"
local pilotname = require "pilotname"
local portrait = require "portrait"


ask_text = _([["Hey there, it looks like you've participated in our races before. Great to see you back! You want to have another race?"]])   

ask_difficulty_text = _([["There are two races you can participate in: a casual one, which is like the races we had before the Melendez sponsorship, or the competitive one one with smaller checkpoints and stronger competition. The casual one has a prize of {casualcredits}, and the competitive one has a prize of {competitivecredits}. Which one do you want to do?"]])

yes_hard_text = _([["You want a challenge huh? We'll all be trying our best, so good luck!"]])

choice1 = _("Casual")
choice2 = _("Competitive")

yes_easy_text = _([["Let's go have some fun then!"]])

checkpoint_text = _("Checkpoint {prev} reached. Proceed to Checkpoint {next}.")

checkpoint_final_text = _("Checkpoint {prev} reached. Land on {planet}.")

wintext = _([[A man in a suit and tie takes you up onto a stage. A large name tag on his jacket says 'Melendez Corporation'. "Congratulations on your win," he says, shaking your hand, "that was a great race. On behalf of Melendez Corporation, I would like to present to you your prize money of {credits}!" He hands you one of those fake oversized checks for the audience, and then a credit chip with the actual prize money on it.]])

fail_left_text = _([["Because you left the race, you have been disqualified."]])

lose_text = _([[As you congratulate the winner on a great race, the laid back person comes up to you.

"That was a lot of fun! If you ever have time, let's race again. Maybe you'll win next time!"]])

NPCname = _("A laid back person")
NPCdesc = _("You see a laid back person, who appears to be one of the locals, looking around the bar, apparently in search of a suitable pilot.")

misndesc = _("You're participating in another race!")

OSDtitle = _("Racing Skills")
OSD = {}
OSD[1] = _("Board checkpoint 1")
OSD[2] = _("Board checkpoint 2")
OSD[3] = _("Board checkpoint 3")
OSD[4] = _("Land on %s")

chatter = {}
chatter[1] = _("Let's do this!")
chatter[2] = _("Wooo!")
chatter[3] = _("Time to Shake 'n Bake")
chatter[4] = _("Checkpoint %s baby!")
chatter[5] = _("Hooyah")
chatter[6] = _("Next!")
timermsg = "%s"
target = {1,1,1,1}
marketing = _("This race is sponsored by Melendez Corporation. Problem-free ships for problem-free voyages!")
positionmsg = _("%s just reached checkpoint %s")
landmsg = _("%s just landed at %s and finished the race")


function create ()
   curplanet = planet.cur()
   missys = system.cur()

   -- Must claim the system since player pilot is controlled for a time.
   if not misn.claim(missys) then
      misn.finish(false)
   end

   misn.setNPC(NPCname, portrait.get(curplanet:faction()), NPCdesc)
   credits_easy = rnd.rnd(20000, 100000)
   credits_hard = rnd.rnd(200000, 300000)
end


function accept ()
   if tk.yesno("", ask_text) then
      misn.accept()
      OSD[4] = string.format(OSD[4], curplanet:name())
      misn.setTitle(OSDtitle)
      misn.setDesc(misndesc)
      misn.osdCreate(OSDtitle, OSD)
      local s = fmt.f(ask_difficulty_text,
            {casualcredits=fmt.credits(credits_easy),
               competitivecredits=fmt.credits(credits_hard)})
      choice, choicetext = tk.choice("", s, choice1, choice2)

      local shipchoices
      ship_list = {}
      if choice == 1 then
         credits = credits_easy
         shipchoices = {
            "Llama", "Lancelot", "Koäla", "Quicksilver", "Ancestor",
         }
         tk.msg("", yes_easy_text)
      else
         credits = credits_hard
         shipchoices = {
            "Llama", "Gawain", "Hyena", "Shark", "Quicksilver",
         }
         tk.msg("", yes_hard_text)
      end
      for i=1,3 do
         table.insert(ship_list, shipchoices[rnd.rnd(1, #shipchoices)])
      end
      ship_list.__save = true

      misn.setReward(fmt.credits(credits))
      hook.takeoff("takeoff")
   else
      misn.finish()
   end
end

function takeoff()
   planetvec = planet.pos(curplanet)
   misn.osdActive(1) 
   checkpoint = {}
   racers = {}
   local rad = system.cur():radius()
   local dist1 = rnd.rnd() * rad
   local angle1 = rnd.rnd() * 2 * math.pi
   local location1 = vec2.new(dist1 * math.cos(angle1),
            dist1 * math.sin(angle1))
   local dist2 = rnd.rnd() * rad
   local angle2 = rnd.rnd() * 2 * math.pi
   local location2 = vec2.new(dist2 * math.cos(angle2),
            dist2 * math.sin(angle2))
   local dist3 = rnd.rnd() * rad
   local angle3 = rnd.rnd() * 2 * math.pi
   local location3 = vec2.new(dist3 * math.cos(angle3),
            dist3 * math.sin(angle3))
   local shiptype
   if choice == 1 then
      shiptype = "Goddard"
   else
      shiptype = "Koäla"
   end
   local f = faction.dynAdd(nil, N_("Referee"), nil, {ai="stationary"})
   checkpoint[1] = pilot.add(shiptype, f, location1)
   checkpoint[2] = pilot.add(shiptype, f, location2)
   checkpoint[3] = pilot.add(shiptype, f, location3)
   for i, p in ipairs(checkpoint) do
      p:rename(string.format(n_("Checkpoint %d", "Checkpoint %d", i), i))
      p:setHilight()
      p:setInvincible()
      p:setActiveBoard()
      p:setVisible()
      p:setNoClear()
   end
   for i, s in ipairs(ship_list) do
      local p = pilot.add(s, "Civilian", curplanet, pilotname.generic())
      racers[i] = p

      if choice == 2 then
         p:outfitRm("all")
         p:outfitRm("cores")
         
         p:outfitAdd("Milspec Prometheus 2203 Core System")
         p:outfitAdd("Unicorp D-2 Light Plating")
         local en_choices = {
            "Nexus Dart 150 Engine", "Tricon Zephyr Engine" }
         p:outfitAdd(en_choices[rnd.rnd(1, #en_choices)])
         if rnd.rnd() < 0.5 then
            p:outfitAdd("Improved Stabilizer")
         end
         p:outfitAdd("Engine Reroute", 6)
      end

      p:setInvincible()
      p:setVisible()
      p:setNoClear()
      p:control()
      p:face(checkpoint[1]:pos(), true)
      p:broadcast(chatter[i])
   end

   local pp = player.pilot()
   pp:setInvincible()
   pp:control()
   pp:face(checkpoint[1]:pos(), true)

   countdown = 5 -- seconds
   omsg = player.omsgAdd(timermsg:format(countdown), 0, 50)
   counting = true
   counterhook = hook.timer(1, "counter")    
   hook.board("board")
   hook.jumpin("jumpin")
   hook.land("land")
end

function counter()
   countdown = countdown - 1
   if countdown == 0 then
      player.omsgChange(omsg, _("Go!"), 1000)
      hook.timer(1, "stopcount")
      local pp = player.pilot()
      pp:setInvincible(false)
      pp:control(false)
      counting = false
      hook.rm(counterhook)
      for i, j in ipairs(racers) do
         j:control()
         j:moveto(checkpoint[target[i]]:pos())
         hook.pilot(j, "land", "racerland")
      end
      hp1 = hook.pilot(racers[1], "idle", "racer1idle")
      hp2 = hook.pilot(racers[2], "idle", "racer2idle")
      hp3 = hook.pilot(racers[3], "idle", "racer3idle")
      player.msg(marketing)
      else
      player.omsgChange(omsg, timermsg:format(countdown), 0)
      counterhook = hook.timer(1, "counter")    
   end
end

function racer1idle(p)
   player.msg(string.format(positionmsg, p:name(),target[1]))
   p:broadcast(string.format(chatter[4], target[1]))
   target[1] = target[1] + 1
   hook.timer(2, "nexttarget1")
end
function nexttarget1()
   if target[1] == 4 then
      racers[1]:land(curplanet)
      hook.rm(hp1)
   else
      racers[1]:moveto(checkpoint[target[1]]:pos())
   end
end

function racer2idle(p)
   player.msg(string.format(positionmsg, p:name(),target[2]))
   p:broadcast(chatter[5])
   target[2] = target[2] + 1
   hook.timer(2, "nexttarget2")
end
function nexttarget2()
   if target[2] == 4 then
      racers[2]:land(curplanet)
      hook.rm(hp2)
   else
      racers[2]:moveto(checkpoint[target[2]]:pos())
   end
end
function racer3idle(p)
   player.msg(string.format(positionmsg, p:name(),target[3]))
   p:broadcast(chatter[6])
   target[3] = target[3] + 1
   hook.timer(2, "nexttarget3")
end
function nexttarget3()
   if target[3] == 4 then
      racers[3]:land(curplanet)
      hook.rm(hp3)
   else
      racers[3]:moveto(checkpoint[target[3]]:pos())
   end
end
function stopcount()
   player.omsgRm(omsg)
end
function board(ship)
   player.unboard()
   for i,j in ipairs(checkpoint) do
      if ship == j and target[4] == i then
         ship:setHilight(false)
         player.msg(string.format(positionmsg, player.name(),target[4]))
         misn.osdActive(i+1)
         target[4] = target[4] + 1
         if target[4] == 4 then
            tk.msg("", fmt.f(checkpoint_final_text,
                  {prev=i, planet=curplanet:name()}))
         else
            tk.msg("", fmt.f(checkpoint_text, {prev=i, next=i+1}))
         end
         break
      end
   end
end


function jumpin()
   mh.showFailMsg(_("You left the race."))
   misn.finish(false)
end


function racerland(p)
   player.msg(string.format(landmsg, p:name(), curplanet:name()))
end


function land()
   if target[4] == 4 then
      if racers[1]:exists() and racers[2]:exists() and racers[3]:exists() then
         tk.msg("", fmt.f(wintext, {credits=fmt.credits(credits)}))
         player.pay(credits)
         if choice == 2 then
            var.push("racing_done", true)
         end
         misn.finish(true)
      else
         tk.msg("", lose_text)
         misn.finish(false)
      end
   else
      tk.msg("", fail_left_text)
      misn.finish(false)
   end
end


function abort()
   if system.cur() == missys then
      -- Restore control in case it's currently taken away.
      local pp = player.pilot()
      pp:setInvincible(false)
      pp:control(false)
   end
end
