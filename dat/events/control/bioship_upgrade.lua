--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Bioship Upgrade">
 <trigger>enter</trigger>
 <chance>100</chance>
 <flags>
  <unique />
 </flags>
</event>
--]]
--[[

   Bioship Upgrade Event

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

   This event runs in the background to upgrade any bioship the player
   may be flying. Bioships upgrade whenever the player gets paid;
   getting paid, if flying a bioship, triggers an increase in
   "experience" points, stored in the "_bioship_exp" variable. Note: all
   bioships share the same experience points; this is done because
   there's no really reliable way to divide them up and players can
   easily game the system anyway by swapping out ships at the right
   moment for many missions (e.g. doing a bounty mission, then swapping
   ships before landing on the faction's planet to get paid).

--]]

local fmt = require "fmt"


-- A table of all part types. Each entry is another table with
-- two entries. The first entry in each inner table is the base name of
-- the part containing %s, which will be replaced by a number indicating
-- the stage of the part, or "X" for the final stage. The second entry
-- in each inner table is the number of normal "stages", excluding the
-- final stage (Stage X).
bioship_parts = {
   -- Hearts (APU analog)
   {"Ultralight Heart Stage %s", 2},
   {"Light Heart Stage %s", 3},
   {"Medium Heart Stage %s", 4},
   {"Medium-Heavy Heart Stage %s", 5},
   {"Heavy Heart Stage %s", 6},
   {"Superheavy Heart Stage %s", 7},

   -- Shells (Hull analog)
   {"Ultralight Shell Stage %s", 2},
   {"Light Shell Stage %s", 3},
   {"Medium Shell Stage %s", 4},
   {"Medium-Heavy Shell Stage %s", 5},
   {"Heavy Shell Stage %s", 6},
   {"Superheavy Shell Stage %s", 7},

   -- Fins (Engine analog)
   {"Ultralight Fast Fin Stage %s", 2},
   {"Light Fast Fin Stage %s", 3},
   {"Medium Fast Fin Stage %s", 4},
   {"Medium-Heavy Fast Fin Stage %s", 5},
   {"Heavy Fast Fin Stage %s", 6},
   {"Superheavy Fast Fin Stage %s", 7},
   {"Ultralight Strong Fin Stage %s", 2},
   {"Light Strong Fin Stage %s", 3},
   {"Medium Strong Fin Stage %s", 4},
   {"Medium-Heavy Strong Fin Stage %s", 5},
   {"Heavy Strong Fin Stage %s", 6},
   {"Superheavy Strong Fin Stage %s", 7},

   -- Weapons
   {"BioPlasma Stinger Stage %s", 3},
   {"BioPlasma Claw Stage %s", 4},
   {"BioPlasma Fang Stage %s", 5},
   {"BioPlasma Talon Stage %s", 6},
   {"BioPlasma Tentacle Stage %s", 7},
}


function create()
   hook.pay("pay")
   hook.gather("gather")
end


function is_bioship_part(s)
   for i, p in ipairs(bioship_parts) do
      if string.match(s, p[1]:format(".*")) then
         return true
      end
   end
   return false
end


-- Returns the index of bioship_parts the given outfit is a part of if a
-- valid undeveloped part, or nil otherwise.
function undeveloped_bioship_part_index(s)
   for i, p in ipairs(bioship_parts) do
      local pat = p[1]:gsub ("-", "[-]")
      if string.match(s, pat:format("%d")) then
         return i
      end
   end
   return nil
end


function has_bioship()
   for i, o in ipairs(player.pilot():outfits()) do
      if is_bioship_part(o:nameRaw()) then
         return true
      end
   end
   return false
end


-- Returns a table of inner tables for each undeveloped bioship part on
-- the player; each inner table contains, respectively:
--    * The outfit name
--    * The corresponding index in bioship_parts
function get_bioship_parts()
   local parts = {}
   for i, o in ipairs(player.pilot():outfits()) do
      local index = undeveloped_bioship_part_index(o:nameRaw())
      if index ~= nil then
         parts[ #parts + 1 ] = {o:nameRaw(), index}
      end
   end
   return parts
end


function log_entry(text)
   player.msg(fmt.f(_("#oBioship Log: {text}#0"), {text=text}))
   shiplog.append("bioship", text)
end


function add_xp(exp_gain)
   local pp = player.pilot()
   shiplog.create("bioship", p_("log", "Bioship XP"), false, 50)
   local exp = var.peek("_bioship_exp") or 0
   exp = exp + exp_gain
   local s = string.format(
         n_("Gained %d XP", "Gained %d XP", exp_gain), exp_gain)
   if exp < 100 then
      s = s .. string.format(n_(" (%d more XP until next upgrade)",
            " (%d more XP until next upgrade)", 100 - exp), 100 - exp)
   end
   log_entry(s)

   while exp >= 100 do
      exp = exp - 100
      local parts = get_bioship_parts()
      if #parts > 0 then
         local part_t = parts[ rnd.rnd(1, #parts) ]
         local part = part_t[1]
         local index = part_t[2]
         local current_level = 0
         local max_level = bioship_parts[index][2]

         for i=1,max_level do
            if part == bioship_parts[index][1]:format(string.format("%d", i)) then
               current_level = i
               break
            end
         end

         local new_level = current_level + 1

         pp:outfitRm(part)
         local new_part
         if new_level > max_level then
            new_part = bioship_parts[index][1]:format("X") 
         else
            local sn = string.format("%d", new_level)
            new_part = bioship_parts[index][1]:format(sn)
         end
         -- Only check slot stuff, ignore CPU and the rest.
         local q = pp:outfitAdd(new_part, 1, true)
         if q <= 0 then
            warn(string.format(_("Unable to upgrade Soromid outfit to %s!"), new_part))
            pp:outfitAdd(part, 1, true) -- Try to add previous one
         else
            log_entry(fmt.f(_("Upgraded {old_part} to {new_part}"),
                  {old_part=part, new_part=new_part}))
         end

         -- Reset stats since we leveled up (prevents gameplay problems)
         pp:setHealth(100, 100)
         pp:setEnergy(100)
         pp:setTemp(0)
         pp:setFuel(true)
      end
      if exp < 100 then
         log_entry(string.format(n_("%d more XP until next upgrade",
               "%d more XP until next upgrade", 100 - exp), 100 - exp))
      end
   end

   var.push("_bioship_exp", exp)
end


function pay(amount, reason)
   local exp_gain = math.floor(amount / 10000)
   if amount > 0 and reason ~= "adjust" and reason ~= "loot"
         and has_bioship() then
      exp_gain = math.max(exp_gain, 1)
      add_xp(exp_gain)
   end
end


function gather(cargo, quantity)
   local exp_gain = math.floor(quantity / 10)
   if quantity > 0 and has_bioship() then
      exp_gain = math.max(exp_gain, 1)
      add_xp(exp_gain)
   end
end
