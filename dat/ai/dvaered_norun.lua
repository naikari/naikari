require("ai/dvaered")

mem.norun = true

function donothing ()
    ai.brake()
end

function idle () 
    ai.pushtask("donothing") 
end
