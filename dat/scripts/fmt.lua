--[[--
Functions for formatting strings.

@usage local fmt = require "fmt"

@module fmt
--]]
local fmt = {}


--[[--
Converts an integer into a human readable string.

The conversion rounds to the nearest integer and inserts commas every
three places.

@usage s = fmt.number(60000000) -- Converts to "60,000,000"
   @tparam number number Number to convert.
   @treturn string The converted string.
--]]
function fmt.number(number)
   number = math.floor(number + 0.5)
   local numberstring = ""
   while number >= 1000 do
      numberstring = string.format(",%03d%s", number % 1000, numberstring)
      number = math.floor(number / 1000)
   end
   numberstring = number % 1000 .. numberstring
   return numberstring
end


--[[--
Converts a number of credits to a string (e.g. "10.00 k¢").

The conversion method is the same as in C credits2str function, but
locked to using 2 decimal places.

@usage misn.setReward(fmt.credits(100000))
   @tparam number credits Number of credits.
   @treturn string The converted string.
--]]
function fmt.credits(credits)
   if credits >= 1e18 then
      return string.format(_("%.2f E¢"), credits / 1e18)
   elseif credits >= 1e15 then
      return string.format(_("%.2f P¢"), credits / 1e15)
   elseif credits >= 1e12 then
      return string.format(_("%.2f T¢"), credits / 1e12)
   elseif credits >= 1e9 then
      return string.format(_("%.2f G¢"), credits / 1e9)
   elseif credits >= 1e6 then
      return string.format(_("%.2f M¢"), credits / 1e6)
   elseif credits >= 1e3 then
      return string.format(_("%.2f k¢"), credits / 1e3)
   else
      return string.format(_("%.2f ¢"), math.floor(credits + 0.5))
   end
end


--[[--
Converts a number of tonnes to a string.

DO NOT USE THIS WITHIN SENTENCES. Relying on it for that use-case can
lead to sentences which cannot be properly translated. Use this
function ONLY for cases where a number of tonnes is shown alone.

   @tparam number tonnes Number of tonnes.
   @treturn string The converted string.
--]]
function fmt.tonnes(tonnes)
   -- Translator note: this form represents an abbreviation of "_ tonnes".
   return n_("%s kt", "%s kt", tonnes):format(fmt.number(tonnes))
end


--[[--
Wrapper for naik.keyGet() which adds a color hilight to the return
string.

@usage bindname = fmt.keyGetH("accel")

   @tparam string keyname  Name of the keybinding to get value of. Valid
      values are listed in src/input.c: keybind_info.
   @treturn string Human-readable display of the bound key, hilighted
      with a color.
--]]
function fmt.keyGetH(keyname)
   return "#b" .. naik.keyGet(keyname) .. "#0"
end


--[[--
String interpolation function.

Inspired by
<a href="https://github.com/hishamhm/f-strings">f-strings</a>, but more
similar to Python's str.format() and simplified. Prefer this over
string.format because it allows translations to change the word order.

@usage fmt.f(_("Land on {pntname} ({sysname} system)"), {pntname=returnpnt:name(), sysname=returnsys:name()})
@usage fmt.f(_("As easy as {1}, {2}, {3}"), {"one", "two", "three"})
@usage fmt.f(_("A few digits of pi: {1:.2f}"), {math.pi})

   @tparam string str Format string which may include placeholders of
      the form "{var}" or "{var:6.3f}" (where the expression after the
      colon is any directive string.format understands). A var which is
      a number is treated as a number; all other var definition is
      treated as a string. This value is used to index the argument
      table.
   @tparam table tab Argument table.
--]]
function fmt.f(str, tab)
   return (str:gsub("%b{}", function(block)
      local key, fmt = block:match("{(.*):(.*)}")
      key = key or block:match("{(.*)}")
      -- Support {1} for printing the first member of the table, etc.
      key = tonumber(key) or key
      val = tab[key]
      if val == nil then
         warn(string.format(_("fmt.f: string '%s' has '%s'==nil!"), str, key))
      end
      return fmt and string.format('%' .. fmt, val) or tostring(val)
   end))
end


return fmt
