--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Pirate Patrol">
 <avail>
  <priority>48</priority>
  <chance>560</chance>
  <location>Computer</location>
  <faction>Pirate</faction>
 </avail>
</mission>
--]]
--[[

   Pirate Patrol

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

   Pirate version of the patrol mission.

--]]

require "missions/neutral/patrol"


abandon_text = {}
abandon_text[1] = _("You are sent a message informing you that landing in the middle of the job is considered to be abandonment. As such, your contract is void and you will not receive payment.")

-- Mission details
misn_title = _("Patrol: Pirate strongholds ({system} system)")
misn_desc = _("A local crime boss has offered a job to patrol the {system} system in an effort to keep outsiders from discovering this Pirate stronghold. You will be tasked with checking various points in the system and eliminating any outsiders along the way. Upon entering, you must remain in the system until the patrol is completed, and you are not permitted to land during the patrol, or else the contract is void and you will not be paid.")

-- Messages
secure_msg = _("Point secure.")
hostiles_msg = _("Outsiders detected. Eliminate all outsiders.")
continue_msg = _("Outsiders eliminated.")
pay_msg = _("{credits} awarded for keeping pirate strongholds safe from discovery.")

osd_title  = _("Patrol")
osd_msg    = {}
osd_msg[1] = _("Fly to the {system} system")
osd_msg[2] = "(null)"
osd_msg[3] = _("Eliminate outsiders")
osd_msg["__save"] = true

mark_name = _("Patrol Point")


use_hidden_jumps = true

