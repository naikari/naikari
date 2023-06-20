--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Long Distance Empire Shipping">
 <avail>
  <priority>71</priority>
  <cond>faction.playerStanding("Empire") &gt;= 5</cond>
  <chance>250</chance>
  <done>Empire Recruitment</done>
  <location>Computer</location>
  <faction>Empire</faction>
 </avail>
 <notes>
  <provides name="Completed 3 or more ES deliveries"/>
 </notes>
</mission>
--]]
--[[
   
   Handles the randomly generated Empire long-distance cargo missions.
   
]]--

local fmt = require "fmt"
require "cargo_common"


misn_desc  = _("Official long distance Empire cargo transport to {planet} in the {system} system.")

piracyrisk = {}
piracyrisk[1] = _("Piracy Risk: None")
piracyrisk[2] = _("Piracy Risk: Low")
piracyrisk[3] = _("Piracy Risk: Medium")
piracyrisk[4] = _("Piracy Risk: High")

msg_timeup = _("MISSION FAILED: You have failed to deliver the goods to the Empire on time!")

osd_title = _("Long Distance Empire Shipping")
osd_msg1 = _("Land on {planet} ({system} system) before {deadline}\n({time} remaining)")

--[[
   -- Empire shipping missions are always timed, but quite lax on the schedules
   -- pays a bit more then the rush missions
--]]


-- This is in cargo_common, but we need to increase the range
function cargo_selectMissionDistance ()
   return rnd.rnd(5, 12)
end


-- Create the mission
function create()
   -- Note: this mission does not make any system claims.

   origin_p, origin_s = planet.cur()
   local routesys = origin_s
   local routepos = origin_p:pos()

   -- target destination
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   if destplanet == nil then
      misn.finish(false)
   end
   if destplanet:faction() == faction.get("Empire") or destplanet:faction() == faction.get("Independent") then
      misn.finish(false)
   end

   -- Override tiers with only low tiers if tutorial is incomplete.
   if not var.peek("tut_complete") then
      tier = rnd.rnd(0, 1)
   end

   -- mission generics
   stuperpx = 7 - 0.3*tier
   stuperjump = 150000
   stupertakeoff = 150000
   timelimit = time.get() + time.create(0, 0,
         traveldist*stuperpx + numjumps*stuperjump + stupertakeoff
            + 4800*numjumps)

   -- Allow extra time for refuelling stops.
   local jumpsperstop = 3
   if numjumps > jumpsperstop then
      timelimit:add(time.create(0, 0,
               math.floor((numjumps-1) / jumpsperstop) * stuperjump))
   end

   --Determine risk of piracy
   if avgrisk == 0 then
      piracyrisk = piracyrisk[1]
      riskreward = 0
   elseif avgrisk <= 25 then
      piracyrisk = piracyrisk[2]
      riskreward = 150
   elseif avgrisk > 25 and avgrisk <= 100 then
      piracyrisk = piracyrisk[3]
      riskreward = 300
   else
      piracyrisk = piracyrisk[4]
      riskreward = 450
   end

   -- Choose amount of cargo and mission reward. This depends on the mission tier.
   amount = rnd.rnd(10 + 3*tier, 20 + 4*tier)
   jumpreward = (commodity.price(cargo) * (25+riskreward)) / 100
   distreward = math.log((100+riskreward)*commodity.price(cargo)) / 100
   reward = (1.75^tier
         * (avgrisk*riskreward + numjumps*jumpreward + traveldist*distreward
            + 20000)
         * (1 + 0.05*rnd.twosigma()))

   local title = n_(
         "ES: Long Distance Cargo: {amount} kt to {planet} ({system} system)",
         "ES: Long Distance Cargo: {amount} kt to {planet} ({system} system)",
         amount)
   misn.setTitle(fmt.f(title,
         {planet=destplanet:name(), system=destsys:name(),
            amount=fmt.number(amount)}))
   misn.markerAdd(destsys, "computer")
   cargo_setDesc(fmt.f(misn_desc,
            {planet=destplanet:name(), system=destsys:name()}),
         cargo, amount, destplanet, numjumps, timelimit, piracyrisk)
   misn.setReward(fmt.credits(reward))
end

-- Mission is accepted
function accept()
   if player.pilot():cargoFree() < amount then
      local required_text = n_(
            "You don't have enough cargo space to accept this mission. It requires {required} kt of free space. ",
            "You don't have enough cargo space to accept this mission. It requires {required} kt of free space. ",
            amount)
      local shortfall = amount - player.pilot():cargoFree()
      local shortfall_text = n_(
            "You need {shortfall} kt more of empty space.",
            "You need {shortfall} kt more of empty space.",
            shortfall)
      tk.msg("", fmt.f(required_text .. shortfall_text,
            {required=fmt.number(amount),
               shortfall=fmt.number(shortfall)}))
      misn.finish()
   end
   player.pilot():cargoAdd("Food", amount)
   local playerbest = cargoGetTransit(timelimit, numjumps, traveldist)
   player.pilot():cargoRm("Food", amount)
   if timelimit < playerbest then
      local tlimit = timelimit - time.get()
      local tmore = playerbest - time.get()
      if not tk.yesno("", fmt.f(
               _("This shipment must arrive within {timelimit}, but it will take at least {time} for your ship to reach {planet}, missing the deadline. Accept the mission anyway?"),
               {timelimit=tlimit:str(), time=tmore:str(),
                  planet=destplanet:name()})) then
         misn.finish()
      end
   elseif system.cur():jumpDist(destsys, true, true) == nil
         or system.cur():jumpDist(destsys, true, true) > numjumps then
      local text = n_(
            "The fastest route to {planet} is not currently known to you. Landing to buy maps, spending time searching for unknown jumps, or taking a route longer than {jumps} jump may cause you to miss the deadline. Accept the mission anyway?",
            "The fastest route to {planet} is not currently known to you. Landing to buy maps, spending time searching for unknown jumps, or taking a route longer than {jumps} jumps may cause you to miss the deadline. Accept the mission anyway?",
            numjumps)
      if not tk.yesno("", fmt.f(text,
               {planet=destplanet:name(), jumps=numjumps})) then
         misn.finish()
      end
   end

   misn.accept()

   carg_id = misn.cargoAdd(cargo, amount)
   local osd_msg = {}
   osd_msg[1] = fmt.f(osd_msg1,
         {planet=destplanet:name(), system=destsys:name(),
            deadline=timelimit:str(),
            time=time.str(timelimit - time.get(), 2)})
   misn.osdCreate(osd_title, osd_msg)
   hook.land("land") -- only hook after accepting
   hook.date(time.create(0, 0, 1000), "tick") -- 100STU per tick
end

-- Land hook
function land()
   if planet.cur() == destplanet then
      local cargo_land = {
         _("The Imperial workers unload the {cargotype} at the docks."),
         _("The crates of {cargotype} are swiftly and professionally unloaded by a team of robots overseen by an Imperial worker."),
      }

      -- Mark the initial tutorial as complete.
      var.push("tut_complete", true)

      local n = var.peek("es_misn") or 0
      n = n + 1
      var.push("es_misn", n)
      if n >= 3 and faction.playerStanding("Empire") >= 10
            and faction.playerStanding("Dvaered") >= 0
            and not player.misnDone("Undercover in Hakoi")
            and not player.misnActive("Undercover in Hakoi") then
         cargo_land = {
            _("As the crates of {cargotype} are unloaded, the Imperial worker in charge relays a message from an Imperial Commander inviting you to Emperor's Fist for an advancement opportunity."),
         }
      end

      tk.msg("", fmt.f(cargo_land[rnd.rnd(1, #cargo_land)],
               {cargotype=_(cargo)}))
      player.pay(reward)

      -- increase faction
      faction.modPlayer("Empire", 1)
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
               deadline=timelimit:str(),
               time=time.str(timelimit - time.get(), 2)})
      misn.osdCreate(osd_title, osd_msg)
   elseif timelimit <= time.get() then
      -- Case missed deadline
      player.msg(msg_timeup)
      misn.finish(false)
   end
end
