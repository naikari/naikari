--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="FLF Weak Point">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <chance>30</chance>
  <done>Disrupt a Dvaered Patrol</done>
  <location>Bar</location>
  <faction>FLF</faction>
  <faction>Frontier</faction>
  <cond>faction.playerStanding("FLF") &gt;= 20</cond>
 </avail>
 <notes>
  <done_misn name="Diversion from Raelid"/>
  <campaign>FLF Hero</campaign>
 </notes>
</mission>
--]]
--[[

   Weak Point

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
local fleet = require "fleet"
require "missions/flf/flf_common"


ask_text = _([[You approach Flint and he looks at you with faint surprise, then grins slightly. "Well, if it isn't {player}! I see you've made the right choice. I heard about your antics with those Dvaereds that ambushed you. Good on you for making the right call! We of course would've obliterated you like the rest of them if you'd taken the Dvaereds' side." He winks, and you laugh somewhat nervously as you thank him for teaching you about the plight of the frontier. When you do, you see his eyes glow in a way you've never seen them glow before. "You're welcome, and I'm glad it turned out!" he says with another wink. "You seem to be turning out to be a fine pilot, and we need all the good pilots we can get.

"Speaking of, maybe you could join me for a bit of a mission I'm about to go on! See, we've noticed that one of those Dvaered warlords is about to attack another Dvaered warlord in the {system} system, so we're going to take advantage of the situation and obliterate them in the chaos! How about it, {player}? Are you in?"]])

ask_again_text = _([["Changed your mind, {player}? It'll be great chaos over in {system} pretty soon! Would you like to join us in obliterating those Dvaered warlord fleets?"]])

yes_text = _([["Great! We'll all meet you at {system}. Let's show those Dvaereds what we're made of!"]])

no_text = _([[Flint shrugs. "Suit yourself. You'll be missing out, though. Let me know if you change your mind!"]])

pay_text = _([[You find Flint among a crowd and when he sees you, he gives you a high-five. "That was awesome!" he says. "Those Dvaereds didn't know what hit them! Glad to see how much you've grown, {player}. Hope to work with you again soon!" You give Flint a thumbs-up, then continue chatting for awhile before heading off.]])

win_msg = _("Hahaha, yes! We got them all! Let's get out of here, {player}! See you at Sindbad!")

misn_title = _("Weak Point")
misn_desc = _("You are joining Flint in on an effort to take advantage of fighting between Dvaered warlords and wipe out both sides.")

npc_name = _("Flint")
npc_desc = _("You see Flint and remember you never got a chance to thank him for teaching you about the Frontier's struggle. Perhaps you should do so.")

osd_title = _("Weak Point")
osd_desc = {}
osd_desc[1] = _("Fly to the {system} system")
osd_desc[2] = _("Destroy all Dvaereds present, taking advantage of the warlord conflict")
osd_desc[3] = _("Return to FLF base")
osd_desc["__save"] = true

log_text = _([[You helped Flint on a mission to destroy the fleets of two warlords that were fighting each other. He complimented you on your performance and said he hopes to work with you again soon.]])


function create()
   mispla, missys = planet.get("Thar")
   if not misn.claim(missys) then
      misn.finish(false)
   end

   asked = false

   misn.setNPC(npc_name, "flf/unique/flint.png", npc_desc)
end


function accept()
   local txt = ask_again_text

   if not asked then
      asked = true
      txt = ask_text
   end

   if tk.yesno("", fmt.f(txt,
            {player=player.name(), system=missys:name()})) then
      tk.msg("", fmt.f(yes_text, {system=missys:name()}))

      misn.accept()

      lastsys = system.cur()
      stage = 0
      flfships = {}
      dvships = {}

      credits = 300000
      reputation = 1

      osd_desc[1] = fmt.f(osd_desc[1], {system=missys:name()})
      misn.osdCreate(osd_title, osd_desc)

      misn.setTitle(misn_title)
      misn.setDesc(misn_desc)
      misn.setReward(fmt.credits(credits))

      marker = misn.markerAdd(missys, "high")

      hook.jumpout("jumpout")
      hook.enter("enter")
      hook.land("land")
   else
      tk.msg("", no_text)
      misn.finish()
   end
end


function jumpout()
   lastsys = system.cur()
end


function enter()
   if stage == 0 then
      if system.cur() == missys then
         pilot.clear()
         pilot.toggleSpawn(false)
         spawnFLF()
         spawnDV()
         misn.osdActive(2)
      else
         misn.osdActive(1)
      end
   end
end


function land()
   if stage == 1 and planet.cur():faction() == faction.get("FLF") then
      tk.msg("", fmt.f(pay_text, {player=player.name()}))
      player.pay(credits)
      flf_setReputation(30)
      faction.get("FLF"):modPlayer(reputation)
      flf_addLog(log_text)
      misn.finish(true)
   end
end


function pilot_attacked_dv(dvpilot, attacker)
   if attacker ~= nil and attacker:faction() == faction.get("FLF") then
      for i, p in ipairs(dvships) do
         if p:exists() then
            p:setHostile()
         end
      end

      for i, p in ipairs(flfships) do
         if p:exists() then
            p:setVisible()
         end
      end
   end
end


function pilot_death_dv(dvpilot)
   local nalive = 0  
   for i, p in ipairs(dvships) do
      if p:exists() and p ~= dvpilot then
         nalive = nalive + 1
      end
   end

   if nalive <= 0 then
      local messaged = false
      for i, p in ipairs(flfships) do
         if p:exists() then
            -- Message player for end of mission
            if not messaged then
               messaged = true
               p:comm(fmt.f(win_msg, {player=player.name()}), true)
            end

            local armor, shield = p:health()
            p:setHealth(armor, shield, 0)
            p:changeAI("flf")
         end
      end

      stage = 1
      misn.osdActive(3)
      misn.markerMove(marker, system.get("Sigur"))
      pilot.toggleSpawn(true)
   end
end


function spawnFLF()
   local origin = lastsys
   if origin == system.cur then
      origin = nil
   end

   flfships = fleet.add({4, 8, 8}, {"Pacifier", "Lancelot", "Vendetta"}, "FLF",
         origin, {N_("FLF Pacifier"), N_("FLF Lancelot"), N_("FLF Vendetta")},
         {ai="flf_norun"})

   -- Make Pacifiers no-death to ensure that Flint still lives.
   for i, p in ipairs(flfships) do
      p:setVisplayer()
      if p:ship():nameRaw() == "Pacifier" or rnd.rnd() < 0.2 then
         p:setNoDeath()
      end
   end
end


function spawnDV()
   dvships = {}
   local invsrc = vec2.new(0, 2700)

   local f1 = faction.dynAdd("Dvaered", N_("Invaders"))
   local f2 = faction.dynAdd("Dvaered", N_("Locals"))
   f1:dynEnemy(f2)
   f2:dynEnemy(f1)

   local goda = pilot.add("Dvaered Goddard", f1, invsrc,
         N_("Invading Warlord"), {ai="dvaered_norun"})
   local attackers = fleet.add({1, 2, 6, 8},
         {"Dvaered Vigilance", "Dvaered Phalanx", "Dvaered Ancestor",
            "Dvaered Vendetta"},
         f1, invsrc, N_("Invading Warlord Force"), {ai="dvaered_norun"}, goda)

   for i, p in ipairs(attackers) do
      dvships[#dvships + 1] = p
   end

   local godd = pilot.add("Dvaered Goddard", f2, mispla, N_("Local Warlord"),
         {ai="dvaered_norun"})
   local defenders = fleet.add({1, 2, 4, 4},
         {"Dvaered Vigilance", "Dvaered Phalanx", "Dvaered Ancestor",
            "Dvaered Vendetta"},
         f2, mispla, N_("Local Warlord Force"), {ai="dvaered_norun"}, godd)

   for i, p in ipairs(defenders) do
      dvships[#dvships + 1] = p
   end

   for i, p in ipairs(dvships) do
      p:setVisible()

      hook.pilot(p, "attacked", "pilot_attacked_dv")
      hook.pilot(p, "death", "pilot_death_dv")

      -- Treat landing and jumping as death so the mission doesn't end
      -- up hanging if something goes wrong. These should never get
      -- triggered, though, because the AI should be set to the norun
      -- AI.
      hook.pilot(p, "jump", "pilot_death_dv")
      hook.pilot(p, "land", "pilot_death_dv")
   end
end
