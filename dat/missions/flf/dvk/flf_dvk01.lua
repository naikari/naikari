--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="FLF Weak Point">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <chance>60</chance>
  <done>Disrupt a Dvaered Patrol</done>
  <location>Bar</location>
  <faction>FLF</faction>
  <cond>faction.playerStanding("FLF") &gt;= 10</cond>
 </avail>
 <notes>
  <campaign>Save the Frontier</campaign>
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


ask_text = _([[Benito smiles as you approach her. "Hello again, {player}!" she says. "I have another mission for you, should you choose to accept it. See, we've noticed that one of those Dvaered warlords is about to attack another Dvaered warlord in the {system} system, so we're goïng to take advantage of the situation and obliterate them in the chaös! These two warlords are particularly vocal about wanting to invade the Frontier, so eliminating both of them should strike a blow to invasionist sentiment, at least temporarily. Would you be interested in joining the operation?"]])

ask_again_text = _([["Oh, {player}, it's you again! Well, have you changed your mind? Would you like to help obliterate those Dvaered warlord fleets in the {system} system?"]])

yes_text = _([["Fantastic! The rest of the fleet will meet you in the {system} system. Try not to get yourself killed!" She winks, and you let out a slightly nervous laugh.]])

no_text = _([["OK, I understand. Let me know if you change your mind."]])

pay_text = _([[As you dock, you see that Benito is already waiting for you with a warm smile. She gives you a thumbs-up as you approach. "You did a fine job," she says. "Those Dvaereds didn't know what hit them! Glad to see how much you've grown, {player}. I look forward to working with you again soon." You give Benito a thumbs-up in return, then she excuses herself to attend to other matters while you meet up with the others you fought with and celebrate the victory.]])

win_msg = _("Hahaha, yes! We got them all! Let's get out of here, {player}! See you at Sindbad!")

misn_title = _("Weak Point")
misn_desc = _("You are joining and FLF fleet in on an effort to take advantage of fighting between Dvaered warlords and wipe out both sides.")

npc_name = _("Benito")
npc_desc = _("Benito seems to want to speak with you.")

osd_title = _("Weak Point")
osd_desc = {}
osd_desc[1] = _("Fly to the {system} system")
osd_desc[2] = _("Destroy all Dvaereds present, taking advantage of the warlord conflict")
osd_desc[3] = _("Return to FLF base")
osd_desc["__save"] = true

log_text = _([[You participated in a mission to destroy the fleets of two warlords that were fighting each other.]])


function create()
   mispla, missys = planet.get("Thar")
   if not misn.claim(missys) then
      misn.finish(false)
   end

   asked = false

   misn.setNPC(npc_name, "flf/unique/benito.png", npc_desc)
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
      reputation = 5

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
         origin, {_("FLF Pacifier"), _("FLF Lancelot"), _("FLF Vendetta")},
         {ai="flf_norun"})

   -- Make Pacifiers no-death to ensure that some wingmates still live.
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
         _("Invading Warlord"), {ai="dvaered_norun"})
   local attackers = fleet.add({1, 2, 6, 8},
         {"Dvaered Vigilance", "Dvaered Phalanx", "Dvaered Ancestor",
            "Dvaered Vendetta"},
         f1, invsrc, _("Invading Warlord Force"), {ai="dvaered_norun"}, goda)

   for i, p in ipairs(attackers) do
      dvships[#dvships + 1] = p
   end

   local godd = pilot.add("Dvaered Goddard", f2, mispla, _("Local Warlord"),
         {ai="dvaered_norun"})
   local defenders = fleet.add({1, 2, 4, 4},
         {"Dvaered Vigilance", "Dvaered Phalanx", "Dvaered Ancestor",
            "Dvaered Vendetta"},
         f2, mispla, _("Local Warlord Force"), {ai="dvaered_norun"}, godd)

   for i, p in ipairs(defenders) do
      dvships[#dvships + 1] = p
   end

   for i, p in ipairs(dvships) do
      p:setVisible()
      p:memory().nosteal = true

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

