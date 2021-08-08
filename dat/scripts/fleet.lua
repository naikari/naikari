--[[--
Functions for adding fleets of pilots.

@module fleet
--]]
local fleet = {}


--[[--
Wrapper for pilot.add() that can operate on tables of ships.

All arguments passed except for the parameters argument can be either
the argument to pass to pilot.add() itself, or tables of arguments to
pass to each ship. If a table is passed as an argument, the size of the
table must be exactly the same as the size of the ship argument table.

   @usage pilots = fleet.add(2, {"Rhino", "Koala"}, "Trader")
   @usage pilots = fleet.add(1, {"Mule", "Llama"}, {"Trader", "Civilian"})

      @param count Number of times to repeat the pattern.
      @param ship Ship to add.
      @param faction Faction to give the pilot.
      @param location Location to jump in from, take off from, or appear at.
      @param pilotname Name to give the pilot.
      @param parameters Table of extra parameters to pass pilot.add().
      @return Ordered table of created pilots.
--]]
-- TODO: With a little work we can support a table of parameters tables,
-- but no one even wants that. (Yet?)
function fleet.add( count, ship, faction, location, pilotname, parameters )
   local pilotnames = {}
   local locations = {}
   local factions = {}
   local out = {}

   -- Put lone ship into table.
   if type(ship) ~= "table" then
      ship = {ship}
   end
   if count == nil then
      count = 1
   end
   counts = _buildDupeTable(count, #ship)
   pilotnames = _buildDupeTable(pilotname, #ship)
   locations = _buildDupeTable(location, #ship)
   factions = _buildDupeTable(faction, #ship)
   if factions[1] == nil then
      print(_("fleet.add: Error, raw ships must have factions!"))
      return
   end

   for i, s in ipairs(ship) do
      for j=1,counts[i] do
         out[#out + 1] = pilot.add(
               s, factions[i], locations[i], pilotnames[i], parameters)
      end
   end
   if #out > 1 then
      _randomizePositions( out )
   end
   return out
end


function _buildDupeTable( input, count )
   local tmp = {}
   if type(input) == "table" then
      if #input ~= count then
         print(_("Warning: Tables are different lengths."))
      end
      return input
   else
      for i=1,count do
         tmp[i] = input
      end
      return tmp
   end
end


-- Randomly stagger the locations of ships so they don't all spawn on top of each other.
function _randomizePositions( ship, override )
   if type(ship) ~= "table" and type(ship) ~= "userdata" then
      print(_("_randomizePositions: Error, ship list is not a pilot or table of pilots!"))
      return
   elseif type(ship) == "userdata" then -- Put lone pilot into table.
      ship = { ship }
   end

   local x = 0
   local y = 0
   for k,v in ipairs(ship) do
      if k ~= 1 and not override then
         if vec2.dist( ship[1]:pos(), v:pos() ) == 0 then
            x = x + rnd.rnd(75,150) * (rnd.rnd(0,1) - 0.5) * 2
            y = y + rnd.rnd(75,150) * (rnd.rnd(0,1) - 0.5) * 2
            v:setPos( v:pos() + vec2.new( x, y ) )
         end
      end
   end
end


return fleet
