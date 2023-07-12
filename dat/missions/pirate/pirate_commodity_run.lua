--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Pirate Commodity Run">
 <avail>
  <priority>79</priority>
  <cond>var.peek("commodity_runs_active") == nil or var.peek("commodity_runs_active") &lt; 3</cond>
  <chance>90</chance>
  <location>Computer</location>
  <faction>Pirate</faction>
 </avail>
</mission>
--]]
--[[

   Pirate Commodity Delivery Mission

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

require "missions/neutral/commodity_run"

misn_title = _("Exploit the Demand for {commodity}")
misn_desc = _("Pirates on {planet} have been demanding a lot of {commodity} lately, and that's driving the price up. If you find some of it and bring it back, you can make some good money off of them.")

cargo_land = {}
cargo_land[1] = _("The containers of {commodity} are bought by the boatload, eventually earning you {credits}.")
cargo_land[2] = _("The containers of {commodity} are quickly sold out, earning you {credits}.")
cargo_land[3] = _("The containers of {commodity} are eventually all sold to the pirates, thô it takes some time. Your total earnings in the end amount to {credits}.")
cargo_land[4] = _("Pirates immediately line up to buy your {commodity}. Before you know it, you have none left, and you find that you're {credits} richer.")

osd_title = _("Pirate Sales")

