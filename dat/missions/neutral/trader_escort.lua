--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Convoy Escort">
 <avail>
  <priority>49</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>540</chance>
  <location>Computer</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Proteron</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Thurion</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--Escort a convoy of traders to a destination--

local fmt = require "fmt"
local fleet = require "fleet"
local mh = require "misnhelper"
require "nextjump"
require "cargo_common"


function create()
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   
   if destplanet == nil then
      misn.finish(false)
   elseif numjumps == 0 then
      misn.finish(false) -- have to escort them at least one jump!
   elseif avgrisk * numjumps <= 25 then
      misn.finish(false) -- needs to be a little bit of piracy possible along route
   end
   
   local piracyrisk, riskreward
   if avgrisk == 0 then
      piracyrisk = _("Piracy Risk: None")
      riskreward = 0
   elseif avgrisk <= 25 then
      piracyrisk = _("Piracy Risk: Low")
      riskreward = 150
   elseif avgrisk > 25 and avgrisk <= 100 then
      piracyrisk = _("Piracy Risk: Medium")
      riskreward = 300
   else
      piracyrisk = _("Piracy Risk: High")
      riskreward = 450
   end
   
   -- Choose mission reward. This depends on the mission tier.
   jumpreward = (commodity.price(cargo) * (20+riskreward)) / 100
   distreward = math.log((50+riskreward)*commodity.price(cargo)) / 100
   reward = (1.75^tier
         * (avgrisk*riskreward + numjumps*jumpreward + traveldist*distreward
            + 25000)
         * (1 + 0.05*rnd.twosigma()))

   local title
   if tier <= 0 then
      title = _("Escort: Tiny Convoy to {planet} ({system} system)")
      pilots_table, pilots_min_speed = genPilots(
         rnd.rnd(2, 3), "Mercenary", {"Llama"})
   elseif tier <= 1 then
      title = _("Escort: Small Convoy to {planet} ({system} system)")
      pilots_table, pilots_min_speed = genPilots(
         rnd.rnd(3, 4), "Trader", {"Llama"})
   elseif tier <= 2 then
      title = _("Escort: Medium Convoy to {planet} ({system} system)")
      pilots_table, pilots_min_speed = genPilots(
         rnd.rnd(4, 5), "Trader", {"Llama", "Koäla"})
   elseif tier <= 3 then
      title = _("Escort: Large Convoy to {planet} ({system} system)")
      pilots_table, pilots_min_speed = genPilots(
         rnd.rnd(5, 6), "Trader", {"Koäla", "Rhino"})
   else
      title = _("Escort: Huge Convoy to {planet} ({system} system)")
      pilots_table, pilots_min_speed = genPilots(
         rnd.rnd(5, 6), "Trader", {"Rhino", "Mule"})
   end

   local desc = _("A convoy of traders needs to be escorted to {planet} in the {system} system. The convoy pilots will join your fleet and follow you, but you cannot issue orders to them. You should take care to ensure that your ship travels slow enough for the convoy to keep up with you.")

   local speed_text = fmt.f(p_("escort_desc", "Speed: {speed:.0f} mAU/s"),
         {speed=pilots_min_speed})
   local desc_extra_lines = {piracyrisk, speed_text}
   local desc_extra = table.concat(desc_extra_lines, "\n")

   cargo_setDesc(
      fmt.f(desc, {planet=destplanet:name(), system=destsys:name()}),
      cargo, nil, destplanet, numjumps, nil, desc_extra)
   
   misn.setTitle(fmt.f(title,
         {planet=destplanet:name(), system=destsys:name()}))
   misn.markerAdd(destsys, "computer")
   misn.setReward(fmt.credits(reward))
end


function accept()
   local player_p = player.pilot()
   local plspeed = player_p:stats().speed_max
   if plspeed > pilots_min_speed then
      local s = fmt.f(_("Your ship, the {shipname}, has a maximum speed of {plspeed:.0f} mAU/s, which is faster than the convoy's maximum speed. This may cause the convoy to struggle to keep up or even become scattered. Accept the mission anyway?"),
            {shipname=player_p:name(), plspeed=plspeed})
      if not tk.yesno("", s) then
         misn.finish()
         return
      end
   end

   misn.accept()

   origin = planet.cur() -- The place where the AI ships spawn from.
   last_planet, last_sys = planet.cur()

   hook.rm(regen_desc_hook)

   updateOSD()

   hook.takeoff("takeoff")
   hook.jumpin("jumpin")
   hook.jumpout("jumpout")
   hook.land("land")
end


function genPilots(n, f, shiptypes)
   local ptables = {}
   ptables.__save = true
   local min_speed = nil
   for i = 1, n do
      local ptable = {}
      ptable.__save = true
      ptable.ship = shiptypes[rnd.rnd(1, #shiptypes)]
      ptable.alive = true

      local p = pilot.add(ptable.ship, f)

      local speed = p:stats().speed_max
      if min_speed == nil or speed < min_speed then
         min_speed = speed
      end

      ptable.outfits = {}
      ptable.outfits.__save = true
      for j, o in ipairs(p:outfits()) do
         table.insert(ptable.outfits, o:nameRaw())
      end

      table.insert(ptables, ptable)
   end

   return ptables, min_speed
end


function updateOSD()
   local alive = getAliveCount()
   local total = #pilots_table

   local osd_desc = {
      fmt.f(_("Land on {planet} ({system} system)"),
         {planet=destplanet:name(), system=destsys:name()}),
      fmt.f(_("Protect the convoy from harm ({alive}/{total} remaining)"),
         {alive=fmt.number(alive), total=fmt.number(total)}),
   }
   misn.osdCreate(_("Convoy Escort"), osd_desc)
end


function takeoff()
   spawnConvoy(last_planet)
end


function jumpin()
   local cursys = system.cur()
   local adjacent = false
   for i, sys in ipairs(last_sys:adjacentSystems()) do
      if cursys == sys then
         adjacent = true
         break
      end
   end
   if adjacent then
      spawnConvoy(last_sys)
   else
      mh.showFailMsg(_("You lost contact with the convoy."))
      misn.finish(false)
   end
end


function jumpout()
   last_sys = system.cur()
   last_planet = nil

   for i, ptable in ipairs(pilots_table) do
      if ptable.alive then
         if ptable.pilot ~= nil and ptable.pilot:exists() then
            ptable.temp = ptable.pilot:temp()
            ptable.armor, ptable.shield, ptable.stress = ptable.pilot:health()
            ptable.energy = ptable.pilot:energy()
            ptable.pilot:rm()
         else
            ptable.temp = nil
            ptable.armor = nil
            ptable.shield = nil
            ptable.stress = nil
            ptable.energy = nil
         end
         ptable.pilot = nil
      end
   end
end


function land()
   last_planet, last_sys = planet.cur()
   if last_planet == destplanet then
      local alive = getAliveCount()
      local total = #pilots_table
      local s
      local credits = 0
      if alive >= total then
         s = _([[You make it to the convoy's destination without suffering any casualties. After verifying that no one from the convoy is unaccounted for, the convoy manager hands you your pay and thanks you for a job well done.]])
         credits = reward
      elseif alive / total >= 0.6 then
         s = _([[You arrive with the convoy more or less intact, but not everyone from the convoy is accounted for. The convoy manager only pays you {credits} as a result.]])
         credits = reward * alive / total
      else
         s = _([[You make it to the convoy's destination with what's left of the convoy. It's not much, but it's better than nothing. The convoy manager hands you a steeply discounted payment of {credits} without saying a word.]])
         credits = reward * alive / total
      end
      tk.msg("", fmt.f(s, {credits=fmt.credits(credits)}))
      player.pay(credits)
      misn.finish(true)
   end

   -- Reset convoy stats and mark missing pilots as dead.
   for i, ptable in ipairs(pilots_table) do
      if ptable.jump_dest ~= nil then
         ptable.alive = false
      end
      if ptable.land_dest ~= nil and ptable.land_dest ~= last_planet then
         ptable.alive = false
      end
      ptable.pilot = nil
      ptable.temp = nil
      ptable.armor = nil
      ptable.shield = nil
      ptable.stress = nil
      ptable.energy = nil
      ptable.jump_dest = nil
      ptable.land_dest = nil
   end

   -- Check for fail condition.
   if getAliveCount() <= 0 then
      tk.msg("", _("You have lost contact with the convoy and failed the mission as a result."))
      misn.finish(false)
   end

   updateOSD()
end


function getAliveCount()
   local alive = 0
   for i, ptable in ipairs(pilots_table) do
      if ptable.alive then
         alive = alive + 1
      end
   end
   return alive
end


function traderDeath(p, killer, ptable)
   ptable.alive = false
   player.msg(fmt.f(_("#r{pilot} has been destroyed.#0"),
         {pilot=p:name()}))
   updateOSD()

   if getAliveCount() <= 0 then
      mh.showFailMsg(_("The convoy you were escorting has been destroyed."))
      misn.finish(false)
   end
end


function traderJump(p, jmp, ptable)
   ptable.jump_dest = jmp:dest()
   player.msg(fmt.f(_("{pilot} has fled to the {system} system."),
         {pilot=p:name(), system=ptable.jump_dest:name()}))
end


function traderLand(p, plnt, ptable)
   if plnt ~= destplanet then
      ptable.land_dest = plnt
      player.msg(fmt.f(_("{pilot} has fled to {planet}."),
            {pilot=p:name(), planet=plnt:name()}))
   end
end


function spawnConvoy(source)
   local cursys = system.cur()
   local player_p = player.pilot()
   local nspawned = 0
   for i, ptable in ipairs(pilots_table) do
      if ptable.land_dest ~= nil and ptable.land_dest ~= source then
         ptable.alive = false
      end
      if ptable.jump_dest ~= nil and ptable.jump_dest ~= cursys then
         ptable.alive = false
      end

      if ptable.alive then
         nspawned = nspawned + 1

         local name = fmt.f(p_("pilot_name", "Convoy {ship}"),
               {ship=_(ptable.ship)})
         local p = pilot.add(ptable.ship, "Trader", source, name,
               {naked=true})
         ptable.pilot = p
         for j, o in ipairs(ptable.outfits) do
            p:outfitAdd(o)
         end
         p:fillAmmo()
         p:setFriendly()

         local temp = 250
         local armor = 100
         local shield = 100
         local stress = 0
         local energy = 100
         if ptable.temp ~= nil then
            temp = ptable.temp
         end
         if ptable.armor ~= nil then
            armor = ptable.armor
         end
         if ptable.shield ~= nil then
            shield = ptable.shield
         end
         if ptable.stress ~= nil then
            -- Limit this to 99 so we don't have the weirdness of a
            -- disabled ship warping in.
            stress = math.min(ptable.stress, 99)
         end
         if ptable.energy ~= nil then
            energy = ptable.energy
         end
         p:setTemp(temp, true)
         p:setHealth(armor, shield, stress)
         p:setEnergy(energy)
         p:setFuel(true)
         p:cargoAdd(cargo, p:cargoFree())

         local mem = p:memory()
         mem.nocommand = true
         mem.noleave = true

         p:setInvincPlayer()
         p:setVisplayer()
         p:setNoClear()

         p:setLeader(player_p)

         hook.pilot(p, "death", "traderDeath", ptable)
         hook.pilot(p, "land", "traderLand", ptable)
         hook.pilot(p, "jump", "traderJump", ptable)
      end
   end

   if nspawned <= 0 then
      mh.showFailMsg(_("You lost contact with the convoy."))
      misn.finish(false)
   end

   updateOSD()
end


function abort()
   for i, ptable in ipairs(pilots_table) do
      if ptable.pilot ~= nil and ptable.pilot:exists() then
         local p = ptable.pilot
         local mem = p:memory()
         mem.nocommand = false
         mem.noleave = false
         mem.loiter = 3
         p:setLeader(nil)
         p:setHilight(false)
         p:setInvincPlayer(false)
         p:setVisplayer(false)
         p:setNoLand(false)
         p:setNoJump(false)
      end
   end
end
