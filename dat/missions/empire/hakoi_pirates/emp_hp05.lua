--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Hakoi Pirates Infiltration">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <cond>
   faction.playerStanding("Empire") &gt;= 10
   and faction.playerStanding("Pirate") &lt; 0
   and not player.misnActive("Fake ID")
   and not var.peek("no_fake_id")
  </cond>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Emperor's Fist</planet>
  <done>Hakoi Needs House Dvaered</done>
 </avail>
 <notes>
  <campaign>Hakoi Pirates</campaign>
 </notes>
</mission>
--]]
--[[

   MISSION: Pirate Infiltration
   DESCRIPTION:
      Ian Structure volunteers to assist the player in a grand operation
      to infiltrate into the ranks of the pirates.

--]]

local fmt = require "fmt"
local pilotname = require "pilotname"
local portrait = require "portrait"
require "missions/empire/common"


local ask_text = _([[Since you don't see Commander Soldner around, you decide to approach Ian Structure and see what he wants. He greets you and sits you down. "I've heard about what you've been working on for the Empire," he begins. "Look, {player}, I… I want to help, and I think I might be able to. I just need you to keep it a secret; if they find out I helped you… I don't want to th-think about what c-could happen." He nervously straightens his necktie.

"I don't know if you've ever been to {planet} in the {system} system. I, um… can pull some strings to get you connected with someone there. Someone on the inside, you know? They'd just think you're a… hired hand. What you do with that connection would be up to you. Would you be interested?"]])

local accept_text = _([[As you accept Ian Structure's offer, he trepidly nods and immediately goes into his wrist computer. After a few minutes, he looks back at you and speaks softly. "Alright. I've got you a job with a businessman named Devin Filer. Some kind of delivery from this planet for {credits}. Hopefully nothing too hot, but with these types, there's no guarantee of that. Regardless, it's essential that you don't arouse the suspicion of your 'accomplices'. If they detect even a slight hint of a sign that this is a sting operation, they'll cancel the delivery, and I don't know if I'll be able to get you connected again."

"I can help with that," a voice whispers from behind. You and Ian Structure flinch at the sound of the voice before turning to see the origin of the voice. You see a plainly dressed man. After staring for a moment, you realize you recognize him: Lieutenant Chesc, but out of his uniform. You whisper this out loud instinctively. "Sorry to startle you," he says. "The Commander heard what you two were discussing and sent me to help."]])

local prepare_text = _([[You ask how Commander Soldner heard your conversation. "I'm sorry, that's classified," Chesc answers. "I'm sure the Commander would be happy to tell you in private later. Regardless, As you said, Mr. Ian Structure, we mustn't arouse suspicion with an operation like this. To assist, {player}, we will fudge your identification so that pirates will believe you to be a wanted criminal among their ranks. In short, you will appear to be a pirate using a fake ID to smuggle contraband materials.

"Of course, there's a great risk of danger to you from this, {player}. To complete the illusion, we must keep the Imperial military in the dark. That means Imperial pilots will attack you on sight with intent to kill. You will also have restricted access to landing on Imperial planets and stations. In short, it will truly be as if you are a wanted criminal."]])

local ask_pirate_name_text = _([[Lieutenant Chesc pushes some buttons on his wrist computer. He then looks back at you. "{player}, I need to put in a fake name for you to use while you pretend to be a pirate. What would you like it to be? If you're not sure, I can assign one randomly for you."]])

local pirate_name_same_text = _([["I'm sorry, {player}, but you really must use a different name than your real name for this operation. Would you choose something else, please?"]])

local pirate_name_confirm_text = _([["Alright." Lieutenant Chesc punches something into his wrist computer. "As of now, you are known as {player_pirate_name}. The pirates should accept you as one of their own now, and Imperial forces will treat you as an enemy of the Empire. There will even officially be a bounty on your head, so be careful." You nod in understanding and Chesc puts his hand on your shoulder. "Good luck, {player} – or, rather, {player_pirate_name}. I know you can do it."

"Your 'accomplices' will discretely load the cargo onto your ship before you take off," Ian Structure adds as Chesc leaves. "Be careful out there and don't be afraid to use an escape jump if you're in a pinch against the Imperial military. I'll see you later. As the Lieutenant said, good luck."]])

local finish_text = _([[You arrive at {planet} with the cargo and meet a man at the spaceport with a suit and tie, neat hair, and a wide grin. He offers your hand for you to shake. "You must be {player_pirate_name}. Well met. I trust you have the cargo I asked for." You shake his hand and ask if he's Devin Filer, the businessman who hired you. "Oh, please, call me Dev," he responds.

He sends in some accomplices who retrieve the package from your cargo hold. "You must be very good at your job if you were able to obtain this from the Imperial interior so quickly." You tell him an exaggerated account of your encounters with Imperial patrols in an attempt to impress him. "Ah, and you managed to break thru all of that. Splendid! Why, I think you might be the perfect candidate for another… job. Meet me at the bar if you're interested." He and his accomplices leave you at the spaceport. It looks like the ruse worked. You hope this next "job" gives you a useful lead.]])

local misn_desc = _("You have accepted a shady job to deliver cargo to {planet} in the {system} system in an attempt to infiltrate the pirates' ranks and find out what they're up to. As a part of this mission, you have been given a false ID as a wanted pirate called {player_pirate_name}")

local credits = 100000

local log_text = _([[You are engaging in an undercover operation in an attempt to infiltrate the pirates' ranks. So far, it seems to have worked; you completed a job for a shady businessman called Dev Filer, who wants to speak to you again on {planet} in the {system} system.]])


function create()
   misplanet, missys = planet.getLandable("Darkshed")
   if misplanet == nil then
      misn.finish(false)
   end

   misn.setNPC(_("Ian Structure"), "neutral/unique/youngbusinessman.png",
         _("You don't see Commander Soldner around anywhere, but you see Ian Structure sitting alone and gesturing to you. He looks nervous."))
end


function accept()
   local playername = player.name()
   local text = fmt.f(ask_text,
         {player=playername, planet=misplanet:name(), system=missys:name()})

   if tk.yesno("", text) then
      tk.msg("", fmt.f(accept_text,
            {player=playername, credits=fmt.credits(credits)}))
      tk.msg("", fmt.f(prepare_text, {player=playername}))

      -- Have the player choose a pirate name to use.
      local pirate_name = tk.input("", 1, 60,
            fmt.f(ask_pirate_name_text, {player=playername}))
      while pirate_name == playername do
         pirate_name = tk.input("", 1, 60,
               fmt.f(pirate_name_same_text, {player=playername}))
      end
      -- If the dialog was canceled, auto-generate a pirate name.
      if pirate_name == nil then
         pirate_name = pilotname.pirate()
      end

      -- Store the chosen player pirate name and send the player off.
      var.push("hp_pirate_name", pirate_name)
      tk.msg("", fmt.f(pirate_name_confirm_text,
            {player=playername, player_pirate_name=pirate_name}))

      misn.accept()

      misn.setTitle(_("Pirate Infiltration"))
      misn.setReward(fmt.credits(credits))
      misn.setDesc(fmt.f(misn_desc,
            {planet=misplanet:name(), system=missys:name(),
               player_pirate_name=pirate_name}))

      marker = misn.markerAdd(missys, "plot", misplanet)

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system)"),
               {planet=misplanet:name(), system=missys:name()}),
      }
      misn.osdCreate(_("Pirate Infiltration"), osd_desc)

      -- Set no_fake_id to block fake ID missions from spawning.
      var.push("no_fake_id", true)

      -- Store true reputation and set fake reputation for each faction.
      -- We choose "random-looking" arbitrary negative numbers for each
      -- faction so it looks like the profile of a real pirate.
      local f = faction.get("Empire")
      var.push("hp_rep_empire", faction.playerStanding(f))
      f:setPlayerStanding(-19)

      local f = faction.get("Dvaered")
      var.push("hp_rep_dvaered", faction.playerStanding(f))
      f:setPlayerStanding(-5)

      local f = faction.get("Za'lek")
      var.push("hp_rep_zalek", faction.playerStanding(f))
      f:setPlayerStanding(-8)

      local f = faction.get("Sirius")
      var.push("hp_rep_sirius", faction.playerStanding(f))
      f:setPlayerStanding(-16)

      local f = faction.get("Goddard")
      var.push("hp_rep_goddard", faction.playerStanding(f))
      f:setPlayerStanding(-7)

      local f = faction.get("Soromid")
      var.push("hp_rep_soromid", faction.playerStanding(f))
      f:setPlayerStanding(-6)

      local f = faction.get("Pirate")
      var.push("hp_rep_pirate", faction.playerStanding(f))
      f:setPlayerStanding(9)

      hook.land("land")
   else
      misn.finish()
   end
end


function land()
   if planet.cur() == misplanet then
      local pirate_name = var.peek("hp_pirate_name") or player.name()
      tk.msg("", fmt.f(finish_text, {player_pirate_name=pirate_name}))

      player.pay(credits)
      faction.get("Pirate"):modPlayer(5)
      emp_addShippingLog(fmt.f(log_text,
            {planet=misplanet:name(), system=missys:name()}))
      misn.finish(true)
   end
end


function abort()
   var.pop("no_fake_id")

   local f = faction.get("Empire")
   local rep = var.peek("hp_rep_empire") or faction.playerStanding(f)
   var.pop("hp_rep_empire")
   f:setPlayerStanding(rep)

   local f = faction.get("Dvaered")
   local rep = var.peek("hp_rep_dvaered") or faction.playerStanding(f)
   var.pop("hp_rep_dvaered")
   f:setPlayerStanding(rep)

   local f = faction.get("Za'lek")
   local rep = var.peek("hp_rep_zalek") or faction.playerStanding(f)
   var.pop("hp_rep_zalek")
   f:setPlayerStanding(rep)

   local f = faction.get("Sirius")
   local rep = var.peek("hp_rep_sirius") or faction.playerStanding(f)
   var.pop("hp_rep_sirius")
   f:setPlayerStanding(rep)

   local f = faction.get("Goddard")
   local rep = var.peek("hp_rep_goddard") or faction.playerStanding(f)
   var.pop("hp_rep_goddard")
   f:setPlayerStanding(rep)

   local f = faction.get("Soromid")
   local rep = var.peek("hp_rep_soromid") or faction.playerStanding(f)
   var.pop("hp_rep_soromid")
   f:setPlayerStanding(rep)

   local f = faction.get("Pirate")
   local rep = var.peek("hp_rep_pirate") or faction.playerStanding(f)
   var.pop("hp_rep_pirate")
   f:setPlayerStanding(rep)
end
