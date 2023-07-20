require("ai/sirius")

mem.norun = true
mem.noleave = true

function donothing ()
    ai.brake()
end

function idle () 
    ai.pushtask("donothing") 
end
