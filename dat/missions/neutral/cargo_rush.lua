--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Cargo Rush">
 <avail>
  <priority>77</priority>
  <chance>960</chance>
  <location>Computer</location>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Independent</faction>
 </avail>
</mission>
--]]
--[[
   -- These are rush cargo delivery missions. They can be failed! But, pay is higher to compensate.
   -- These missions require fast ships, but higher tiers may also require increased cargo space.
--]]

local fmt = require "fmt"
local mh = require "misnhelper"
require "cargo_common"

osd_title = _("Rush Cargo")

-- Create the mission
function create()
   -- Calculate the route, distance, jumps, risk of piracy, and cargo to take
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   if destplanet == nil then
      misn.finish(false)
   end

   -- Override tiers with only low tiers if tutorial is incomplete.
   if not var.peek("tut_complete") then
      tier = rnd.rnd(0, 1)
   end

   -- Calculate time limit. Depends on tier and distance.
   -- The second time limit is for the reduced reward.
   stuperpx = 4.6 - 0.57*tier
   stuperjump = 103000 - 6000*tier
   stupertakeoff = 103000 - 750*tier
   allowance = traveldist*stuperpx + numjumps*stuperjump + stupertakeoff
         + 2400*numjumps

   -- Allow extra time for refuelling stops.
   local jumpsperstop = 2 + math.min(tier-1, 2)
   if numjumps > jumpsperstop then
      allowance = allowance + math.floor((numjumps-1) / jumpsperstop) * stuperjump
   end

   timelimit = time.get() + time.create(0, 0, allowance)
   timelimit2 = time.get() + time.create(0, 0, allowance * 1.2)

   local piracyrisk, riskreward
   if avgrisk == 0 then
      piracyrisk = _("#nPiracy Risk:#0 None")
      riskreward = 0
   elseif avgrisk <= 25 then
      piracyrisk = _("#nPiracy Risk:#0 Low")
      riskreward = 50
   elseif avgrisk > 25 and avgrisk <= 100 then
      piracyrisk = _("#nPiracy Risk:#0 Medium")
      riskreward = 100
   else
      piracyrisk = _("#nPiracy Risk:#0 High")
      riskreward = 150
   end

   -- Choose amount of cargo and mission reward. This depends on the mission tier.
   -- Note: Pay is independent from amount by design! Not all deals are equally attractive!
   amount = rnd.rnd(10 + 5 * tier, 20 + 15 * tier)
   jumpreward = (commodity.price(cargo) * (20+riskreward)) / 100
   distreward = math.log((50+riskreward)*commodity.price(cargo)) / 100
   reward = (1.75^tier
         * (avgrisk*riskreward + numjumps*jumpreward + traveldist*distreward
            + 10000)
         * (1 + 0.05*rnd.twosigma()))

   local title, desc
   if tier <= 0 then
      title = n_("Rush Cargo (Courier): {amount} kt to {planet} ({system} system)",
            "Rush Cargo (Courier): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Courier cargo transport to {planet} in the {system} system.")
   elseif tier <= 1 then
      title = n_("Rush Cargo (Priority): {amount} kt to {planet} ({system} system)",
            "Rush Cargo (Priority): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Priority cargo shipment to {planet} in the {system} system.")
   elseif tier <= 2 then
      title = n_("Rush Cargo (Pressing): {amount} kt to {planet} ({system} system)",
            "Rush Cargo (Pressing): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Pressing cargo delivery to {planet} in the {system} system.")
   elseif tier <= 3 then
      title = n_("Rush Cargo (Urgent): {amount} kt to {planet} ({system} system)",
            "Rush Cargo (Urgent): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Urgent cargo delivery to {planet} in the {system} system.")
   else
      title = n_("Rush Cargo (Emergency): {amount} kt to {planet} ({system} system)",
            "Rush Cargo (Emergency): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Emergency cargo delivery to {planet} in the {system} system.")
   end

   misn.setTitle(fmt.f(title,
         {planet=destplanet:name(), system=destsys:name(),
            amount=fmt.number(amount)}))
   misn.markerAdd(destsys, "computer", destplanet)
   cargo_setDesc(fmt.f(desc,
            {planet=destplanet:name(), system=destsys:name()}),
         cargo, amount, destplanet, numjumps, timelimit, piracyrisk);
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
   intime = true
   misn.cargoAdd(cargo, amount)
   create_osd()

   hook.land("land")
   hook.date(time.create(0, 0, 1000), "tick")
end


function create_osd()
   local osd_desc
   if timelimit >= time.get() then
      osd_desc = {
         fmt.f(_("Land on {planet} ({system} system) before {deadline}"),
            {planet=destplanet, system=destsys, deadline=timelimit:str()}),
         "\t" .. fmt.f(_("{time} remaining"),
            {time=time.str(timelimit - time.get(), 2)}),
      }
   else
      osd_desc = {
         fmt.f(_("Land on {planet} ({system} system) before {deadline}"),
            {planet=destplanet, system=destsys, deadline=timelimit:str()}),
         "\t" .. _("Deadline missed, but you can still make a late delivery if you hurry"),
      }
   end
   misn.osdCreate(osd_title, osd_desc)
end


function land()
   if planet.cur() == destplanet then
      -- Semi-random message.
      local cargo_land = {
         _("The containers of {cargotype} are carried out of your ship by a sullen group of workers. The job takes inordinately long to complete, and the leader pays you without speaking a word."),
         _("The containers of {cargotype} are rushed out of your vessel by a team shortly after you land. Before you can even collect your thoughts, one of them presses a credit chip in your hand and departs."),
         _("The containers of {cargotype} are unloaded by an exhausted-looking bunch of dockworkers. Still, they make fairly good time, delivering your pay upon completion of the job."),
      }
      if intime then
         if tier >= 3 then
            cargo_land = {
               _("A group of workers efficiently unloads the containers of {cargotype} from your ship. When they finish, the leader thanks you with a smile and hands you your pay on a credit chip before moving on to another job."),
               _("The containers of {cargotype} are rushed out of your veessel by a team that awaits you at the spaceport. Before you know it, the job is done; one of them presses a credit chip into your hand, quickly thanks you, and departs."),
               _("The containers of {cargotype} are unloaded by a relaxed-looking bunch of dockworkers. They make very good time, thanking you and delivering your pay upon completion of the job."),
            }
            local f = planet.cur():faction()
            if f ~= nil then
               f:modPlayerSingle(1)
            end
         end
      else
         -- Semi-random message for being late.
         cargo_land = {
            _("The containers of {cargotype} are carried out of your ship by a sullen group of workers. They are not happy that they have to work overtime because you were late. You are paid only half the original reward you were promised."),
            _("The containers of {cargotype} are rushed out of your vessel by a team shortly after you land. Your late arrival is stretching quite a few schedules! Your pay is only half your original pay because of that."),
            _("The containers of {cargotype} are unloaded by an exhausted-looking bunch of dockworkers. You missed the deadline, so your reward is only half the amount you were hoping for."),
         }
         reward = reward / 2
      end

      -- Mark the initial tutorial as complete.
      var.push("tut_complete", true)

      tk.msg("", fmt.f(cargo_land[rnd.rnd(1, #cargo_land)],
               {cargotype=_(cargo)}))
      player.pay(reward)
      misn.finish(true)
   end
end

-- Date hook
function tick()
   create_osd()

   if timelimit < time.get() then
      -- Missed first deadline
      intime = false
      if timelimit2 <= time.get() then
         -- Missed second deadline
         mh.showFailMsg(
            fmt.f(_("Deadline for delivery to {planet} ({system}) missed."),
               {planet=destplanet, system=destsys}))
         misn.finish(false)
      end
   end
end
