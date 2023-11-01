--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Big Time">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>
   faction.playerStanding("Pirate") &gt;= 0
  </cond>
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
local pilotname = require "pilotname"
local portrait = require "portrait"
require "missions/empire/common"


local ask_text = _([["Are you ready for the big time, {player_pirate_name}? I can get you started! Of course, you'll have to assist me in return.

"It'll be an escort mission. You will meet contacts on New Haven – I'll put a word in so they know to expect you – and escort them south to the Qorel Expanse. Once you get there, I assure you that you will make your way up the ladder very quickly. How does that sound?"]])

local accept_text = _([[This "Qorel Expanse" Dev Filer mentioned might be just the lead you're looking for. You agree to the mission and shake Dev Filer's hand. "Good, good!" Dev Filer responds. "I trust you will do a good job out there. With your skills, I'm sure I'll see you again before long."]])

local land_text = _([[You arrive on the pirate stronghold and can't help but look around in awe. You had never known prior to your adventures in space that pirates had bases as sophisticated as this. Its scale dwarfs many Imperial military stations. After a moment, you catch the eye of a pirate looking at you with a raised eyebrow. She matches the description Dev Filer gave for your contacts. You open your mouth to speak, but she speaks up first. "{player_pirate_name}, is it?" You confirm that it's you, but she continues staring for a moment. "Alright, newbie. Just don't slow us down, got it? We go to Qorellia and–"

She's interrupted by an intercom announcement. You can tell that this is unusual by the way your contact jolts. "Heya there everyone!" a voice booms thruout the station. "Sorry to bother you, but it looks like we've got an Imperial mole aboard, {player}, calling themself '{player_pirate_name}'. Be sure to give the mole a good time, eh? The boss is offering a nice reward for anyone who takes care of them."]])

local finish_text = _([[Hearing the announcement, your contact immediately draws a laser gun, but you manage to escape into the crowd before she has a chance to aim at you. Luckily, no one else seems to recognize you. It seems you'll be able to stay safe for now, but you're sure all hell will break loose once you take off.

Since your cover is blown, you should probably check with Commander Soldner on {planet} in the {system} system at your next opportunity.]])

local misn_title = _("Big Time")
local misn_desc = _([[You've been given an escort mission by Dev Filer starting on {planet} in the {system} system. He claims this will help "work your way up to the big time".]])

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
   local pirate_name = var.peek("hp_pirate_name") or player.name()
   local text = fmt.f(ask_text,
         {player_pirate_name=pirate_name, planet=misplanet:name(),
            system=missys:name()})

   if tk.yesno("", text) then
      tk.msg("", fmt.f(accept_text, {player_pirate_name=pirate_name}))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setReward(p_("reward", "None"))
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
   local homepla, homesys = planet.get("Emperor's Fist")
   local pirate_name = var.peek("hp_pirate_name") or player.name()
   tk.msg("", fmt.f(land_text,
         {player_pirate_name=pirate_name, player=player.name()}))
   tk.msg("", fmt.f(finish_text,
         {planet=homepla:name(), system=homesys:name()}))

   emp_addShippingLog(fmt.f(log_text,
         {planet=homepla:name(), system=homesys:name()}))

   -- Start the Empire/Dvaered civil war.
   diff.apply("empire_vs_dvaered")

   -- Cancel fake ID.
   var.pop("no_fake_id")

   local f = faction.get("Empire")
   local rep = var.peek("hp_rep_empire") or faction.playerStanding(f)
   var.pop("hp_rep_empire")
   f:setPlayerStanding(rep)

   local f = faction.get("Za'lek")
   local rep = var.peek("hp_rep_zalek") or faction.playerStanding(f)
   var.pop("hp_rep_zalek")
   f:setPlayerStanding(rep)

   local f = faction.get("Sirius")
   local rep = var.peek("hp_rep_sirius") or faction.playerStanding(f)
   var.pop("hp_rep_sirius")
   f:setPlayerStanding(rep)

   local f = faction.get("Goddard")
   local rep = var.peek("hp_rep_goddard") or faction.playerStanding(f)
   var.pop("hp_rep_goddard")
   f:setPlayerStanding(rep)

   local f = faction.get("Soromid")
   local rep = var.peek("hp_rep_soromid") or faction.playerStanding(f)
   var.pop("hp_rep_soromid")
   f:setPlayerStanding(rep)

   local f = faction.get("Pirate")
   local rep = var.peek("hp_rep_pirate") or faction.playerStanding(f)
   var.pop("hp_rep_pirate")
   f:setPlayerStanding(rep)

   misn.finish(true)
end
