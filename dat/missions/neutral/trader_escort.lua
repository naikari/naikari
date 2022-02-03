--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Trader Escort">
 <avail>
  <priority>49</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>560</chance>
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
   --This mission does not make any system claims
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   
   if destplanet == nil then
      misn.finish(false)
   elseif numjumps == 0 then
      misn.finish(false) -- have to escort them at least one jump!
   elseif avgrisk * numjumps <= 25 then
      misn.finish(false) -- needs to be a little bit of piracy possible along route
   end
   
   if avgrisk == 0 then
      piracyrisk = piracyrisk[1]
   elseif avgrisk <= 25 then
      piracyrisk = piracyrisk[2]
   elseif avgrisk <= 100 then
      piracyrisk = piracyrisk[3]
   else
      piracyrisk = piracyrisk[4]
   end
    
   convoysize = rnd.rnd(1,5)
   
   -- Choose mission reward.
   -- Reward depends on type of cargo hauled. Hauling expensive commodities gives a better deal.
   if convoysize == 1 then
      jumpreward = 6*commodity.price(cargo)
      distreward = math.log(500*commodity.price(cargo))/100
   elseif convoysize == 2 then
      jumpreward = 7*commodity.price(cargo)
      distreward = math.log(700*commodity.price(cargo))/100
   elseif convoysize == 3 then
      jumpreward = 8*commodity.price(cargo)
      distreward = math.log(800*commodity.price(cargo))/100
   elseif convoysize == 4 then
      jumpreward = 9*commodity.price(cargo)
      distreward = math.log(900*commodity.price(cargo))/100
   elseif convoysize == 5 then
      jumpreward = 10*commodity.price(cargo)
      distreward = math.log(1000*commodity.price(cargo))/100
   end
   reward = 2.0 * (avgrisk * numjumps * jumpreward + traveldist * distreward) * (1. + 0.05*rnd.twosigma())
   
   misn.setTitle(fmt.f(misn_title[convoysize],
         {planet=destplanet:name(), system=destsys:name()}))
   cargo_setDesc(fmt.f(misn_desc,
            {planet=destplanet:name(), system=destsys:name()}),
         cargo, nil, destplanet, nil, piracyrisk)
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
   unsafe = false

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
      fail(_("MISSION FAILED! You jumped into the wrong system."))
   else
      spawnConvoy()
   end
end

function jumpout()
   if alive <= 0 or exited <= 0 then
      fail(_("MISSION FAILED! You jumped before the convoy you were escorting."))
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

function traderDeath()
   alive = alive - 1
   updateOSD()
   if alive <= 0 then
      fail(_("MISSION FAILED! The convoy you were escorting has been destroyed."))
   elseif exited >= alive then
      -- No more left to defend, proceed to follow the rest
      misn.osdActive(2)
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
   unsafe = true
   p:control(false)
   p:setNoJump(true)
   p:setNoLand(true)

   if not shuttingup then
      shuttingup = true
      p:comm(player.pilot(), traderdistress)
      hook.timer(5, "traderShutup") -- Shuts him up for at least 5s.
   end
end

function traderShutup()
    shuttingup = false
end

function timer_traderSafe()
   hook.timer(2, "timer_traderSafe")

   if unsafe then
      unsafe = false
      for i, j in ipairs(convoy) do
         continueToDest(j)
      end
   end
end

function spawnConvoy ()
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
      convoy = fleet.add(4, "Koala", "Trader", origin, _("Convoy Koala"))

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

   local minspeed = nil
   for i, p in ipairs(convoy) do
      if alive ~= nil and alive < i then
         p:rm()
      end
      if p:exists() then
         p:outfitRm("cores")
         for j, o in ipairs(p:outfits()) do
            if o == "Improved Stabilizer" then
               p:outfitRm("Improved Stabilizer")
               p:outfitAdd("Cargo Pod")
            end
         end

         for j, c in ipairs(p:cargoList()) do
            p:cargoRm(c.name, c.q)
         end

         local class = p:ship():class()
         if class == "Yacht" or class == "Luxury Yacht" or class == "Scout"
               or class == "Courier" or class == "Fighter" or class == "Bomber"
               or class == "Drone" or class == "Heavy Drone" then
            p:outfitAdd("Unicorp PT-80 Core System")
            p:outfitAdd("Melendez Ox XL Engine")
            p:outfitAdd("S&K Small Cargo Hull")
         elseif class == "Freighter" or class == "Armored Transport"
               or class == "Corvette" or class == "Destroyer" then
            p:outfitAdd("Unicorp PT-400 Core System")
            p:outfitAdd("Melendez Buffalo XL Engine")
            p:outfitAdd("S&K Medium Cargo Hull")
         elseif class == "Cruiser" or class == "Carrier" then
            p:outfitAdd("Unicorp PT-400 Core System")
            p:outfitAdd("Melendez Mammoth XL Engine")
            p:outfitAdd("S&K Large Cargo Hull")
         end

         p:setHealth(100, 100)
         p:setEnergy(100)
         p:setTemp(0)
         p:setFuel(true)
         p:cargoAdd(cargo, p:cargoFree())

         local myspd = p:stats().speed_max
         if minspeed == nil or myspd < minspeed then
            minspeed = myspd
         end

         p:control()
         p:setHilight(true)
         p:setInvincPlayer()
         continueToDest(p)

         hook.pilot(p, "death", "traderDeath")
         hook.pilot(p, "attacked", "traderAttacked", p)
         hook.pilot(p, "land", "traderLand")
         hook.pilot(p, "jump", "traderJump")
      end
   end

   if minspeed ~= nil then
      for i, p in ipairs(convoy) do
         if p ~= nil and p:exists() then
            p:setSpeedLimit(minspeed)
         end
      end
   end

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
      if orig_alive <= 0 then misn.finish(false) end
   end

   updateOSD()

   hook.timer(1, "timer_traderSafe")
end

function continueToDest(p)
   if p ~= nil and p:exists() then
      p:control(true)
      p:setNoJump(false)
      p:setNoLand(false)

      if system.cur() == destsys then
         p:land(destplanet, true)
      else
         p:hyperspace(getNextSystem(system.cur(), destsys), true)
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

-- Fail the mission, showing message to the player.
function fail(message)
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
