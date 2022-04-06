--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Alive Bounty">
 <avail>
  <priority>42</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>360</chance>
  <location>Computer</location>
  <faction>Empire</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[

   Alive Pirate Bounty

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

   Bounty mission where you must capture the target alive.
   Can work with any faction.

--]]

local fmt = require "fmt"
require "missions/neutral/pirbounty_dead"


pay_capture_text = {}
pay_capture_text[1] = _("An officer takes %s into custody and hands you your pay.")
pay_capture_text[2] = _("The officer seems to think your acceptance of the alive bounty for %s was foolish. They carefully take the pirate off your hands, taking precautions you think are completely unnecessary, and then hand you your pay.")
pay_capture_text[3] = _("The officer you deal with seems to especially dislike %s. They take the pirate off your hands and hand you your pay without speaking a word.")
pay_capture_text[4] = _("A fearful-looking officer rushes %s into a secure hold, pays you the appropriate bounty, and then hurries off.")
pay_capture_text[5] = _("The officer you deal with thanks you profusely for capturing %s alive, pays you, and sends you off.")
pay_capture_text[6] = _("Upon learning that you managed to capture %s alive, the officer who previously sported a defeated look suddenly brightens up. The pirate is swiftly taken into custody as you are handed your pay.")
pay_capture_text[7] = _("When you ask the officer for your bounty on %s, they sigh, take the pirate into custody, go through some paperwork, and hand you your pay, mumbling something about how useless capturing pirates alive is.")

fail_kill_text = _("MISSION FAILURE! {pilot} has been killed.")

misn_title = {}
misn_title[1] = _("Tiny Alive Bounty in %s")
misn_title[2] = _("Small Alive Bounty in %s")
misn_title[3] = _("Moderate Alive Bounty in %s")
misn_title[4] = _("High Alive Bounty in %s")
misn_title[5] = _("Dangerous Alive Bounty in %s")
misn_desc   = _("The pirate known as %s was recently seen in the %s system. %s authorities want this pirate alive.")

osd_msg[2] = _("Capture %s")


function pilot_death ()
   fail(fmt.f(fail_kill_text, {pilot=name}))
end


-- Set up the ship, credits, and reputation based on the level.
function bounty_setup ()
   pirate_faction = faction.get("Wanted Pirate")

   if level == 1 then
      ship = "Hyena"
      credits = 100000 + rnd.sigma() * 15000
      reputation = 0
   elseif level == 2 then
      ship = "Pirate Shark"
      credits = 250000 + rnd.sigma() * 50000
      reputation = 1
   elseif level == 3 then
      if rnd.rnd() < 0.5 then
         ship = "Pirate Vendetta"
      else
         ship = "Pirate Ancestor"
      end
      credits = 350000 + rnd.sigma() * 80000
      reputation = 3
   elseif level == 4 then
      if rnd.rnd() < 0.5 then
         ship = "Pirate Admonisher"
      else
         ship = "Pirate Phalanx"
      end
      credits = 850000 + rnd.sigma() * 120000
      reputation = 5
   elseif level == 5 then
      ship = "Pirate Kestrel"
      credits = 1500000 + rnd.sigma() * 200000
      reputation = 7
   end
end
