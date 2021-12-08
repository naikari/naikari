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


function create()
   misn.finish(false)
end


function accept()
end
