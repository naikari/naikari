--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="The Dvfiler">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>faction.playerStanding("Pirate") &lt; 0</cond>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Darkshed</planet>
  <done>Hakoi Pirates Infiltration</done>
 </avail>
 <notes>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</mission>
--]]
--[[

   MISSION: The Dvfiler
   DESCRIPTION:
      Dev Filer offers the player another mission. The player needs to
      complete this mission to further earn his trust.

--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "missions/empire/common"


local ask_text = _([["Ah, {player}! Because of your performance in the last job, I've decided to offer you another opportunity.

"See, I have a customer on {planet} in the {system} system who needs a delivery. It's from the goods you brought here. All you need to do is deliver the goods to my customer, no questions asked, and I'll pay you {credits}. What do you say?"]])

local accept_text = _([[Dev Filer shakes your hand. "Good, good, I knew you would accept! Meet me back here after you've finished the delivery. I will have your payment ready for you then."

You hope doing this "job" will earn some more of Dev Filer's trust before someone finds out about your true identity.]])

local deliver_text = _([[You land at your destination and locate your contact, a hooded, masked figure. They seemingly pause for a moment before proceding to send accomplices into your ship to retrieve the goods without speaking a word. Looks like your job here is done and you can head back to {planet} and speak to Dev Filer.]])

local finish_text = _([[You meet Dev Filer at the spaceport, where he pats you on the back as he hands you your payment. "Great job, {player}! I like you, eager to work your way up to the big time. I'll tell you what: I'll help you with that. Meet me at the bar in a bit."]])

-- Translators: "Dvfiler" is a pun based on the words "Dvaered" and
-- "defiler", as well as Dev Filer's name.
local misn_title = _("The Dvfiler")
local misn_desc = _([[You have accepted another sketchy "job" given to you by Dev Filer, a delivery to {planet} in the {system} system. Hopefully, this will earn some of Dev Filer's trust.]])

local credits = 100000

local log_text = _([[In an attempt to earn Dev Filer's trust, you performed a sketchy delivery for him. The ruse seems to have worked, and he's asked you to speak with him again on {planet} in the {system} system.]])


function create()
   startpla, startsys = planet.cur()
   misplanet, missys = planet.getLandable("Secundus Station")
   if misplanet == nil then
      misn.finish(false)
   end

   job_done = false

   -- Translators: "Dev Filer" is a play on the English word "defiler".
   misn.setNPC(_("Dev Filer"), "neutral/unique/shifty_merchant.png",
         _("You see Dev Filer. You should approach him and see if he has another \"job\" for you."))
end


function accept()
   local text = fmt.f(ask_text,
         {player=player.name(), planet=misplanet:name(),
            system=missys:name(), credits=fmt.credits(credits)})

   if tk.yesno("", text) then
      tk.msg("", fmt.f(accept_text, {player=player.name()}))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(credits))
      misn.setDesc(fmt.f(misn_desc,
            {planet=misplanet:name(), system=missys:name()}))

      marker = misn.markerAdd(missys, "plot", misplanet)

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system)"),
               {planet=misplanet:name(), system=missys:name()}),
         fmt.f(_("Land on {planet} ({system} system)"),
               {planet=startpla:name(), system=startsys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)

      hook.land("land")
   else
      misn.finish()
   end
end


function land()
   if job_done and planet.cur() == startpla then
      tk.msg("", fmt.f(finish_text, {player=player.name()}))

      player.pay(credits)
      faction.get("Dvaered"):modPlayerSingle(-5)

      emp_addShippingLog(fmt.f(log_text,
            {planet=startpla:name(), system=startsys:name()}))
      misn.finish(true)
   elseif not job_done and planet.cur() == misplanet then
      tk.msg("", fmt.f(deliver_text,
            {planet=startpla:name(), system=startsys:name()}))
      job_done = true
      misn.markerMove(marker, startsys, startpla)
   end
end
