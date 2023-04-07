--[[--
Functions which assist with working with tables.

@usage local tablehelper = require "tablehelper"

@module tablehelper
--]]

local tablehelper = {}


--[[--
Inverts a table's values so that keys become values and vice-versa.

This returns a table of keys: each value of the original table becomes
a key, and each associated key of the original table becomes a value.
For example, if a list contains the entries "foo", "bar", and "baz",
then a keys table for that list would assign the value 1 to the key
"foo", the value 2 to the key "bar", and the value 3 to the key "baz".

@usage i = tablehelper.keys({"foo", "bar", "baz"})["bar"] -- i = 2
   @tparam table T Table to get the keys table of.
   @treturn table The keys table.
--]]
function tablehelper.keys(T)
    local keys = {}
    for i, v in pairs(T) do
        keys[v] = i
    end
    return keys
end


--[[--
Returns whether or not something is in a table as a value.

@usage if tablehelper.inTable("foo") then -- "foo" is in the table
   @tparam table T The table to search for the value in.
   @param x The value to search for.
   @treturn bool Whether or not x is a value in T.
--]]
function tablehelper.inTable(T, x)
   for i, v in pairs(T) do
      if v == x then
         return true
      end
   end
   return false
end


return tablehelper
