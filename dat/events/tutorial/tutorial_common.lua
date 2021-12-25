-- Capsule function for tk.msg that disables all key input WHILE the msg is open.
function tkMsg(title, msg, keys)
    naev.keyDisableAll()
    enableBasicKeys()
    tk.msg(title, msg)
    if keys ~= nil then
       enableKeys(keys)
    else
       naev.keyEnableAll()
    end
end


-- Capsule function for enabling the keys passed to it in a table, plus some defaults.
function enableKeys(keys)
    naev.keyDisableAll()
    for _, key in ipairs(keys) do
        naev.keyEnable(key, true)
    end
    enableBasicKeys()
end


-- Capsule function for enabling basic, important keys.
function enableBasicKeys()
    local alwaysEnable = { "speed", "menu", "screenshot", "console" }
    for _, key in ipairs(alwaysEnable) do
        naev.keyEnable(key, true)
    end
end


-- Capsule function for naev.keyGet() that adds a color code to the return string.
function tutGetKey(command)
    return "#b" .. naev.keyGet(command) .. "#0"
end


-- @brief Create a tutorial log, for referencing tutorial information later.
--
-- @usage addTutLog(_("Insert lesson here"), N_("Lesson Category"))
--
--    @luaparam text Text of the log entry.
--    @luaparam logname_raw The raw (untranslated) name of the log to use.
function addTutLog( text, logname_raw )
   shiplog.create(logname_raw, _(logname_raw), _("Tutorial"))
   shiplog.append(logname_raw, text)
end


-- Adds the boarding tutorial log (so multiple missions can use it)
function tutExplainBoarding(explanation)
   if not var.peek("tutorial_boarding") then
      local log = _("To board a ship, you generally must first use disabling weapons, such as ion cannons, to disable it, although some missions and events allow you to board certain ships without disabling them. Once the ship is disabled or otherwise can be boarded, you can board it by either double-clicking on it, or targeting it with the Target Nearest key (T by default) and then pressing the Board Target key (B by default). From there, you generally can steal the ship's credits, cargo, ammo, and/or fuel. Boarding ships can also trigger special mission events.")
      if var.peek("_tutorial_passive_active") then
         tk.msg("", explanation)
      end
      addTutLog(log, N_("Boarding"))
      var.push("tutorial_boarding", true)
   end
end
