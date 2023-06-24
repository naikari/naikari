--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Nebula Satellite">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>29</priority>
  <chance>10</chance>
  <cond>
   var.peek("tut_complete") == true
   or planet.cur():faction() ~= faction.get("Empire")
  </cond>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Goddard</faction>
 </avail>
</mission>
--]]
--[[

   Nebula Satellite

   One-shot mission

   Help some independent scientists put a satellite in the nebula.

]]--

local fmt = require "fmt"
require "missions/neutral/common"


bar_desc = _("A bunch of scientists seem to be chattering nervously among themselves.")
mtitle = _("Nebula Probe")
mdesc = _("You have been tasked with helping a group of scientists launch a special probe into the Nebula.")

ask_text = _([[You approach the scientists. They seem a bit nervous and one mutters something about whether it's a good idea or not. Eventually one of them comes up to you.

"Hello Captain, we're looking for a ship to take us to the margins of the Inner Nebula. Would you be willing to help us?"]])
explain1_text = _([["We had a trip scheduled with a space trader ship, but they backed out at the last minute. So we were stuck here until you came. We've got a research probe that we have to release into the {system} system to monitor the Nebula's growth rate. The probe launch procedure is pretty straightforward and shouldn't have any complications."

He takes a deep breath, "We hope to be able to find out more secrets of the Sol Nebula so mankind can once again regain its lost patrimony. So far the radiation and volatility of the deeper areas haven't been very kind to our instruments. That's why we designed this probe we're going to launch."]])
explain2_text = _([["The plan is for you to take us to {launchsystem} so we can launch the probe, and then return us to our home at {homeplanet} in the {homesystem} system. The probe will automatically send us the data we need if all goes well. You'll be paid {credits} when we arrive."]])
pay_text = _([[The scientists thank you for your help and pay you before going back to their home to continue their nebula research.]])

log_text = _([[You helped a group of scientists launch a research probe into the Nebula.]])


function create ()
   -- Note: this mission does not make any system claims.
   -- Set up mission variables
   misn_stage = 0
   homeworld, homeworld_sys = planet.getLandable(misn.factions())
   if homeworld == nil then
      misn.finish(false)
   end

   satellite_sys = system.get("Arandon") -- Not too unstable
   credits = 400000
   probe_mass = 3

   -- Set stuff up for the spaceport bar
   misn.setNPC(_("Scientists"), "neutral/unique/neil.png", bar_desc)

end


function accept ()
   if not tk.yesno("", ask_text) then
      misn.finish()
   end

   if player.pilot():cargoFree() < probe_mass then
      local t = n_("\"Ah, sorry, I forgot to mention that you need %d kt of cargo space. Let us know if you manage to free up enough.\"",
               "\"Ah, sorry, I forgot to mention that you need %d kt of cargo space. Let us know if you manage to free up enough.\"",
               probe_mass)
      tk.msg("", t:format(probe_mass))
      misn.finish()
   end

   misn.accept()

   local c = misn.cargoNew(N_("Nebula Probe"),
         N_("A small probe loaded with sensors for exploring the depths of the nebula."))
   cargo = misn.cargoAdd(c, probe_mass)

   misn.setTitle(mtitle)
   misn.setReward(fmt.credits(credits))
   misn.setDesc(mdesc)
   misn_marker = misn.markerAdd(satellite_sys, "low")

   tk.msg("", fmt.f(explain1_text, {system=satellite_sys:name()}))
   tk.msg("", fmt.f(explain2_text,
         {launchsystem=satellite_sys:name(), homeplanet=homeworld:name(),
            homesystem=homeworld_sys:name(), credits=fmt.credits(credits)}))

   local osd_msg = {
      fmt.f(_("Fly to the {system} system and wait for the probe to launch"),
            {system=satellite_sys:name()}),
      fmt.f(_("Land on {planet} ({system} system)"),
            {planet=homeworld:name(), system=homeworld_sys:name()}),
   }
   misn.osdCreate(mtitle, osd_msg)

   hook.land("land")
   hook.enter("jumpin")
end


function land ()
   landed = planet.cur()
   if misn_stage == 1 and landed == homeworld then
      tk.msg("", pay_text)
      player.pay(credits)
      addMiscLog(log_text)
      misn.finish(true)
   end
end


function jumpin ()
   sys = system.cur()
   if misn_stage == 0 and sys == satellite_sys then
      hook.timer(3, "beginLaunch")
   end
end

--[[
   Launch process
--]]
function beginLaunch ()
   player.msg(_("Preparing to launch probe…"))
   hook.timer(3, "beginCountdown")
end
function beginCountdown ()
   countdown = 5
   player.msg(string.format(
         n_("Launch in %d…", "Launch in %d…", countdown), countdown))
   hook.timer(1, "countLaunch")
end
function countLaunch ()
   countdown = countdown - 1
   if countdown <= 0 then
      launchSatellite()
   else
      player.msg(string.format(
            n_("Launch in %d…", "Launch in %d…", countdown), countdown))
      hook.timer(1, "countLaunch")
   end
end
function launchSatellite ()
   var.push("nebu_probe_launch", time.get():tonumber())

   misn_stage = 1
   player.msg(_("Probe launch successful."))
   misn.cargoJet(cargo)
   misn.osdActive(2)
   misn.markerMove(misn_marker, homeworld_sys)
end
