--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Hakoi Pirates Infiltration">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>
   faction.playerStanding("Empire") &gt;= 10
   and faction.playerStanding("Pirate") &lt; 0
  </cond>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Emperor's Fist</planet>
  <done>Hakoi Needs House Dvaered</done>
 </avail>
 <notes>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</mission>
--]]
--[[

   MISSION: Pirate Infiltration
   DESCRIPTION:
      Ian Structure volunteers to assist the player in a grand operation
      to infiltrate into the ranks of the pirates.

--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "missions/empire/common"


local ask_text = _([[Since you don't see Commander Soldner around, you decide to approach Ian Structure and see what he wants. He greets you and sits you down. "I've heard about what you've been working on for the Empire," he begins. "Look, {player}, I… I want to help, and I think I might be able to. I just need you to keep it a secret; if they find out I helped you… I don't want to th-think about what c-could happen." He nervously straightens his necktie.

"I don't know if you've ever been to {planet} in the {system} system. I, um… can pull some strings to get you connected with someone there. Someone on the inside, you know? They'd just think you're a… hired hand. What you do with that connection would be up to you. Would you be interested?"]])

-- Translators: This string contains some subtle hints that
-- Ian Structure is familiar with Devin Filer, first by specifically
-- saying something about him as if he knows him and second by
-- accidentally using his nickname, "Dev" before correcting himself.
local accept_text = _([[As you accept Ian Structure's offer, he trepidly nods and immediately starts making inputs into his palmtop. After a few minutes, he looks back at you and speaks quietly. "Alright. I've got you a job with a businessman named Devin Filer. Some kind of delivery from this planet for {credits}. Hopefully nothing too hot, but with him, there's no guarantee of that.

"In any case, you're supposed to deliver the goods to Dev on– uh, I mean, to Devin Filer on {planet} in the {system} system. I'm sure he'll offer more jobs to you afterward. Good luck, and stay safe."]])

local finish_text = _([[You arrive on {planet} with the cargo and meet a man at the spaceport with a suit and tie, neat hair, and a wide grin. He offers your hand for you to shake. "You must be {player}. Well met. I trust you have the cargo I asked for." You shake his hand and ask if he's Devin Filer, the businessman who hired you. "Oh, please, call me Dev," he responds.

He sends in some accomplices who retrieve the package from your cargo hold. "You must be very good at your job if you were able to obtain this from the Imperial interior so quickly." You decide to impress Dev Filer by telling stories of encounters, conveniently leaving out who those encounters were with. "Ah, splendid! Why, I think you might be the perfect candidate for another… job. Meet me at the bar if you're interested." He and his accomplices leave you at the spaceport. It looks like the ruse worked. You hope this next "job" gives you a useful lead.]])

local misn_title = _("Pirate Infiltration")
local misn_desc = _("You have accepted a shady job to deliver cargo to {planet} in the {system} system in an attempt to infiltrate the pirates' ranks and find out what they're up to.")

local credits = 100000

local log_text = _([[At the suggestion of Ian Structure, you are attempting to infiltrate the ranks of the pirates by doing jobs for someone called Dev Filer. So far, it seems to have worked; Dev Filer is satisfied with your work and wants to speak to you again on {planet} in the {system} system.]])


function create()
   misplanet, missys = planet.getLandable("Darkshed")
   if misplanet == nil then
      misn.finish(false)
   end

   misn.setNPC(_("Ian Structure"), "neutral/unique/youngbusinessman.png",
         _("You don't see Commander Soldner around anywhere, but you see Ian Structure sitting alone and gesturing to you. He looks nervous."))
end


function accept()
   local playername = player.name()
   local text = fmt.f(ask_text,
         {player=playername, planet=misplanet:name(), system=missys:name()})

   if tk.yesno("", text) then
      tk.msg("", fmt.f(accept_text,
            {player=playername, credits=fmt.credits(credits),
               planet=misplanet:name(), system=missys:name()}))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(credits))
      misn.setDesc(fmt.f(misn_desc,
            {planet=misplanet:name(), system=missys:name()}))

      marker = misn.markerAdd(missys, "plot", misplanet)

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system)"),
               {planet=misplanet:name(), system=missys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)

      hook.land("land")
   else
      misn.finish()
   end
end


function land()
   if planet.cur() == misplanet then
      tk.msg("", fmt.f(finish_text,
            {player=player.name(), planet=misplanet:name()}))

      player.pay(credits)
      emp_addShippingLog(fmt.f(log_text,
            {planet=misplanet:name(), system=missys:name()}))
      misn.finish(true)
   end
end
