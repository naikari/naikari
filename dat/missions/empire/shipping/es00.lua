--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Empire Shipping 1">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>faction.playerStanding("Empire") &gt;= 10 and faction.playerStanding("Dvaered") &gt;= 0 and faction.playerStanding("FLF") &lt; 10 and var.peek("es_misn") ~= nil and var.peek("es_misn") &gt;= 3</cond>
  <chance>35</chance>
  <location>Bar</location>
  <faction>Empire</faction>
 </avail>
 <notes>
  <done_misn name="Empire Shipping">3 times or more</done_misn>
  <campaign>Empire Shipping</campaign>
 </notes>
</mission>
--]]
--[[

   Empire Shipping Prisoner Exchange

   Author: bobbens
      minor edits by Infiltrator

]]--

local fmt = require "fmt"
local fleet = require "fleet"
require "missions/empire/common"

bar_desc = _("You see an Empire Commander. He seems to have noticed you.")
misn_title = _("Prisoner Exchange")
misn_desc = _("You have been tasked with performing a prisoner exchange with the FLF on behalf of the Empire. You are to exchange the FLF prisoners with Empire prisoners on {planet}, then return the Empire prisoners to {planet2}.")

ask_text = _([[You approach the Empire Commander.

"Hello, you must be {player}. I've heard about you. I'm Commander Soldner. We've got some harder missions for someone like you in the Empire Shipping division. There would be some real danger involved in these missions, unlike the ones you've recently completed for the division. Would you be up for the challenge?"]])

accept_text = _([["We've got a prisoner exchange set up with the FLF to take place on {planet} in the {system} system. They want a more neutral pilot to do the exchange. You would have to go to {planet} with some FLF prisoners aboard your ship and exchange them for some of our own. You won't have visible escorts but we will have your movements watched by ships in nearby sectors.

"Once you get the soldiers they captured back, bring them over to {planet2} in {system2} for debriefing. You'll be compensated for your troubles. Good luck."

The Prisoners are loaded onto your ship along with a few marines to ensure nothing untoward happens.]])

land_text = _([[As you land, you notice the starport has been emptied. You also notice explosives rigged on some of the columns. This doesn't look good. The marines tell you to sit still while they go out to try to complete the prisoner exchange.

From the cockpit you see how the marines lead the prisoners in front of them with guns to their backs. You see figures step out of the shadows with weapons too; most likely the FLF.]])

land2_text = _([[All of a sudden a siren blares and you hear shooting break out. You quickly start your engines and prepare for take off. Shots ring out all over the landing bay and you can see a couple of corpses as you leave the starport. You remember the explosives just as loud explosions go off behind you. This doesn't look good at all.

You start your climb out of the atmosphere and notice how you're picking up many FLF and Dvaered ships. Looks like you're going to have quite a run to get the hell out of here. It didn't go as you expected.]])

pay_text = _([[After you leave your ship in the starport, you meet up with Commander Soldner. From the look on his face, it seems like he already knows what happened.

"It was all the Dvaereds' fault. They just came in out of nowhere and started shooting. What a horrible mess. We're already working on sorting out the blame.

"We had good soldiers there. And we certainly didn't want you to start with a mess like this, but if you're interested in another, meet me up in the bar in a while. We get no rest around here. The payment has already been transferred to your bank account."]])

log_text = _([[You took part in a prisoner exchange with the FLF on behalf of the Empire. Unfortunately, the prisoner exchange failed. "It was all the Dvaereds' fault. They just came in out of nowhere and started shooting." Commander Soldner has asked you to meet him in the bar on Halir if you're interested in another mission.]])


function create ()
   dest, destsys = planet.getLandable(faction.get("Frontier"))
   ret, retsys = planet.getLandable("Halir")
   if dest == nil or ret == nil or not misn.claim(destsys) then
      misn.finish(false)
   end

   misn.setNPC(_("Commander"), "empire/unique/soldner.png", bar_desc)
end


function accept ()
   -- Intro text
   if not tk.yesno("", fmt.f(ask_text, {player=player.name()})) then
      misn.finish()
   end

   -- Accept mission
   misn.accept()

   reward = 500000
   misn.setTitle(misn_title)
   misn.setReward(fmt.credits(reward))
   misn.setDesc(fmt.f(misn_desc, {planet=dest:name(), planet2=ret:name()}))

   tk.msg("", fmt.f(accept_text,
         {planet=dest:name(), system=destsys:name(), planet2=ret:name(),
            system2=retsys:name()}))

   local osd_desc = {
      fmt.f(_("Land on {planet} ({system} system)"),
            {planet=dest:name(), system=destsys:name()}),
      fmt.f(_("Land on {planet} ({system} system)"),
            {planet=ret:name(), system=retsys:name()}),
   }
   misn.osdCreate(misn_title, osd_desc)

   misn_marker = misn.markerAdd(destsys, "low")

   misn_stage = 0

   -- Set hooks
   hook.land("land")
   hook.enter("enter")
   hook.jumpout("jumpout")
end


function land ()
   landed = planet.cur()
   if landed == dest and misn_stage == 0 then
      misn_stage = 1

      tk.msg("", land_text)
      tk.msg("", land2_text)

      misn.markerMove(misn_marker, retsys)
      misn.osdActive(2)

      -- Prevent players from saving on the destination planet
      player.allowSave(false)

      player.takeoff()

      -- Saving should be disabled for as short a time as possible
      player.allowSave()
   elseif landed == ret and misn_stage == 1 then
      player.pay(reward)
      faction.modPlayer("Empire", 2)

      tk.msg("", pay_text)

      emp_addShippingLog(log_text)

      misn.finish(true)
   end
end


function enter ()
   local sys = system.cur()
   if misn_stage == 1 and sys == destsys then
      -- Force FLF combat music (note: must clear this later on).
      var.push("music_combat_force", "FLF")

      -- Get a random position near the player
      ang = rnd.rnd(0, 360)
      enter_vect = player.pos() + vec2.newP(rnd.rnd(1500, 2000), ang)

      -- Safe FLF faction so that the player doesn't lose reputation
      -- with the FLF from doing this mission (in case the player made
      -- the bad decision to fly a Destroyer or something here).
      local f = faction.dynAdd("FLF", "FLF_safe", N_("FLF"))

      -- Create some pilots to go after the player
      local flt = fleet.add({1, 2}, {"Lancelot", "Vendetta"}, f, enter_vect,
            {_("FLF Lancelot"), _("FLF Vendetta")})
      -- Set hostile
      for i, p in ipairs(flt) do
         p:setHostile()
      end

      -- Get a far away position for fighting to happen
      local battle_pos = player.pos() +
            vec2.newP(rnd.rnd(4000, 5000), ang + 180)

      -- We'll put the FLF first
      enter_vect = battle_pos + vec2.newP(rnd.rnd(700, 1000), rnd.rnd(0, 360))

      fleet.add({1, 2, 2}, {"Pacifier", "Lancelot", "Vendetta"}, f, enter_vect,
            {_("FLF Pacifier"), _("FLF Lancelot"), _("FLF Vendetta")})

      -- Now the Dvaered
      enter_vect = battle_pos + vec2.newP(rnd.rnd(200, 300), rnd.rnd(0, 360))
      fleet.add({1, 1, 2, 2}, {"Dvaered Vigilance", "Dvaered Phalanx",
               "Dvaered Ancestor", "Dvaered Vendetta"},
            "Dvaered", enter_vect)

      -- Player should not be able to reland
      player.allowLand(false,
            _("The docking stabilizers have been damaged by weapons fire!"))
   end
end


function jumpout ()
   -- Storing the system the player jumped from.
   if system.cur() == destsys then
      var.pop("music_combat_force")
   end
end


function abort ()
   if system.cur() == destsys then
      var.pop("music_combat_force")
   end
   misn.finish(false)
end
