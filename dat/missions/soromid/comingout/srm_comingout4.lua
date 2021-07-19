--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Visiting Family">
  <flags>
   <unique />
  </flags>
  <avail>
   <priority>2</priority>
   <done>A Friend's Aid</done>
   <chance>10</chance>
   <location>Bar</location>
   <faction>Soromid</faction>
  </avail>
  <notes>
   <campaign>Coming Out</campaign>
  </notes>
 </mission>
 --]]
 --[[

   Visiting Family

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

--]]

require "numstring"
require "nextjump"
require "missions/soromid/common"


ask_text = _([[Chelsea greets you as before. "Hi, %s! It's so nice to see you again!" The two of you talk about your travels once again. "I'm using they/them pronouns again," they eventually say. "I've done more soul-searching and found that nonbinary transfeminine feels right to me." You thank them for telling you. "You're welcome!" they say. "And thank you for respecting that! I sure hope my parents do too. I was thinking of meeting up with them back at %s, but I must admit that I'm a bit nervous and not entirely sure if my ship is up for getting through that part of space yet.

"Oh! Actually, maybe you could help! I could meet up with you at %s and then you could escort me to %s. And I know I'd feel a lot better talking about this with my parents if you were there. What do you think, is that something you can do? I'll pay you, of course."]])

yes_text = _([["Thank you so much! Like I said, I'll meet you at %s; I can get that far on my own. See you soon!"]])

no_text = _([["Ah, busy, eh? That's OK. Let me know later if you can do it!"]])

ask_again_text = _([["Oh, %s! Have you changed your mind? Can you help me get to %s?"]])

darkshed_text = _([[You meet up with Chelsea. "Hello again, %s!" they say. "I'm all ready for takeoff! Like last time, I'll need you to follow me along, make sure I finish jumping or landing before you do, and help me shoot down any hostilities. See you out in space!"]])

home_text = {}
home_text[1] = _([[You land and dock on %s, then meet up with both of Chelsea's parents. They welcome Chelsea and their mother gives them a warm hug, then releases them. Chelsea's father slightly waves, and the three of them start chatting.

Eventually, the topic of Chelsea's gender comes up. Chelsea explains that they are nonbinary and now use they/them pronouns similarly to when they explained it to you. Their mother thanks them and hugs them.

Chelsea's father sighs. "Well, if you really wanna go with that, I guess I'll humor you." You look over at Chelsea; it's obvious that they're hurt by this.]])
home_text[2] = _([[Chelsea's mother speaks up. "What do you mean, 'humor' them? You don't believe your own child about their personal experiences?"

"I mean, you wanna identify as 'nonbinary' or a Kestrel or whatever because it makes you feel better, we both know that's not true, but at least you're not one of those those sorofreaks."

You see a look of shock on Chelsea's face, followed by a glare aimed at their father. "What do you think you're doing, using that slur? The Soromid are people just like us! And I'm not pretending! Do you honestly think I'm fooling around and lying to you because it 'makes me feel better'? I'm telling you that I'm nonbinary because I really am nonbinary."]])
home_text[3] = _([[Chelsea's father sighs. "Look, you're my son, and you always will be, but those sorofreaks are messing with your head. You need to come back to the real world eventually. I know you will."

Chelsea snaps back. "I won't sit here and listen to you attacking the Soromid like that! I've made some great friends with Soromid folks! Business partners even! And it's a Soromid who gave me treatments to make me more comfortable in my body!

"I am not your son, dad, and I never will be. I'm your nonbinary child, whether you accept me or not. Not because of the Soromid 'messing with my head', but because that's what my gender is. You have no right to stop me from doing what makes me happy."]])
home_text[4] = _([[Chelsea's father pauses. "So you're even making business deals with sorofreaks, huh? And you're thoroughly convinced that you're this 'nonbinary' nonsense. It's like you've become a sorofreak yourself." He reaches for something you can't see. "You know what? You're right. You're not my son. I won't stand by and let  the sorofreak agenda plague this galaxy!"

Suddenly, Chelsea's mother tackles her husband. That's when you see what he was reaching for: a laser gun. The two start to wrestle for control as Chelsea's mother shouts. "Run! Both of you! Get out of here!" Not needing to be told twice, you grab Chelsea's arm and run as fast as you can. Just as you make it out of view, you hear the laser gun fire.

With no time to lose, you and Chelsea dash into your ships and immediately start launch procedures just in time to see Chelsea's father appear and attempt to fire his weapon at Chelsea. The shots hit their ship, but deflect harmlessly off of their shields. Chelsea sends you a message saying that they're setting course for %s immediately.]])

end_text = _([[After docking on %s, you meet up again with Chelsea to see them sobbing and frustrated. "I should have known I couldn't trust him! He never was openly accepting when I came out as trans to him before and misgendered me multiple times, but I just hoped it was in my imagination, you know? And I had no idea he was so bigoted against the Soromid!" You tell Chelsea that it's not their fault. "I know, it's just… I hope my mother is OK."

They wipe the tears from their eyes. "He had thugs on our tail shortly after we left and that tells me that this isn't over. I'll need to make sure I'm prepared when I face trouble from him again. Heck, maybe I should get more of a battle-hardened ship.

"Thank you for your help, %s. This isn't the outcome that I wanted but I honestly could have died there if it wasn't for you. Here." They hand you a credit chip. "The payment I promised. I need to go build up my strength. Next time I see you, I swear, I'll have a ship that won't be left in a vulnerable position when I run into trouble!" You offer a hug and say your goodbyes, hoping that Chelsea will be OK.]])

left_fail_text = _("You have lost contact with Chelsea and therefore failed the mission.")

misn_title = _("Visiting Family")
misn_desc = _("Chelsea wants to revisit their family in %s. They have asked you to escort them to there from %s.")

npc_name = _("Chelsea")
npc_desc = _("You see Chelsea in the bar and feel an urge to say hello.")

cheljump_msg = _("Chelsea has jumped to %s.")
chelland_msg = _("Chelsea has landed on %s.")
chelkill_msg = _("MISSION FAILED: A rift in the space-time continuum causes you to have never met Chelsea in that bar.")
chelflee_msg = _("MISSION FAILED: Chelsea has abandoned the mission.")
plflee_msg = _("MISSION FAILED: You have abandoned the mission.")

ambush_msg = _("You heard the boss, folks! Get them!")
noland_msg = _("It's too dangerous to land here right now.")

log_text = _([[You escorted Chelsea, who requests they/them pronouns now, to Durea so that they could see their parents. However, Chelsea's father turned on them because of their gender identity and dealings with the Soromid, aiming a laser gun at Chelsea before he was tackled and held back by Chelsea's mother. You didn't see what happened, but as you and Chelsea ran away, you heard a gunshot. Chelsea's father then caught up with you as you began launch procedures, attempted to fire his laser gun at Chelsea's ship, and then sent a group of thugs after you as you escorted Chelsea to safety.

Chelsea has vowed to strengthen their ship so they aren't left in a vulnerable position again.]])


function create ()
   startplanet, startsys = planet.get("Darkshed")
   destplanet, destsys = planet.get("Durea")
   if not misn.claim(destsys) then misn.finish(false) end

   credits = 600000
   started = false

   misn.setNPC(npc_name, "soromid/unique/chelsea.png", npc_desc)
end


function accept ()
   local txt
   if started then
      txt = ask_again_text:format(player.name(), destplanet:name())
   else
      txt = ask_text:format(player.name(), destplanet:name(),
            startplanet:name(), destplanet:name())
   end
   started = true

   if tk.yesno("", txt) then
      tk.msg("", yes_text:format(startplanet:name()))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setDesc(misn_desc:format(destplanet:name(), startplanet:name()))
      misn.setReward(creditstring(credits))
      marker = misn.markerAdd(startsys, "low")

      local osd_desc = {}
      osd_desc[1] = string.format(_("Land on %s (%s system)"),
            startplanet:name(), startsys:name())
      osd_desc[2] = string.format(_("Escort Chelsea to %s"),
            destsys:name(), destplanet:name())
      misn.osdCreate(misn_title, osd_desc)

      stage = 1

      hook.takeoff("takeoff")
      hook.jumpin("jumpin")
      hook.jumpout("jumpout")
      hook.land("land")
   else
      tk.msg("", no_text)
      misn.finish()
   end
end


function spawnChelseaShip( param )
   chelsea = pilot.add(
         "Llama", "Comingout_associates", param, _("Chelsea"), {naked=true})
   chelsea:addOutfit("Milspec Aegis 3601 Core System")
   chelsea:addOutfit("Unicorp Hawk 300 Engine")
   chelsea:addOutfit("S&K Light Combat Plating")
   chelsea:addOutfit("Plasma Turret MK1", 2)
   chelsea:addOutfit("Small Shield Booster")
   chelsea:addOutfit("Improved Refrigeration Cycle")
   chelsea:addOutfit("Shield Capacitor", 2)

   chelsea:setHealth(100, 100)
   chelsea:setEnergy(100)
   chelsea:setTemp(0)
   chelsea:setFuel(true)

   chelsea:setFriendly()
   chelsea:setHilight()
   chelsea:setVisible()
   chelsea:setInvincPlayer()

   hook.pilot(chelsea, "death", "chelsea_death")
   hook.pilot(chelsea, "jump", "chelsea_jump")
   hook.pilot(chelsea, "land", "chelsea_land")
   hook.pilot(chelsea, "attacked", "chelsea_attacked")

   chelsea_jumped = false
end


function jumpNext ()
   local missys = destsys
   local misplanet = destplanet
   if stage >= 3 then
      missys = startsys
      misplanet = startplanet
   end

   if chelsea ~= nil and chelsea:exists() then
      chelsea:taskClear()
      chelsea:control()
      misn.osdDestroy()
      if system.cur() == missys then
         chelsea:land(misplanet, true)
         local osd_desc = {}
         osd_desc[1] = string.format(
               _("Protect Chelsea and wait for her to land on %s"),
               misplanet:name())
         osd_desc[2] = string.format(_("Land on %s"), misplanet:name())
         misn.osdCreate(misn_title, osd_desc)
      else
         local nextsys = getNextSystem(system.cur(), missys)
         local jumps = system.cur():jumpDist(missys)
         chelsea:hyperspace(nextsys, true)
         local osd_desc = {}
         osd_desc[1] = string.format(
               _("Protect Chelsea and wait for her to jump to %s"),
               nextsys:name())
         osd_desc[2] = string.format(_("Jump to %s"), nextsys:name())
         if jumps > 1 then
            osd_desc[3] = string.format(
                  _("%s more jumps after this one"), numstring(jumps - 1))
         end
         misn.osdCreate(misn_title, osd_desc)
      end
   end
end


function takeoff ()
   player.allowSave(true)
   if stage == 2 and system.cur() == startsys then
      spawnChelseaShip(startplanet)
      jumpNext()
   elseif stage >= 3 and system.cur() == destsys then
      player.allowLand(false, noland_msg)
      hook.timer(10000, "ambush_timer")
      spawnChelseaShip(destplanet)
      jumpNext()
   end
end


function jumpout ()
   lastsys = system.cur()
end


function jumpin ()
   if stage >= 2 then
      local missys = destsys
      if stage >= 3 then
         missys = startsys
      end
      if chelsea_jumped and system.cur() == getNextSystem(lastsys, missys) then
         spawnChelseaShip(lastsys)
         jumpNext()
      else
         fail(plflee_msg)
      end
   end
end


function land ()
   if stage == 1 and planet.cur() == startplanet then
      tk.msg("", darkshed_text:format(player.name()))
      stage = 2
      if marker ~= nil then misn.markerRm(marker) end
      marker = misn.markerAdd(destsys, "high")
   elseif stage == 2 then
      if chelsea_jumped and planet.cur() == destplanet then
         player.allowSave(false)

         tk.msg("", home_text[1]:format(destplanet:name()))
         tk.msg("", home_text[2])
         tk.msg("", home_text[3])
         tk.msg("", home_text[4]:format(startplanet:name()))

         stage = 3
         if marker ~= nil then misn.markerRm(marker) end
         marker = misn.markerAdd(startsys, "high")

         player.takeoff()
      else
         tk.msg("", left_fail_text)
         misn.finish(false)
      end
   elseif stage >= 3 then
      if chelsea_jumped and planet.cur() == startplanet then
         tk.msg("", end_text:format(startplanet:name(), player.name()))
         player.pay(credits)
         srm_addComingOutLog(log_text)
         misn.finish(true)
      else
         tk.msg("", left_fail_text)
         misn.finish(false)
      end
   end
end


function ambush_timer ()
   local thugships = {
      "Vendetta", "Hyena", "Hyena",
   }
   local leaderthug
   for i, shiptype in ipairs(thugships) do
      local p = pilot.add(shiptype, "Comingout_thugs", destplanet,
            _("Thug %s"):format(_(shiptype)))
      p:setHostile()
      p:setLeader(leaderthug)

      if i == 1 then
         leaderthug = p
      end
   end

   if stage == 3 then
      leaderthug:comm(ambush_msg)
      stage = 4
   end
end


function chelsea_death ()
   fail(chelkill_msg)
end


function chelsea_jump( p, jump_point )
   local missys = destsys
   if stage >= 3 then
      missys = startsys
   end
   if jump_point:dest() == getNextSystem(system.cur(), missys) then
      player.msg(cheljump_msg:format(jump_point:dest():name()))
      chelsea_jumped = true
      misn.osdActive(2)
   else
      fail(chelflee_msg)
   end
end


function chelsea_land( p, planet )
   local misplanet = destplanet
   if stage >= 3 then
      misplanet = startplanet
   end
   if planet == misplanet then
      player.msg(chelland_msg:format(planet:name()))
      chelsea_jumped = true
      misn.osdActive(2)
   else
      fail(chelflee_msg)
   end
end


function chelsea_attacked ()
   if chelsea ~= nil and chelsea:exists() then
      chelsea:control(false)
      if distress_timer_hook ~= nil then hook.rm(distress_timer_hook) end
      distress_timer_hook = hook.timer(1000, "chelsea_distress_timer")
   end
end


function chelsea_distress_timer ()
   jumpNext()
end


-- Fail the mission, showing message to the player.
function fail( message )
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
