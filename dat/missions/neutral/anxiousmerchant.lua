--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Anxious Merchant">
 <avail>
  <priority>50</priority>
  <chance>1</chance>
  <cond>
   var.peek("tut_complete") == true
   or planet.cur():faction() ~= faction.get("Empire")
  </cond>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[

   Anxious Merchant
   Author: PhoenixRiver (from an ideä on the wiki)

   A merchant with a slow ship suddenly realizes he can't make the delivery and
   implores the player to do it for him. Since he has to look good with his
   employers he'll pay the player a bonus if he does it.

   Note: Variant of the Drunkard and Rush Cargo missions combined

]]--

local fmt = require "fmt"
require "cargo_common"
local portrait = require "portrait"


bar_desc = _("You see a merchant at the bar in a clear state of anxiety.")

--- Missions details
misn_title = _("Anxious Merchant")

-- OSD
osd_title = _("Anxious Merchant")
osd_desc_1 = _("Land on {planet} ({system} system) before {deadline}\n({time} remaining)")
osd_desc_2 = _("Land on {planet} ({system} system) before {deadline}\n(You are late)")

misn_desc = _("You decided to help a fraught merchant by delivering some goods to {planet}.")

ask_text = _([[As you sit down the merchant looks up at you with a panicked expression, "Ahh! What do you want? Can't you see I've enough on my plate as it is?" You apologize and offer a drink. The merchant visibly relaxes. "Jeez, that's nice of you.…"

You grab a couple of drinks and hand one to the merchant as they start to talk. "So, I work for a company called NGL. I transport stuff for them, they pay me. Only problem is I kinda strained my engines running from pirates on the way to the pick-up and now I'm realising that my engines just don't have the speed to get me back to beat the deadline. And to top it all off, I'm late on my bills as is; I can't afford new engines now! it's like I'm in the Sol Nebula without a shield generator, you know?"

You attempt to reassure the merchant by telling them that surely the company will cut some slack. "Like hell they will! I've already been scolded by management for this exact same thing before! {job_description} I really need this job, you know? I don't know what to do.…" The merchant pauses. "Unless… say, you wouldn't be able to help me out here, would you? I'd just need you to take the cargo to {planet} in the {system} system. Could you? I'll give you the payment for the mission if you do it; it means a lot!"]])

yes_text = _([[The merchant sighs in relief. "Thank you so much for this. Just bring the cargo to the cargo guy at {planet}. They should pay you {credits} when you get there. Don't be late, OK?"]])

pay_text = _([[As you touch down at the spaceport you see the NGL depot surrounded by a hustle and bustle. The cargo inspector looks at you with surprise and you explain to them what happened as the cargo is unloaded from your ship. "Wow, thanks for the help! You definitely saved us a ton of grief. Here's your payment. Maybe I can buy you a drink some time!" You laugh and part ways.]])

pay_late_text = _([[Landing at the spaceport you see the NGL depot surrounded by a fraught hum of activity. The cargo inspector looks at you with surprise and then anger, "What the hell is this?! This shipment was supposed to be here ages ago! We've been shifting stuff around to make up for it and then you come waltzing in here… where the hell is the employee who was supposed to deliver this stuff?" A group of workers rushes along with the inspector and you as you try to explain what happened. The inspector frowns at your explanation. "That fool has been causing us all sorts of problems, and passing on the job to someone as incompetent as you is the last straw! I swear!"

You wait to one side as the cargo is hauled off your ship at breakneck speed and wonder if you should have just dumped the stuff in space. Just as the last of the cargo is taken off your ship the inspector, who has clearly cooled off a bit, comes up to you. "Look, I know you were trying to do us a favor and I'm glad you didn't just dump it all into space like some people have done, so I'll give you a few credits for your troubles. But next time don't bother if you can't make it on time." The inspector shakes their head and walks away. "That pilot is so fired.…"]])


function create()
   -- Note: this mission does not make any system claims.

   -- Calculate the route, distance, jumps and cargo to take
   dest_planet, dest_sys, num_jumps, travel_dist, cargo, avgrisk, tier = cargo_calculateRoute()
   if dest_planet == nil or dest_sys == system.cur() then
      misn.finish(false)
   end

   misn.setNPC(_("Merchant"), portrait.get("Trader"), bar_desc)

   -- Hardcoded tier of 4 ("Emergency" level)
   tier = 4

   -- Calculate time limit. Depends on tier and distance.
   stuperpx = 4.6 - 0.57*tier
   stuperjump = 103000 - 6000*tier
   stupertakeoff = 103000 - 750*tier
   allowance = travel_dist*stuperpx + num_jumps*stuperjump + stupertakeoff
         + 2400*num_jumps
   
   -- Allow extra time for refuelling stops.
   local jumpsperstop = 2 + math.min(tier-1, 2)
   if num_jumps > jumpsperstop then
      allowance = allowance + math.floor((num_jumps-1)/jumpsperstop)*stuperjump
   end

   time_limit = time.get() + time.create(0, 0, allowance)

   if avgrisk == 0 then
      riskreward = 0
   elseif avgrisk <= 25 then
      riskreward = 150
   elseif avgrisk > 25 and avgrisk <= 100 then
      riskreward = 300
   else
      riskreward = 450
   end

   cargo_size = rnd.rnd(10 + 5 * tier, 20 + 15 * tier)
   jumpreward = (commodity.price(cargo) * (20+riskreward)) / 100
   distreward = math.log((50+riskreward)*commodity.price(cargo)) / 100
   payment = (1.85^tier
         * (avgrisk*riskreward + num_jumps*jumpreward + travel_dist*distreward
            + 10000)
         * (1 + 0.05*rnd.twosigma()))
end

function accept()
   local job_description = fmt.f(n_(
            "If I don't get this {tonnes} kt of {cargo} to {planet}…",
            "If I don't get these {tonnes} kt of {cargo} to {planet}…",
            cargo_size),
         {tonnes=cargo_size, cargo=_(cargo), planet=dest_planet:name()})
   if not tk.yesno("", fmt.f(ask_text,
         {job_description=job_description, planet=dest_planet:name(),
            system=dest_sys:name()})) then
      misn.finish()
   end

   if player.pilot():cargoFree() < cargo_size then
      local required_text = n_(
            "You don't have enough cargo space to accept this mission. It requires {required} kt of free space. ",
            "You don't have enough cargo space to accept this mission. It requires {required} kt of free space. ",
            cargo_size)
      local shortfall = cargo_size - player.pilot():cargoFree()
      local shortfall_text = n_(
            "You need {shortfall} kt more of empty space.",
            "You need {shortfall} kt more of empty space.",
            shortfall)
      tk.msg("", fmt.f(required_text .. shortfall_text,
            {required=fmt.number(cargo_size),
               shortfall=fmt.number(shortfall)}))
      misn.finish()
   end
   player.pilot():cargoAdd("Food", cargo_size)
   local playerbest = cargoGetTransit(time_limit, num_jumps, travel_dist)
   player.pilot():cargoRm("Food", cargo_size)
   local mindist = system.cur():jumpDist(dest_sys, true, true)
   if time_limit < playerbest then
      local tlimit = time_limit - time.get()
      local tmore = playerbest - time.get()
      if not tk.yesno("", fmt.f(
               _("This shipment must arrive within {timelimit}, but it will take at least {time} for your ship to reach {planet}, missing the deadline. Accept the mission anyway?"),
               {timelimit=tlimit:str(), time=tmore:str(),
                  planet=dest_planet:name()})) then
         misn.finish()
      end
   elseif mindist == nil or mindist > num_jumps then
      local text = n_(
            "The fastest route to {planet} is not currently known to you. Landing to buy maps, spending time searching for unknown jumps, or taking a route longer than {jumps} jump may cause you to miss the deadline. Accept the mission anyway?",
            "The fastest route to {planet} is not currently known to you. Landing to buy maps, spending time searching for unknown jumps, or taking a route longer than {jumps} jumps may cause you to miss the deadline. Accept the mission anyway?",
            num_jumps)
      if not tk.yesno("", fmt.f(text,
               {planet=dest_planet:name(), jumps=num_jumps})) then
         misn.finish()
      end
   end

   misn.accept()

   misn.setTitle(misn_title)
   misn.setReward(fmt.credits(payment))
   misn.setDesc(fmt.f(misn_desc, {planet=dest_planet:name()}))

   marker = misn.markerAdd(dest_sys, "low")

   cargo_ID = misn.cargoAdd(cargo, cargo_size)

   local osd_msg = {
      fmt.f(osd_desc_1,
            {planet=dest_planet:name(), system=dest_sys:name(),
               deadline=time_limit:str(),
               time=time.str(time_limit - time.get(), 2)})
   }
   misn.osdCreate(osd_title, osd_msg)

   tk.msg("", fmt.f(yes_text,
         {planet=dest_planet:name(), credits=fmt.credits(payment)}))

   intime = true

   hook.land("land")
   hook.enter("hilight_next")
   date_hook = hook.date(time.create(0, 0, 1000), "tick")
end

function land()
   if planet.cur() == dest_planet then
      if intime then
         tk.msg("", pay_text)
         player.pay(payment)
      else
         tk.msg("", pay_late_text)
         player.pay(payment / 5)
      end
      misn.finish(true)
   end
end

function tick()
   local osd_msg
   if time_limit >= time.get() then
      osd_msg = {
         fmt.f(osd_desc_1,
               {planet=dest_planet:name(), system=dest_sys:name(),
                  deadline=time_limit:str(),
                  time=time.str(time_limit - time.get(), 2)})
      }
   else
      osd_msg = {
         fmt.f(osd_desc_2,
               {planet=dest_planet:name(), system=dest_sys:name(),
                  deadline=time_limit:str()})
      }
      intime = false
      hook.rm(date_hook)
   end
   misn.osdCreate(osd_title, osd_msg)
end


function hilight_next()
   planet.hilightAdd(destplanet)
end


function abort()
   planet.hilightRm(destplanet)
end
