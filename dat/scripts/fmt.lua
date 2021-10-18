local fmt = {}


-- Converts an integer into a human readable string, delimiting every third digit with a comma.
-- Note: rounds input to the nearest integer. Primary use is for payment descriptions.
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


--[[
-- @brief Properly converts a number of credits to a string.
--
-- Should be used everywhere a number of credits is displayed.
--
-- @usage tk.msg("", _("You have been paid %s."):format(fmt.credits(credits)))
--
--    @param credits Number of credits.
--    @return A string taking the form of "X ¤".
--]]
function fmt.credits(credits)
   return n_("%s ¢", "%s ¢", credits):format(fmt.number(credits))
end


--[[
-- @brief Properly converts a number of tonnes to a string, utilizing ngettext.
--
-- This adds "tonnes" to the output of fmt.number in a translatable way.
-- Should be used everywhere a number of tonnes is displayed.
--
-- @usage tk.msg("", _("You are carrying %s."):format(fmt.tonnes(tonnes)))
--
--    @param tonnes Number of tonnes.
--    @return A string taking the form of "X tonne" or "X tonnes".
--]]
function fmt.tonnes(tonnes)
   return n_("%s tonne", "%s tonnes", tonnes):format(fmt.number(tonnes))
end


--[[
-- @brief Like fmt.tonnes, but for abbreviations.
--
--    @param tonnes Number of tonnes.
--    @return A short string like "22 t" describing the given mass.
--]]
function fmt.tonnes_short(tonnes)
   -- Translator note: this form represents an abbreviation of "_ tonnes".
   return n_("%d t", "%d t", tonnes):format(tonnes)
end


--[[
-- @brief Properly converts a number of jumps to a string, utilizing ngettext.
--
-- This adds "jumps" to the output of fmt.number in a translatable way.
-- Should be used everywhere a number of jumps is displayed.
--
-- @usage tk.msg("", _("The system is %s away."):format(fmt.jumps(jumps)))
--
--    @param jumps Number of jumps.
--    @return A string taking the form of "X jump" or "X jumps".
--]]
function fmt.jumps(jumps)
   return n_("%s jump", "%s jumps", jumps):format(fmt.number(jumps))
end


--[[
-- @brief Properly converts a number of times (occurrences) to a string,
-- utilizing ngettext.
--
-- This adds "times" to the output of fmt.number in a translatable way.
-- Should be used everywhere a number of occurrences is displayed.
--
-- @usage tk.msg("", _("Brush your teeth % per day."):format(fmt.times(times)))
--
--    @param times Number of times.
--    @return A string taking the form of "X time" or "X times".
--]]
function fmt.times(times)
   return n_("%s time", "%s times", times):format(fmt.number(times))
end


local function loads(code, name, env)
   local fn, err = loadstring(code, name)
   if fn then
      setfenv(fn, env)
      return fn
   end
   return nil, err
end

--[[--
String interpolation, inspired by <a href="https://github.com/hishamhm/f-strings">f-strings</a> without debug stuff.
   Prefer this over string.format because it allows translations to change the word order.
   @usage fmt.f(_("Deliver the loot to {pntname} in the {sysname} system"),{pntname=returnpnt:name(), sysname=returnsys:name()})
   @tparam string str Format string which may include placeholders of
      the form "{var}" or "{var:%6.3f}" (where the expression after the
      colon is any directive string.format understands).
   @tparam table tab Argument table.
--]]
function fmt.f(str, tab)
   return (str:gsub("%b{}", function(block)
      local code, sfmt = block:match("{(.*):(%%.*)}")
      code = code or block:match("{(.*)}")
      local fn, err = loads("return " .. code,
            string.format(_("format expression `%s`"), code), tab)
      if fn then
         fn = fn()
         if fn == nil then
            warn(string.format(_("fmt.f: string '%s' has '%s'==nil!"),str,code))
         end
         return sfmt and string.format(sfmt, fn) or tostring(fn)
      else
         error(err, 0)
      end
   end))
end


return fmt
