--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Love Train">
 <avail>
  <priority>76</priority>
  <chance>10</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
  <cond>not planet.cur():restriction() or planet.cur():restriction() == "lowclass" or planet.cur():restriction() == "hiclass"</cond>
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


send_text = {
   mono = {
      rom = {
         m = {
            _([["Oh, h-hi!" The civilian blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my boyfriend? I-it's a special surprise and I want it to be… you know. He'll b-be in the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
            _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something for my boyfriend. Such a special man he is! He's on {planet} in the {system} system and you should be able to find him at the bar; I'll make sure he's there." The civilian grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
         },
         f = {
            _([["Oh, h-hi!" The civilian blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my girlfriend? I-it's a special surprise and I want it to be… you know. She'll b-be in the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
            _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something for my girlfriend. Such a special woman she is! She's on {planet} in the {system} system and you should be able to find her at the bar; I'll make sure she's there." The civilian grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
         },
         x = {
            _([["Oh, h-hi!" The civilian blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my sweetheart? I-it's a special surprise and I want it to be… you know. They'll b-be in the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
            _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something for my sweetheart. Such a special person they are! They're on {planet} in the {system} system and you should be able to find them at the bar; I'll make sure they're there." The civilian grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
         },
      },
      qpp = {
         m = {
            _([["Oh, h-hi!" The civilian blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my QPP? I-it's a special surprise and I want it to be… you know. He'll b-be in the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
            _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something for my QPP. Such a special man he is! He's on {planet} in the {system} system and you should be able to find him at the bar; I'll make sure he's there." The civilian grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
         },
         f = {
            _([["Oh, h-hi!" The civilian blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my QPP? I-it's a special surprise and I want it to be… you know. She'll b-be in the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
            _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something for my QPP. Such a special woman she is! She's on {planet} in the {system} system and you should be able to find her at the bar; I'll make sure she's there." The civilian grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
         },
         x = {
            _([["Oh, h-hi!" The civilian blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering a special package to my QPP? I-it's a special surprise and I want it to be… you know. They'll b-be in the bar of {planet} in the {system} system. I-I can give you {credits} for it. C-can you do it?"]]),
            _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something for my QPP. Such a special person they are! They're on {planet} in the {system} system and you should be able to find them at the bar; I'll make sure they're there." The civilian grins in excitement at the plan. "I'll pay you {credits} for the service. What do you say?"]]),
         },
      },
   },
   poly = {
      rom = {
         _([["Oh, h-hi!" The civilian blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering some special packages to my sweethearts? I-it's a special surprise and I want it to be… you know. You would j-just have to go to these places and give them each their p-package at the bar." The civilian shows you a list:\n\n{places_list}\n\n"I-I can give you {credits} for it. C-can you do it?"]]),
         _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something for my sweethearts. Such special people they are! All I'd need you to do is meet them at the bars of these locations; I'll make sure they're there." The civilian grins in excitement at the plan and shows you a list:\n\n{places_list}\n\n"I'll pay you {credits} for the service. What do you say?"]]),
      },
      qpp = {
         _([["Oh, h-hi!" The civilian blushes. "Y-you're a pilot, aren't you? I was wondering if, um, you could do a job for me d-delivering some special packages to my QPPs? I-it's a special surprise and I want it to be… you know. You would j-just have to go to these places and give them each their p-package at the bar." The civilian shows you a list:\n\n{places_list}\n\n"I-I can give you {credits} for it. C-can you do it?"]]),
         _([["Why, hello there! You look to be a capable pilot, so could you help me out? I was thinking of sending a special something for my QPPs. Such lovely people they are! All I'd need you to do is meet them at the bars of these locations; I'll make sure they're there." The civilian grins in excitement at the plan and shows you a list:\n\n{places_list}\n\n"I'll pay you {credits} for the service. What do you say?"]]),
      },
   },
}

receive_text = {
   m = {
      
   }
   f = {
   }
   x = {
   }
}

sender_name = _("Unusual Civilian")
sender_desc = {
   _("A civilian stares longingly at something with a smile on their face."),
   _("A civilian sitting alone tries to grab your attention."),
   _("A civilian sits at a table with some sort of package, grinning to themself."),
}

misn_title = _("Love Train")
misn_desc_mono = _("You have been tasked with delivering a package to someone's partner.")
misn_desc_poly = _("You have been tasked with delivering packages to someone's partners.")


function avail_planets()
   local srcpla = planet.cur()
   local planets = {}
   getsysatdistance(system.cur(), 6, 12,
      function(s)
         for i, pl in ipairs(s:planets()) do
            local f = pl:faction()
            if pl:services()["inhabited"] and pl:canLand()
                  and (not srcpla:restriction()
                     or srcpla:restriction() == "lowclass"
                     or srcpla:restriction() == "hiclass")
                  and f ~= faction.get("FLF") and f ~= faction.get("Pirate")
                  and f ~= faction.get("Proteron")
                  and f ~= faction.get("Thurion") then
               planets[#planets + 1] = {pl, s}
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

   local genders = {"m", "f", "x"}
   gender = genders[rnd.rnd(1, #genders)]
   numpartners = 1
   if polyam then
      numpartners = rnd.rnd(2, math.min(num_planets, 4))
   end
end


function gen_portraits()
   sender_portrait = portrait.get(planet.cur():faction():nameRaw())
   for i, dest in ipairs(dests) do
      local dname = dest:nameRaw()
      if gender == "m" then
         portraits[dname] = portrait.getMale(dest:faction():nameRaw())
      elseif gender == "f" then
         portraits[dname] = portrait.getFemale(dest:faction():nameRaw())
      else
         portraits[dname] = portrait.get(dest:faction():nameRaw())
      end
   end
end


function create()
   misn.finish(false)
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
   portraits["__save"] = true

   gen_partners(#planets)

   dests = {}
   dests["__save"] = true
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
      local itotaldist = cursys:jumpDist(dest[2])
      for j, source in ipairs(dests) do
         if i ~= j then
            itotaldist = itotaldist + source[2]:jumpDist(dest[2])
         end
      end
      totaldist = totaldist + itotaldist/#dests
   end

   credits = 55000 * math.sqrt(totaldist)

   if polyam then
      local t = send_text.poly[reltype]
      local list = ""
      for i, dest in ipairs(dests) do
         list = list .. fmt.f(_("{planet} ({system} system)"),
               {planet=dest[1]:name(), system=dest[2]:name()})
         if i ~= #dests then
            list = list .. "\n"
         end
      end
      csend_text = fmt.f(t[rnd.rnd(1, #t)],
            {places_list=list, credits=fmt.credits(credits)})
   else
      local t = send_text.mono[reltype][gender]
      csend_text = fmt.f(t[rnd.rnd(1, #t)],
            {planet=dests[1][1]:name(), system=dests[1][2]:name(),
               credits=fmt.credits(credits)})
   end

   misn.setNPC(sender_name, sender_portrait,
         sender_desc[rnd.rnd(1, #sender_desc)])
end


function accept()
   if tk.yesno("", csend_text) then
      misn.accept()

      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(credits))
      if polyam then
         misn.setDesc(misn_desc_poly)
      else
         misn.setDesc(misn_desc_mono)
      end
   else
      misn.finish()
   end
end
