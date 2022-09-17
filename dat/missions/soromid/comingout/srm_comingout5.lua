--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Waste Collector">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <done>Visiting Family</done>
  <chance>90</chance>
  <location>Bar</location>
  <faction>Soromid</faction>
 </avail>
 <notes>
  <campaign>Coming Out</campaign>
 </notes>
</mission>
--]]
--[[

   Waste Collector

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
require "numstring"
require "missions/soromid/comingout/srm_comingout3"
require "missions/soromid/common"


text = {}

ask_text = _([[You walk over to Chelsea to greet them when you notice an unpleasant odor coming off of them. Chelsea notices you. "Ah! %s! Uh, sorry about the smell. I don't know why the hell I did this, but I took a job from some guy here and now I'm stuck with it." You ask what kind of job it is. "Erm, I kind of agreed to take their trash from them." You grimace. "Yeah," Chelsea says, "it's gross. And what's worse, I'm in over my head. I've already taken the garbage and my new ship is packed to the brim with the stuff, but there's gangsters outside giving me a lot of trouble.

"I, uh, know I ask a lot of you, but could you help me out again? I just need an escort to %s so I can drop off this garbage there. I'll give you %s for the trouble. What do you say?"]])

start_text = _([["I appreciate it very much. I'll wait at the spaceport until you're ready to take off. Get ready for a fight when we get out of the atmosphere; it's going to be a bumpy ride."]])

no_text = _([["OK, I understand. I guess I'll have to find some other way to get rid of all this garbage..."]])

ask_again_text = _([["I'm not having any luck coming up with a plan to get rid of all of this garbage without getting jumped by those gangsters. Is there any chance you could reconsider escorting me? It would be a big help."]])

success_text = _([[As you dock, you can't help but notice the foul smell of garbage all around you. The planet really does fit the name. You grimace as you watch workers unload what must be hundreds of kilotonnes of garbage from Chelsea's ship, some of which is leaking. Eventually Chelsea's ship is emptied and you and Chelsea are handed your credit chips for the job. You and Chelsea part ways, with you vowing to take a shower immediately while Chelsea vows to scrub the cargo hold of their ship clean.]])

misn_title = _("Waste Collector")
misn_desc = _("Chelsea needs an escort to %s so they can get rid of the garbage now filling their ship.")

npc_name = _("Chelsea")
npc_desc = _("Chelsea seems like they're stressed. Maybe you should see how they're doing?")

log_text = _([[You helped Chelsea get rid of a load of garbage they naively agreed to take to The Stinker as a mission, defending them from gangsters along the way.]])


function create ()
   misplanet, missys = planet.get("The Stinker")
   if misplanet == nil or missys == nil
         or system.cur():jumpDist(missys) > 4 then
      misn.finish(false)
   end

   local claimsys = {system.cur()}
   for i, jp in ipairs(system.cur():jumpPath(missys)) do
      claimsys[#claimsys + 1] = jp:dest()
   end
   if not misn.claim(claimsys) then
      misn.finish(false)
   end

   credits = 500000
   started = false

   misn.setNPC(npc_name, "soromid/unique/chelsea.png", npc_desc)
end


function accept ()
   local txt
   if started then
      txt = ask_again_text
   else
      txt = ask_text:format(player.name(), misplanet:name(), creditstring(credits))
   end
   started = true

   if tk.yesno("", txt) then
      tk.msg("", start_text)

      misn.accept()

      misn.setTitle(misn_title)
      misn.setDesc(misn_desc:format(misplanet:name()))
      misn.setReward(creditstring(credits))
      marker = misn.markerAdd(missys, "low")

      local nextsys = getNextSystem(system.cur(), missys)
      local jumps = system.cur():jumpDist(missys)
      local osd_desc = {}
      osd_desc[1] = string.format(
            _("Protect Chelsea and wait for her to jump to %s"),
            nextsys:name())
      osd_desc[2] = string.format(_("Jump to %s"), nextsys:name())
      osd_desc[3] = string.format(
            _("%s more jumps after this one"), numstring(jumps - 1))
      misn.osdCreate(misn_title, osd_desc)

      startplanet = planet.cur()

      hook.enter("enter")
      hook.takeoff("takeoff")
      hook.jumpout("jumpout")
      hook.jumpin("jumpin")
      hook.land("land")
   else
      tk.msg("", no_text)
      misn.finish()
   end
end


function spawnChelseaShip(param)
   chelsea = pilot.add("Rhino", "Comingout_associates", param, _("Chelsea"))
   chelsea:outfitRm("all")
   chelsea:outfitRm("cores")
   chelsea:outfitAdd("Milspec Aegis 5401 Core System")
   chelsea:outfitAdd("Melendez Buffalo XL Engine")
   chelsea:outfitAdd("S&K Medium Cargo Hull")
   chelsea:outfitAdd("Heavy Ripper Turret", 2)
   chelsea:outfitAdd("Enygma Systems Turreted Fury Launcher", 2)
   chelsea:outfitAdd("Medium Shield Booster")
   chelsea:outfitAdd("Targeting Array")
   chelsea:outfitAdd("Droid Repair Crew")
   chelsea:outfitAdd("Medium Cargo Pod", 4)

   chelsea:fillAmmo()
   chelsea:setHealth(100, 100)
   chelsea:setEnergy(100)
   chelsea:setTemp(0)
   chelsea:setFuel(true)

   local c = misn.cargoNew(N_("Waste Containers"), N_("A bunch of waste containers leaking all sorts of indescribable liquids."))
   chelsea:cargoAdd(c, chelsea:cargoFree())

   chelsea:setFriendly()
   chelsea:setHilight()
   chelsea:setVisible()
   chelsea:setInvincPlayer()
   chelsea:setNoBoard()

   hook.pilot(chelsea, "death", "chelsea_death")
   hook.pilot(chelsea, "jump", "chelsea_jump")
   hook.pilot(chelsea, "land", "chelsea_land")
   hook.pilot(chelsea, "attacked", "chelsea_attacked")

   chelsea_jumped = false
end


function spawnGangster(param)
   local shiptypes = {
      "Hyena", "Shark", "Lancelot", "Vendetta", "Ancestor", "Admonisher",
      "Phalanx",
   }
   local shiptype = shiptypes[rnd.rnd(1, #shiptypes)]

   gangster = pilot.add(shiptype, "Comingout_gangsters", param,
         _("Gangster %s"):format(_(shiptype)))

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
         local osd_desc = {}
         osd_desc[1] = fmt.f(
               _("Protect Chelsea and wait for them to land on {planet}"),
               {planet=misplanet:name()})
         osd_desc[2] = fmt.f(_("Land on {planet}"), {planet=misplanet:name()})
         misn.osdCreate(misn_title, osd_desc)
      else
         local nextsys = getNextSystem(system.cur(), missys)
         local jumps = system.cur():jumpDist(missys)
         chelsea:hyperspace(nextsys, true)
         local osd_desc = {}
         osd_desc[1] = fmt.f(
               _("Protect Chelsea and wait for them to jump to {system}"),
               {system=nextsys:name()})
         osd_desc[2] = fmt.f(_("Jump to {system}"), {system=nextsys:name()})
         if jumps > 1 then
            osd_desc[3] = fmt.f(
                  n_("{jumps} more jump after this one",
                     "{jumps} more jumps after this one", jumps - 1),
                  {jumps=fmt.number(jumps - 1)})
         end
         misn.osdCreate(misn_title, osd_desc)
      end
   end
end


function takeoff ()
   spawnChelseaShip(startplanet)
   jumpNext()

   for i=1,3 do
      spawnGangster()
   end
end


function land ()
   if chelsea_jumped and planet.cur() == misplanet then
      tk.msg("", success_text)
      player.pay(credits)

      local t = time.get():tonumber()
      var.push("comingout_time", t)

      srm_addComingOutLog(log_text)

      misn.finish(true)
   else
      tk.msg("", left_fail_text)
      misn.finish(false)
   end
end


function gangster_timer()
   for i=1,4 do
      spawnGangster()
   end
   if system.cur() == missys then
      for i=1,2 do
         spawnGangster(lastsys)
      end
   end
end
