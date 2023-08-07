--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Cargo">
 <avail>
  <priority>78</priority>
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
   -- These are regular cargo delivery missions. Pay is low, but so is difficulty.
   -- Most of these missions require BULK ships. Not for small ships!
--]]

local fmt = require "fmt"
local mh = require "misnhelper"
require "cargo_common"


osd_title = _("Cargo")
osd_msg = _("Land on {planet} ({system} system)")


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

   local piracyrisk, riskreward
   if avgrisk == 0 then
      piracyrisk = _("#nPiracy Risk:#0 None")
      riskreward = 0
   elseif avgrisk <= 25 then
      piracyrisk = _("#nPiracy Risk:#0 Low")
      riskreward = 100
   elseif avgrisk > 25 and avgrisk <= 100 then
      piracyrisk = _("#nPiracy Risk:#0 Medium")
      riskreward = 200
   else
      piracyrisk = _("#nPiracy Risk:#0 High")
      riskreward = 300
   end

   -- Choose amount of cargo and mission reward. This depends on the mission tier.
   -- Reward depends on type of cargo hauled. Hauling expensive commodities gives a better deal.
   -- Note: Pay is independent from amount by design! Not all deals are equally attractive!
   amount = rnd.rnd(5 + 20*tier, 20 + 50*tier)
   jumpreward = (commodity.price(cargo) * (20+riskreward)) / 100
   distreward = math.log((50+riskreward)*commodity.price(cargo)) / 100
   reward = (1.5^tier
         * (avgrisk*riskreward + numjumps*jumpreward + traveldist*distreward
            + 5000)
         * (1 + 0.05*rnd.twosigma()))

   local title, desc
   if tier <= 0 then
      title = n_("Cargo (Small): {amount} kt to {planet} ({system} system)",
            "Cargo (Small): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Small shipment to {planet} in the {system} system.")
   elseif tier <= 1 then
      title = n_("Cargo (Medium): {amount} kt to {planet} ({system} system)",
            "Cargo (Medium): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Medium shipment to {planet} in the {system} system.")
   elseif tier <= 2 then
      title = n_("Cargo (Sizable): {amount} kt to {planet} ({system} system)",
            "Cargo (Sizable): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Sizable cargo delivery to {planet} in the {system} system.")
   elseif tier <= 3 then
      title = n_("Cargo (Large): {amount} kt to {planet} ({system} system)",
            "Cargo (Large): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Large cargo delivery to {planet} in the {system} system.")
   else
      title = n_("Cargo (Bulk): {amount} kt to {planet} ({system} system)",
            "Cargo (Bulk): {amount} kt to {planet} ({system} system)",
            amount)
      desc = _("Bulk freight delivery to {planet} in the {system} system.")
   end

   misn.setTitle(fmt.f(title,
         {planet=destplanet:name(), system=destsys:name(),
            amount=fmt.number(amount)}))
   misn.markerAdd(destsys, "computer", destplanet)
   cargo_setDesc(fmt.f(desc,
            {planet=destplanet:name(), system=destsys:name()}),
         cargo, amount, destplanet, numjumps, nil, piracyrisk)
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
   misn.accept()
   misn.cargoAdd(cargo, amount)
   misn.osdCreate(osd_title, {
         fmt.f(osd_msg, {planet=destplanet:name(), system=destsys:name()})
      })

   hook.land("land")
end

-- Land hook
function land()
   if planet.cur() == destplanet then
      -- Semi-random message.
      local cargo_land = {
         _("The containers of {cargotype} are carried out of your ship by a sullen group of workers. The job takes inordinately long to complete, and the leader pays you without speaking a word."),
         _("The containers of {cargotype} are rushed out of your vessel by a team shortly after you land. Before you can even collect your thoughts, one of them presses a credit chip in your hand and departs."),
         _("The containers of {cargotype} are unloaded by an exhausted-looking bunch of dockworkers. Still, they make fairly good time, delivering your pay upon completion of the job."),
      }
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

      -- Mark the initial tutorial as complete.
      var.push("tut_complete", true)

      tk.msg("", fmt.f(cargo_land[rnd.rnd(1, #cargo_land)],
               {cargotype=_(cargo)}))
      player.pay(reward)
      misn.finish(true)
   end
end
