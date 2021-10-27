local fmt = require "fmt"
-- NOTE: This file is deprecated. Please use fmt.lua instead.

-- Depricated. Aliases fmt.number().
function numstring(number)
   number = math.floor(number + 0.5)
   local numberstring = ""
   while number >= 1000 do
      numberstring = string.format( ",%03d%s", number % 1000, numberstring )
      number = math.floor(number / 1000)
   end
   numberstring = number % 1000 .. numberstring
   return fmt.number(number)
end


-- Deprecated. Aliases fmt.credits().
function creditstring( credits )
   return fmt.credits(credits)
end


-- Depricated. Aliases fmt.tonnes().
function tonnestring( tonnes )
   return fmt.tonnes(tonnes)
end


-- Deprecated. Aliases fmt.tonnes().
function tonnestring_short( tonnes )
   -- Translator note: this form represents an abbreviation of "_ tonnes".
   return fmt.tonnes(tonnes)
end


--[[
-- Deprecated. Do not use.
--]]
function jumpstring( jumps )
   if jumps == nil then
      return _("∞ jumps")
   end
   return gettext.ngettext("%s jump", "%s jumps", jumps):format(
         numstring(jumps))
end
