require("ai/collective")

mem.norun = true

function donothing ()
    ai.brake()
end

function idle () 
    ai.pushtask("donothing") 
end
