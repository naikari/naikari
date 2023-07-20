require("ai/dvaered")

mem.norun = true
mem.noleave = true

function donothing ()
    ai.brake()
end

function idle () 
    ai.pushtask("donothing") 
end
