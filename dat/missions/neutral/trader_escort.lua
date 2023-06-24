--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Trader Escort">
 <avail>
  <priority>40</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>360</chance>
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


misn_title = {}
misn_title[1] = _("Escort: Tiny Convoy to {planet} ({system} system)")
misn_title[2] = _("Escort: Small Convoy to {planet} ({system} system)")
misn_title[3] = _("Escort: Medium Convoy to {planet} ({system} system)")
misn_title[4] = _("Escort: Large Convoy to {planet} ({system} system)")
misn_title[5] = _("Escort: Huge Convoy to {planet} ({system} system)")

misn_desc = _("A convoy of traders needs protection while they go to {planet} in the {system} system. You must stick with the convoy at all times, waiting to jump or land until the entire convoy has done so.")
   
piracyrisk = {}
piracyrisk[1] = _("Piracy Risk: None")
piracyrisk[2] = _("Piracy Risk: Low")
piracyrisk[3] = _("Piracy Risk: Medium")
piracyrisk[4] = _("Piracy Risk: High")

osd_title = _("Convey Escort")
osd_msg = _("Escort a convoy of traders to {planet} ({system} system)")

landsuccesstext = _("You successfully escorted the trading convoy to the destination. There wasn't a single casualty and you are rewarded the full amount.")

landcasualtytext = {}
landcasualtytext[1] = _("You've arrived with the trading convoy more or less intact. Your pay is docked slightly due to the loss of part of the convoy.")
landcasualtytext[2] = _("You arrive with what's left of the convoy. It's not much, but it's better than nothing. You are paid a steeply discounted amount.")

landfailtext = _("You have landed, abandoning your mission to escort the trading convoy.")

convoynolandtext = _([[You landed at the planet before ensuring that the rest of your convoy was safe. You have abandoned your duties, and failed your mission.]])

traderdistress = _("Convoy ships under attack! Requesting immediate assistance!")


function create()
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   
   if destplanet == nil then
      misn.finish(false)
   elseif numjumps == 0 then
      misn.finish(false) -- have to escort them at least one jump!
   elseif avgrisk * numjumps <= 25 then
      misn.finish(false) -- needs to be a little bit of piracy possible along route
   end

   local claimsys = {system.cur()}
   for i, jp in ipairs(system.cur():jumpPath(destsys)) do
      claimsys[#claimsys + 1] = jp:dest()
   end
   if not misn.claim(claimsys) then
      misn.finish(false)
   end
   
   if avgrisk == 0 then
      piracyrisk = piracyrisk[1]
      riskreward = 0
      riskmod = 5
   elseif avgrisk <= 25 then
      piracyrisk = piracyrisk[2]
      riskreward = 20
      riskmod = 10
   elseif avgrisk <= 50 then
      -- Note: duplication of piracy risk descriptions here is
      -- intentional, for consistency with other missions that don't
      -- have this level of granularity.
      piracyrisk = piracyrisk[3]
      riskreward = 30
      riskmod = 15
   elseif avgrisk <= 100 then
      piracyrisk = piracyrisk[3]
      riskreward = 50
      riskmod = 20
   else
      piracyrisk = piracyrisk[4]
      riskreward = 100
      riskmod = 25
   end
    
   convoysize = rnd.rnd(1,5)
   
   -- Choose mission reward.
   -- Reward depends on type of cargo hauled. Hauling expensive commodities gives a better deal.
   if convoysize == 1 then
      jumpreward = 6 * riskmod * commodity.price(cargo)
      distreward = riskmod * math.log(500*commodity.price(cargo))/100
   elseif convoysize == 2 then
      jumpreward = 7 * riskmod * commodity.price(cargo)
      distreward = riskmod * math.log(700*commodity.price(cargo))/100
   elseif convoysize == 3 then
      jumpreward = 8 * riskmod * commodity.price(cargo)
      distreward = riskmod * math.log(800*commodity.price(cargo))/100
   elseif convoysize == 4 then
      jumpreward = 9 * riskmod * commodity.price(cargo)
      distreward = riskmod * math.log(900*commodity.price(cargo))/100
   elseif convoysize == 5 then
      jumpreward = 10 * riskmod * commodity.price(cargo)
      distreward = riskmod * math.log(1000*commodity.price(cargo))/100
   end
   reward = (avgrisk*riskreward + numjumps*jumpreward + traveldist*distreward)
         * (1 + 0.05*rnd.twosigma())
   
   misn.setTitle(fmt.f(misn_title[convoysize],
         {planet=destplanet:name(), system=destsys:name()}))
   cargo_setDesc(fmt.f(misn_desc,
            {planet=destplanet:name(), system=destsys:name()}),
         cargo, nil, destplanet, numjumps, nil, piracyrisk)
   misn.markerAdd(destsys, "computer")
   misn.setReward(fmt.credits(reward))
end


function accept()
   local pjumps = player.jumps()
   if pjumps ~= nil and pjumps < numjumps then
      local needed_text = n_("The destination is {distance} jump away. ",
            "The destination is {distance} jumps away. ", numjumps)
      local avail_text = n_(
            "You only have enough fuel for {range} jump. You cannot stop to refuel. Accept the mission anyway?",
            "You only have enough fuel for {range} jumps. You cannot stop to refuel. Accept the mission anyway?",
            pjumps)
      if not tk.yesno("", fmt.f(needed_text .. avail_text,
               {distance=fmt.number(numjumps), range=fmt.number(pjumps)})) then
         misn.finish()
      end
   end

   nextsys = getNextSystem(system.cur(), destsys) -- This variable holds the system the player is supposed to jump to NEXT.
   origin = planet.cur() -- The place where the AI ships spawn from.

   orig_alive = nil
   alive = nil
   exited = 0
   misnfail = false

   misn.accept()
   misn.osdCreate(osd_title,
         {fmt.f(osd_msg, {planet=destplanet:name(), system=destsys:name()})})

   hook.takeoff("takeoff")
   hook.jumpin("jumpin")
   hook.jumpout("jumpout")
   hook.land("land")
end


function takeoff()
   spawnConvoy()
end


function jumpin()
   if system.cur() ~= nextsys then
      mh.showFailMsg(_("You jumped into the wrong system."))
   else
      spawnConvoy()
   end
end


function jumpout()
   if alive <= 0 or exited <= 0 then
      mh.showFailMsg(_("You jumped before the convoy you were escorting."))
   else
      -- Treat those that didn't exit as dead
      alive = math.min(alive, exited)
   end
   origin = system.cur()
   nextsys = getNextSystem(system.cur(), destsys)
end

function land()
   alive = math.min(alive, exited)

   if planet.cur() ~= destplanet then
      tk.msg("", landfailtext)
      misn.finish(false)
   elseif alive <= 0 then
      tk.msg("", convoynolandtext)
      misn.finish(false)
   else
      if alive >= orig_alive then
         tk.msg("", landsuccesstext)
         player.pay(reward)
      elseif alive / orig_alive >= 0.6 then
         tk.msg("", landcasualtytext[1])
         player.pay(reward * alive / orig_alive)
      else
         tk.msg("", landcasualtytext[2])
         player.pay(reward * alive / orig_alive)
      end
      misn.finish(true)
   end
end


function traderDeath(p)
   alive = alive - 1
   updateOSD()
   if alive <= 0 then
      mh.showFailMsg(_("The convoy you were escorting has been destroyed."))
   elseif exited >= alive then
      -- No more left to defend, proceed to follow the rest
      misn.osdActive(2)
   else
      organize_fleet(convoy)
   end
end


-- Handle the jumps of convoy.
function traderJump(p, j)
   if j:dest() == getNextSystem(system.cur(), destsys) then
      exited = exited + 1
      updateOSD()
      if p:exists() then
         player.msg(fmt.f(
               _("{ship} has jumped to {system}."),
               {ship=p:name(), system=j:dest():name()}))
      end
      if exited >= alive then
         misn.osdActive(2)
      end
   else
      traderDeath()
   end
end


--Handle landing of convoy
function traderLand(p, plnt)
   if plnt == destplanet then
      exited = exited + 1
      updateOSD()
      if p:exists() then
         player.msg(fmt.f(
               _("{ship} has landed on {planet}."),
               {ship=p:name(), planet=plnt:name()}))
      end
      if exited >= alive then
         misn.osdActive(2)
      end
   else
      traderDeath()
   end
end


-- Handle the convoy getting attacked.
function traderAttacked(p, attacker)
   if not shuttingup then
      shuttingup = true
      p:comm(player.pilot(), traderdistress)
      hook.timer(5, "traderShutup") -- Shuts him up for at least 5s.
   end
end


function traderShutup()
    shuttingup = false
end


function spawnConvoy()
   --Make it interesting
   local ambush_src = destplanet
   if system.cur() ~= destsys then
      ambush_src = getNextSystem(system.cur(), destsys)
   end

   if convoysize == 1 then
      convoy = fleet.add(3, "Llama", "Trader", origin, _("Convoy Llama"))

      ambush = fleet.add({1, 1, 2},
            {"Pirate Ancestor", "Pirate Vendetta", "Hyena"}, "Pirate",
            ambush_src, {nil, nil, _("Pirate Hyena")})
   elseif convoysize == 2 then
      convoy = fleet.add(4, "Koäla", "Trader", origin, _("Convoy Koäla"))

      ambush = fleet.add({1, rnd.rnd(1, 3), 2},
            {"Pirate Ancestor", "Pirate Vendetta", "Hyena"}, "Pirate",
            ambush_src, {nil, nil, _("Pirate Hyena")})
   elseif convoysize == 3 then
      convoy = fleet.add({2, 3}, {"Rhino", "Mule"}, "Trader", origin,
            {_("Convoy Rhino"), _("Convoy Mule")})

      if rnd.rnd() < 0.5 then
         ambush = fleet.add({1, 3, 2},
               {"Pirate Ancestor", "Pirate Vendetta", "Hyena"}, "Pirate",
               ambush_src, {nil, nil, _("Pirate Hyena")})
      else
         ambush = fleet.add({1, 2, 2},
               {"Pirate Admonisher", "Pirate Rhino", "Pirate Shark"}, "Pirate",
               ambush_src)
      end
   elseif convoysize == 4 then
      convoy = fleet.add(3, {"Rhino", "Mule"}, "Trader", origin,
            {_("Convoy Rhino"), _("Convoy Mule")})

      local r = rnd.rnd()
      if r < 0.33 then
         ambush = fleet.add({1, 3, 2},
               {"Pirate Ancestor", "Pirate Vendetta", "Hyena"}, "Pirate",
               ambush_src, {nil, nil, _("Pirate Hyena")})
      elseif r < 0.66 then
         ambush = fleet.add({1, 2, 2, 2},
               {"Pirate Admonisher", "Pirate Phalanx", "Pirate Shark",
                  "Hyena"}, "Pirate", ambush_src,
               {nil, nil, nil, _("Pirate Hyena")})
      else
         ambush = fleet.add({1, 2, 2},
               {"Pirate Admonisher", "Pirate Rhino", "Pirate Shark"}, "Pirate",
               ambush_src)
      end
   else
      convoy = fleet.add(4, {"Rhino", "Mule"}, "Trader", origin,
            {_("Convoy Rhino"), _("Convoy Mule")})

      local r = rnd.rnd()
      if r < 0.33 then
         ambush = fleet.add({1, 2, 2, 2},
               {"Pirate Admonisher", "Pirate Phalanx", "Pirate Shark",
                  "Hyena"}, "Pirate", ambush_src,
               {nil, nil, nil, _("Pirate Hyena")})
      elseif r < 0.66 then
         ambush = fleet.add({1, 1, 1, 2, 3},
               {"Pirate Kestrel", "Pirate Admonisher", "Pirate Rhino",
                  "Pirate Shark", "Hyena"}, "Pirate", ambush_src,
               {nil, nil, nil, nil, _("Pirate Hyena")})
      else
         ambush = fleet.add({1, 2, 2, 2},
               {"Pirate Admonisher", "Pirate Phalanx", "Pirate Shark",
                  "Hyena"}, "Pirate", ambush_src,
               {nil, nil, nil, _("Pirate Hyena")})
      end
   end

   for i, p in ipairs(convoy) do
      if alive ~= nil and alive < i then
         p:rm()
      end
      if p:exists() then
         for j, c in ipairs(p:cargoList()) do
            p:cargoRm(c.name, c.q)
         end

         p:setFuel(true)
         p:cargoAdd(cargo, p:cargoFree())

         p:setHilight(true)
         p:setInvincPlayer()
         p:setVisplayer()

         hook.pilot(p, "exploded", "traderDeath")
         hook.pilot(p, "attacked", "traderAttacked")
         hook.pilot(p, "land", "traderLand")
         hook.pilot(p, "jump", "traderJump")
      end
   end

   organize_fleet(convoy)

   exited = 0
   if orig_alive == nil then
      orig_alive = 0
      for i, p in ipairs(convoy) do
         if p ~= nil and p:exists() then
            orig_alive = orig_alive + 1
         end
      end
      alive = orig_alive

      -- Shouldn't happen
      if orig_alive <= 0 then
         misn.finish(false)
      end
   end

   updateOSD()
end


function organize_fleet(convoy)
   local minspeed = nil
   local leader = nil
   for i, p in ipairs(convoy) do
      if p:exists() then
         -- Remove any existing speed limit (in case the leader changed).
         p:setSpeedLimit(0)

         local myspd = p:stats().speed_max
         if minspeed == nil or myspd < minspeed then
            minspeed = myspd
            leader = p
         end

         -- Make sure the convoy stays close together.
         p:memory().leadermaxdist = 1000

         p:taskClear()
         p:setNoLand()
         p:control(false)
      end
   end

   if minspeed == nil or leader == nil then
      -- This should never happen, but is here as a failsafe.
      warn(_("No minspeed or leader set for convoy, maybe the table is empty."))
      return
   end

   local plmax = player.pilot():stats().speed_max * 0.8
   leader:setSpeedLimit(math.min(plmax, minspeed * 0.8))

   for i, p in ipairs(convoy) do
      if p ~= leader and p:exists() then
         p:setLeader(leader)
      end
   end

   leader:memory().formation = "wall"
   leader:setNoLand(false)
   leader:control()

   local dest
   if system.cur() == destsys then
      leader:land(destplanet, true)
      dest = destplanet:pos()
   else
      local nextsys = getNextSystem(system.cur(), destsys)
      leader:hyperspace(nextsys, true)
      dest = jump.get(system.cur(), nextsys):pos()
   end

   hook.rm(prox_timer)
   prox_timer = hook.timer(0.5, "prox_jump", dest)
end


function prox_jump(dest)
   local nearby = false
   for i, p in ipairs(convoy) do
      if p:exists() and vec2.dist(p:pos(), dest) <= 1000 then
         nearby = true
         break
      end
   end

   if not nearby then
      prox_timer = hook.timer(0.5, "prox_jump", dest)
      return
   end

   for i, p in ipairs(convoy) do
      if p:exists() then
         p:setNoLand(false)
         p:control()
         if system.cur() == destsys then
            p:land(destplanet, true)
         else
            local nextsys = getNextSystem(system.cur(), destsys)
            p:hyperspace(nextsys, true)
         end
      end
   end
end


function updateOSD()
   misn.osdDestroy()
   if system.cur() == destsys then
      local osd_desc = {}
      osd_desc[1] = fmt.f(
            _("Protect the convoy ships and wait for them to land on {planet} ({landed}/{remaining})"),
            {planet=destplanet:name(), landed=fmt.number(exited),
               remaining=fmt.number(alive)})
      osd_desc[2] = fmt.f(_("Land on {planet}"), {planet=destplanet:name()})
      misn.osdCreate(osd_title, osd_desc)
   else
      local sys = getNextSystem(system.cur(), destsys)
      local jumps = system.cur():jumpDist(destsys)
      local osd_desc = {
         fmt.f(
            _("Protect the convoy ships and wait for them to jump to {system} ({jumped}/{remaining})"),
            {system=sys:name(), jumped=fmt.number(exited),
               remaining=fmt.number(alive)}),
         fmt.f(_("Jump to {system}"), {system=sys:name()}),
      }
      if jumps > 1 then
         osd_desc[3] = fmt.f(
               n_("{remaining} more jump after this one",
                  "{remaining} more jumps after this one", jumps - 1),
               {remaining=fmt.number(jumps - 1)})
      end
      misn.osdCreate(osd_title, osd_desc)
   end
end


function abort()
   if convoy ~= nil then
      for i, p in ipairs(convoy) do
         if p:exists() then
            p:setHilight(false)
            p:setInvincPlayer(false)
            p:setVisplayer(false)
            p:setSpeedLimit(0)
            p:setNoLand(false)
            p:control(false)
            p:taskClear()
         end
      end
   end
end
