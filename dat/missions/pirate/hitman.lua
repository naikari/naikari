--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Hitman">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <chance>100</chance>
  <location>Bar</location>
  <cond>system.cur() == system.get("Alteris")</cond>
 </avail>
</mission>
--]]
--[[

   Pirate Hitman

   Corrupt Merchant wants you to destroy competition

   Author: nloewen

--]]

local fmt = require "fmt"
require "missions/pirate/common"


bar_desc = _("You see a shifty looking man sitting in a darkened corner of the bar. He is trying to discreetly motion you to join him, but is only managing to make himself look suspicious. Perhaps he's watched too many holovideos.")

misn_title = _("Shifty Business")
misn_reward = _("Some easy money")
misn_desc = _("A shifty businessman has tasked you with chasing away merchant competition in the {system} system.")

osd_desc = {}
osd_desc_1 = _("Attack, but do not kill, Trader pilots in the {system} system so that they run away ({done}/{needed})")
osd_desc[2] = _("Land on {planet} ({system} system)")
osd_desc["__save"] = true

-- Text
ask_text = _([[The man motions for you to take a seat next to him. Voice barely above a whisper, he asks, "How'd you like to earn some easy money? If you're comfortable with getting your hands dirty, that is."]])
explain_text = _([[Apparently relieved that you've accepted his offer, he continues, "There're some new merchants edging in on my trade routes in {system}. I want you to make sure they know they're not welcome." Pausing for a moment, he notes, "You don't have to kill anyone, just rough them up a bit."]])
pay_text = _([[As you inform your acquaintance that you successfully scared off the traders, he grins and transfers a sum of credits to your account. "That should teach them to stay out of my space."]])

log_text = _([[You chased away a shifty merchant's competition and were paid a sum of credits by the shifty merchant for your services.]])


function create()
   targetsystem = system.get("Delta Pavonis")
   misn.setNPC(_("Shifty Trader"), "neutral/unique/shifty_merchant.png", bar_desc)
end


function accept()
   if not tk.yesno("", ask_text) then
      misn.finish()
   end
   misn.accept()
   tk.msg("", fmt.f(explain_text, {system=targetsystem:name()}))

   misn_done = false
   fledTraders = 0
   tradersNeeded = 5
   misn_base, misn_base_sys = planet.cur()

   misn.setTitle(misn_title)
   misn.setReward(misn_reward)
   misn.setDesc(fmt.f(misn_desc, {system=targetsystem:name()}))

   misn_marker = misn.markerAdd(targetsystem, "low")

   osd_desc[1] = fmt.f(osd_desc_1,
         {system=targetsystem:name(), done=fledTraders, needed=tradersNeeded})
   osd_desc[2] = fmt.f(osd_desc[2], {planet=misn_base:name(), system=misn_base_sys:name()})
   misn.osdCreate(misn_title, osd_desc)

   hook.enter("sys_enter")
end


function sys_enter()
   hook.rm(attacked_hook)
   attacked_hook = nil
   if system.cur() == targetsystem then
      attacked_hook = hook.attacked("trader_attacked")
   end
end


function trader_attacked(hook_pilot, hook_attacker)
   if misn_done then
      return
   end
   local mem = hook_pilot:memory()
   if not mem.natural then
      return
   end

   if hook_pilot:faction() == faction.get("Trader") and hook_attacker ~= nil
         and (hook_attacker == player.pilot()
            or hook_attacker:leader(true) == player.pilot()) then
      mem.natural = false
      hook_pilot:hookClear()
      hook.pilot(hook_pilot, "jump", "trader_jumped")
      hook.pilot(hook_pilot, "land", "trader_jumped")
   end
end


function trader_jumped(hook_pilot, hook_arg)
   if misn_done then
      return
   end

   fledTraders = fledTraders + 1
   if fledTraders >= tradersNeeded then
      attack_finished()
   else
      osd_desc[1] = fmt.f(osd_desc_1, {system=targetsystem:name(),
               done=fledTraders, needed=tradersNeeded})
      misn.osdCreate(misn_title, osd_desc)
      misn.osdActive(1)
   end
end


function attack_finished()
   if misn_done then
      return
   end
   misn_done = true
   misn.markerMove(misn_marker, misn_base_sys, misn_base)
   misn.osdActive(2)
   hook.land("landed")
end


function landed()
   if planet.cur() == misn_base then
      tk.msg("", pay_text)
      player.pay(150000)
      faction.modPlayer("Pirate", 5)
      pir_addMiscLog(log_text)
      misn.finish(true)
   end
end
