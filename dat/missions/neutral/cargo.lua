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
require "cargo_common"


misn_desc = {}
-- Note: indexed from 0 to match mission tiers.
misn_desc[0] = _("Small shipment to {planet} in the {system} system.")
misn_desc[1] = _("Medium shipment to {planet} in the {system} system.")
misn_desc[2] = _("Sizable cargo delivery to {planet} in the {system} system.")
misn_desc[3] = _("Large cargo delivery to {planet} in the {system} system.")
misn_desc[4] = _("Bulk freight delivery to {planet} in the {system} system.")

piracyrisk = {}
piracyrisk[1] = _("Piracy Risk: None")
piracyrisk[2] = _("Piracy Risk: Low")
piracyrisk[3] = _("Piracy Risk: Medium")
piracyrisk[4] = _("Piracy Risk: High")

osd_title = _("Cargo mission")
osd_msg = _("Land on {planet} ({system} system)")

-- Create the mission
function create()
   -- Note: this mission does not make any system claims. 
   
   -- Calculate the route, distance, jumps, risk of piracy, and cargo to take
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   if destplanet == nil then
      misn.finish(false)
   end
   
   if avgrisk == 0 then
      piracyrisk = piracyrisk[1]
      riskreward = 0
   elseif avgrisk <= 25 then
      piracyrisk = piracyrisk[2]
      riskreward = 20
   elseif avgrisk > 25 and avgrisk <= 100 then
      piracyrisk = piracyrisk[3]
      riskreward = 50
   else
      piracyrisk = piracyrisk[4]
      riskreward = 100
   end

   -- Choose amount of cargo and mission reward. This depends on the mission tier.
   -- Reward depends on type of cargo hauled. Hauling expensive commodities gives a better deal.
   -- Note: Pay is independent from amount by design! Not all deals are equally attractive!
   amount = rnd.rnd(5 + 20*tier, 20 + 50*tier)
   jumpreward = commodity.price(cargo) * 1.2
   distreward = math.log(200*commodity.price(cargo)) / 100
   reward = (1.5^tier
         * (avgrisk*riskreward + numjumps*jumpreward + traveldist*distreward
            + 25000)
         * (1 + 0.05*rnd.twosigma()))

   local title = n_("Cargo: {amount} t to {planet} ({system} system)",
         "Cargo: {amount} t to {planet} ({system} system)", amount)
   misn.setTitle(fmt.f(title,
         {planet=destplanet:name(), system=destsys:name(),
            amount=fmt.number(amount)}))
   misn.markerAdd(destsys, "computer")
   cargo_setDesc(fmt.f(misn_desc[tier],
            {planet=destplanet:name(), system=destsys:name()}),
         cargo, amount, destplanet, nil, piracyrisk);
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

      tk.msg("", fmt.f(cargo_land[rnd.rnd(1, #cargo_land)],
               {cargotype=_(cargo)}))
      player.pay(reward)
      misn.finish(true)
   end
end

function abort ()
   misn.finish(false)
end

