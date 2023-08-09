-- Capsule function for naik.keyGet() that adds a color code to the return string.
function tutGetKey(command)
    return "#b" .. naik.keyGet(command) .. "#0"
end
