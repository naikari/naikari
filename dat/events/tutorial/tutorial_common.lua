-- Capsule function for naev.keyGet() that adds a color code to the return string.
function tutGetKey(command)
    return "#b" .. naev.keyGet(command) .. "#0"
end
