--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Tutorial Part 2">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>1</priority>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Em 1</planet>
 </avail>
 <notes>
  <done_misn name="Tutorial"/>
  <campaign>Tutorial</campaign>
 </notes>
</mission>
--]]
--[[

   Tutorial Part 2

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

--

   MISSION: Tutorial Part 2
   DESCRIPTION: Player buys some commodities for an NPC.

--]]

local fmt = require "fmt"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"


ask_text = _([[You approach the well-dressed man and ask if he is the one you have been referred to by the Melendez salesperson. He smiles in response. "Yes, that would be me," he says. "{player}, right? Pleased to meet you! My name is Ian Structure. I run a business near this areä and I was hoping to find a suitable pilot. Don't worry, it's a simple job, and you will of course be paid fairly for your services. What do you say?"]])

ask_again_text = _([["Ah, {player}! Have you changed your mind? I promise I won't bite, and the payment will be worth it!"]])

accept_text = _([["Excellent! I look forward to working with you.

"Now, to start with, I need you to buy 10 kt #n[10 kilotonnes]#0 of Food on my behalf." You begin to protest, but Ian holds up his hand to interrupt. "Have no fear, {player}. I wouldn't make you pay for it using your own credits, of course." He pulls out a credit chip and hands it to you. "That should be sufficient to pay for what I need. I put some extra on just to be absolutely sure it will cover the cost; you can keep the extra credits left over in addition to your payment.

"You can buy the Food from the Commodity tab. Once you've picked it up, return here so we can transfer the Food to my storage unit."]])

reminder_text = _([[You ask Ian what cargo it was that he needed again, apologizing for forgetting already. "Oh, that's no problem!" he assures you. "It's 10 kt #n[10 kilotonnes]#0 of Food. You should be able to find it in the Commodity tab. Let me know when you have it!"]])

finish_text = _([[You approach Ian and inform him that you have the cargo he needs. "Ah, perfect!" he responds. "Let's initiate that transfer, then.…" Ian Structure pushes a series of buttons on his datapad and you see that the cargo has been removed from your ship.

"You saved me some trouble by doïng that for me," Ian says. "Thank you. I have transferred the payment I promised into your account. If you would be willing to do it, I have another job for you. Talk to me here at the bar again when you're ready for it."]])

misn_desc = _("A businessman named Ian Structure has given you the task of buying 10 kt of Food for him.")
misn_log = _([[You helped a businessman named Ian Structure acquire some Food. He asked you to speak with him again on {planet} ({system} system) for another job.]])


function create()
   -- Note: This mission makes no system claims.
   misplanet, missys = planet.get("Em 1")
   credits = 5000
   talked = false

   misn.setNPC(_("A well-dressed man"),
         "neutral/unique/youngbusinessman.png",
         _("This must be the potential employer the Melendez salesperson referred you to."))
end


function accept()
   local text
   if talked then
      text = fmt.f(ask_again_text, {player=player.name()})
   else
      text = fmt.f(ask_text, {player=player.name()})
      talked = true
   end

   if tk.yesno("", text) then
      tk.msg("", fmt.f(accept_text, {player=player.name()}))

      misn.accept()

      misn.setTitle(_("Ian's Structure"))
      misn.setReward(fmt.credits(credits))
      misn.setDesc(misn_desc)

      local osd_desc = {
         fmt.f(_("Buy 10 kt of Food from the Commodity tab and then talk to Ian Structure at the bar on {planet} ({system} system)"),
            {planet=misplanet:name(), system=missys:name()}),
      }
      misn.osdCreate(_("Ian's Structure"), osd_desc)

      local cost = commodity.get("Food"):priceAtTime(planet.cur(), time.get())
      player.pay(cost * 30, "adjust")

      land()

      hook.land("land")
      hook.load("land")
   else
      misn.finish()
   end
end


function land()
   npc = misn.npcAdd("approach", _("Ian Structure"),
         "neutral/unique/youngbusinessman.png",
         _("Ian is in the bar doïng some sort of work on his datapad."), 1)
end


function approach()
   local ftonnes = player.pilot():cargoHas("Food")
   if ftonnes and ftonnes >= 10 then
      tk.msg("", finish_text)

      player.pilot():cargoRm("Food", 10)
      player.pay(credits)
      addMiscLog(fmt.f(misn_log,
            {planet=misplanet:name(), system=missys:name()}))

      naev.missionStart("Tutorial Part 3")
      misn.finish(true)
   else
      tk.msg("", reminder_text)
   end
end
