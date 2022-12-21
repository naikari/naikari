--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Empire Shipping 2">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>15</priority>
  <cond>faction.playerStanding("Empire") &gt;= 10 and faction.playerStanding("Dvaered") &gt;= 0 and faction.playerStanding("FLF") &lt; 10</cond>
  <chance>50</chance>
  <done>Empire Shipping 1</done>
  <location>Bar</location>
  <planet>Halir</planet>
 </avail>
 <notes>
  <campaign>Empire Shipping</campaign>
 </notes>
</mission>
--]]
--[[

   Empire Shipping Dangerous Cargo Delivery

   Author: bobbens
      minor edits by Infiltrator

]]--

local fmt = require "fmt"
local fleet = require "fleet"
require "missions/empire/common"

-- Mission details
bar_desc = _("You see Commander Soldner who is expecting you.")
misn_title = _("Empire Shipping Delivery")
misn_desc = _("You have been tasked with covertly delivering a package for the Empire.")

text = {}
ask_text = _([[You approach Commander Soldner, who seems to be waiting for you.
"Hello, ready for your next mission?"]])

yes_text = _([[Commander Soldner begins, "We have an important package that we must take from {planet} in the {system} system to {destplanet} in the {destsys} system. We have reason to believe that it is also wanted by external forces.

"The plan is to send an advance convoy with guards to make the run in an attempt to confuse possible enemies. You will then go in and do the actual delivery by yourself. This way we shouldn't arouse suspicion. You are to report here when you finish delivery and you'll be paid {credits}.

"Avoid hostility at all costs. The package must arrive at its destination. Since you are undercover, Empire ships won't assist you if you come under fire, so stay sharp. Good luck."]])

pickup_text = _([[Packages labelled "Food" are loaded discreetly onto your ship.]])

deliver_text = _([[Workers quickly unload the package as mysteriously as it was loaded. You notice that one of them gives you a note. Looks like you'll have to go to {planet} in the {system} system to report to Commander Soldner.]])

pay_text = _([[You locate Commander Soldner and report When you finish, he gives you an approving smile. "I'm glad you managed to deliver the package. Did you encounter resistance? Well, in any case, great work out there.

"If you're interested in more work, meet me in the bar in a bit. I've got some paperwork I need to finish first."]])

log_text = _([[You successfully completed a package delivery for the Empire. Commander Soldner said that you can meet him in the bar at Halir if you're interested in more work.]])


function create ()
   -- Note: this mission does not make any system claims.

   -- Planet targets
   pickup, pickupsys = planet.getLandable("Selphod")
   dest, destsys = planet.getLandable("Cerberus")
   ret, retsys = planet.getLandable("Halir")
   if pickup==nil or dest==nil or ret==nil then
      misn.finish(false)
   end

   cargoAmount = 3
   reward = 500000

   -- Bar NPC
   misn.setNPC(_("Soldner"), "empire/unique/soldner.png", bar_desc)
end

function accept ()
   if not tk.yesno("", ask_text) then
      misn.finish()
   end

   misn.accept()

   misn.setTitle(misn_title)
   misn.setReward(fmt.credits(reward))
   misn.setDesc(misn_desc)

   tk.msg("", fmt.f(yes_text,
         {planet=pickup:name(), system=pickupsys:name(),
            destplanet=dest:name(), destsys=destsys:name(),
            credits=fmt.credits(reward)}))

   local osd_desc = {
      fmt.f(
         n_("Land on {planet} ({system} system) to pick up {tonnes} kt of cargo",
            "Land on {planet} ({system} system) to pick up {tonnes} kt of cargo",
            cargoAmount),
         {planet=pickup:name(), system=pickupsys:name(),
            tonnes=fmt.number(cargoAmount)}),
      fmt.f(_("Land on {planet} ({system} system)"),
         {planet=dest:name(), system=destsys:name()}),
   }
   misn.osdCreate(misn_title, osd_desc)

   misn_marker = misn.markerAdd(pickupsys, "low")

   misn_stage = 0

   -- Set hooks
   hook.land("land")
   hook.enter("enter")
end


function land ()
   landed = planet.cur()

   if landed == pickup and misn_stage == 0 then
      if player.pilot():cargoFree() < cargoAmount then
         local required_text = n_(
               "You don't have enough cargo space to pick up the packages. The packages weigh {required} kt. Please increase your cargo capacity and go to the Commodity tab to try again. ",
               "You don't have enough cargo space to pick up the packages. The packages weigh {required} kt. Please increase your cargo capacity and go to the Commodity tab to try again. ",
               cargoAmount)
         local shortfall = cargoAmount - player.pilot():cargoFree()
         local shortfall_text = n_(
               "You need {shortfall} kt more of empty space.",
               "You need {shortfall} kt more of empty space.",
               shortfall)
         tk.msg("", fmt.f(required_text .. shortfall_text,
               {required=fmt.number(cargoAmount),
                  shortfall=fmt.number(shortfall)}))
         return
      end

      tk.msg("", pickup_text)

      -- Update mission
      local c = misn.cargoNew(N_("Packages"),
            _("Packages labelled \"Food\" which you are undercover delivering for the Empire."))
      package = misn.cargoAdd(c, cargoAmount)
      misn_stage = 1
      jumped = 0

      misn.markerMove(misn_marker, destsys)
      misn.osdActive(2)
   elseif landed == dest and misn_stage == 1 then
      if misn.cargoRm(package) then
         tk.msg("", fmt.f(deliver_text,
               {planet=ret:name(), system=retsys:name()}))

         misn_stage = 2

         misn.markerMove(misn_marker, retsys)
         local osd_desc = {
            fmt.f(_("Land on {planet} ({system} system)"),
               {planet=ret:name(), system=retsys:name()}),
         }
         misn.osdCreate(misn_title, osd_desc)
      end
   elseif landed == ret and misn_stage == 2 then
      tk.msg("", pay_text)

      player.pay(reward)
      faction.modPlayer("Empire", 5)

      emp_addShippingLog(log_text)

      misn.finish(true)
   end
end


function enter()
   sys = system.cur()

   if misn_stage == 1 then

      -- Mercenaries appear after a couple of jumps
      jumped = jumped + 1
      if jumped <= 3 then
         return
      end

      -- Get player position
      enter_vect = player.pos()

      -- Calculate where the enemies will be
      r = rnd.rnd(0,4)
      -- Next to player (always if landed)
      if enter_vect:dist() < 1000 or r < 2 then
         a = rnd.rnd() * 2 * math.pi
         d = rnd.rnd(400, 1000)
         enter_vect:add(math.cos(a) * d, math.sin(a) * d)
         enemies()
      -- Enter after player
      else
         t = hook.timer(rnd.rnd(2, 5) , "enemies")
      end
   end
end


function enemies()
   local sources = {}
   for i, ojp in ipairs(system.cur():jumps(true)) do
      local jp = jump.get(ojp:dest(), system.cur())
      if jp ~= nil and not jp:exitonly() and not jp:hidden() then
         sources[#sources + 1] = jp:system()
      end
   end
   local source = sources[rnd.rnd(1, #sources)]

   local leader = nil
   if rnd.rnd() < 0.9 then
      local choices = {
         {"Pacifier", _("Mercenary Pacifier")},
         {"Vigilance", _("Mercenary Vigilance")},
         {"Phalanx", _("Mercenary Phalanx")},
         {"Admonisher", _("Mercenary Admonisher")},
         {"Ancestor", _("Mercenary Ancestor")},
      }
      local choice = choices[rnd.rnd(1, #choices)]
      leader = pilot.add(choice[1], "Mercenary", source, choice[2])
   end

   local flt = fleet.add({rnd.rnd(0, 2), rnd.rnd(0, 2)},
         {"Lancelot", "Vendetta"}, "Mercenary", source,
         {_("Mercenary Lancelot"), _("Mercenary Vendetta")}, leader)
   for i, p in ipairs(flt) do
      p:setHostile()
   end
end


