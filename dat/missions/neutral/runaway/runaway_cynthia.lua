--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="The Runaway">
 <flags>
   <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <chance>11</chance>
  <location>Bar</location>
  <system>Gamma Polaris</system>
 </avail>
</mission>
--]]
--[[
This is the "The Runaway" mission as described on the wiki.
There will be more missions to detail how you are perceived as the kidnapper of "Cynthia"
--]]

require "numstring"
require "missions/neutral/common"


npc_name = _("Young Teenager")
bar_desc = _("A young teenager sits alone at a table.")
title = _("The Runaway")
misn_desc_pre_accept = _([[She looks out of place in the bar. As you approach, she seems to stiffen.

"H-H-Hi", she stutters. "My name is Cynthia. Could you give me a lift? I really need to get out of here. I can't pay you much, just what I have on me, %s." You wonder who she must be to have this many credits on her person. "I need you to take me to Geron."

You wonder who she is, but you dare not ask. Do you accept?]])
not_enough_cargospace = _("Your cargo hold doesn't have enough free space.")
misn_desc = _("Deliver Cynthia safely to %s (%s system).")

post_accept = {}
post_accept[1] = _([["Thank you. But we must leave now, before anyone sees me."]])
misn_accomplished = _([[As you walk into the docking bay, she warns you to look out behind yourself.

When you look back to where she was, nothing remains but a tidy pile of credit chips and a worthless pendant.]])

osd_text = {}
osd_text[1] = _("Land on Geron (Goddard system)")

log_text = _([[You gave a teenage girl named Cynthia a lift to Geron. When you got there, she suddenly disappeared, leaving behind a tidy pile of credit chips and a worthless pendant.]])


function create ()
   startworld, startworld_sys = planet.cur()

   targetworld, targetworld_sys = planet.get("Geron")

   reward = 500000

   misn.setNPC(npc_name, "neutral/unique/cynthia.png", bar_desc)
end


function accept ()
   --This mission does not make any system claims
   if not tk.yesno("", misn_desc_pre_accept:format(
            creditstring(reward), targetworld:name())) then
      misn.finish()
   end

   --Our *cargo* weighs nothing
   --This will probably cause a mess if this fails
   if player.pilot():cargoFree() < 0 then
      tk.msg("", not_enough_cargospace)
      misn.finish()
   end

   misn.accept()

   misn.osdCreate(title, osd_text)
   misn.osdActive(1)

   misn.setTitle(title)

   misn.setReward(creditstring(reward))

   misn.setDesc(string.format(misn_desc, targetworld:name(), targetworld_sys:name()))
   misn.markerAdd(targetworld_sys, "high")

   tk.msg("", post_accept[1])

   hook.land("land")
end

function land ()
  --If we land, check if we're at our destination
   if planet.cur() == targetworld then
      player.pay(reward)

      tk.msg("", misn_accomplished:format(numstring(reward)))

      addMiscLog(log_text)

      var.push("cynthia_time", time.get():tonumber())
      misn.finish(true)
   end
end

