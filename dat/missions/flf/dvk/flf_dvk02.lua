--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="FLF Pirate Alliance">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <chance>30</chance>
  <done>Diversion from Doranthex</done>
  <location>Bar</location>
  <faction>FLF</faction>
  <cond>faction.playerStanding("FLF") &gt;= 30</cond>
 </avail>
 <notes>
  <campaign>Save the Frontier</campaign>
 </notes>
</mission>
--]]
--[[

   Pirate Alliance

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

--]]

local fmt = require "fmt"
local fleet = require "fleet"
require "missions/flf/flf_common"


intro_text = _([[Benito looks up at you and sighs. "Hello again, {player}. Sorry I'm such a mess at the moment. Maybe you can help with this little problem I have." You ask what the problem is. "Pirates. The damn pirates are making things difficult for us. Activity has picked up in the {sys} system and we don't know why.

"Pirates usually don't cause a huge problem for us because they attack Dvaered ships as well as our ships and Frontier ships, so it sort of evens out. But in that region of space, they're nothing but a nuisance. No Dvaered ships for them to attack, it's just us and the occasional Empire ship. And that's on our most direct route to Frontier space. If pirates are going to be giving us even more trouble there than before, that could slow down – or worse, wreck – our operations."]])

ask_text = _([[You remark that it's strange that pirates are there in the first place. "Yes!" Benito says. "It makes no sense! Pirates are always after civilians and traders to steal their credits and cargo, so why would they be there? We don't carry much cargo, the Empire doesn't carry much cargo… it just doesn't add up!

"My only guess is that maybe they're trying to find our hidden jump to Gilligan's Light, and if that's the case, that could be tremendously bad news. I'm not worried about the damage pirates can do to the Frontier; they've been prevalent in Frontier space for a long while. But if they start attacking Gilligan's Light, that could leave the Frontier Council in a vulnerable position that the Dvaereds can take advantage of!"

Benito sighs. "Could you help us with this problem, {player}?"]])

ask_again_text = _([["Hello again, {player}. Are you able to help us deal with the pirates in the nebula now?"]])

yes_text = _([["Perfect! I knew you would do it!

"First, we need to do some investigating, find out why they're there and what they want. I suspect they won't tell you without a fight, so I need you to… persuade them. I would recommend boarding one of them and interrogating them personally. I will leave you to decide what to do after that. If you don't have any non-lethal weaponry, there should be some Ion Cannons at the outfitter here on Sindbad. Let me know how it goes, what you've found out and what you've accomplished. Good luck!"]])

no_text = _([[You see a defeated expression on Benito's face. "OK. Let me know if you change your mind."]])

board_text = _([[You force your way onto the pirate ship and subdue the pirate on board. You seem to have had a good stroke of luck: the pirate is clearly unprepared and has a very poorly secured ship. Clearly, this pirate is new to the job.

Not wanting to give away your suspicions, you order the pirate to tell you what the pirates are doing in the nebula. "What do you think we're doing? Exploring the nebula, of course!" You tell them to elaborate. "Surely you've heard the ghost stories, haven't you? They say ghosts lurk in the nebula, hiding, waiting to strike. Of course we don't believe in the supernatural, but that means there must be alien ships in there! Aliens with technology so advanced they're able to freely traverse the Nebula! If we could capture one of those ships, we'd be both rich and unstoppable!" You ask where they got into the Nebula from. "What's it to you?!" the pirate shouts back.]])

unboard_text = _([[Undeterred, you pull out a laser gun and put it against the pirate's head, ordering them again to tell you where they got into the Nebula from. This seems to convince the previously boisterous pirate. "W-we have a hidden jump to {system}! We come in from there! It's on my computer, you can check for yourself!"

You grin. Taking the pirate's suggestion, you look at the ship's computer, and sure enough, you find the hidden jump they were talking about. The map also reveals that there is a station in {system} called {station}. You decide that this station is a good next place to investigate.]])

station_text = _([[You land on the newly constructed station and begin searching around. Considering its purpose you are impressed by the station's construction and how advanced it is, with equipment, ships, and even station defenses far exceeding those of Sindbad. Piracy must be lucrative indeed, at least for whoever built this station. Either that, or perhaps a great return on investment is anticipated.

You go around the station's bar and start prodding its patrons, posing as a pirate. You find that pirates around the bar generally confirm what the pirate you interrogated before said about trying to find some unknown alien civilization. However, something that one pirate says catches your ear. After rambling for what feels like hours about alien tech and how great this would be, he continues with something concerning. "And besides, even if we don't find any alien tech, we could still suss out whatever secret jump those FLF fools use to get into the Frontier and get a nice, easy income source in the heart of the Frontier!"]])

station_text2 = _([[You resist the urge to frown; showing your anger in this situation, surrounded by pirates, would be dangerous. To your relief, all of the other pirates at the table seem to disagree. "I'm all for getting some nice alien tech, but pissing off the FLF is a bad move, I'm telling you!" one pirate responds. "Word is they've got enough ships and strength to keep the Dvaereds at bay, so what chance do we have? They'd swoop in and blow us all up in an instant! Honestly the only reason they're not a problem for us is because we don't threaten the Frontier all that much and they know that." The rest of the pirates murmur in agreement, and the table goes silent.

You excuse yourself from the table, but decide that rogue pirate is dangerous. You patiently wait until the rogue pirate is alone in a secluded location, then sneak up behind him and put a laser gun to his back. The pirate suddenly freezes in place, not daring to make any sudden movements.]])

station_text3 = _([[You tell the pirate in no uncertain terms that he should listen to his contemporaries and not piss off the FLF. "U-understood," the pirate responds. "I'm sorry, I won't be encouraging g-going against you again, I promise!" You grin to yourself, then have another ideä. With the pirate thoroughly intimidated, you tell him that they will be annihilated if they piss off the FLF, but that if he and his fellow pirates behave themselves, they just might be able to work together with the FLF for a level of profit that far exceeds anything they may expect to get alone.

The pirate shifts slightly in shock. "Y-you want to work with us?" You assure him that if he and his contemporaries behave, aliens or not, this station will lead them to riches beyond their wildest dreams. He closes his hands into a pair of tight fists. "OK. I understand. I will spread the word." You voice your approval and leave him, grinning to yourself. Perfect! Now to return to Sindbad to report your results.…]])

sindbad_text = _([[As soon as you arrive at Sindbad, you locate Benito and inform her of the situation, including the location of the pirate station, the fact that your efforts seem to have been fruitful, and how you promised a chance at cooperative profit should they behave. Benito looks thankful, yet concerned.

"I see," she responds. "That was certainly a good ideä, mixing in an offer like that alongside intimidation. Of course, those pirates' conception that we would destroy them is absurd, but from their vantage point, we must look capable of such a feat and we may as well use that misconception to our advantage. Of course, having to live up to that promise you made creätes a complication, but I'm sure we can work something out.

"Thank you for your service, {player}. It sounds like we may have been clear of any real danger already if it's true that they're looking for so-called aliens in the Nebula, but that little bit of intimidation and offer of cooperation should solidify the safety of our position. We may very soon start seeing reduced hostility from pirates as a result, which helps us further."]])

pay_text = _([[Benito hands you payment on a credit chip before continuing. "I must admit I'm also curious about their whole 'aliens' ideä. We don't tend to really explore the Nebula since we only use it for cover, but I have indeed heard the ghost stories. Perhaps we should do our own investigation. I'm not sure if I believe them, but if there really are aliens, making allies out of them could be very helpful to our cause. Of course, we can't put too many resources into that as the so-called ghosts could maybe just be some pre-Incident artifacts that somehow survived being turned to dust by the nebula, but it wouldn't hurt to do some cursory investigation and trade information with the pirates.

"Well, I'll go discuss what we should do next regarding the pirates. I think I already have some ideäs. Thank you again, and blow up a Dvaered for me, eh?" You laugh at her quip and wave goodbye as you consider what to next.]])

misn_title = _("FLF's Pirate Problem")
misn_desc = _("Benito has tasked you with figuring out what the pirates are doing in the Nebula and doing whatever you can to ensure they don't disrupt FLF operations.")

npc_name = _("Benito")
npc_desc = _("You see exhaustion on Benito's face. Perhaps you should see what's up.")

osd_title   = _("FLF's Pirate Problem")
osd_desc    = {}
osd_desc[1] = _("Fly to the {system} system")
osd_desc[2] = _("Board a pirate's ship and interrogate them")
osd_desc["__save"] = true

log_text = _([[You learned that pirates have entered the nebula region apparently seeking to find so-called nebula ghost ships which they believe to be aliens and in general should not pose a problem for the FLF. However, to make absolutely sure of it, you cornered one pirate who was suggesting trying to break into Frontier space, intimidated him, and also suggested that he and his pirate contemporaries could benefit from working together with the FLF if they don't misbehave.]])


function create()
   missys = system.get("Tormulex")
   missys2 = system.get("Anger")
   hj1, hj2 = jump.get("Tormulex", "Anger")
   if not misn.claim(missys) then
      misn.finish(false)
   end

   asked = false

   misn.setNPC(npc_name, "flf/unique/benito.png", npc_desc)
end


function accept()
   local txt = ask_again_text

   if not asked then
      asked = true
      txt = ask_text
      tk.msg("", fmt.f(intro_text, {player=player.name(), sys=missys:name()}))
   end

   if tk.yesno("", fmt.f(txt, {player=player.name()})) then
      tk.msg("", yes_text)

      misn.accept()

      stage = 0

      hj1known = hj1:known()
      hj2known = hj2:known()
      missys2known = missys2:known()

      credits = 300000
      reputation = 5

      osd_desc[1] = fmt.f(osd_desc[1], {system=missys:name()})
      misn.osdCreate(osd_title, osd_desc)

      misn.setTitle(misn_title)
      misn.setDesc(misn_desc)
      misn.setReward(fmt.credits(credits))

      marker = misn.markerAdd(missys, "plot")

      hook.enter("enter")
      hook.board("board")
      hook.land("land")
   else
      tk.msg("", no_text)
      misn.finish()
   end
end


function enter()
   if stage == 0 then
      if system.cur() == missys then
         misn.osdActive(2)
      else
         misn.osdActive(1)
      end
   end
end


function board(p)
   if p == nil or not p:exists() then
      return
   end

   if system.cur() ~= missys or stage ~= 0 then
      return
   end

   if p:faction() == faction.get("Pirate") then
      stage = 1
      diff.apply("Fury_Station")
      misplanet = planet.get("Fury Station")

      player.unboard()
      tk.msg("", board_text)
      tk.msg("", fmt.f(unboard_text,
               {system=missys2:name(), station=misplanet:name()}))

      hj1:setKnown()
      hj2:setKnown()
      misplanet:setKnown()
      missys2:setKnown()

      misn.markerMove(marker, missys2)

      osd_desc[3] = fmt.f(_("Land on {planet} ({system} system)"),
            {planet=misplanet:name(), system=missys2:name()})
      misn.osdDestroy()
      misn.osdCreate(osd_title, osd_desc)
      misn.osdActive(3)
   end
end


function land()
   if stage == 1 and planet.cur() == misplanet then
      stage = 2

      tk.msg("", station_text)
      tk.msg("", station_text2)
      tk.msg("", station_text3)

      misn.markerMove(marker, system.get("Sigur"))

      osd_desc[4] = _("Return to FLF base")
      misn.osdDestroy()
      misn.osdCreate(osd_title, osd_desc)
      misn.osdActive(4)
   elseif stage == 2 and planet.cur():faction() == faction.get("FLF") then
      tk.msg("", fmt.f(sindbad_text, {player=player.name()}))
      tk.msg("", pay_text)

      diff.apply("flf_pirate_ally")
      player.pay(credits)
      faction.get("FLF"):modPlayer(reputation)

      local pf = faction.get("Pirate")
      if pf:playerStanding() < 0 then
         pf:setPlayerStanding(0)
      end

      flf_addLog(log_text)
      misn.finish(true)
   end
end


function abort()
   hj1:setKnown(hj1known)
   hj2:setKnown(hj2known)
   missys2:setKnown(missys2known)
   if diff.isApplied("Fury_Station") then
      diff.remove("Fury_Station")
   end

   misn.finish(false)
end

