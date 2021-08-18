--This script chooses the mercenaries that spawn
local scom = require "factions.spawn.lib.common"

local merc = {}


function merc.spawnLtMerc(faction)
   local pilots = {}
   local r = rnd.rnd()

   if r < 0.1 then
      scom.addPilot(pilots, "Lancelot", 25,
            {name=N_("Mercenary Lancelot"), faction="Mercenary"})
      scom.addPilot(pilots, "Phalanx", 45,
            {name=N_("Mercenary Phalanx"), faction="Mercenary"})
   elseif r < 0.3 then
      scom.addPilot(pilots, "Hyena", 15,
            {name=N_("Mercenary Hyena"), faction="Mercenary"})
      scom.addPilot(pilots, "Hyena", 15,
            {name=N_("Mercenary Hyena"), faction="Mercenary"})
      scom.addPilot(pilots, "Shark", 20,
            {name=N_("Mercenary Shark"), faction="Mercenary"})
   elseif r < 0.5 then
      scom.addPilot(pilots, "Vendetta", 25,
            {name=N_("Mercenary Vendetta"), faction="Mercenary"})
      scom.addPilot(pilots, "Shark", 20,
            {name=N_("Mercenary Shark"), faction="Mercenary"})
   elseif r < 0.8 then
      scom.addPilot(pilots, "Vendetta", 25,
            {name=N_("Mercenary Vendetta"), faction="Mercenary"})
      scom.addPilot(pilots, "Lancelot", 25,
            {name=N_("Mercenary Lancelot"), faction="Mercenary"})
      scom.addPilot(pilots, "Ancestor", 20)
   else
      scom.addPilot(pilots, "Vendetta", 25,
            {name=N_("Mercenary Vendetta"), faction="Mercenary"})
      scom.addPilot(pilots, "Ancestor", 20,
            {name=N_("Mercenary Ancestor"), faction="Mercenary"})
      scom.addPilot(pilots, "Admonisher", 45,
            {name=N_("Mercenary Admonisher"), faction="Mercenary"})
   end

   return pilots
end

function merc.spawnMdMerc(faction)
   local pilots = {}
   local r = rnd.rnd()

   if r < 0.5 then
      scom.addPilot(pilots, "Vendetta", 25,
            {name=N_("Mercenary Vendetta"), faction="Mercenary"})
      scom.addPilot(pilots, "Ancestor", 20,
            {name=N_("Mercenary Ancestor"), faction="Mercenary"})
      scom.addPilot(pilots, "Vigilance", 70,
            {name=N_("Mercenary Vigilance"), faction="Mercenary"})
   elseif r < 0.8 then
      scom.addPilot(pilots, "Vendetta", 25,
            {name=N_("Mercenary Vendetta"), faction="Mercenary"})
      scom.addPilot(pilots, "Lancelot", 25,
            {name=N_("Mercenary Lancelot"), faction="Mercenary"})
      scom.addPilot(pilots, "Ancestor", 20,
            {name=N_("Mercenary Ancestor"), faction="Mercenary"})
      scom.addPilot(pilots, "Pacifier", 70,
            {name=N_("Mercenary Pacifier"), faction="Mercenary"})
   else
      scom.addPilot(pilots, "Vendetta", 25,
            {name=N_("Mercenary Vendetta"), faction="Mercenary"})
      scom.addPilot(pilots, "Vigilance", 70,
            {name=N_("Mercenary Vigilance"), faction="Mercenary"})
      scom.addPilot(pilots, "Phalanx", 45,
            {name=N_("Mercenary Phalanx"), faction="Mercenary"})
   end

   return pilots
end

function merc.spawnBgMerc(faction)
   local pilots = {}

   -- Generate the capship
   local r = rnd.rnd()
   if r < 0.5 then
      scom.addPilot(pilots, "Kestrel", 90,
            {name=N_("Mercenary Kestrel"), faction="Mercenary"})
   elseif r < 0.8 then
      scom.addPilot(pilots, "Hawking", 105,
            {name=N_("Mercenary Hawking"), faction="Mercenary"})
   else
      scom.addPilot(pilots, "Goddard", 120,
            {name=N_("Mercenary Goddard"), faction="Mercenary"})
   end

   -- Generate the escorts
   r = rnd.rnd()
   if r < 0.1 then
      scom.addPilot(pilots, "Lancelot", 25,
            {name=N_("Mercenary Lancelot"), faction="Mercenary"})
      scom.addPilot(pilots, "Phalanx", 45,
            {name=N_("Mercenary Phalanx"), faction="Mercenary"})
   elseif r < 0.3 then
      scom.addPilot(pilots, "Hyena", 15,
            {name=N_("Mercenary Hyena"), faction="Mercenary"})
      scom.addPilot(pilots, "Hyena", 15,
            {name=N_("Mercenary Hyena"), faction="Mercenary"})
      scom.addPilot(pilots, "Shark", 20,
            {name=N_("Mercenary Shark"), faction="Mercenary"})
   elseif r < 0.5 then
      scom.addPilot(pilots, "Vendetta", 25,
            {name=N_("Mercenary Vendetta"), faction="Mercenary"})
      scom.addPilot(pilots, "Shark", 20,
            {name=N_("Mercenary Shark"), faction="Mercenary"})
   elseif r < 0.8 then
      scom.addPilot(pilots, "Vendetta", 25,
            {name=N_("Mercenary Vendetta"), faction="Mercenary"})
      scom.addPilot(pilots, "Lancelot", 25,
            {name=N_("Mercenary Lancelot"), faction="Mercenary"})
      scom.addPilot(pilots, "Ancestor", 20,
            {name=N_("Mercenary Ancestor"), faction="Mercenary"})
   else
      scom.addPilot(pilots, "Vendetta", 25,
            {name=N_("Mercenary Vendetta"), faction="Mercenary"})
      scom.addPilot(pilots, "Ancestor", 20,
            {name=N_("Mercenary Ancestor"), faction="Mercenary"})
      scom.addPilot(pilots, "Admonisher", 45,
            {name=N_("Mercenary Admonisher"), faction="Mercenary"})
   end

   return pilots
end


return merc
