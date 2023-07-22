--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Family Suspicion">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <done>A Friend's Aid</done>
  <chance>40</chance>
  <location>Bar</location>
  <faction>Soromid</faction>
 </avail>
 <notes>
  <campaign>Coming Out</campaign>
 </notes>
</mission>
--]]
--[[

   Family Suspicion

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

local fmt = require "fmt"
local mh = require "misnhelper"
local tablehelper = require "tablehelper"
require "nextjump"
require "missions/soromid/common"


ask_text = _([[Chelsea looks at you with surprise. "Oh! {player}! It's nice to see you again! I, uh, decided to change my pronouns. I'm using they/them pronouns again." You thank them for telling you and ask what they're looking at. "Oh, information about this gang we got in hot water with. They call themselves the 'Imperyan Brotherhood' and they're a vicious anti-Soromid organization. They claim the Soromid are 'degenerating' Imperial society with their gene treatments, the ones that saved them from the plague of Sorom. Really bigoted stuff.

"But what really troubles me is, I remember my dad talking about 'the brotherhood' on occasion. It could be a coincidence, but if there's a connection… but then again, going there myself could be pretty dangerous. Too many pirates around, and besides, if there's anything behind my hunch, this could go south real fast.

"Actually, maybe you could help! Could you meet me on {startplanet} in the {startsystem} system and then escort me to {destplanet} in the {destsystem} system and back, and back me up while I confront my parents? I could give you, say, {credits} in exchange."]])

yes_text = _([["You're a life-saver, {player}, maybe literally! That's perfect. I'll meet you on {planet}, then, and we'll go from there."]])

no_text = _([["Ah, if you're too busy, that's OK. I'll have to investigate some other time, I guess. Let me know if you change your mind!"]])

ask_again_text = _([["Ah, {player}! I could still use your help guiding me from {startplanet} in the {startsystem} system to {destplanet} in the {destsystem} system and back for {credits}. Are you up for it now?"]])

darkshed_text = _([[You meet up with Chelsea. "Hello again, {player}!" they say with a wave. "I'm all ready to head to {planet}! Like last time, I'll need you to follow me along, make sure I finish jumping or landing before you do, and help me shoot down any hostilities. See you out in space!"]])

home_text = {}
home_text[1] = _([[You land and dock on {destplanet} with trepidation and meet up with Chelsea. It seems they're just as tense as you are. They make a phone call, presumably to their parents, asking to meet them at the bar for "some catching up". They then hang up and look at you with a serious expression. "I seriously hope my hunch is wrong. Those Imperyan Brotherhood types, you saw how dangerous they can be. Absolutely vicious and won't rest until you're dead the second they think you're a… well. I don't want to repeat the horrible thing they say about the Soromid. So be ready for anything, OK?" You nod, and you head to the bar with Chelsea.

After a half hour or so of waiting, Chelsea points out a couple entering the bar, a respectable-looking man and woman. They must be her parents. When they see Chelsea, they walk over and warmly greet Chelsea, but do so using a name you don't recognize. Chelsea sighs. "I told you, that's not my name anymore. It's 'Chelsea'. And I'm using they/them pronouns now."]])
home_text[2] = _([["Ah, right, I'm so sorry about that," Chelsea's mom says after a short pause. "This is so hard! I know I slip up sometimes, but don't you worry, I'm trying my best. I've known you as C– uh, your old name for so long, it's going to take awhile to get used to 'Chelsea'."

"They pronouns?" Chelsea's father raises an eyebrow as he speaks. "That's a plural noun, how's that work?"

"It's just singular 'they', dad," Chelsea responds with a tinge of annoyance that they're clearly trying to hide. "You use it all the time without realizing it. It dates back to centuries before space travel."]])
home_text[3] = _([[Chelsea's father shrugs. "I don't get it, but whatever makes you happy, I guess. So, tell me, son– uh, er, I mean, kid. What brings you here?"

"Oh, um, I just wanted to catch up with you, is all. I'm doing real well as a pilot in Soromid space."

Chelsea's father frowns. "You should be careful there. Lots of scammers, you know?"

"Oh, I'm sure he wouldn't make that mistake," Chelsea's mother says reassuringly. "I mean, look at {player} there! An Imperial thru and thru!" She addresses you. "You wouldn't let him– er, I mean, them get into trouble with… unsavory sorts, right?" You raise an eyebrow.]])
home_text[4] = _([["It's the government I worry about," Chelsea's father interjects. "It's in the pocket of big genetics, you know? Those bio-augmenters, they're swindlers." He looks into Chelsea's eyes. "You haven't been working with the government, have you? That backwards Soromid government?"

Chelsea frowns. "So what if I was?"

"You mean to tell me you have?!" Chelsea's father slams his fist on the table. "I just told you what if! Swindlers! Crooks! They're trying to tear down Imperial civilization, and now they're trying to take my son away! Don't you see, kid? The Sorofreak government is brainwashing you! How long do we have to humor you on this bullshit until you see it's all a Sorofreak ploy?!"]])
home_text[5] = _([[Chelsea stares with shock as the truth starts to emerge. Their mother puts her hand on her husband's shoulder as she speaks to Chelsea. "Look, you'll always be our son. We're just worried about you." A moment of silence follows.

Chelsea breaks the silence. "Those things you're saying about the Soromid… dad, that 'Brotherhood' you always talked about. That was the Imperyan Brotherhood, wasn't it?"

Their father frowns. "Yes, and I should have brought you into it a long time ago. Look at what's happened to you. Those Sorofreaks have messed with your mind." He holds out a hand. "I'm tired of pretending. Let's be real here. Come on, son, I'm sure you've developed some great piloting skills. We could use you in the Brotherhood. Forget that fantasy of turning into a girl or whatever. You can't fight biology. It's not the course of nature. But with the Brotherhood, you can become the man you were always meant to be."]])
home_text[6] = _([["Mom, dad… I'm not your son, I never was, and I never will be. If you've been lying to me about accepting it all this time–"

"So the Sorofreaks really have gotten to you," their mother interrupts. "I guess {player} must not be such an upstanding Imperial after all. I'd bet both of you are Sorofreak-lovers."

"Yeah, you know what?" Chelsea's father says. "You're right, 'Chelsea'. You're not my son. My son would be smarter than you. He wouldn't take a job from the Sorofreaks like an idiot and let them turn him against his own father, his own kind. Yeah, that's not you, subhuman Sorofreak-lover." You catch a glimpse of a laser gun. Acting almost instinctively, you kick the table into Chelsea's parents, knocking them down and causing the father to drop his laser gun. You tell Chelsea to run and meet you out in space. As you and Chelsea climb into your ships and initiate takeoff, you have a feeling you won't be safe just yet when you get to space.]])

end_text = _([[After finishing docking procedures on {planet}, you meet a dejected Chelsea. You offer your condolences. "Thank you, {player}," they reply. "You know, I always knew my parents weren't perfect, but I thought they were good. I thought they were telling the truth when they said they accepted me. And I never fully appreciated the gravity of the things they said, or that they had such bigoted attitudes toward the Soromid.

"I've made up my mind. I'm going to train to become a great pilot, and I'm going to do whatever I can to help put an end to the Imperyan Brotherhood. Knowing that I was raised by people in that vile hate group… I can't ignore them." Chelsea hands you a credit chip. "Thank you for your help, {player}. I'm going to continue to improve my ship and my skills as a pilot. I hope to see you again when I'm stronger." You wish them luck and part ways.]])

left_fail_text = _("You have lost contact with Chelsea and therefore failed the mission.")

misn_title = _("Family Suspicion")
misn_desc = _("Chelsea has hired you to escort her to {planet} in the {system} system so she can investigate a possible connection between her parents and the Imperyan Brotherhood.")

log_text = _([[You assisted Chelsea, who now uses they/them pronouns, in confronting their parents about a hunch. As you did so, you discovered that their parents were actually unaccepting of Chelsea coming out as trans all along, and that their father is affiliated with the vicious anti-Soromid gang, the Imperyan Brotherhood. Chelsea's father attempted to kill them, calling them a "subhuman Sorofreak-lover", but they managed to escape with your help. Chelsea resolved to become a great pilot and help fight against the Imperyan Brotherhood.]])


function create ()
   startplanet, startsys = planet.get("Darkshed")
   destplanet, destsys = planet.get("Durea")

   local claimsys = {startsys, destsys}
   for i, jp in ipairs(startsys:jumpPath(destsys)) do
      local dest = jp:dest()
      if not tablehelper.inTable(claimsys, dest) then
         table.insert(claimsys, dest)
      end
   end
   for i, jp in ipairs(destsys:jumpPath(startsys)) do
      local dest = jp:dest()
      if not tablehelper.inTable(claimsys, dest) then
         table.insert(claimsys, dest)
      end
   end
   if not misn.claim(claimsys) then
      misn.finish(false)
   end

   credits = 600000
   started = false

   misn.setNPC(_("Chelsea"), "soromid/unique/chelsea.png",
         _("Chelsea is staring at a datapad with a troubled expression."))
end


function accept ()
   local txt
   if started then
      txt = ask_again_text
   else
      txt = ask_text
   end
   started = true

   if tk.yesno("", fmt.f(txt,
         {player=player.name(), destplanet=destplanet:name(),
            destsystem=destsys:name(), startplanet=startplanet:name(),
            startsystem=startsys:name(), credits=fmt.credits(credits)})) then
      tk.msg("", fmt.f(yes_text,
            {player=player.name(), planet=startplanet:name()}))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setDesc(fmt.f(misn_desc,
            {planet=destplanet:name(), system=destsys:name()}))
      misn.setReward(fmt.credits(credits))
      marker = misn.markerAdd(startsys, "plot")

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system)"),
               {planet=startplanet:name(), system=startsys:name()}),
         fmt.f(_("Escort Chelsea to {planet} ({system} system)"),
               {planet=destplanet:name(), system=destsys:name()}),
      }
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


function createFactions()
   local f1 = faction.dynAdd("Mercenary", "Chelsea_f", N_("Civilian"))
   local f2 = faction.dynAdd("Mercenary", N_("Imperyan Brotherhood"))
   f1:dynEnemy(f2)
   f1:dynEnemy("Pirate")
   f1:setPlayerStanding(100)
   f2:setPlayerStanding(-20)
end


function spawnChelseaShip(param)
   local f = faction.dynAdd("Mercenary", "Chelsea_f", N_("Civilian"))
   chelsea = pilot.add("Llama", f, param, _("Chelsea"), {naked=true})
   chelsea:outfitAdd("Milspec Aegis 3601 Core System")
   chelsea:outfitAdd("Unicorp Hawk 300 Engine")
   chelsea:outfitAdd("S&K Light Combat Plating")
   chelsea:outfitAdd("Plasma Turret MK1", 2)
   chelsea:outfitAdd("Small Shield Booster")
   chelsea:outfitAdd("Rotary Turbo Modulator")
   chelsea:outfitAdd("Shield Capacitor", 2)

   chelsea:setHealth(100, 100)
   chelsea:setEnergy(100)
   chelsea:setTemp(0)
   chelsea:setFuel(true)

   chelsea:setFriendly()
   chelsea:setHilight()
   chelsea:setVisible()
   chelsea:setInvincPlayer()
   chelsea:setNoBoard()

   local plmax = player.pilot():stats().speed_max * 0.8
   if chelsea:stats().speed_max > plmax then
      chelsea:setSpeedLimit(plmax)
   end

   hook.pilot(chelsea, "death", "chelsea_death")
   hook.pilot(chelsea, "jump", "chelsea_jump")
   hook.pilot(chelsea, "land", "chelsea_land")
   hook.pilot(chelsea, "attacked", "chelsea_attacked")

   chelsea_jumped = false

   if faction.get("Empire"):playerStanding() >= 0 then
      -- Spawn a bunch of Empire to help keep pirates busy
      local merc_ships = {
         "Empire Shark", "Empire Lancelot", "Empire Admonisher",
         "Empire Pacifier", "Empire Hawking", "Empire Peacemaker",
      }
      local r = system.cur():radius()
      for i=1,20 do
         local shipname = merc_ships[rnd.rnd(1, #merc_ships)]
         local param = vec2.new(rnd.rnd(-r, r), rnd.rnd(-r, r))
         pilot.add(shipname, "Empire", param)
      end
   end
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
         local osd_desc = {
            fmt.f(_("Protect Chelsea and wait for them to land on {planet}"),
                  {planet=misplanet:name()}),
            fmt.f(_("Land on {planet}"), {planet=misplanet:name()}),
         }
         misn.osdCreate(misn_title, osd_desc)
      else
         local nextsys = getNextSystem(system.cur(), missys)
         local jumps = system.cur():jumpDist(missys)
         chelsea:hyperspace(nextsys, true)
         local osd_desc = {
            fmt.f(_("Protect Chelsea and wait for them to jump to {system}"),
                  {system=nextsys:name()}),
            fmt.f(_("Jump to {system}"), {system=nextsys:name()}),
         }
         if jumps > 1 then
            table.insert(osd_desc,
                  fmt.f(n_("{remaining} more jump after this one",
                        "{remaining} more jumps after this one", jumps - 1),
                     {remaining=fmt.number(jumps - 1)}))
         end
         misn.osdCreate(misn_title, osd_desc)
      end
      if chelsea_jumped then
         misn.osdActive(2)
      end
   end
end


function takeoff()
   if stage == 2 and system.cur() == startsys then
      spawnChelseaShip(startplanet)
      jumpNext()
   elseif stage >= 3 and system.cur() == destsys then
      player.allowLand(false, _("It's too dangerous to land here right now."))
      hook.timer(10, "ambush_timer")
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
         mh.showFailMsg(_("You have abandoned the mission."))
         misn.finish(false)
      end
   end
end


function land ()
   if stage == 1 and planet.cur() == startplanet then
      tk.msg("", fmt.f(darkshed_text,
            {player=player.name(), planet=destplanet:name(),
               system=destsys:name()}))
      stage = 2
      misn.osdActive(2)
      misn.markerRm(marker)
      marker = misn.markerAdd(destsys, "high")
   elseif stage == 2 then
      if chelsea_jumped and planet.cur() == destplanet then
         for i, s in ipairs(home_text) do
            tk.msg("", fmt.f(s,
                  {player=player.name(), destplanet=destplanet:name(),
                     destsystem=destsys:name(), startplanet=startplanet:name(),
                     startsystem=startsys:name()}))
         end

         stage = 3
         misn.markerRm(marker)
         marker = misn.markerAdd(startsys, "high")

         player.allowSave(false)
         player.takeoff()
         player.allowSave()
      else
         tk.msg("", left_fail_text)
         misn.finish(false)
      end
   elseif stage >= 3 then
      if chelsea_jumped and planet.cur() == startplanet then
         tk.msg("", fmt.f(end_text,
               {player=player.name(), planet=startplanet:name()}))
         player.pay(credits)
         srm_addComingOutLog(log_text)
         misn.finish(true)
      else
         tk.msg("", left_fail_text)
         misn.finish(false)
      end
   end
end


function ambush_timer()
   local f = faction.dynAdd("Mercenary", N_("Imperyan Brotherhood"))
   local goonships = {
      "Vendetta", "Hyena", "Hyena",
   }
   local leadergoon
   for i, shiptype in ipairs(goonships) do
      local p = pilot.add(shiptype, f, destplanet,
            fmt.f(_("Gangster {ship}"), {ship=_(shiptype)}))
      p:setHostile()
      p:setLeader(leadergoon)

      if i == 1 then
         leadergoon = p
      end
   end

   if stage == 3 then
      leadergoon:comm(_("You heard the boss, folks! Get them!"))
      stage = 4
   end
end


function chelsea_death ()
   mh.showFailMsg(_("A rift in the space-time continuum causes you to have never met Chelsea in that bar."))
   misn.finish(false)
end


function chelsea_jump(p, jump_point)
   local missys = destsys
   if stage >= 3 then
      missys = startsys
   end
   if jump_point:dest() == getNextSystem(system.cur(), missys) then
      player.msg(fmt.f(_("Chelsea has jumped to {system}."),
            {system=jump_point:dest():name()}))
      chelsea_jumped = true
      misn.osdActive(2)
   else
      mh.showFailMsg(_("Chelsea has abandoned the mission."))
      misn.finish(false)
   end
end


function chelsea_land(p, planet)
   local misplanet = destplanet
   if stage >= 3 then
      misplanet = startplanet
   end
   if planet == misplanet then
      player.msg(fmt.f(_("Chelsea has landed on {planet}."),
            {planet=planet:name()}))
      chelsea_jumped = true
      misn.osdActive(2)
   else
      mh.showFailMsg(_("Chelsea has abandoned the mission."))
      misn.finish(false)
   end
end


function chelsea_attacked()
   if chelsea ~= nil and chelsea:exists() then
      chelsea:control(false)
      hook.rm(distress_timer_hook)
      distress_timer_hook = hook.timer(1, "chelsea_distress_timer")
   end
end


function chelsea_distress_timer()
   jumpNext()
end
