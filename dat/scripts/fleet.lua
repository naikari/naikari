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
nil values are allowed in the location and pilotname tables, since they
are indexed directly based on looping through the ship table rather than
used directly.



@usage pilots = fleet.add(2, {"Rhino", "Koäla"}, "Trader")
@usage pilots = fleet.add(1, {"Mule", "Llama"}, {"Trader", "Civilian"})

   @param count Number of times to repeat the pattern.
   @param ship Ship to add.
   @param faction Faction to give the pilot.
   @param[opt] location Location to jump in from, take off from, or
      appear at. If set to nil (and not a table), all pilots will spawn
      from the same random point, based on the faction of the first
      pilot in the fleet. If set to a table containing nil values, each
      pilot with a nil location will spawn in its own individually
      determined random location.
   @param[opt] pilotname Name to give the pilot.
   @param[opt] parameters Table of extra parameters to pass pilot.add().
   @param[opt] leader A pilot to add to the start of the fleet and make
      into the fleet's leader, true to automatically assign the first
      ship added as the fleet's leader, or nil (default) for no
      leader.
   @treturn {Pilot,...} Ordered table of created pilots.
--]]
function fleet.add(count, ship, faction, location, pilotname, parameters,
      leader)
   -- TODO: With a little work we can support a table of parameters
   -- tables, but no one even wants that. (Yet?)
   local pilotnames = {}
   local locations = {}
   local factions = {}
   local out = {}

   -- Allow false as a synonym for nil
   if leader == false then
      leader = nil
   end

   -- Put the leader in, if an external one is specified.
   if leader ~= nil and leader ~= true and leader ~= false then
      if leader:exists() then
         out[1] = leader
      else
         print(_("fleet.add: Warning: attempted to assign a leader that doesn't exist."))
         leader = nil
      end
   end

   -- Put lone ship into table.
   if type(ship) ~= "table" then
      ship = {ship}
   end

   if count == nil then
      count = 1
   end

   counts = _buildDupeTable(count, #ship)
   factions = _buildDupeTable(faction, #ship)
   pilotnames = _buildDupeTable(pilotname, #ship, true)

   -- When nil is used as the location, group the fleet together.
   if location == nil then
      location = pilot.choosePoint(factions[1], false, false)
   end

   locations = _buildDupeTable(location, #ship, true)

   if factions[1] == nil then
      print(_("fleet.add: Error, raw ships must have factions!"))
      return
   end

   for i, s in ipairs(ship) do
      for j=1,counts[i] do
         local p = pilot.add(
               s, factions[i], locations[i], pilotnames[i], parameters)

         if leader ~= nil then
            if leader == true then
               leader = p
            elseif leader:exists() then
               p:setLeader(leader)
            else
               print(_("fleet.add: Warning: Auto leader doesn't exist."))
               leader = nil
            end
         end

         table.insert(out, p)
      end
   end
   if #out > 1 then
      _randomizePositions( out )
   end
   return out
end


function _buildDupeTable(input, count, ignore_length)
   local tmp = {}
   if type(input) == "table" then
      if not ignore_length and #input ~= count then
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
