local fmt = {}


-- Converts an integer into a human readable string, delimiting every third digit with a comma.
-- Note: rounds input to the nearest integer.
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
-- @brief Converts a number of credits to a string (e.g. "10 ¢").
--
-- The conversion method is the same as in C credits2str function, but
-- locked to using 2 decimal places.
--
-- @usage misn.setReward(fmt.credits(100000))
--
--    @param credits Number of credits.
--    @return A string taking the form of "X ¤".
--]]
function fmt.credits(credits)
   if credits >= 1e21 then
      return string.format(_("%.2f E¢"), credits / 1e18)
   elseif credits >= 1e18 then
      return string.format(_("%.2f P¢"), credits / 1e15)
   elseif credits >= 1e15 then
      return string.format(_("%.2f T¢"), credits / 1e12)
   elseif credits >= 1e12 then
      return string.format(_("%.2f G¢"), credits / 1e9)
   elseif credits >= 1e9 then
      return string.format(_("%.2f M¢"), credits / 1e6)
   elseif credits >= 1e6 then
      return string.format(_("%.2f k¢"), credits / 1e3)
   else
      return string.format(_("%.2f ¢"), credits)
   end
end


--[[
-- @brief Converts a number of tonnes to a string.
--
-- DO NOT USE THIS WITHIN SENTENCES. Relying on it for that use-case can
-- lead to sentences which cannot be properly translated. Use this
-- function ONLY for cases where a number of tonnes is shown alone.
--
--    @param tonnes Number of tonnes.
--    @return A string taking the form of "X tonne" or "X tonnes".
--]]
function fmt.tonnes(tonnes)
   -- Translator note: this form represents an abbreviation of "_ tonnes".
   return n_("%s t", "%s t", tonnes):format(fmt.number(tonnes))
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
