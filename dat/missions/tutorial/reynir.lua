--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Teddy Bears from Space">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>1</priority>
  <chance>100</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Frontier</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <faction>Soromid</faction>
  <faction>Za'lek</faction>
  <done>Tutorial Part 4</done>
  <cond>
   not system.cur():presences()["Pirate"]
   and planet.cur():class() ~= "0"
   and planet.cur():class() ~= "1"
   and planet.cur():class() ~= "2"
   and planet.cur():class() ~= "3"
   and planet.cur():services()["refuel"]
   and planet.cur():services()["commodity"]
   and (var.peek("tut_complete") == true
      or planet.cur():faction() ~= faction.get("Empire")
      or var.peek("tut_reynir_show") == true)
  </cond>
 </avail>
 <notes>
  <campaign>Tutorial</campaign>
 </notes>
</mission>
--]]
--[[

   MISSION: Teddy Bears from Space
   DESCRIPTION: An old man who owns a teddy bear factory wants to go to space

   The old man has elevated pressure in his cochlea so he can't go to
   space. He's getting old and wants to go to space before he dies. He
   owns a teddy bear factory and will pay you in teddy bears
   (Luxury Goods). Because of his illness, you can't leave the system.

   This mission serves as the tutorial for escape jumps.

--]]

local fmt = require "fmt"
local mh = require "misnhelper"
require "events/tutorial/tutorial_common"
require "missions/neutral/common"


bar_desc = _("You see an old man with a name tag that says \"Reynir\".")

misn_title = _("Teddy Bears from Space")
misn_reward = _("All of the teddy bears (Luxury Goods) your ship can hold")
misn_desc = _("Reynir wants to travel to space and will reward you richly.")

ask_text = _([[The man greets you with a tired, but warm expression. "Ah, hello there. You wouldn't happen to be that {player} fellow I've heard of, would you?" With a little surprise, you tell him that is indeed your name. "Ah, so you are! I've heard about you from an acquaintance, Mr. Ian Structure. Good things, I assure you. Tell me: do you like money?"]])

confirm_text = _([["Ever since I was a kid I've wanted to go to space. However, my doctor says I can't go to space because I have elevated pressure in my cochlea, a common disease around here.

"I am getting old now, as you can see. I want to travel to space while I'm still kicking, and I want you to fly me there. I own a robot teddy bear factory, so I can reward you richly: in exchange for just flying me around the system a bit, I will give you all of the robot teddy bears your ship can hold. They're worth their weight in gold, I assure you, some of the finest Luxury Goods on the market! Will you do it?"]])

accept_text = _([["Thank you so much! I'll wait in your ship. I think it would be too dangerous for me to enter hyperspace, so it's important that you remain in the {system} system."]])

localjump_text = _([[Reynir looks at {planet} in awe, taking in the view. "I'm actually in space," he mutters to himself. He clears his throat and speaks a little more loudly to you. "This is everything I dreamed it would be. Thank you for taking me out here. Seeïng my home planet from afar… it's magnificent!

"I have just one more request before we return. As I said, I don't think I can enter hyperspace, but I very much would like to experience what it's like to make a jump." He studies your ship's controls. "I believe pressing {local_jump_key} will initiate your ship's escape jump procedure. It's like a jump, but it doesn't actually take you into hyperspace; instead it just takes you a great distance away in the current system. Could you do an escape jump or two for me?"]])

done_text = _([[You look over at Reynir, who looks as if he just got off the greatest rollercoaster in the universe. "Fantastic," he mutters. "That was even more thrilling than I expected! Alright, I think that's enough. Let's go back to {planet}."]])

nospace_text = _([["Oh! Your ship is full! There's no way I could just give you nothing after all you've done for me. I'll tell you what: here's a credit chip worth {credits} instead."]])

lowspace_text = _([["Oh! I didn't realize you had so little cargo space on your ship! I'll tell you what: here's a credit chip worth {credits}, as well."]])

log_text = _([[You took an old man named Reynir on a ride in outer space. He was happy and gave you all of the robot teddy bears your ship could hold in exchange.]])


function create ()
   misn_base, misn_base_sys = planet.cur()
   if not misn.claim(misn_base_sys) then
      misn.finish(false)
   end

   -- Override delaying of this mission once it shows up (so if the
   -- player leaves Empire space, it can now spawn in Empire space).
   var.push("tut_reynir_show", true)

   misn.setNPC(_("Reynir"), "neutral/unique/reynir.png", bar_desc)

   took_off = false
   finished = false
end


function accept ()
   if tk.yesno("", fmt.f(ask_text, {player=player.name()}))
         and tk.yesno("", confirm_text) then
      misn.accept()

      tk.msg("", fmt.f(accept_text, {system=misn_base_sys:name()}))

      misn.setTitle(misn_title)
      misn.setReward(misn_reward)
      misn.setDesc(misn_desc)

      local osd_msg = {
         fmt.f(_("Fly to the {system} system\nDo not leave the {system} system"),
            {system=misn_base_sys:name()}),
         fmt.f(_("Land on {planet} ({system} system)"),
            {planet=misn_base:name(), system=misn_base_sys:name()}),
      }
      misn.osdCreate(misn_title, osd_msg)

      hook.takeoff("takeoff")
      hook.land("landed")
      hook.jumpin("jumpin")
   end

end


function takeoff()
   if not finished then
      localjump_hook = hook.input("localjump_input")
      if not took_off then
         timer_hook = hook.timer(5, "takeoff_timer")
      end
   end
end


function takeoff_timer()
   took_off = true

   tk.msg("", fmt.f(localjump_text, {planet=misn_base:name(), local_jump_key=tutGetKey("local_jump")}))

   local osd_msg = {
      fmt.f(_("Press {local_jump_key} to initiate an escape jump\nDo not leave the {system} system"),
         {local_jump_key=naev.keyGet("local_jump"),
            system=misn_base_sys:name()}),
      fmt.f(_("Land on {planet} ({system} system)"),
         {planet=misn_base:name(), system=misn_base_sys:name()}),
   }
   misn.osdCreate(misn_title, osd_msg)
end


function localjump_input(inputname, inputpress)
   if inputname ~= "local_jump" or not inputpress then
      return
   end

   finished = true

   hook.rm(timer_hook)
   timer_hook = hook.timer(8, "localjump_timer")
end


function localjump_timer()
   hook.rm(localjump_hook)

   tk.msg("", fmt.f(done_text, {planet=misn_base:name()}))
   misn.osdActive(2)
end


function landed()
   hook.rm(timer_hook)
   hook.rm(localjump_hook)

   if finished and planet.cur() == misn_base then
      local reward = player.pilot():cargoFree()
      local min_payment = 10
      local commprice = commodity.priceAtTime("Luxury Goods", planet.cur(),
            time.get())
      local extra_credits = math.max(0, (min_payment-reward) * commprice)

      local s = n_(
         [["Thank you so much! My ears are ringing a bit, but that might have been the best experience of my life! As promised, I'm transferring {amount} kt of robot teddy bears to your ship."]],
         [["Thank you so much! My ears are ringing a bit, but that might have been the best experience of my life! As promised, I'm transferring {amount} kt of robot teddy bears to your ship."]],
         reward)
      tk.msg("", fmt.f(s, {amount=fmt.number(reward)}))

      if reward <= 0 then
         tk.msg("", fmt.f(nospace_text, {credits=extra_credits}))
         player.pay(extra_credits)
      elseif reward < min_payment then
         tk.msg("", fmt.f(lowspace_text, {credits=extra_credits}))
         player.pay(extra_credits)
      end

      player.pilot():cargoAdd("Luxury Goods", reward)
      addMiscLog(log_text)
      misn.finish(true)
   end
end


function jumpin()
   mh.showFailMsg(fmt.f(_("You left the {system} system."),
         {system=misn_base_sys:name()}))
   misn.finish(false)
end
