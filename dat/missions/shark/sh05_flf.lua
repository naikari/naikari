--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="The FLF Contact">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>3</priority>
  <done>The Meeting</done>
  <chance>3</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
  <cond>not diff.isApplied("flf_dead")</cond>
 </avail>
 <notes>
  <campaign>Nexus show their teeth</campaign>
 </notes>
</mission>
--]]
--[[

   This is the sixth mission of the Shark's teeth campaign. The player has to take contact with the FLF.

   Stages :
   0) Way to Eiger/Surano
   1) Way back to Darkshed

--]]

require "numstring"
require "missions/shark/common"


osd_msg = {}
npc_desc = {}
bar_desc = {}

asktext = _([["Hello, %s! Are you ready to take part in another sales mission?

"As you know, the FLF is a heavy user of our ships, but they're also heavy users of Dvaered ships, chiefly the Vendetta design. Since House Dvaered is an enemy of the FLF, we see this as an opportunity to expand our sales: we want to convince the FLF leaders to buy more Nexus ships and fewer Dvaered ships. This will be through a false contraband company so that word doesn't get out that we're supporting terrorists by selling them ships. What do you say? Can you help us once again?"]])

refusetext = _([["Alright, then. I'll see if anyone else is interested."]])

yestext = _([["Perfect! So, this mission is pretty simple: I want you to pass on this proposal to them." He hands you a data chip. "It's a request to meet with the FLF leaders on %s. If all goes well, I'll be asking you to take me there next.

"Any FLF ship should do the job. Try hailing them and see if you get a response. If they won't talk, disable and board them so you can force them to listen. Pretty simple, really. Good luck!"]])

successtext = _([[Smith is clearly pleased with the results. "I have received word that the FLF leaders are indeed interested. Meet me at the bar whenever you're ready to take me to %s. And here's your payment."]])

peacefultext = _([[The FLF ship peacefully responds to you. You explain the details of what is going on and transmit the proposal, after which you both go your separate ways.]])

hostiletext = _([[The FLF officers are clearly ready for battle, but after subduing them, you assure them that you're just here to talk. Eventually, you are able to give them a copy of the proposal and leave peacefully, for lack of a better word.]])

basetext = _([[As you dock on %s, you can't help but grin to yourself at how easy this job is compared to some of the others. You hand the proposal over to an FLF official, who thanks you for delivering the message.]])

-- Mission details
misn_title = _("The FLF Contact")
misn_desc = _("Nexus Shipyards is looking to strike a better deal with the FLF.")

-- NPC
npc_desc[1] = _("Arnold Smith")
bar_desc[1] = _([[It looks like he has yet another job for you.]])

-- OSD
osd_title = _("The FLF Contact")
osd_msg[1] = _("Hail any FLF ship, or disable and board one if necessary")
osd_msg[2] = _("Land on %s (%s system)")

log_text = _([[You helped Arnold Smith establish a contact with the FLF. He said to meet you at the bar on Alteris when you're ready to take him to Arandon.]])


function create ()
   -- Change here to change the planets and the systems
   paypla, paysys = planet.get("Darkshed")
   -- This should be the same as the system used in sh06!
   nextsys = system.get("Arandon")
   basepla = planet.get("Sindbad")

   osd_msg[2] = osd_msg[2]:format(paypla:name(), paysys:name())

   misn.setNPC(npc_desc[1], "neutral/unique/arnoldsmith.png", bar_desc[1])
end


function accept()
   stage = 0
   reward = 1000000

   if tk.yesno("", asktext:format(player.name())) then
      misn.accept()
      tk.msg("", yestext:format(nextsys:name()))

      misn.setTitle(misn_title)
      misn.setReward(creditstring(reward))
      misn.setDesc(misn_desc)
      osd = misn.osdCreate(osd_title, osd_msg)
      misn.osdActive(1)

      hook.land("land")
      hook.hail("hail")
      hook.board("board")
   else
      tk.msg("", refusetext)
      misn.finish(false)
   end
end


function land()
   if stage == 0 and planet.cur() == basepla then
      tk.msg("", basetext:format(basepla:name()))
      stage = 1
      misn.osdActive(2)
      marker2 = misn.markerAdd(paysys, "low")
   elseif stage == 1 and planet.cur() == paypla then
      -- Job is done
      tk.msg("", successtext:format(nextsys:name()))
      player.pay(reward)
      shark_addLog(log_text)
      misn.finish(true)
   end
end


function hail(p)
   if stage == 0 and p:faction() == faction.get("FLF") and not p:hostile() then
      player.commClose()
      tk.msg("", peacefultext)
      stage = 1
      misn.osdActive(2)
      marker2 = misn.markerAdd(paysys, "low")
   end
end


function board(p)
   if stage == 0 and p:faction() == faction.get("FLF") then
      player.unboard()
      tk.msg("", hostiletext)
      stage = 1
      misn.osdActive(2)
      marker2 = misn.markerAdd(paysys, "low")
   end
end
