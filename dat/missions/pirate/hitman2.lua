--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Hitman 2">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <chance>100</chance>
  <location>Bar</location>
  <cond>system.cur() == system.get("Alteris")</cond>
  <done>Hitman</done>
 </avail>
</mission>
--]]
--[[

   Pirate Hitman 2

   Corrupt Merchant wants you to destroy competition

   Author: nloewen

--]]

local fmt = require "fmt"
require "missions/pirate/common"


bar_desc = _("You see the shifty merchant who hired you previously. He looks somewhat anxious; perhaps he has more business to discuss.")

misn_title  = _("Deadly Business")
misn_reward = _("Some easy money")
misn_desc = _("A shifty businessman has tasked you with killing merchant competition in the {system} system.")

osd_desc = {}
osd_desc_1 = _("Kill Trader pilots in the {system} system ({done}/{needed})")
osd_desc[2] = _("Land on {planet} ({system} system)")
osd_desc["__save"] = true

ask_text = _([[As you approach, the man turns to face you and his anxiousness seems to abate somewhat. As you take a seat he greets you, "Ah, so we meet again. My… shall we say, problem… has recurred." Leaning closer, he continues, "This will be somewhat bloodier than last time, but I'll pay you more for your trouble. Are you up for it?"]])
yes_text = _([[He nods approvingly. "It seems that the traders are rather stubborn, they didn't get the message last time and their presence is increasing." He lets out a brief sigh before continuing, "This simply won't do, it's bad for business. Perhaps if a few of their ships disappear, they'll take the hint." With the arrangement in place, he gets up. "I look forward to seeing you soon. Hopefully this will be the end of my problems."]])
pay_text = _([[You glance around, looking for your acquaintance, but he has noticed you first, motioning for you to join him. As you approach the table, he smirks. "I hope the Empire didn't give you too much trouble." After a short pause, he continues, "The payment has been transferred. Much as I enjoy working with you, hopefully this is the last time I'll require your services."]])

log_text = _([[You assassinated some of the shifty merchant's competition and were paid a sum of credits for your services. He said that he should hopefully not require further services from you.]])


function create()
   -- Note: this mission does not make any system claims. 
   targetsystem = system.get("Delta Pavonis")
   misn.setNPC(_("Shifty Trader"), "neutral/unique/shifty_merchant.png", bar_desc)
end


function accept()
   if not tk.yesno("", ask_text) then
      misn.finish()
   end
   misn.accept()
   tk.msg("", yes_text)

   misn_done      = false
   attackedTraders = {}
   attackedTraders["__save"] = true
   deadTraders = 0
   tradersNeeded = 3
   misn_base, misn_base_sys = planet.cur()

   misn.setTitle(misn_title)
   misn.setReward(misn_reward)
   misn.setDesc(fmt.f(misn_desc, {system=targetsystem:name()}))

   misn_marker = misn.markerAdd(targetsystem, "low")

   osd_desc[1] = fmt.f(osd_desc_1,
         {system=targetsystem:name(), done=deadTraders, needed=tradersNeeded})
   osd_desc[2] = fmt.f(osd_desc[2], {planet=misn_base:name(), system=misn_base_sys:name()})
   misn.osdCreate(misn_title, osd_desc)

   hook.enter("sys_enter")
end


function sys_enter()
   cur_sys = system.cur()
   if cur_sys == targetsystem then
      hook.pilot(nil, "death", "trader_death")
   end
end


function trader_death(hook_pilot, hook_attacker, hook_arg)
   if misn_done then
      return
   end

   if hook_pilot:faction() == faction.get("Trader") and hook_attacker ~= nil
         and (hook_attacker == player.pilot()
            or hook_attacker:leader(true) == player.pilot()) then
      deadTraders = deadTraders + 1
      if deadTraders >= tradersNeeded then
         attack_finished()
      else
         misn.osdDestroy()
         osd_desc[1] = fmt.f(osd_desc_1, {system=targetsystem:name(),
                  done=deadTraders, needed=tradersNeeded})
         misn.osdCreate(misn_title, osd_desc)
         misn.osdActive(1)
      end
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
      player.pay(500000) -- 500K
      faction.modPlayer("Pirate", 5)
      pir_addMiscLog(log_text)
      misn.finish(true)
   end
end
