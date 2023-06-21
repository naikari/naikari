--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Hypergate Handler">
 <trigger>land</trigger>
 <chance>20</chance>
 <cond>system.get("Sol"):known()</cond>
</event>
--]]
--[[

   Hypergate Handler Event

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

   This event activates hypergates when conditions for them are met.

--]]

local fmt = require "fmt"


function create()
   local exp = time.get() + time.create(0, 250, 0)

   if diff.isApplied("hypergate_empire") then
      -- Check to see if the Sol jump news entry should be added.
      if not var.peek("sol_hypergate_discovered") then
         if jump.get("Hypergate Zone", "Sol"):known() then
            news.add("Generic", _("Explorer Finds Hypergate to Sol"),
                  _([[Explorers have uncovered an unexpected hypergate leading straight to Sol, the dead system which was once the heart of the Empire. "Hypergates are a human construction," one of the explorers explained, "so this is a surprising find indeed." Rumors of a secret Imperial exploration project abound, but Imperial officials have declined to comment, stating only that adventurers should stay clear of the system due to its dangerously volatile nebula.]]),
                  exp)
            var.push("sol_hypergate_discovered", true)
         end
      end

      local standing = faction.get("Dvaered"):playerStanding()
      if not diff.isApplied("hypergate_dvaered")
            and (standing >= 20 or standing <= -20) then
         diff.apply("hypergate_dvaered")
         news.add("Generic", _("Dvaered Hypergate Constructed"),
               _([[Dvaered officials have announced today that construction of a hypergate in the Dvaer system is complete, sponsored by the Empire. Dvaered warlords have shown little interest in the project, but traders rejoice as transporting Dvaered ore out of Dvaered space has become less time-consuming.]]),
               exp)
      end

      local standing = faction.get("Za'lek"):playerStanding()
      if not diff.isApplied("hypergate_zalek")
            and (standing >= 20 or standing <= -20) then
         diff.apply("hypergate_zalek")
         news.add("Generic", _("Za'lek Hypergate Constructed"),
               _([[Za'lek scientists have excitedly jumped on the hypergate bandwagon, constructing a hypergate in the Za'lek system. The team involved in the construction of the project refused to comment on the hypergate's effect on intergalactic commerce, seemingly more interested in the potential for research the technology creätes.]]),
               exp)
      end

      local standing = faction.get("Sirius"):playerStanding()
      if not diff.isApplied("hypergate_sirius")
            and (standing >= 20 or standing <= -20) then
         diff.apply("hypergate_sirius")
         news.add("Generic", _("Sirius Hypergate Constructed"),
               _([[Sirius officials have announced, as they call it, the "Great Hypergate of Sirichana" in the Aesir system. "It was through the will of Sirichana that the Empire developed this technology," one official stated. "Through this new interconnected galaxy, more people will learn of His might and glory."]]),
               exp)
      end
   else
      -- Activate Empire hypergate
      local standing = faction.get("Empire"):playerStanding()
      if standing >= 20 or standing <= -20 then
         diff.apply("hypergate_empire")
         news.add("Generic", _("Empire Announces Hypergate Network"),
               _([[The Emperor has announced the creätion of a new system of mass transit: hypergates. "Unlike regular jump gates, hypergates operate through a central hub called the Hypergate Zone," a leading researcher in charge of the project explained. Currently, the only working hypergate is found in Gamma Polaris. Imperial officials state that they are working with the Great Houses to finish construction of the hypergate network.]]),
               exp)
      end
   end

   evt.finish()
end
