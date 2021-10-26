--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Pirate Shipping">
 <avail>
  <priority>70</priority>
  <cond>faction.playerStanding("Pirate") &gt;= 0</cond>
  <chance>960</chance>
  <location>Computer</location>
  <faction>Pirate</faction>
 </avail>
</mission>
--]]
--[[

   Handles the randomly generated Pirate cargo missions.

   Most of the code taken from Empire Shipping.

]]--

local fmt = require "fmt"
require "cargo_common"
require "numstring"


misn_desc = _("Pirate cargo transport of contraband goods to {planet} in the {system} system.")

msg_timeup = _("MISSION FAILED: You have failed to deliver the goods on time!")

osd_title = _("Pirate Shipping")
osd_msg1 = _("Fly to {planet} ({system} system) before {timelimit}\n({time} remaining)")

-- Use hidden jumps
cargo_use_hidden = true

-- Always available
cargo_always_available = true

--[[
--   Pirates shipping missions are always timed, but quite lax on the schedules
--   and pays a lot more then the rush missions
--]]


-- This is in cargo_common, but we need to increase the range
function cargo_selectMissionDistance ()
   return rnd.rnd(3, 10)
end


function create()
   -- Note: this mission does not make any system claims.

   origin_p, origin_s = planet.cur()
   local routesys = origin_s
   local routepos = origin_p:pos()

   -- target destination
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   if destplanet == nil or destplanet:faction() == faction.get("Pirate") then
      misn.finish(false)
   end

   -- We’re redefining the cargo
   local cargoes = {
      {
         N_("Unmarked Boxes"),
         _("A collection of unmarked boxes you were not told the contents of.")
      },
      {
         N_("Weapons"),
         _("Assorted crates of illegally sourced weapons to be sold on the black market.")
      },
      {
         N_("Drugs"),
         _("A collection of various illegal drugs that will surely net a large profit.")
      },
      {
         N_("Exotic Animals"),
         _("Several exotic animal species being trafficked from all around the galaxy.")
      },
      {
         N_("Radioactive Materials"),
         _("Highly dangerous, yet highly useful, radioactive materials being sold on the black market, outside of regulatory bodies.")
      },
   }
   cargo = cargoes[rnd.rnd(1, #cargoes)]
   cargo["__save"] = true

   -- mission generics
   stuperpx   = 0.3 - 0.015 * tier
   stuperjump = 11000 - 75 * tier
   stupertakeoff = 15000
   timelimit  = time.get() + time.create(0, 0, traveldist * stuperpx + numjumps * stuperjump + stupertakeoff + 480 * numjumps)

   -- Allow extra time for refuelling stops.
   local jumpsperstop = 3 + math.min(tier, 1)
   if numjumps > jumpsperstop then
      timelimit:add(time.create(
               0, 0, math.floor((numjumps-1) / jumpsperstop) * stuperjump))
   end
   
   -- Choose amount of cargo and mission reward. This depends on the mission tier.
   finished_mod = 2.0 -- Modifier that should tend towards 1.0 as Naev is finished as a game
   amount    = rnd.rnd(10 + 3 * tier, 20 + 4 * tier) 
   jumpreward = 1500
   distreward = 0.30
   reward    = 1.5^tier * (numjumps * jumpreward + traveldist * distreward) * finished_mod * (1. + 0.05*rnd.twosigma())
   
   misn.setTitle(fmt.f(
            _("PIRACY: Illegal Cargo transport ({amount} of {cargotype})"),
            {amount=fmt.tonnes(amount), cargotype=_(cargo[1])}))
   misn.markerAdd(destsys, "computer")
   cargo_setDesc(
         fmt.f(misn_desc, {planet=destplanet:name(), system=destsys:name()}),
         cargo[1], amount, destplanet, timelimit);
   misn.setReward(fmt.credits(reward))
end

-- Mission is accepted
function accept()
   local playerbest = cargoGetTransit(timelimit, numjumps, traveldist)
   if timelimit < playerbest then
      if not tk.yesno("", fmt.f(
               _("This shipment must arrive within {timelimit}, but it will take at least {time} for your ship to reach {planet}, missing the deadline. Accept the mission anyway?"),
               {timelimit=(timelimit - time.get()):str(),
                  time=(playerbest - time.get()):str(),
                  planet=destplanet:name()})) then
         misn.finish()
      end
   end
   if player.pilot():cargoFree() < amount then
      tk.msg("", fmt.f(
               _("You don't have enough cargo space to accept this mission. It requires {amount} of free space ({amount2} more than you have)."),
               {amount=fmt.tonnes(amount),
                  amount2=fmt.tonnes(amount - player.pilot():cargoFree())}))
      misn.finish()
   end

   misn.accept()

   local cobj = misn.cargoNew(cargo[1], cargo[2])
   carg_id = misn.cargoAdd(cobj, amount)

   local osd_msg = {}
   osd_msg[1] = fmt.f(osd_msg1,
      {planet=destplanet:name(), system=destsys:name(),
         timelimit=timelimit:str(), time=(timelimit - time.get()):str()})
   misn.osdCreate(osd_title, osd_msg)
   hook.land("land") -- only hook after accepting
   hook.date(time.create(0, 0, 100), "tick") -- 100STU per tick
end

-- Land hook
function land()
   if planet.cur() == destplanet then
         tk.msg("", fmt.f(
                  _("The containers of {cargotype} are unloaded at the docks."),
                  {cargotype=_(cargo[1])}))
      player.pay(reward)
      n = var.peek("ps_misn")
      if n ~= nil then
         var.push("ps_misn", n+1)
      else
         var.push("ps_misn", 1)
      end

      -- increase faction
      if player.misnActive("Fake ID") then
         -- Won't get immediately noticed with fake ID.
         faction.modPlayerSingle("Pirate", 1)
      else
         faction.modPlayer("Pirate", 1)
      end
      misn.finish(true)
   end
end

-- Date hook
function tick()
   if timelimit >= time.get() then
      -- Case still in time
      local osd_msg = {}
      osd_msg[1] = fmt.f(osd_msg1,
         {planet=destplanet:name(), system=destsys:name(),
            timelimit=timelimit:str(), time=(timelimit - time.get()):str()})
      misn.osdCreate(osd_title, osd_msg)
   elseif timelimit <= time.get() then
      -- Case missed deadline
      player.msg(msg_timeup)
      misn.finish(false)
   end
end
