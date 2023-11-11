--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Big Time">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>faction.playerStanding("Pirate") &lt; 0</cond>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Darkshed</planet>
  <done>The Dvfiler</done>
 </avail>
 <notes>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</mission>
--]]
--[[

   MISSION: Big Time
   DESCRIPTION:
      Dev Filer offers a chance for the player to get into "the big
      time".

--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "missions/empire/common"


local ask_text = _([["Are you ready for the big time, {player}? I can get you started! Of course, you'll have to assist me in return.

"It'll be an escort mission. You will meet a contact on New Haven – I'll put a word in so they know to expect you – and escort them south to the Qorel Expanse. Once you get there, I assure you that you will make your way up the ladder very quickly. How does that sound?"]])

local accept_text = _([[This "Qorel Expanse" Dev Filer mentioned might be just the lead you're looking for. You agree to the mission and shake Dev Filer's hand, secretly planning to ditch it as soon as you find out where this "Qorel Expanse" is. "Good, good!" Dev Filer responds. "I trust you will do a good job out there. With your skills, I'm sure I'll see you again before long."]])

local finish_text = _([[You arrive on the pirate stronghold and can't help but look around in awe. You had never known prior to your adventures in space that pirates had bases as sophisticated as this. Its scale dwarfs many Imperial military stations. After a moment, you catch the eye of a pirate looking at you with a raised eyebrow. She matches the description Dev Filer gave for your contacts. You open your mouth to speak, but she speaks up first. "{player}, is it?" You confirm that it's you, but she continues staring for a moment. "Alright, newbie. Just don't slow us down, got it? You'll get your share once we make it to {planet}. You at least know where it is, right?" You indicate that you don't.

"God damn it." She starts inputting something on her wrist computer. "Fine, I'll send the location to you. But not the hidden jumps. If you can't get those yourself, I'm leaving you behind. I'll let you know when I'm ready to take off." She leaves, and as she does so you check and find that you indeed have the location of a {planet} in the {system} system on your map. You decide to take this opportunity to ditch the pirates and make your way back to Soldner on {homeplanet} in the {homesystem} system to report your findings.]])

local misn_title = _("Big Time")
local misn_desc = _([[You've been given an escort mission by Dev Filer starting on {planet} in the {system} system. He claims this will help "work your way up to the big time", but it may also .]])

local log_text = _([[You managed to infiltrate a pirate stronghold, but then were caught by the pirates. You should probably go to {planet} in the {system} system and give a report to Commander Soldner.]])


function create()
   misplanet, missys = planet.get("New Haven")
   if misplanet == nil then
      misn.finish(false)
   end

   -- Translators: "Dev Filer" is a play on the English word "defiler".
   misn.setNPC(_("Dev Filer"), "neutral/unique/shifty_merchant.png",
         _([[Dev Filer offered to help "work your way up to the big time". You should see what he meant.]]))
end


function accept()
   local text = fmt.f(ask_text,
         {player=player.name(), planet=misplanet:name(),
            system=missys:name()})

   if tk.yesno("", text) then
      tk.msg("", fmt.f(accept_text, {player=player.name()}))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setReward(_("Location information for the Qorel Expanse"))
      misn.setDesc(fmt.f(misn_desc,
            {planet=misplanet:name(), system=missys:name()}))

      marker = misn.markerAdd(missys, "plot", misplanet)

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system)"),
               {planet=misplanet:name(), system=missys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)

      hook.enter("enter")
      hook.land("land")
   else
      misn.finish()
   end
end


function enter()
   if system.cur() == missys then
      misplanet:landOverride(true)
   end
end


function land()
   if planet.cur() ~= misplanet then
      return
   end

   local homepla, homesys = planet.get("Emperor's Fist")
   local qorellia, qorel = planet.get("Qorellia")
   tk.msg("", fmt.f(finish_text,
         {player=player.name(), planet=qorellia:name(), system=qorel:name(),
            homeplanet=homepla:name(), homesystem=homesys:name()}))

   qorel:setKnown()
   qorellia:setKnown()

   emp_addShippingLog(fmt.f(log_text,
         {planet=homepla:name(), system=homesys:name()}))

   misn.finish(true)
end
