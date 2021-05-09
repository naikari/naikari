--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Tour the Frontier">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>2</priority>
  <chance>100</chance>
  <location>Bar</location>
  <cond>var.peek("flfbase_intro") == 2</cond>
  <planet>Sindbad</planet>
 </avail>
 <notes>
  <done_misn name="Deal with the FLF agent">If you return Gregar to Sindbad</done_misn>
  <campaign>Join the FLF</campaign>
 </notes>
</mission>
--]]
--[[

   Tour the Frontier

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

require "numstring"
require "missions/flf/flf_common"


intro_text = _([[You approach and greet the man with a friendly gesture, but he is unmoved and maintains his icy stare. After spending what feels like an eternity staring into his piercing gaze, he finally speaks up.

"I don't trust you," he bluntly states. "I doubt anyone here trusts you. You may have helped out one of our own, but I don't know your motives. You could be a spy or assassin for all I know." The man pauses, then briefly closes his eyes as he lets out a sigh before opening them again. "That said, if the higher-ups have decided to trust you, I guess there's nothing I can do about it. No matter. You couldn't stop the FLF even if you had ill intent. Not fully."

You promise the man that you have no ill intent and won't rat the FLF out to the authorities. You explain that you are neutral in the conflict between House Dvaered and the FLF, just a common freelancer helping out someone in need. The man frowns.]])

ask_text = _([["Neutral?! How could you be neutral in this conflict? Do you have any idea what the Dvaereds do to us day to day in the Frontier? What they aspire to do if only we would get out of the way? Do you know nothing about our struggles?" You knew you weren't trusted, but you certainly didn't expect this level of anger. You open your mouth to answer, but not knowing what to say, so you close it again. and your eyes move to the floor below you. Around you, you hear murmurs of agreement; it seems his outburst has attracted an audience, and the audience is firmly against you.

The man lets out another sigh, then stands up. His expression has reverted again from one of intense anger to one of firm distrust. "I'll show you exactly what's going on in the Frontier, what the Dvaereds do to us, what the Dvaereds plan to do to us, and why we need to resist them. I'm sick and tired of outsiders like you who have no idea just how horrible the Dvaereds are." The offer takes you by surprise. You stand there silently, transfixed by the man's eyes which, now that you think about it, have a touch of pain and sadness to them behind their piercing quality. "Well?" he say, breaking you out of your trance. "Will you take me aboard your ship so I can show you what's going on in the Frontier?"]])

ask_return_text = _([["I see you're back. Have you changed your mind about letting me show you what's going on in the Frontier?"]])

response_no = _([[The man frowns, then silently returns to his seat and crosses his arms.]])

response_yes = _([["Good. You'll see soon why being neutral in this conflict is unacceptable.

"Our first stop will be my homeworld: %s. I'll be waiting in your ship until we arrive. I already know where it is." Sure enough, he begins to walk in the direction of your ship, but then stops and looks behind himself toward you. "Oh, by the way, my name is Flint. And also..." He pulls out a laser gun from some place you cannot discern. You had no idea he was carrying a weapon. You feel the color draining from your face. "Don't even think of trying any funny business. If you even think of trying to rat me out to the Dvaereds, I will kill you."

Flint puts away his gun as swiftly as he took it out, still leaving you without a clue as to where he keeps it, and turns back away from you. "Nothing personal, but I gotta protect myself. Hopefully you should know well enough not to get yourself into that situation." He then walks off, leaving you to ponder the situation. You hope you haven't made a grave mistake just now, but Flint does seem to have positive intentions, so you brush your concerns aside and resolve to see just what it is that the FLF hate so much about House Dvaered.]])


function create ()
   homepla, homesys = planet.get("Cetrat")
   misn.finish(false)
end
