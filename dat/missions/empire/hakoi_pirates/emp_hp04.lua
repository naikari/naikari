--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Hakoi Needs House Dvaered">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>
   faction.playerStanding("Empire") &gt;= 10
   and faction.playerStanding("Dvaered") &gt;= 0
  </cond>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Emperor's Fist</planet>
  <done>Hakoi and Salvador</done>
 </avail>
 <notes>
  <done_misn name="The macho teenager"/>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</mission>
--]]
--[[

   A Galactic Threat

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

   MISSION: A Galactic Threat
   DESCRIPTION:
      Commander Soldner realizes that the pirates that threaten Hakoi
      are between Empire and Dvaered space and cannot be taken care of
      by the Empire alone. Soldner tasks the player with attempting to
      convince House Dvaered to aid in the campaign.

--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "missions/empire/common"


ask_text = _([["So, {player}, based on those flight logs you obtained, it seems the pirates are actually coming from an uncharted area between Empire and House Dvaered space. Given that, it seems we need to get House Dvaered involved in this.

"I have another task for you, then. You should be able to find the Imperial Dvaered Liaison Officer, Lensa, at the bar on {planet} in the {system} system. I need you to go there and officially request the coöperation of the Dvaered warlords. When you're finished talking to her, return to me so we can discuss the results. As soon as we work out a deal, you will be paid {credits}. Does that sound good to you?"]])

accept_text = _([["This will be of great help to us, {player}. I'm going to go check on some things and talk to some more people, but I'll be available here at the bar as soon as you're done talking to Lensa."]])

decline_text = _([["Alright, {player}. I can understand your reluctance. The offer is still open, so if you ever change your mind, just let me know."]])

empire_request_text = _([[You approach Lensa and tell her that you're on official business with the Empire. Lensa rolls her eyes. "Oh, joy," she remarks sarcastically. "Here comes an Imperial lapdog bothering me about the Empire's problems."

You begin to explain the situation in the Hakoi system which the Empire is trying to solve, but Lensa cuts you off. "You Imperials really need to get your heads out of the damn clouds. The Empire doesn't control us anymore. Sure, you Imperials might delude yourselves into thinking we're just your "Great House", but everyone outside of Empire space knows that's bullshit. You can't just come waltzing in here and commandeer our troops to help you with your personal problems. That's a fact.

"So tell this to your Commander: Piss off. I'm not going to bother the warlords for this petty bullshit."]])

empire_request_again_text = _([[Lensa pointedly ignores you. It looks like you're not going to make any progress at this rate, so you'll just have to go back to Commander Soldner.]])

approach_soldner_text = _([[You approach Commander Soldner and relay the bad news to him. He sighs, as if disappointed, but not surprised. "I was hoping it might go differently, but I guess luck isn't on our side this time. See, the truth is, {player}, we have a… complicated relationship with House Dvaered. Yes, they are a part of the Empire, but they have an independent spirit, and the Empire just isn't what it used to be.

"In that case, we will have to revise our plan. I want you to go out into Dvaered space and make a name for yourself among them. Do missions, hunt pirates, that sort of thing. Once your standing with House Dvaered is at least {standing:.0f}%, talk to Lensa not as an Imperial representative, but as yourself. Talk about your own experience and what this mission means to you. Perhaps, then, she will be more open to helping out."]])

approach_soldner_again_text = _([["Good luck, {player}. Hopefully this works."]])

personal_request_text = _([[You approach Lensa a second time and talk to her about the pirate situation from your own perspective, mentioning how it has affected you personally. Lensa sighs. "Look," she says. "{player}, was it? I'm aware of everything you've done for the Dvaered, and we really do appreciate it, but the wider piracy issue isn't anything new. It's the tip of the iceberg, you know?

"My mother once told me that chaös is like a hurricane. Most people get stuck in the thick of it, but there's always a small group of people in the eye of chaös: people who can't see the deadly winds circling around them. It makes them complacent. The Empire has been in the eye of chaös for so long, it's like they didn't even realize the storm was looming in the first place, and now it's hitting them all at once."]])

personal_request_text_2 = _([[Lensa goes silent for a moment and takes a sip of her drink before continuing. "The fact of the matter is, {player}, you and the Empire are on your own with this piracy shit. If you want to look into the piracy problem as a civilian, by all means, be my guest, just as long as you don't bring the Imperial military where it doesn't belong. But there's no chance in hell of the Dvaered warlords helping you without getting something substantial in return. Do you understand?" You hesitantly nod to Lensa indicating your understanding. "Good." She finishes her drink and leaves. It looks like you have bad news to report to Commander Soldner.]])

finish_text = _([[You locate Commander Soldner and deliver the news to him. He listens patiently and nods when you finish. "I see. That's an unfortunate outcome, but thrû no fault of your own. You've done a great job out there, {player}. Earning the trust of a Dvaered is no easy feat, and it sounds like you may have earned Lensa's trust, but it seems that just won't be enough to get the warlords involved.

"I'll have to think on what to do next. Meet me at the bar here on {planet} in a bit. Whatever the plan of action is, I know for sure now that we can't solve this problem without you."]])

misn_title = _("A Galactic Threat")
misn_desc = _("The Hakoi pirate threat requires the assistance of the Dvaered warlords, so Commander Soldner has sent you to Imperial Dvaered Liaison Officer Lensa in an attempt to convince them to help out.")

log_text = _([[Commander Soldner sent you to Imperial Dvaered Liaison Officer Lensa to try to get the Dvaered warlords involved in the Imperial investigation into the Hakoi pirates situation. The mission was mostly unsuccessful. Commander Soldner asked you to meet him at the bar on {startplanet} ({startsys} system) for another mission.]])


function create()
   -- Note: This mission does not make system claims.
   startpla, startsys = planet.cur()
   mispla, missys = planet.getLandable("Praxis")
   if mispla == nil then
      misn.finish(false)
   end

   credits = 400000
   standing_target = 10
   stage = 1

   misn.setNPC(_("Soldner"), "empire/unique/soldner.png",
         _("Commander Soldner is studying the flight logs you retrieved for him. Perhaps you should prod him for what to do next."))
end


function accept()
   if tk.yesno("", fmt.f(ask_text,
         {player=player.name(), planet=mispla:name(), system=missys:name(),
            credits=fmt.credits(credits)})) then
      tk.msg("", fmt.f(accept_text,
            {player=player.name(), startplanet=startpla:name()}))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(credits))
      misn.setDesc(misn_desc)

      marker = misn.markerAdd(missys, "plot")

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system) and talk to Lensa at the bar"),
            {planet=mispla:name(), system=missys:name()}),
         fmt.f(_("Land on {planet} ({system} system) and talk to Soldner at the bar"),
            {planet=startpla:name(), system=startsys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)

      hook.land("land")
   else
      tk.msg("", fmt.f(decline_text, {player=player.name()}))
      misn.finish()
   end
end


function land()
   if planet.cur() == startpla then
      if stage == 2 then
         soldner = misn.npcAdd("approach_soldner", _("Soldner"),
               "empire/unique/soldner.png",
               _("Commander Soldner is waiting for you."),
               10)
      elseif stage == 4 then
         tk.msg("", fmt.f(finish_text,
               {player=player.name(), planet=startpla:name()}))

         player.pay(credits)
         faction.modPlayer("Empire", 3)
         emp_addShippingLog(fmt.f(log_text,
               {startplanet=startpla:name(), startsys=startsys:name()}))
         misn.finish(true)
      end
   elseif planet.cur() == mispla then
      if stage == 1 then
         lensa = misn.npcAdd("approach_lensa", _("Lensa"),
               "dvaered/unique/lensa.png",
               _("This appears to be Imperial Dvaered Liaison Officer Lensa."),
               10)
      elseif stage == 3
            and faction.get("Dvaered"):playerStanding() >= standing_target then
         lensa = misn.npcAdd("approach_lensa", _("Lensa"),
               "dvaered/unique/lensa.png",
               _("You see Lensa sitting alone, sipping a drink."),
               10)
      end
   end
end


function approach_lensa()
   if stage == 1 then
      tk.msg("", empire_request_text)

      stage = 2
      misn.osdActive(2)

      misn.markerMove(marker, startsys)
   elseif stage == 2 then
      tk.msg("", empire_request_again_text)
   elseif stage == 3 then
      tk.msg("", fmt.f(personal_request_text, {player=player.name()}))
      tk.msg("", fmt.f(personal_request_text_2, {player=player.name()}))

      stage = 4
      misn.osdActive(3)

      misn.markerRm(marker)
      marker = misn.markerAdd(startsys, "plot")

      misn.npcRm(lensa)
      hook.rm(standing_hook)
   end
end


function approach_soldner()
   if stage == 2 then
      tk.msg("", fmt.f(approach_soldner_text,
            {player=player.name(), standing=standing_target}))

      stage = 3

      local osd_desc = {
         fmt.f(_("Increase your Dvaered standing to at least {standing:.0f}%."),
            {standing=standing_target}),
         fmt.f(_("Land on {planet} ({system} system) and talk to Lensa at the bar"),
            {planet=mispla:name(), system=missys:name()}),
         fmt.f(_("Land on {planet} ({system} system)"),
            {planet=startpla:name(), system=startsys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)

      update_osd()
      standing_hook = hook.standing("update_osd")
   elseif stage == 3 then
      tk.msg("", fmt.f(approach_soldner_again_text, {player=player.name()}))
   end
end


function update_osd()
   if stage ~= 3 then
      return
   end

   misn.markerRm(marker)

   if faction.get("Dvaered"):playerStanding() < standing_target then
      misn.osdActive(1)
   else
      misn.osdActive(2)
      marker = misn.markerAdd(missys, "plot")
   end
end
