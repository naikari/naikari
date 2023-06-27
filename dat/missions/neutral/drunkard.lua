--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Drunkard">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>25</priority>
  <chance>3</chance>
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

  Drunkard
  Author: geekt

  A drunkard at the bar has gambled his ship into hock, and needs you to do a mission for him.

]]--

local fmt = require "fmt"
require "missions/neutral/common"


-- Bar Description
bar_desc = _("You see a drunkard at the bar mumbling about how he was so close to getting his break.")

-- Mission Details
misn_title = _("Drunkard")
misn_reward = _("An undisclosed sum of credits")
misn_desc = _("You've decided to help some drunkard at the bar by picking up some goods for some countess. You're not sure why you accepted.")

ask_text = _([[You sit next to the drunk man at the bar and listen to him almost sob into his drink. "I was so close! I almost had it! I could feel it in my grasp! And then I messed it all up! Why did I do it? Hey, wait! You! You can help me!" The man grabs your collar. "How'd you like to make a bit of money and help me out? You can help me! It'll be good for you, it'll be good for me, it'll be good for everyone! Will you help me?"]])

yes_text = _([["Oh, thank the ancestors! I knew you would help me!" The man relaxes considerably and puts his arm around you. "Have a drink while I explain it to you.", he motions to the bartender to bring two drinks over. "You see, I know this countess, she's like...whoa...you know what I mean?", he nudges you. "But she's rich, like personal escort fleet rich, golden shuttles, diamond laser turrets rich.

Well, occasionally she needs some things shipped that she can't just ask her driver to go get for her. So, she asks me to go get this package. I don't know what it is; I don't ask; she doesn't tell me; that's the way she likes it. I had just got off this 72 hour run through pirate infested space though, and I was all hopped up on grasshoppers without a hatch to jump. So I decided to get a drink or two and hit the hay. Turned out those drinks er two got a little procreätion goin' on and turned into three or twelve. Maybe twenty. I don't know, but they didn't seem too liking to my gamblin', as next thing I knew, I was wakin' up with water splashed on my face, bein' tellered I gots in the hock, and they gots me ship, ye know? But hey, all yous gotta do is go pick up whatever it is she wants at {planet} in the {system} system. I doubt it's anything too hot, but I also doubt it's kittens and rainbows. All I ask is 25%. So just go get it, deliver it to {destplanet} in the {destsys} system, and don't ask any questions. And if she's there when you drop it off, just tell her I sent you. And don't you be lookin' at her too untoforward, or um, uh, you know what I mean." You figure you better take off before the drinks he's had take any more hold on him.]])

pickup_text = _([[You land on the planet and hand the manager of the docks the crumpled claim slip that the drunkard gave you, realizing now that you don't think he even told you his name. The man looks at the slip, and then gives you an odd look before motioning for the dockworkers to load up the cargo that's brought out after he punches in a code on his electronic pad.]])

deliver_text = _([[You finally arrive at your destination, bringing your ship down to land right beside a beautiful woman with long blonde locks in a long extravagant gown. You know this must be the countess, but you're unsure how she knew you were going to arrive, to be waiting for you. When you get out of your ship, you notice there are no dock workers anywhere in sight, only a group of heavily armed private militia that weren't there when you landed.

You gulp as she motions to them without showing a hint of emotion. In formation, they all raise their weapons. As you think your life is about to end, every other row turns and hands off their weapon, and then marches forward and quickly unloads your cargo onto a small transport carrier, and march off. The countess smirks at you and winks before walking off. You breath a sigh of relief, only to realize you haven't been paid. As you walk back onto your ship, you see a card laying on the floor with simply her name, Countess Amelia Vollana.]])

pay_text = _([[As you finish your takeoff procedures and once again enter the cold black of space, you can't help but feel relieved. You might not have gotten paid, but you're just glad to still be alive. Just as you're about to punch it to the jump gate to get far away from whatever you just dropped off, you see the flashing light of an incoming hail and answer it.

"Hello again. It's Willie. I'm just here to inform you that the countess has taken care of your payment and transferred it to your account. And don't worry about me, the countess has covered my portion just fine!"

You check your account balance as he closes the comm channel to find yourself {credits} richer. Just being alive felt good, but this feels better. You can't help but think that she might have given him more than just the 25% he was asking for, judging by his sunny disposition. At least you have your life, though!]])

log_text = _([[You helped some drunkard deliver goods for some countess. You thought you might get killed along the way, but you survived and got a generous payment.]])


function create ()
   -- Note: this mission does not make any system claims.
   pickupWorld, pickupSys = planet.getLandable("Vertigo")
   delivWorld, delivSys = planet.getLandable("Darkshed")
   if pickupWorld == nil or delivWorld == nil then -- Must be landable
      misn.finish(false)
   end
   origWorld, origSys = planet.cur()

   misn.setNPC(_("Drunkard"), "neutral/unique/drunkard.png", bar_desc)

   cargoAmount = 45
   payment = 400000
end

function accept ()
   if not tk.yesno("", ask_text) then
      misn.finish()
   end

   misn.accept()

   tk.msg("", fmt.f(yes_text,
         {planet=pickupWorld:name(), system=pickupSys:name(),
            destplanet=delivWorld:name(), destsys=delivSys:name()}))

   misn.setTitle(misn_title)
   misn.setReward(misn_reward)
   misn.setDesc(misn_desc)

   local osd_desc = {
      fmt.f(
         n_("Land on {planet} ({system} system) to pick up {tonnes} kt of cargo",
            "Land on {planet} ({system} system) to pick up {tonnes} kt of cargo",
            cargoAmount),
         {planet=pickupWorld:name(), system=pickupSys:name(),
            tonnes=fmt.number(cargoAmount)}),
      fmt.f(_("Land on {planet} ({system} system)"),
         {planet=delivWorld:name(), system=delivSys:name()}),
   }
   misn.osdCreate(misn_title, osd_desc)

   pickedup = false
   droppedoff = false

   marker = misn.markerAdd(pickupSys, "low")

   hook.land("land")
end

function land ()
   if planet.cur() == pickupWorld and not pickedup then
      if player.pilot():cargoFree() < cargoAmount then
         local required_text = n_(
               "You don't have enough cargo space to pick up the goods. The goods weigh {required} kt. ",
               "You don't have enough cargo space to pick up the goods. The goods weigh {required} kt. ",
               cargoAmount)
         local shortfall = cargoAmount - player.pilot():cargoFree()
         local shortfall_text = n_(
               "You need {shortfall} kt more of empty space.",
               "You need {shortfall} kt more of empty space.",
               shortfall)
         tk.msg("", fmt.f(required_text .. shortfall_text,
               {required=fmt.number(cargoAmount),
                  shortfall=fmt.number(shortfall)}))
      else
         tk.msg("", pickup_text)
         local c = misn.cargoNew(N_("Goods"),
               N_("Some sort of cargo you picked up for some countess."))
         cargoID = misn.cargoAdd(c, cargoAmount)
         pickedup = true

         misn.markerMove(marker, delivSys)

         misn.osdActive(2)
      end
   elseif planet.cur() == delivWorld and pickedup and not droppedoff then
      tk.msg("", deliver_text)
      misn.cargoRm(cargoID)

      misn.markerRm(marker)
      misn.osdDestroy()

      droppedoff = true
      hook.takeoff("takeoff")
   end
end

function takeoff()
   if system.cur() == delivSys and droppedoff then
      player.pay(payment)
      tk.msg("", fmt.f(pay_text, {credits=fmt.credits(payment)}))
      addMiscLog(log_text)
      misn.finish(true)
   end
end
