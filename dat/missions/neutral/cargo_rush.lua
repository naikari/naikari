--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Cargo Rush">
 <avail>
  <priority>77</priority>
  <chance>960</chance>
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
--[[
   -- These are rush cargo delivery missions. They can be failed! But, pay is higher to compensate.
   -- These missions require fast ships, but higher tiers may also require increased cargo space.
--]]

local fmt = require "fmt"
require "cargo_common"


piracyrisk = {}
piracyrisk[1] = _("Piracy Risk: None")
piracyrisk[2] = _("Piracy Risk: Low")
piracyrisk[3] = _("Piracy Risk: Medium")
piracyrisk[4] = _("Piracy Risk: High")

msg_timeup = _("The delivery to {system} has been canceled! You were too late.")

osd_title = _("Rush cargo mission")
osd_msg1 = _("Land on {planet} ({system} system) before {deadline}\n({time} remaining)")
osd_timeup = _("Land on {planet} ({system} system) before {deadline}\n(deadline missed, but you can still make a late delivery if you hurry)")

-- Create the mission
function create()
   -- Note: this mission does not make any system claims. 
   
   -- Calculate the route, distance, jumps, risk of piracy, and cargo to take
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   if destplanet == nil then
      misn.finish(false)
   end
   
   -- Calculate time limit. Depends on tier and distance.
   -- The second time limit is for the reduced reward.
   stuperpx = 0.2 - 0.025*tier
   stuperjump = 10300 - 600*tier
   stupertakeoff = 10300 - 75*tier
   allowance = traveldist*stuperpx + numjumps*stuperjump + stupertakeoff
         + 240*numjumps
   
   -- Allow extra time for refuelling stops.
   local jumpsperstop = 2 + math.min(tier-1, 2)
   if numjumps > jumpsperstop then
      allowance = allowance + math.floor((numjumps-1) / jumpsperstop) * stuperjump
   end
   
   timelimit = time.get() + time.create(0, 0, allowance)
   timelimit2 = time.get() + time.create(0, 0, allowance * 1.2)
   
   if avgrisk == 0 then
      piracyrisk = piracyrisk[1]
      riskreward = 0
   elseif avgrisk <= 25 then
      piracyrisk = piracyrisk[2]
      riskreward = 10
   elseif avgrisk > 25 and avgrisk <= 100 then
      piracyrisk = piracyrisk[3]
      riskreward = 25
   else
      piracyrisk = piracyrisk[4]
      riskreward = 50
   end
   
   -- Choose amount of cargo and mission reward. This depends on the mission tier.
   -- Note: Pay is independent from amount by design! Not all deals are equally attractive!
   finished_mod = 2.0 -- Modifier that should tend towards 1.0 as Naev is finished as a game
   amount = rnd.rnd(10 + 5 * tier, 20 + 6 * tier) -- 45 max (quicksilver)
   jumpreward = commodity.price(cargo)*1.2
   distreward = math.log(300*commodity.price(cargo))/100
   reward = (1.5^tier
         * (avgrisk*riskreward + numjumps*jumpreward + traveldist*distreward)
         * finished_mod * (1. + 0.05*rnd.twosigma()))

   local title, desc
   if tier <= 0 then
      title = n_("Courier Cargo: {amount} t to {planet} ({system} system)",
            "Courier Cargo: {amount} t to {planet} ({system} system)", amount)
      desc = _("Courier cargo transport to {planet} in the {system} system.")
   elseif tier <= 1 then
      title = n_("Priority Cargo: {amount} t to {planet} ({system} system)",
            "Priority Cargo: {amount} t to {planet} ({system} system)", amount)
      desc = _("Priority cargo shipment to {planet} in the {system} system.")
   elseif tier <= 2 then
      title = n_("Pressing Cargo: {amount} t to {planet} ({system} system)",
            "Pressing Cargo: {amount} t to {planet} ({system} system)", amount)
      desc = _("Pressing cargo delivery to {planet} in the {system} system.")
   elseif tier <= 3 then
      title = n_("Urgent Cargo: {amount} t to {planet} ({system} system)",
            "Urgent Cargo: {amount} t to {planet} ({system} system)", amount)
      desc = _("Urgent cargo delivery to {planet} in the {system} system.")
   else
      title = n_(
            "Emergency Cargo: {amount} t to {planet} ({system} system)",
            "Emergency Cargo: {amount} t to {planet} ({system} system)",
            amount)
      desc = _("Emergency cargo delivery to {planet} in the {system} system.")
   end

   misn.setTitle(fmt.f(title,
         {planet=destplanet:name(), system=destsys:name(),
            amount=fmt.number(amount)}))
   misn.markerAdd(destsys, "computer")
   cargo_setDesc(fmt.f(desc,
            {planet=destplanet:name(), system=destsys:name()}),
         cargo, amount, destplanet, timelimit, piracyrisk);
   misn.setReward(fmt.credits(reward))
end

-- Mission is accepted
function accept()
   if player.pilot():cargoFree() < amount then
      local required_text = n_(
            "You don't have enough cargo space to accept this mission. It requires {required} tonne of free space. ",
            "You don't have enough cargo space to accept this mission. It requires {required} tonnes of free space. ",
            amount)
      local shortfall = amount - player.pilot():cargoFree()
      local shortfall_text = n_(
            "You need {shortfall} more tonne of empty space.",
            "You need {shortfall} more tonnes of empty space.",
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
         or system.cur():jumpDist(destsys, true, true) < numjumps then
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
   local osd_msg = {}
   osd_msg[1] = fmt.f(osd_msg1,
         {planet=destplanet:name(), system=destsys:name(),
            deadline=timelimit:str(), time=tonumber(timelimit - time.get())})
   misn.osdCreate(osd_title, osd_msg)
   hook.land("land")
   hook.date(time.create(0, 0, 100), "tick") -- 100STU per tick
end

-- Land hook
function land()
   if planet.cur() == destplanet then
      if intime then
      -- Semi-random message.
      local cargo_land = {
         _("The containers of {cargotype} are carried out of your ship by a sullen group of workers. The job takes inordinately long to complete, and the leader pays you without speaking a word."),
         _("The containers of {cargotype} are rushed out of your vessel by a team shortly after you land. Before you can even collect your thoughts, one of them presses a credit chip in your hand and departs."),
         _("The containers of {cargotype} are unloaded by an exhausted-looking bunch of dockworkers. Still, they make fairly good time, delivering your pay upon completion of the job."),
      }

      tk.msg("", fmt.f(cargo_land[rnd.rnd(1, #cargo_land)],
               {cargotype=_(cargo)}))
   else
      -- Semi-random message for being late.
      local cargo_land = {
         _("The containers of {cargotype} are carried out of your ship by a sullen group of workers. They are not happy that they have to work overtime because you were late. You are paid only half the original reward you were promised."),
         _("The containers of {cargotype} are rushed out of your vessel by a team shortly after you land. Your late arrival is stretching quite a few schedules! Your pay is only half your original pay because of that."),
         _("The containers of {cargotype} are unloaded by an exhausted-looking bunch of dockworkers. You missed the deadline, so your reward is only half the amount you were hoping for."),
      }

      tk.msg("", fmt.f(cargo_land[rnd.rnd(1, #cargo_land)],
               {cargotype=_(cargo)}))
      reward = reward / 2
   end
   player.pay(reward)
   misn.finish(true)
   end
end

-- Date hook
function tick()
   local osd_msg = {}
   if timelimit >= time.get() then
      local osd_msg = {}
      osd_msg[1] = fmt.f(osd_msg1,
            {planet=destplanet:name(), system=destsys:name(),
               deadline=timelimit:str(), time=tonumber(timelimit - time.get())})
      misn.osdCreate(osd_title, osd_msg)
   elseif timelimit2 <= time.get() then
      -- Case missed second deadline
      player.msg(fmt.f(msg_timeup, {system=destsys:name()}))
      misn.finish(false)
   elseif intime then
      -- Case missed first deadline
      osd_msg[1] = fmt.f(osd_timeup,
            {planet=destplanet:name(), system=destsys:name(),
               deadline=timelimit:str()})
      misn.osdCreate(osd_title, osd_msg)
      intime = false
   end
end
