require("ai/tpl/generic")
require("ai/personality/patrol")
local fmt = require "fmt"

--[[

   Pirate AI

--]]

-- Settings
mem.aggressive = true
mem.safe_distance = 1800
mem.armour_run = 80
mem.armour_return = 100
mem.atk_board = true
mem.atk_kill = false
mem.careful = true


function create()
   local p = ai.pilot()
   local sprice = p:ship():price()
   ai.setcredits(rnd.rnd(0.05 * sprice, 0.1 * sprice))
   mem.kill_reward = rnd.rnd(0.05 * sprice, 0.1 * sprice)

   -- Deal with bribing
   mem.bribe = math.sqrt(p:stats().mass) * (300*rnd.rnd() + 850)
   bribe_prompt = {
      p_("bribe_prompt", "\"It'll cost you {credits} for me to ignore your pile of rubbish.\""),
      p_("bribe_prompt", "\"I'm in a good mood so I'll let you go for {credits}.\""),
      p_("bribe_prompt", "\"Send me {credits} or you're dead.\""),
      p_("bribe_prompt", "\"Pay up {credits} or it's the end of the line.\""),
      p_("bribe_prompt", "\"Your money or your life. {credits} and make the choice quickly.\""),
      p_("bribe_prompt", "\"Money talks bub. {credits} up front or get off my channel.\""),
      p_("bribe_prompt", "\"Shut up and give me your money! {credits} now.\""),
      p_("bribe_prompt", "\"You're either really desperate or really rich. {credits} or shut up.\""),
      p_("bribe_prompt", "\"If you're willing to negotiate I'll gladly take {credits} to not kill you.\""),
      p_("bribe_prompt", "\"You give me {credits} and I'll act like I never saw you.\""),
      p_("bribe_prompt", "\"So this is the part where you pay up or get shot up. Your choice. What'll be, {credits} or…?\""),
      p_("bribe_prompt", "\"Pay up or don't. {credits} now just means I'll wait till later to collect the rest.\""),
      p_("bribe_prompt", "\"This is a toll road, pay up {credits} or die.\""),
   }
   mem.bribe_prompt = fmt.f(bribe_prompt[rnd.rnd(1, #bribe_prompt)],
         {credits=fmt.credits(mem.bribe)})
   bribe_paid = {
      p_("bribe_paid", "\"You're lucky I'm so kind.\""),
      p_("bribe_paid", "\"Life doesn't get easier than this.\""),
      p_("bribe_paid", "\"Pleasure doing business.\""),
      p_("bribe_paid", "\"See you again, real soon.\""),
      p_("bribe_paid", "\"I'll be around if you get generous again.\""),
      p_("bribe_paid", "\"Lucky day, lucky day!\""),
      p_("bribe_paid", "\"And I didn't even have to kill anyone!\""),
      p_("bribe_paid", "\"See, this is how we become friends.\""),
      p_("bribe_paid", "\"Now if I kill you it'll be just for fun!\""),
      p_("bribe_paid", "\"You just made a good financial decision today.\""),
      p_("bribe_paid", "\"Know what? I won't kill you.\""),
      p_("bribe_paid", "\"Something feels strange. It's almost as if my urge to kill you has completely dissipated.\""),
      p_("bribe_paid", "\"Can I keep shooting you anyhow? No? You sure? Fine.\""),
      p_("bribe_paid", "\"And it only cost you an arm and a leg.\""),
   }
   mem.bribe_paid = bribe_paid[rnd.rnd(1,#bribe_paid)]

   -- Deal with refueling
   local standing = p:faction():playerStanding()
   mem.refuel = rnd.rnd(2000, 4000)
   if standing > 60 then
      mem.refuel = mem.refuel * 0.5
   end
   mem.refuel_msg = fmt.f(
      p_("refuel_prompt", "\"I'll take {credits} for some fuel.\""),
      {credits=fmt.credits(mem.refuel)})

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass thrû before leaving the system

   -- Finish up creation
   create_post()
end


local taunts_offense = {
   p_("taunt", "Prepare to be boarded!"),
   p_("taunt", "Give me your credits or die!"),
   p_("taunt", "Your ship's mine!"),
   p_("taunt", "Oh ho ho, what do I see here?"),
   p_("taunt", "You may want to send that distress signal now."),
   p_("taunt", "It's time to die."),
   p_("taunt", "Nothing personal, just business."),
   p_("taunt", "Nothing personal."),
   p_("taunt", "Just business."),
   p_("taunt", "Sorry, but I'm a private tracker."),
   p_("taunt", "Looks like you've picked the wrong sector of space!"),
   p_("taunt", "Give me your credits now if you want to live!"),
   p_("taunt", "Hey, space is a tough place where wimps eat flaming plasma death."),
}
local taunts_defense = {
   p_("taunt_defensive", "You dare attack me?!"),
   p_("taunt_defensive", "You think that you can take me on?"),
   p_("taunt_defensive", "Die!"),
   p_("taunt_defensive", "You'll regret this!"),
   p_("taunt_defensive", "You can either pray now or sit in hell later."),
   p_("taunt_defensive", "Game over, you're dead!"),
   p_("taunt_defensive", "Knock it off!"),
   p_("taunt_defensive", "Now you're in for it!"),
   p_("taunt_defensive", "Did you really think you would get away with that?"),
   p_("taunt_defensive", "I just painted this thing!"),
   p_("taunt_defensive", "I can't wait to see you burn!"),
   p_("taunt_defensive", "Okay, that's enough of that!"),
   p_("taunt_defensive", "I'm gonna torrent you to bits!"),
}
function taunt (target, offense)
   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   -- some taunts
   local taunts
   if offense then
      taunts = taunts_offense
   else
      taunts = taunts_defense
   end

   ai.pilot():comm(target, taunts[rnd.rnd(1, #taunts)])
end

