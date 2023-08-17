--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Love Train">
 <avail>
  <priority>50</priority>
  <chance>15</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
  <cond>
   (not planet.cur():restriction() or planet.cur():restriction() == "lowclass"
      or planet.cur():restriction() == "hiclass")
   and (var.peek("tut_complete") == true
      or planet.cur():faction() ~= faction.get("Empire"))
  </cond>
 </avail>
</mission>
--]]
--[[

   Love Train

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
local portrait = require "portrait"
require "jumpdist"


receive_text = {
   m = {
      _([[The man is ecstatic when you explain that you are delivering a package for him and who it is from. He thanks you excitedly and leaves.]]),
      _([[The man squeals with glee when he sees the name on the package. You smile at him as he rushes out without even finishing his drink.]]),
      _([[The man laughs nervously as you hand him the package, but nonetheless thanks you.]]),
      _([[The man tears up with joy as he opens his package, thanking you for delivering it.]]),
   },
   f = {
      _([[The woman is ecstatic when you explain that you are delivering a package for her and who it is from. She thanks you excitedly and leaves.]]),
      _([[The woman squeals with glee when she sees the name on the package. You smile at her as she rushes out without even finishing her drink.]]),
      _([[The woman laughs nervously as you hand her the package, but nonetheless thanks you.]]),
      _([[The woman tears up with joy as she opens her package, thanking you for delivering it.]]),
   },
   x = {
      _([[The lover is ecstatic when you explain that you are delivering a package for them and who it is from. They thank you excitedly and leave.]]),
      _([[The lover squeals with glee when they see the name on the package. You smile at them as they rush out without even finishing their drink.]]),
      _([[The lover laughs nervously as you hand them the package, but nonetheless thanks you.]]),
      _([[The lover tears up with joy as they open their package, thanking you for delivering it.]]),
   },
}

pay_text = {
   _([[Not long after you finish your delivery, you see your reward has been deposited into your account.]]),
   _([[You soon see your payment added to your account's balance.]]),
   _([[Shortly after you finish the job, you see that your payment has been sent to your account.]]),
   _([[Soon after finishing the job, you check your account balance and find that the promised payment has been wired into your account.]]),
}

sender_name = _("Unusual Patron")
sender_desc = {
   _("A patron stares longingly at something with a smile on their face."),
   _("A patron sitting alone fiddles with some kind of package."),
   _("A patron sits at a table with some sort of package, grinning to themself."),
   _("You see a patron glancing around the bar, perhaps trying to find a suitable pilot."),
}

receiver_name = _("Lover")
receiver_desc = {
   _("This must be the lover you've been hired to deliver a package to."),
   _("The lover you have been sent to deliver a package to sits at the bar in anticipation."),
   _("You see the lover you've been tasked with delivering a package to, fidgeting in their seat."),
   _("A patron looks every which way around the bar. This seems to be the lover you're supposed to deliver a package to."),
}

misn_title = _("Love Train")


function gen_sender_text()
   if polyam then
      local text_choices = {
         rom = {
            n_("\"Oh, h-hi!\" The patron blushes. \"Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to {numpartners} of my sweethearts? I-it's a special surprise and I want it to be… you know. You would j-just have to go to this place and give them each their p-package at the bar.\" The patron shows you a list:\n\n{places_list}\n\n\"I-I can give you {credits} for it. C-can you do it?\"",
               "\"Oh, h-hi!\" The patron blushes. \"Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering some special packages to {numpartners} of my sweethearts? I-it's a special surprise and I want it to be… you know. You would j-just have to go to these places and give them each their p-package at the bar.\" The patron shows you a list:\n\n{places_list}\n\n\"I-I can give you {credits} for it. C-can you do it?\"",
               numpartners),
            n_("\"Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to {numpartners} of my sweethearts. All I'd need you to do is meet them at the bar of this location; I'll make sure they're there.\" The patron grins in excitement at the plan and shows you a list:\n\n{places_list}\n\n\"I'll pay you {credits} for the service. What do you say?\"",
               "\"Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to {numpartners} of my sweethearts. All I'd need you to do is meet them at the bars of these locations; I'll make sure they're there.\" The patron grins in excitement at the plan and shows you a list:\n\n{places_list}\n\n\"I'll pay you {credits} for the service. What do you say?\"",
               numpartners),
            n_("\"Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful sweetheart since I can't see them for awhile. You'll just need to take it to the bar here.\" The patron hands you a scrap of paper showing you the location:\n\n{places_list}\n\n\"I'll make it worth your while, I assure you! Deliver this package and I'll give you {credits}. What do you think?\"",
               "\"Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful sweethearts since I can't see them for awhile. You'll just need to take a few packages to the bars of these locations.\" The patron hands you a scrap of paper with a list on it:\n\n{places_list}\n\n\"I'll make it worth your while, I assure you! Deliver all of these packages and I'll give you {credits}. What do you think?\"",
               numpartners),
            n_("Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. \"No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my sweetheart. I love them a lot, but I haven't been able to see them lately, you know? I was actually thinking of sending them– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to them for me? They'll be at the bar of this location.\" The patron shows you a list:\n\n{places_list}\n\n\"{credits} for delivery of this package. Well? How about it?\"",
               "Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. \"No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my sweethearts. I love them all a lot, but I haven't been able to see them lately, you know? I was actually thinking of sending them– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to them for me? They'll be at the bars of these locations.\" The patron shows you a list:\n\n{places_list}\n\n\"{credits} for delivery of all of these packages. Well? How about it?\"",
               numpartners),
         },
         qpp = {
            n_("\"Oh, h-hi!\" The patron smiles nervously. \"Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to {numpartners} of my QPPs? I-it's a special surprise and I want it to be… you know. You would j-just have to go to this place and give them each their p-package at the bar.\" The patron shows you a list:\n\n{places_list}\n\n\"I-I can give you {credits} for it. C-can you do it?\"",
               "\"Oh, h-hi!\" The patron smiles nervously. \"Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering some special packages to {numpartners} of my QPPs? I-it's a special surprise and I want it to be… you know. You would j-just have to go to these places and give them each their p-package at the bar.\" The patron shows you a list:\n\n{places_list}\n\n\"I-I can give you {credits} for it. C-can you do it?\"",
               numpartners),
            n_("\"Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to {numpartners} of my QPPs. All I'd need you to do is meet them at the bar of this location; I'll make sure they're there.\" The patron grins in excitement at the plan and shows you a list:\n\n{places_list}\n\n\"I'll pay you {credits} for the service. What do you say?\"",
               "\"Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to {numpartners} of my QPPs. All I'd need you to do is meet them at the bars of these locations; I'll make sure they're there.\" The patron grins in excitement at the plan and shows you a list:\n\n{places_list}\n\n\"I'll pay you {credits} for the service. What do you say?\"",
               numpartners),
            n_("\"Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful QPP since I can't see them for awhile. You'll just need to take it to the bar here.\" The patron hands you a scrap of paper showing you the location:\n\n{places_list}\n\n\"I'll make it worth your while, I assure you! Deliver this package and I'll give you {credits}. What do you think?\"",
               "\"Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful QPPs since I can't see them for awhile. You'll just need to take a few packages to the bars of these locations.\" The patron hands you a scrap of paper with a list on it:\n\n{places_list}\n\n\"I'll make it worth your while, I assure you! Deliver all of these packages and I'll give you {credits}. What do you think?\"",
               numpartners),
            n_("Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. \"No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my QPP. I love them a lot, but I haven't been able to see them lately, you know? I was actually thinking of sending them– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to them for me? They'll be at the bar of this location.\" The patron shows you a list:\n\n{places_list}\n\n\"{credits} for delivery of this package. Well? How about it?\"",
               "Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. \"No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my QPPs. I love them all a lot, but I haven't been able to see them lately, you know? I was actually thinking of sending them– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to them for me? They'll be at the bars of these locations.\" The patron shows you a list:\n\n{places_list}\n\n\"{credits} for delivery of all of these packages. Well? How about it?\"",
               numpartners),
         },
      }
      local t = text_choices[reltype]
      local list = ""
      for i, dest in ipairs(dests) do
         list = list .. fmt.f(_("{planet} ({system} system)"),
               {planet=dest.pla:name(), system=dest.sys:name()})
         if i ~= #dests then
            list = list .. "\n"
         end
      end
      send_text = fmt.f(t[rnd.rnd(1, #t)],
            {numpartners=numpartners, places_list=list,
               credits=fmt.credits(credits)})
   else
      local text_choices = {
         rom = {
            m = {
               _([["Oh, h-hi!" The patron blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my boyfriend? I-it's a special surprise and I want it to be… you know. He'll b-be at the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
               _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to my boyfriend. He's on {planet} in the {system} system and you should be able to find him at the bar; I'll make sure he's there." The patron grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
               _([["Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful boyfriend since I can't see him for awhile. You'll just need to take it to the bar of {planet} in the {system} system. I'll make it worth your while, I assure you! Deliver this package and I'll give you {credits}. What do you think?"]]),
               _([[Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. "No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my boyfriend. I love him a lot, but I haven't been able to see him lately, you know? I was actually thinking of sending him– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to him for me? He'll be at the bar of {planet} in the {system} system. {credits} for delivery of the package. Well? How about it?"]]),
            },
            f = {
               _([["Oh, h-hi!" The patron blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my girlfriend? I-it's a special surprise and I want it to be… you know. She'll b-be at the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
               _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to my girlfriend. She's on {planet} in the {system} system and you should be able to find her at the bar; I'll make sure she's there." The patron grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
               _([["Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful girlfriend since I can't see her for awhile. You'll just need to take it to the bar of {planet} in the {system} system. I'll make it worth your while, I assure you! Deliver this package and I'll give you {credits}. What do you think?"]]),
               _([[Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. "No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my girlfriend. I love her a lot, but I haven't been able to see her lately, you know? I was actually thinking of sending her– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to her for me? She'll be at the bar of {planet} in the {system} system. {credits} for delivery of the package. Well? How about it?"]]),
            },
            x = {
               _([["Oh, h-hi!" The patron blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my sweetheart? I-it's a special surprise and I want it to be… you know. They'll b-be at the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
               _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to my sweetheart. They're on {planet} in the {system} system and you should be able to find them at the bar; I'll make sure they're there." The patron grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
               _([["Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful sweetheart since I can't see them for awhile. You'll just need to take it to the bar of {planet} in the {system} system. I'll make it worth your while, I assure you! Deliver this package and I'll give you {credits}. What do you think?"]]),
               _([[Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. "No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my sweetheart. I love them a lot, but I haven't been able to see them lately, you know? I was actually thinking of sending them– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to them for me? They'll be at the bar of {planet} in the {system} system. {credits} for delivery of the package. Well? How about it?"]]),
            },
         },
         qpp = {
            m = {
               _([["Oh, h-hi!" The patron smiles nervously. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my QPP? I-it's a special surprise and I want it to be… you know. He'll b-be at the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
               _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to my QPP. He's on {planet} in the {system} system and you should be able to find him at the bar; I'll make sure he's there." The patron grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
               _([["Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful QPP since I can't see him for awhile. You'll just need to take it to the bar of {planet} in the {system} system. I'll make it worth your while, I assure you! Deliver this package and I'll give you {credits}. What do you think?"]]),
               _([[Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. "No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my QPP. I love him a lot, but I haven't been able to see him lately, you know? I was actually thinking of sending him– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to him for me? He'll be at the bar of {planet} in the {system} system. {credits} for delivery of the package. Well? How about it?"]]),
            },
            f = {
               _([["Oh, h-hi!" The patron smiles nervously. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my QPP? I-it's a special surprise and I want it to be… you know. She'll b-be at the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
               _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to my QPP. She's on {planet} in the {system} system and you should be able to find her at the bar; I'll make sure she's there." The patron grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
               _([["Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful QPP since I can't see her for awhile. You'll just need to take it to the bar of {planet} in the {system} system. I'll make it worth your while, I assure you! Deliver this package and I'll give you {credits}. What do you think?"]]),
               _([[Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. "No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my QPP. I love her a lot, but I haven't been able to see her lately, you know? I was actually thinking of sending her– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to her for me? She'll be at the bar of {planet} in the {system} system. {credits} for delivery of the package. Well? How about it?"]]),
            },
            x = {
               _([["Oh, h-hi!" The patron smiles nervously. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my QPP? I-it's a special surprise and I want it to be… you know. They'll b-be at the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
               _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something to my QPP. They're on {planet} in the {system} system and you should be able to find them at the bar; I'll make sure they're there." The patron grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
               _([["Ah, perfect! I was hoping I'd find someone like you! You're a pilot, right? I can tell! Look, I have an easy job for you. I wanted to send something special to my wonderful QPP since I can't see them for awhile. You'll just need to take it to the bar of {planet} in the {system} system. I'll make it worth your while, I assure you! Deliver this package and I'll give you {credits}. What do you think?"]]),
               _([[Seeing you, the patron recoils in surprise. You apologize for startling them, but the patron waves off your concern with a blush. "No, no, that's alright. Sorry, I just didn't see you there. I was just thinking about my QPP. I love them a lot, but I haven't been able to see them lately, you know? I was actually thinking of sending them– Oh! You're a pilot, aren't you? Perfect timing! Could you maybe deliver a package to them for me? They'll be at the bar of {planet} in the {system} system. {credits} for delivery of the package. Well? How about it?"]]),
            },
         },
      }
      local t = text_choices[reltype][gender]
      send_text = fmt.f(t[rnd.rnd(1, #t)],
            {planet=dests[1].pla:name(), system=dests[1].sys:name(),
               credits=fmt.credits(credits)})
   end
end


function avail_planets()
   local planets = {}
   getsysatdistance(system.cur(), 6, 12,
      function(s)
         for i, pl in ipairs(s:planets()) do
            local f = pl:faction()
            if pl:services()["inhabited"] and pl:services()["bar"]
                  and pl:canLand()
                  and (not pl:restriction() or pl:restriction() == "lowclass"
                     or pl:restriction() == "hiclass")
                  and f ~= faction.get("FLF") and f ~= faction.get("Pirate")
                  and f ~= faction.get("Proteron")
                  and f ~= faction.get("Thurion") then
               planets[#planets + 1] = {pla=pl, sys=s}
            end
         end
         return true
      end)
   return planets
end


function gen_partners(num_planets)
   polyam = false
   if num_planets > 1 then
      polyam = rnd.rnd() < 0.1
   end

   reltype = "rom"
   if rnd.rnd() < 0.05 then
      reltype = "qpp"
   end

   if polyam then
      gender = "x"
      numpartners = rnd.rnd(1, math.min(num_planets, 4))
   else
      local genders = {"m", "f", "x"}
      gender = genders[rnd.rnd(1, #genders)]
      numpartners = 1
   end
end


function gen_portraits()
   sender_portrait = portrait.get()
   for i, dest in ipairs(dests) do
      local dname = dest.pla:nameRaw()
      if gender == "m" then
         portraits[dname] = portrait.getMale()
      elseif gender == "f" then
         portraits[dname] = portrait.getFemale()
      else
         portraits[dname] = portrait.get()
      end
   end
end


function create()
   local planets = avail_planets()
   if #planets < 1 then
      misn.finish(false)
   end

   -- Safe defaults
   reltype = "rom"
   gender = "x"
   numpartners = 1
   sender_portrait = "none.png"
   portraits = {}
   portraits.__save = true

   gen_partners(#planets)

   dests = {}
   dests.__save = true
   for i=1,numpartners do
      dests[#dests + 1] = planets[rnd.rnd(1, #planets)]
   end

   if #dests < 1 then
      -- Shouldn't happen, but check just in case.
      misn.finish(false)
   end

   gen_portraits()

   -- To try to make a calculation of distance traveled more accurate,
   -- check the average distance it would take to travel to each system.
   -- This is to avoid weird cases where clustered together systems are
   -- equally as rewarding as spread apart systems; this should lead
   -- a higher travel distance to be calculated for more spread out
   -- destinations, on average.
   local cursys = system.cur()
   local totaldist = 0
   for i, dest in ipairs(dests) do
      local itotaldist = cursys:jumpDist(dest.sys)
      for j, source in ipairs(dests) do
         if i ~= j then
            itotaldist = itotaldist + source.sys:jumpDist(dest.sys)
         end
      end
      totaldist = totaldist + itotaldist/#dests
   end

   credits = 85000 * math.sqrt(totaldist)
   markers = {}
   markers.__save = true

   gen_sender_text()

   misn.setNPC(sender_name, sender_portrait,
         sender_desc[rnd.rnd(1, #sender_desc)])
end


function accept()
   if tk.yesno("", send_text) then
      misn.accept()

      local s = fmt.f(
            n_("The patron hands you {number} package. You will be paid when it is delivered.",
               "The patron hands you {number} packages. You will be paid when they are all delivered.",
               numpartners),
            {number=numpartners})
      tk.msg("", s)

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(credits))
      misn.setDesc(
            n_("You have been tasked with delivering a package to someone's partner.",
               "You have been tasked with delivering packages to someone's partners.",
               numpartners))

      setup_osd()

      hook.land("land")
      hook.load("land")
   else
      misn.finish()
   end
end


function setup_osd()
   for i, marker in ipairs(markers) do
      misn.markerRm(marker)
   end
   markers = {}
   markers.__save = true

   local osd_msg = {}
   for i, dest in ipairs(dests) do
      markers[#markers + 1] = misn.markerAdd(dest.sys, "low", dest.pla)
      osd_msg[#osd_msg + 1] = fmt.f(
            _("Talk to lover in bar on {planet} ({system} system)"),
            {planet=dest.pla:name(), system=dest.sys:name()})
   end
   misn.osdCreate(misn_title, osd_msg)
end


function land()
   for i, dest in ipairs(dests) do
      if planet.cur() == dest.pla then
         npc = misn.npcAdd("approach", receiver_name,
               portraits[dest.pla:nameRaw()],
               receiver_desc[rnd.rnd(1, #receiver_desc)], 50)
         return
      end
   end
end


function approach()
   local t = receive_text[gender]
   tk.msg("", t[rnd.rnd(1, #t)])

   if npc ~= nil then
      misn.npcRm(npc)
      npc = nil
   end

   -- Delete the destination and shift all later dests forward.
   for i, dest in ipairs(dests) do
      if dest.pla == planet.cur() then
         for j=i,#dests do
            dests[j] = dests[j + 1]
         end
         break
      end
   end

   if #dests <= 0 then
      player.pay(credits)
      tk.msg("", pay_text[rnd.rnd(1, #pay_text)])
      misn.finish(true)
   end

   setup_osd()
end
