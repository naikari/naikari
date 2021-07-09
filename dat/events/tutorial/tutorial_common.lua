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
