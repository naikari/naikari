--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Za'lek Shipping Delivery">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>25</priority>
  <chance>25</chance>
  <location>Bar</location>
  <planet>Niflheim</planet>
 </avail>
</mission>
--]]
--[[

Za'lek Cargo Run. adapted from Drunkard Mission
]]--

local fmt = require "fmt"
require "missions/zalek/common"


-- Bar Description
bar_desc = _("This Za'lek scientist seems to be looking for someone.")

-- Mission Details
misn_title = _("Za'lek Shipping Delivery")
misn_reward = _("A handsome payment.")
misn_desc = _("You agreed to help a Za'lek scientist pick up some cargo way out in the sticks. Hopefully this'll be worth it.")

-- OSD
OSDtitle = _("Za'lek Cargo Monkey")
OSDdesc = {}
OSDdesc[1] = _("Land on %s (%s system) to pick up some equipment")
OSDdesc[2] = _("Land on %s (%s system) to deliver the cargo")

payment = 2500000

-- Cargo Details
cargo = "Equipment"
cargoAmount = 20

text = {}   --mission text

text[1] = _([[This Za'lek scientist seems to be looking for someone. As you approach, he begins to speak. "Excuse me, but do you happen to know a ship captain who can help me with something?"]])

text[2] = _([[You say that he is looking at one right now. Rather surprisingly, he laughs slightly, looking relieved. "Thank you, captain! I was hoping that you could help me. My name is Dr. Andrej Logan. The job will be a bit dangerous, but I will pay you handsomely for your services.

"I need a load of equipment that is stuck at %s in the %s system. Unfortunately, that requires going through the pirate-infested fringe space between the Empire, Za'lek and Dvaered. Seeing as no one can agree whose responsibility it is to clean the vermin out, the pirates have made that route dangerous to traverse. I have had a devil of a time finding someone willing to take the mission on. Once you get the equipment, please deliver it to %s in the %s system. I will meet you there."]])

text[3] = _([[Once planetside, you find the acceptance area and type in the code Dr. Logan gave you to pick up the equipment. Swiftly, a group of droids backed by a human overseer loads the heavy reinforced crates on your ship and you are ready to go.]])

text[4] = _([[You land on the Za'lek planet and find your ship swarmed by dockhands in red and advanced-looking droids rapidly. They unload the equipment and direct you to a rambling edifice for payment.

When you enter, your head spins at a combination of the highly advanced and esoteric-looking tech so casually on display as well as the utter chaos of the facility. It takes a solid ten hectoseconds before someone comes to you asking what you need, looking quite frazzled. You state that you delivered some equipment and are looking for payment. The man types in a wrist-pad for a few seconds and says that the person you are looking for has not landed yet. He gives you a code to act as a beacon so you can catch the shuttle in-bound.]])

text[5] = _([[You feel a little agitated as you leave the atmosphere, but you guess you can't blame the scientist for being late, especially given the lack of organization you've seen on the planet. Suddenly, you hear a ping on your console, signifying that someone's hailing you.]])

pay_text = _([["Hello again. It's Dr. Logan. I am terribly sorry for the delay. As agreed, you will be paid your fee. I am pleased by your help, captain; I hope we meet again."

You check your account balance as he closes the comm channel to find yourself {credits} richer. A good compensation indeed. You feel better already.]])

text[9] = _([[You don't have enough cargo space to accept this mission.]])

log_text = _([[You helped a Za'lek scientist deliver some equipment and were paid generously for the job.]])


function create ()
   -- Note: this mission does not make any system claims.

   misn.setNPC(_("Za'lek Scientist"), "zalek/unique/logan.png", bar_desc)  -- creates the scientist at the bar

   -- Planets
   pickupWorld, pickupSys  = planet.getLandable("Vilati Vilata")
   delivWorld, delivSys    = planet.getLandable("Oberon")
   if pickupWorld == nil or delivWorld == nil then -- Must be landable
      misn.finish(false)
   end
   origWorld, origSys      = planet.cur()

--   origtime = time.get()
end

function accept ()
   if not tk.yesno("", text[1]) then
      misn.finish()

   elseif player.pilot():cargoFree() < 20 then
      tk.msg("", text[9])  -- Not enough space
      misn.finish()

   else
      misn.accept()

      -- mission details
      misn.setTitle(misn_title)
      misn.setReward(misn_reward)
      misn.setDesc(misn_desc:format(pickupWorld:name(), pickupSys:name(), delivWorld:name(), delivSys:name()))

      -- OSD
      OSDdesc[1] =  OSDdesc[1]:format(pickupWorld:name(), pickupSys:name())
      OSDdesc[2] =  OSDdesc[2]:format(delivWorld:name(), delivSys:name())

      pickedup = false
      droppedoff = false

      marker = misn.markerAdd(pickupSys, "low")  -- pickup
      misn.osdCreate(OSDtitle, OSDdesc)  -- OSD

      tk.msg("", text[2]:format(pickupWorld:name(), pickupSys:name(), delivWorld:name(), delivSys:name()))

      landhook = hook.land ("land")
      flyhook = hook.takeoff ("takeoff")
   end
end

function land ()
   if planet.cur() == pickupWorld and not pickedup then
      if player.pilot():cargoFree() < 20 then
         tk.msg("", text[9])  -- Not enough space
         misn.finish()

      else

         tk.msg("", text[3])
         cargoID = misn.cargoAdd(cargo, cargoAmount)  -- adds cargo
         pickedup = true

         misn.markerMove(marker, delivSys)  -- destination

         misn.osdActive(2)  --OSD
      end
   elseif planet.cur() == delivWorld and pickedup and not droppedoff then
      tk.msg("", text[4])
      misn.cargoRm (cargoID)

      misn.markerRm(marker)
      misn.osdDestroy ()

      droppedoff = true
   end
end

function takeoff()
   if system.cur() == delivSys and droppedoff then

      logan = pilot.add("Gawain", "Civilian", player.pos() + vec2.new(-500,-500), _("Civilian Gawain"))
      logan:rename(_("Dr. Logan"))
      logan:setFaction("Za'lek")
      logan:setFriendly()
      logan:setInvincible()
      logan:setVisplayer()
      logan:setHilight(true)
      logan:hailPlayer()
      logan:control()
      logan:moveto(player.pos() + vec2.new(150, 75), true)
      tk.msg("", text[5])
      hailhook = hook.pilot(logan, "hail", "hail")
   end
end

function hail()
   player.commClose()
   tk.msg("", fmt.f(pay_text, {credits=fmt.credits(payment)}))
   player.pay(payment)
   logan:setVisplayer(false)
   logan:setHilight(false)
   logan:setInvincible(false) 
   logan:hyperspace()
   faction.modPlayer("Za'lek", 1)
   zlk_addMiscLog(log_text)
   misn.finish(true)
end

function abort()
   hook.rm(landhook)
   hook.rm(flyhook)
   if hailhook then hook.rm(hailhook) end
   misn.finish()
end
