--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="A Friend's Aid">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <done>Coming of Age</done>
  <chance>70</chance>
  <location>Bar</location>
  <faction>Soromid</faction>
  <cond>
   faction.get("Soromid"):playerStanding() >= 0
   and player.numOutfit("Mercenary License") &gt; 0
   and (var.peek("comingout_time") == nil
      or time.get() &gt;= time.fromnumber(var.peek("comingout_time")) + time.create(0, 20, 0))
  </cond>
 </avail>
 <notes>
  <campaign>Coming Out</campaign>
 </notes>
</mission>
--]]
--[[

   A Friend's Aid

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
require "cargo_common"
require "nextjump"
require "missions/soromid/common"


ask_text = _([[Chelsea gleefully waves you over. "{player}! It's nice to see you again!" she says. "And perfect timing! I was just looking for help from another pilot, but everyone I've talked to isn't up to it. With all the adventures you've been on, I'm sure it'll be a cinch for you!

"See, I got a… well, I can't say exactly, but a special contract that they say is goïng to get me in some hot water with some sort of militant anti-Soromid gang. Not just pirates, mind; they said I can expect to be bombarded by them like there's no tomorrow, which is why I can't go alone. {planet} in the {system} system is my destination, and as soon as you finish escorting me there, you'll be paid {credits}. So, what do you think? Wanna see how good of a team we make?"]])

start_text = _([["Perfect! I must admit that though I'm a bit scared, I'm also kind of excited to see what my ship can do when I push it to the limit! Remember, follow my lead and make sure I jump before you do. I'll assist with combat as much as I can, but my ship is built for cargo moreso than combat, so just be prepared for that.

"I'll meet you out in space when you're ready. See you there!"]])

no_text = _([["Dang, you would have been perfect. Oh well, I know it's a lot to ask. Let me know if you change your mind."]])

ask_again_text = _([["Oh, hi again, {player}! Have you changed your mind about escorting me to {planet} in the {system} system? The {credits} offer still stands."]])

left_fail_text = _("You have lost contact with Chelsea and therefore failed the mission.")

success_text = _([[As you and Chelsea land, you notice, to your surprise, a contingent of Soromid military forces waiting. Chelsea seems to have been expecting this, however. So that's the kind of contract she got.

As Chelsea's cargo is swiftly unloaded, an officer approaches her and says some words to her that you can't make out, handing her a credit chip. The officer then approaches you. "{player}, yes? I must thank you for your assistance in this mission. It sounds like you've done a fantastic service. I apologize for not revealing the full scope of the mission to you, but it was a matter of national security. I trust you understand." She hands you a credit chip with the promised payment. "I hope we meet again sometime, {player}. The same goes for Chelsea." She shakes your hand and leaves as the cargo containers are taken away. You exchange a few pleasantries with Chelsea before seeïng her off.]])

misn_title = _("A Friend's Aid")
misn_desc = _("Chelsea needs you to escort her to {planet} in the {system} system. You must wait for her to jump to or land on her destination before you jump or land, and you must not deviate from her course. You will likely be attacked by gangsters.")

log_text = _([[You helped escort Chelsea through a cargo delivery which had some connection to the Soromid government, although you don't know the details. You encountered some kind of anti-Soromid gang along the way.]])


function create ()
   misplanet, missys, njumps, tdist, cargo, avgrisk = cargo_calculateRoute()
   if misplanet == nil or missys == nil or avgrisk > 0 then
      misn.finish(false)
   end

   local claimsys = {system.cur()}
   for i, jp in ipairs(system.cur():jumpPath(missys)) do
      table.insert(claimsys, jp:dest())
   end
   if not misn.claim(claimsys) then
      misn.finish(false)
   end

   credits = 500000
   started = false

   misn.setNPC(_("Chelsea"), "soromid/unique/chelsea.png",
         _("You see Chelsea looking around. Perhaps she needs help with something."))
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
         {player=player.name(), planet=misplanet:name(), system=missys:name(),
            credits=fmt.credits(credits)})) then
      tk.msg("", start_text)

      misn.accept()

      misn.setTitle(misn_title)
      misn.setDesc(fmt.f(misn_desc,
            {planet=misplanet:name(), system=missys:name()}))
      misn.setReward(fmt.credits(credits))
      marker = misn.markerAdd(missys, "high")

      local nextsys = getNextSystem(system.cur(), missys)
      local jumps = system.cur():jumpDist(missys)
      local osd_desc = {
         fmt.f(_("Protect Chelsea and wait for her to jump to {system}"),
               {system=nextsys:name()}),
         fmt.f(_("Jump to {system}"), {system=nextsys:name()}),
         fmt.f(n_("{remaining} more jump after this one",
                  "{remaining} more jumps after this one", jumps - 1),
               {remaining=fmt.number(jumps - 1)}),
      }
      misn.osdCreate(misn_title, osd_desc)

      startplanet = planet.cur()

      hook.takeoff("takeoff")
      hook.jumpout("jumpout")
      hook.jumpin("jumpin")
      hook.land("land")
   else
      tk.msg("", no_text)
      misn.finish()
   end
end


function cargo_selectMissionDistance ()
   return 3
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
   chelsea:outfitAdd("Unicorp PT-80 Core System")
   chelsea:outfitAdd("Unicorp Hawk 300 Engine")
   chelsea:outfitAdd("Unicorp D-4 Light Plating")
   chelsea:outfitAdd("Plasma Turret MK1", 2)
   chelsea:outfitAdd("Small Shield Booster")
   chelsea:outfitAdd("Rotary Turbo Modulator")
   chelsea:outfitAdd("Cargo Pod", 2)

   chelsea:setHealth(100, 100)
   chelsea:setEnergy(100)
   chelsea:setTemp(0)
   chelsea:setFuel(true)

   chelsea:cargoAdd("Industrial Goods", chelsea:cargoFree())

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
end


function spawnGangster(param)
   local f = faction.dynAdd("Mercenary", N_("Imperyan Brotherhood"))
   local shiptypes = {"Hyena", "Hyena", "Hyena", "Shark", "Lancelot"}
   local shiptype = shiptypes[rnd.rnd(1, #shiptypes)]

   gangster = pilot.add(shiptype, f, param,
         fmt.f(_("Gangster {ship}"), {ship=_(shiptype)}))

   gangster:setHostile()

   hook.pilot(gangster, "death", "gangster_removed")
   hook.pilot(gangster, "jump", "gangster_removed")
   hook.pilot(gangster, "land", "gangster_removed")
end


function jumpNext ()
   if chelsea ~= nil and chelsea:exists() then
      chelsea:taskClear()
      chelsea:control()

      misn.osdDestroy()
      if system.cur() == missys then
         chelsea:land(misplanet, true)
         local osd_desc = {
            fmt.f(_("Protect Chelsea and wait for her to land on {planet}"),
                  {planet=misplanet:name()}),
            fmt.f(_("Land on {planet}"), {planet=misplanet:name()}),
         }
         misn.osdCreate(misn_title, osd_desc)
      else
         local nextsys = getNextSystem(system.cur(), missys)
         local jumps = system.cur():jumpDist(missys)
         chelsea:hyperspace(nextsys, true)
         local osd_desc = {
            fmt.f(_("Protect Chelsea and wait for her to jump to {system}"),
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
   createFactions()
   spawnChelseaShip(startplanet)
   jumpNext()

   -- Spawn the first gangster at the jump from the next system (makes
   -- sure it doesn't spawn right on top of the player right at the
   -- start).
   spawnGangster(getNextSystem(system.cur(), missys))
end


function jumpout ()
   lastsys = system.cur()
end


function jumpin()
   createFactions()
   if chelsea_jumped and system.cur() == getNextSystem(lastsys, missys) then
      spawnChelseaShip(lastsys)
      jumpNext()
      hook.timer(5, "gangster_timer")
   else
      mh.showFailMsg(_("You have abandoned the mission."))
      misn.finish(false)
   end
end


function land()
   if chelsea_jumped and planet.cur() == misplanet then
      tk.msg("", fmt.f(success_text, {player=player.name()}))
      player.pay(credits)
      faction.get("Soromid"):modPlayer(3)
      srm_addComingOutLog(log_text)
      misn.finish(true)
   else
      tk.msg("", left_fail_text)
      misn.finish(false)
   end
end


function gangster_timer()
   spawnGangster()
   if system.cur() == missys then
      spawnGangster(lastsys)
   end
end


function chelsea_death()
   mh.showFailMsg(_("A rift in the space-time continuum causes you to have never met Chelsea in that bar."))
   misn.finish(false)
end


function chelsea_jump( p, jump_point )
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
   if planet == misplanet then
      player.msg(fmt.f(_("Chelsea has landed on {planet}."),
            {planet=planet:name()}))
      chelsea_jumped = true
      misn.osdActive(2)
      hook.rm(distress_timer_hook)
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


function gangster_removed()
   if rnd.rnd() < 0.8 then
      spawnGangster()
   end
   hook.rm(distress_timer_hook)
   jumpNext()
end
