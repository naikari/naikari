--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Baron">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>29</priority>
  <chance>100</chance>
  <location>None</location>
 </avail>
 <notes>
  <done_evt name="Baroncomm_baron">Triggers</done_evt>
  <campaign>Baron Sauterfeldt</campaign>
 </notes>
</mission>
--]]
--[[
-- This is the first mission in the baron string.
--]]

local fmt = require "fmt"
local portrait = require "portrait"
require "missions/baron/common"
require "missions/neutral/common"


local hail_text = _([[Your viewscreen flashes to life. You're greeted by a nondescript pilot who doesn't seem to be affiliated with anyone you know.

"Hello there! I represent a man by the name of Baron Sauterfeldt. You may have heard of him in your travels? No? Well, I suppose you can't have it all. My employer is a moderately influential man, you see, and… but no, I'll not bore you with the details. The bottom line is, Lord Sauterfeldt is looking for hired help, and you seem like the sort he needs, judging by the work you did for, uh, the robot terry bears guy, or whatever it was."]])

local ask_text = _([[You inquire what it is exactly this Mr. Sauterfeldt needs from you. "Oh, nothing too terribly invasive, I assure you. His lordship currently needs a courier, nothing more. Erm, well, a courier who can't be traced back to him, if you understand what I mean. So what do you think? Sounds like a suitable job for you? The pay is good, much better than a bunch of junk from some toy factory. I've been informed that he is prepared to pay {credits} for the service."

You pause for a moment before responding to this sudden offer. It's not every day that people come to bring you work instead of making you look for it, but then again this job sounds like it could get you in trouble with the authorities if you're not careful. What will you do?]])

local accept_text = _([["Oh, that's great! Okay, here's what Baron Sauterfeldt needs you to do. You should fly to the Dvaered world {planet}. There's an art museum dedicated to one of the greatest Warlords in recent Dvaered history. I forget his name. Drovan or something? Durvan? Uh, anyway. This museum has a holopainting of the Warlord and his military entourage. His Lordship really wants this piece of art, but the museum has refused to sell it to him. So, we've sent agents to… appropriate… the holopainting."

You raise an eyebrow, but the pilot on the other end seems to be oblivious to the gesture. "So, right, you're going to {planet} to meet with our agents. You should find them in the spaceport bar. They'll get the item onto your ship, and you'll transport it out of Dvaered space. All quiet-like of course. No need for the authorities to know until you're long gone. Don't worry, our people are pros. It'll go off without a hitch, trust me."]])

local details_text = _([[You smirk at that. You know from experience that things seldom "go off without a hitch", and this particular plan doesn't seem to be all that well thought out. Still, it doesn't seem like you'll be in a lot of danger. If things go south, they'll go south well before you are even in the picture. And even if the authorities somehow get on your case, you'll only have to deal with the planetary police, not the entirety of House Dvaered. Worst-case scenario, a simple escape jump should be able to get you out of trouble.

You ask the Baron's messenger where this holopainting needs to be delivered. "His Lordship will be taking your delivery in the {system} system, aboard his ship the Pinnacle," he replies. "Once you arrive with the holopainting onboard your ship, hail the Pinnacle and ask for docking permission. They'll know who you are, so you should be allowed to dock. You'll be paid on delivery. Any questions?" You indicate that you know what to do, then cut the connection. Next stop: planet {planet}.]])

local approach_text = _([[The three shifty-looking patrons regard you with apprehension as you approach their table. Clearly they don't know who their contact is supposed to be. You decide to be discreet, asking them if they've ever heard of a certain Sauterfeldt. Upon hearing this, the trio visibly relaxes. They tell you that indeed they know the man you speak of, and that they have something of his in their possession. Things proceed smoothly from that point, and several minutes later you are back at your ship, preparing it for takeoff while you wait for the agents to bring you your cargo.

You're halfway thru your pre-flight security checks when the three appear in your docking hangar. They have a cart with them on which sits a rectangular chest as tall as a man and as long as two. Clearly this holopainting is fairly sizeable. As you watch them from your bridge's viewport, you can't help but wonder how they managed to get something that big out of a Dvaered museum unnoticed.]])

local chase_text = _([[As it turns out, they didn't. They have only just reached the docking bridge leading into your ship when several armed Dvaered security forces come bursting into the docking hangar. They spot the three agents and immediately open fire. One of them goes down, the others hurriedly push the crate over the bridge towards your ship. Despite the drastic change in the situation, you have time to note that the Dvaered seem more interested in punishing the criminals than retrieving their possession intact.

The second agent is caught by a Dvaered bullet, and topples off the docking bridge and into the abyss below. The third manages to get the cart with the chest into your airlock before catching a round with his chest as well. As the Dvaered near your ship, you seal the airlock, fire up your engines and punch it out of the docking hangar. Once you get into space, you may want to use an escape jump to get away from Varia before the security forces blow you to bits.]])

local baron_hail_text = _([[Your comm is answered by a communications officer on the bridge of the Pinnacle. You tell her you've got a delivery for the baron. She runs a few checks on a console off the screen, then tells you you've been cleared for docking and that the Pinnacle will be brought to a halt.]])

local board_text = _([[When you arrive at your ship's airlock, the chest containing the Dvaered holopainting is already being carted onto the Pinnacle by a pair of crewmen. "You'll be wanting your reward, eh? Come along", one of them yells at you. They both chuckle and head off down the corridor.

You follow the crewmen as they push the cart thru the main corridor of the ship. Soon you arrive at a door leading to a large, luxurious compartment. You can tell at a glance that these are Baron Sauterfeldt's personal quarters. The Baron himself is present, wearing a purple suit with a golden necktie, which you suspect may be actual gold. His fingers, meanwhile, are decorated with an assortment of shiny rings. Clearly, the Baron has a taste for the extravagant.

"Ah, my holopainting," he coos as the chest is carried into his quarters. "At last, I've been waiting forever." The Baron does not seem to be aware of your presence at all. He continues to fuss over the holopainting even as his crewman strip away the chest and lift the frame up to the wall.]])

local pay_text = _([[You look around his quarters. All sorts of exotic blades and other "art" works adorn his room, along with tapestries and various other holopaintings. You notice a bowl atop a velvet rug with "Fluffles" on it. Hanging above it seems to be a precariously balanced ancient blade.

The crewmen finally unpack the holopainting. You glance at the three-dimensional depiction of a Dvaered warlord, who seems to be discussing strategy with his staff. Unfortunately you don't seem to be able to appreciate Dvaered art, and you lose interest almost right away.

You cough to get the Baron's attention. He looks up, clearly displeased at the disturbance, then notices you for the first time. "Ah, of course," he grunts. "I suppose you must be paid for your service. Here, have some credits. Now leave me alone. I have art to admire." The Baron tosses you a couple of credit chips, and then you are once again air to him. Nonetheless, satisfied that you got your payment, you return to your ship and undock.]])

local refusetext = _([["Oh. Oh well, too bad. I'll just try to find someone who will take the job, then. Sorry for taking up your time. See you around!"]])

local comm1 = _("All troops, engage {shipname}! They have broken {planet} law!")

local misn_title = _("Baron")
local misn_desc = _("You've been hired as a courier for one Baron Sauterfeldt. Your job is to transport a holopainting from a Dvaered world to the Baron's ship.")

local credits = 200000

-- NPC stuff
local npc_desc = _("This must be one of the 'agents' hired by this Baron Sauterfeldt.")

log_text_succeed = _([[You helped Baron Dovai Sauterfeldt steal a Dvaered holopainting and were paid a sum of credits.]])
log_text_refuse = _([[You were offered a sketchy-looking job by a nondescript pilot, but you rudely refused to accept the job. It seems whoever the pilot worked for won't be contacting you again.]])


function create ()
   mispla, missys = planet.get("Varia")
   paypla, paysys = planet.get("Ulios")

   tk.msg("", hail_text)
   local c = tk.choice("", fmt.f(ask_text, {credits=fmt.credits(credits)}),
         _("Accept the job"), _("Politely decline"))
   if c == 1 then
      accept()
   else
      tk.msg("", refusetext)
      misn.finish(false)
   end
end

function accept()
   tk.msg("", fmt.f(accept_text, {planet=mispla:name()}))
   tk.msg("", fmt.f(details_text, {system=paysys:name(), planet=mispla:name()}))

   misn.accept()

   misn.setTitle(misn_title)
   misn.setReward(fmt.credits(credits))
   misn.setDesc(misn_desc)

   local osd_msg = {
      fmt.f(_("Land on {planet} ({system} system) and talk to Sauterfeldt's agents at the bar"),
            {planet=mispla:name(), system=missys:name()}),
      fmt.f(_("Fly to the {system} system"),
            {system=paysys:name()}),
      fmt.f(_("Hail Kahan Pinnacle (orbiting {planet})"),
            {planet=paypla:name()}),
      _("Dock with (board) Kahan Pinnacle"),
   }
   misn.osdCreate(misn_title, osd_msg)

   misn_marker = misn.markerAdd(missys, "low", mispla)

   talked = false
   tookoff = false
   stopping = false

   hook.land("land")
   hook.load("land")
   hook.enter("jumpin")
   hook.takeoff("takeoff")
end

function land()
   if planet.cur() == mispla and not talked then
      thief1 = misn.npcAdd("talkthieves", _("Sauterfeldt's agent"),
            portrait.get("Thief"), npc_desc)
      thief2 = misn.npcAdd("talkthieves", _("Sauterfeldt's agent"),
            portrait.get("Thief"), npc_desc)
      thief3 = misn.npcAdd("talkthieves", _("Sauterfeldt's agent"),
            portrait.get("Thief"), npc_desc)
   end
end

function jumpin()
   if talked then
      if system.cur() == paysys then
         misn.osdActive(3)
         pinnacle = pilot.add("Proteron Kahan", "Civilian",
               paypla:pos() + vec2.new(-400,-400), N_("Pinnacle"),
               {ai="trader"})
         pinnacle:setInvincible(true)
         pinnacle:setFriendly()
         pinnacle:setSpeedLimit(100)
         pinnacle:setHilight(true)
         pinnacle:setNoClear()
         pinnacle:control()
         pinnacle:moveto(paypla:pos() + vec2.new(400, -400), false)
         idlehook = hook.pilot(pinnacle, "idle", "idle")
         hook.pilot(pinnacle, "hail", "hail")
      else
         misn.osdActive(2)
      end
   end
end

function idle()
   pinnacle:moveto(paypla:pos() + vec2.new(400,  400), false)
   pinnacle:moveto(paypla:pos() + vec2.new(-400,  400), false)
   pinnacle:moveto(paypla:pos() + vec2.new(-400, -400), false)
   pinnacle:moveto(paypla:pos() + vec2.new(400, -400), false)
end

function hail()
   if talked then
      player.commClose()
      tk.msg("", baron_hail_text)
      pinnacle:taskClear()
      pinnacle:brake()
      pinnacle:setActiveBoard(true)
      hook.pilot(pinnacle, "board", "board")
      hook.rm(idlehook)
      misn.osdActive(4)
   end
end

function board(p, boarder)
   if boarder ~= player.pilot() then
      return
   end
   player.unboard()
   tk.msg("", board_text)
   tk.msg("", pay_text)
   player.pay(credits)
   pinnacle:setHilight(false)
   pinnacle:setActiveBoard(false)
   pinnacle:taskClear()
   pinnacle:land()
   baron_addLog(log_text_succeed)
   misn.finish(true)
end

function talkthieves()
   tk.msg("", approach_text)
   tk.msg("", chase_text)

   misn.npcRm(thief1)
   misn.npcRm(thief2)
   misn.npcRm(thief3)

   talked = true
   local c = misn.cargoNew(N_("The Baron's holopainting"),
         N_("A rectangular chest containing a holopainting."))
   carg_id = misn.cargoAdd(c, 0)

   misn.osdActive(2)
   misn.markerMove(misn_marker, paysys)

   player.takeoff()
end

function takeoff()
   if talked and not tookoff and system.cur() == missys then
      hook.timer(1, "dvtimer")
      player.allowLand(false, _("It's not safe to land right now."))
      tookoff = true
   end
end

function dvtimer()
   vendetta1 = pilot.add("Dvaered Vendetta", "Dvaered", mispla, nil,
         {ai="dvaered_norun"})
   vendetta2 = pilot.add("Dvaered Vendetta", "Dvaered", mispla, nil,
         {ai="dvaered_norun"})
   vendetta1:memory().nofactionhit = true
   vendetta2:memory().nofactionhit = true
   vendetta1:setHostile()
   vendetta1:setNoClear()
   vendetta2:setHostile()
   vendetta2:setNoClear()
   vendetta1:broadcast(
      fmt.f(comm1, {shipname=player.ship(), planet=mispla:name()}), true)
end

function abort()
   misn.finish(false)
end
