--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Follow Tutorial">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>1</priority>
  <chance>100</chance>
  <location>Bar</location>
  <done>Tutorial Part 4</done>
  <cond>player.numOutfit("Mercenary License") &gt; 0 and not system.cur():presences()["Pirate"]</cond>
 </avail>
 <notes>
  <campaign>Tutorial</campaign>
 </notes>
</mission>
--]]
--[[

   Follow Tutorial

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

--

   MISSION: Follow Tutorial (Ian's Courage)
   DESCRIPTION: Player escorts Ian Structure to an adjacent system.

--]]

local fmt = require "fmt"
local mh = require "misnhelper"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"


ask_text = _([[You approach Ian and wave. When he notices you, he smiles. "Ah, {player}!" He stands and firmly shakes your hand. "Pleased to meet you once again. Ah, look at that, you have a Mercenary License now! I knew you would make it this far with all that talent you showed me before when…" Ian pauses and stares blankly into space for a moment before snapping back into awareness of where he is. "Sorry. Anyway, I was just looking for a qualified pilot, and I know there's no pilot I trust more than the one who personally saved my life!

"Specifically, I need an escort to {planet} in the {system} system. See, you were such an inspiration to me, I decided to get myself a pilot license so I can travel thrû space on my own. I'd just like some protection for the first time, and I'll pay you {credits} to escort me. Can you do it?"]])

accept_text = _([["Thank you, I know it's a bit silly. The areä should be safe. It's just… you remember what happened before, right? And what if my engines fail or something and I get stuck? I just need some support for my first journey.

"Anyway, I'll meet you out in space!"]])

takeoff_text = _([[As you begin the takeoff procedure, you receive a hail from a Llama piloted by Ian. "Well met," he says. "Alright, I'm initiating takeoff. When we get into space, I will start going for the jump to {system}. All you need to do is follow me, wait for me to jump, and then jump after me. Then, when we get to {system}, you'll just need to follow me to {planet}, wait for me to land, and then land after me.

"I don't suppose you know how to tell Autonav to follow a target, do you? It'll make the journey much easier. Just target my ship by #bleft-clicking#0 on it or by pressing {target_next_key}, then press {followkey} to initiate automatic following."]])

pay_text = _([[You and Ian successfully land at his destination. When you meet up with him at the spaceport, you can tell that he's relieved nothing bad happened as he hands you your payment. "Thank you again for your assistance," he reiterates. "I think I feel a bit better about flying now, thanks to you. It'll be awhile before I can feel comfortable going into hostile space, but in the heavily patrolled places, I can rest assured now that I'm competent enough to fly on my own. Maybe I should hire some escorts, too.

"As always, working with you has been a pleasure. Maybe we'll see each other in space again as fellow pilots!" He shakes your hand and goes off on his own business.]])

misn_desc = _("Ian Structure has tasked you with escorting him so that he can begin to feel comfortable flying a ship.")
misn_log = _([[You escorted Ian Structure, who has decided to learn how to pilot a ship, safely from one planet to another without incident. He said that he feels confident enough in his flying skills to continue on his own now and hopes to meet you in space someday.]])


function create()
   startpla, startsys = planet.cur()
   misplanet = nil
   missys = nil
   for i, jp in ipairs(startsys:jumps()) do
      if not jp:hidden() and not jp:exitonly() then
         local sys = jp:dest()
         if not sys:presences()["Pirate"] then
            for j, pla in ipairs(sys:planets()) do
               if pla:canLand() then
                  misplanet = pla
                  missys = sys
                  break
               end
            end
         end
      end
      if misplanet ~= nil then
         break
      end
   end

   if misplanet == nil or missys == nil
         or not misn.claim({system.cur(), missys}) then
      misn.finish(false)
   end

   credits = 200000

   misn.setNPC(_("Ian Structure"),
         "neutral/unique/youngbusinessman.png",
         _("You find your old acquaintance, Ian Structure, sitting in the bar and studying his datapad. Perhaps you should greet him and see how he's doing."))
end


function accept()
   if tk.yesno("", fmt.f(ask_text,
         {player=player.name(), planet=misplanet:name(), system=missys:name(),
            credits=fmt.credits(credits)})) then
      tk.msg("", fmt.f(accept_text, {player=player.name()}))

      misn.accept()

      misn.setTitle(_("Ian's Courage"))
      misn.setReward(fmt.credits(credits))
      misn.setDesc(misn_desc)

      local osd_desc = {
         fmt.f(_("Follow Ian Structure by left-clicking on his ship and then pressing {followkey}, then wait for Ian Structure to jump to {system}"),
            {followkey=naev.keyGet("follow"), system=missys:name()}),
         fmt.f(_("Jump to {system}"), {system=missys:name()}),
         fmt.f(_("Follow Ian Structure and wait for him to land on {planet}"),
            {planet=misplanet:name()}),
         fmt.f(_("Land on {planet}"), {planet=misplanet:name()}),
      }
      misn.osdCreate(_("Ian's Courage"), osd_desc)

      ian_jumped = false
      ian_landed = false

      hook.takeoff("takeoff")
      hook.jumpin("jumpin")
      hook.land("land")
   else
      misn.finish()
   end
end


function spawn_ian(src)
   local p = pilot.add("Llama", "Civilian", src, _("Ian Structure"),
         {noequip=true})

   p:setHilight()
   p:setVisplayer()
   p:setInvincible()

   local plmaxspeed = player.pilot():stats().speed_max * 0.75
   local maxspeed = p:stats().speed_max
   if maxspeed > plmaxspeed then
      p:setSpeedLimit(plmaxspeed)
   end

   hook.pilot(p, "jump", "ian_jump")
   hook.pilot(p, "land", "ian_land")

   return p
end


function takeoff()
   ian = spawn_ian(startpla)
   ian:control()
   ian:hyperspace(missys)

   tk.msg("", fmt.f(takeoff_text,
         {system=missys:name(), planet=misplanet:name(),
            target_next_key=tutGetKey("target_next"),
            followkey=tutGetKey("follow")}))
end


function ian_jump()
   ian_jumped = true
   misn.osdActive(2)
end


function jumpin()
   local sys = system.cur()
   if sys ~= missys then
      mh.showFailMsg(_("You jumped into the wrong system."))
      misn.finish(false)
   elseif not ian_jumped then
      mh.showFailMsg(_("You jumped before Ian Structure did."))
      misn.finish(false)
   end
   local adjacent = false
   for i, s in ipairs(startsys:adjacentSystems()) do
      if sys == s then
         adjacent = true
      end
   end

   local source = nil
   if adjacent then
      source = startsys
   end

   ian = spawn_ian(source)
   ian:control()
   ian:land(misplanet)

   misn.osdActive(3)
end


function ian_land()
   ian_landed = true
   misn.osdActive(4)
end


function land()
   if not ian_landed or planet.cur() ~= misplanet then
      tk.msg("", _("You abandoned Ian Structure, thus aborting the mission."))
      misn.finish(false)
   end

   tk.msg("", pay_text)

   player.pay(credits)

   addMiscLog(misn_log)
   misn.finish(true)
end


function abort()
   if ian ~= nil and ian:exists() then
      ian:setHilight(false)
      ian:setVisplayer(false)
   end
   misn.finish(false)
end
