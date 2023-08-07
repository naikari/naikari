--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Drinking Aristocrat">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>29</priority>
  <chance>5</chance>
  <cond>
   var.peek("tut_complete") == true
   or planet.cur():faction() ~= faction.get("Empire")
  </cond>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Goddard</faction>
  <faction>Sirius</faction>
  <faction>Za'lek</faction>
 </avail>
</mission>
--]]
--[[

  Drinking Aristocrat
  Author: geekt
  Idea from todo list.

  An aristocrat wants a specific drink which he recalls from a certain planet and will pay handsomely if you bring it. When you get to said planet it turns out the drink isn't served there but the bartender gives you a hint. You are then hinted until you end up getting the drink and bringing it back.

Thank you to Bobbens, Deiz, BTAxis, and others that have helped me with learning to use Lua and debugging my scripts in the IRC channel. Thanks as well to all those that have contributed to Naev and made it as great as it is today, and continue to make it better every day.

]]--

local fmt = require "fmt"
require "jumpdist"
require "missions/neutral/common"


bar_desc = _("You see an aristocrat sitting at a table in the middle of the bar, drinking a swirling concoction in a martini glass with a disappointed look on his face every time he takes a sip.")

-- Mission Details
misn_title = _("Drinking Aristocrat")
misn_reward = _("He will pay handsomely.")
misn_desc = _("You've been tasked with finding a special drink for a snobby aristocrat.")

-- defines Previous Planets table
prevPlanets = {}
prevPlanets.__save = true

payment = 200000

ask_text = _([[You begin to approach the aristocrat. Next to him stands a well dressed and muscular man, perhaps his assistant, or maybe his bodyguard, you're not sure. When you get close to his table, he begins talking to you as if you work for him. "This simply will not do. When I ordered this 'drink', if you can call it that, it seemed interesting. It certainly doesn't taste interesting. It's just bland. The only parts of it that are in any way interesting are not at all pleasing. It just tastes so… common.

You know what I would really like? There was this drink at a bar on, what planet was that? Damien, do you remember? The green drink with the red fruit shavings." Damien looks down at him and seems to think for a second before shaking his head. "I believe it might have been {planet} in the {system} system. The drink was something like an Atmospheric Reëntry or Gaian Bombing or something. It's the bar's specialty. They'll know what you're talking about. You should go get me one. Can you leave right away?"]])

yes_text = _([["Oh, good! Of course you will be paid handsomely for your efforts. Let's say, {credits}. I trust you can figure out how to get it here intact on your own." The aristocrat goes back to sipping his drink, making an awful face every time he tastes it, ignoring you. You walk away, a bit confused.]])

no_text = _([["What do you mean, you can't leave right away? Then why even bother? Remove yourself from my sight." The aristocrat makes a horrible face, and sips his drink, only to look even more disgusted. He puts his drink back on the table and motions to the bartender, ignoring you beyond now.]])

cluetxt = _([[You walk into the bar and approach the bartender. You describe the drink, but the bartender doesn't seem to know what you're talking about. There is another bartender that they think may be able to help you thô, at {planet} in the {system} system.]])

moreinfotxt = {}
moreinfotxt[1] = _([[You walk in and see someone behind the bar. When you approach and describe the drink, they tell you that the drink isn't the specialty of any one bar, but actually the specialty of a bartender who used to work here. "It's called a Swamp Bombing. I don't know where they work now, but they started working at the bar on {planet} in the {system} system after they left here. Good luck!" With high hopes, you decide to head off to there.]])
moreinfotxt[2] = _([[You walk in and see someone behind the bar. When you approach and describe the drink, they tell you that the drink isn't the specialty of any one bar, but actually the specialty of a bartender who used to work here. "It's called a Swamp Bombing. I don't know where he works now, but he started working at the bar on {planet} in the {system} system after he left here. Good luck!" With high hopes, you decide to head off to there.]])
moreinfotxt[3] = _([[You walk in and see someone behind the bar. When you approach and describe the drink, they tell you that the drink isn't the specialty of any one bar, but actually the specialty of a bartender who used to work here. "It's called a Swamp Bombing. I don't know where she works now, but she started working at the bar on {planet} in the {system} system after she left here. Good luck!" With high hopes, you decide to head off to there.]])

exworktxt = _([[You walk into the bar fully confident that this is the bar. You walk up to the bartender and ask for a Swamp Bombing. "A wha???" Guess this isn't the right bar. You get another possible clue, {planet} in the {system} system, and head on your way.]])

worktxt = {}
worktxt[1] = _([[You walk into the bar and know instantly that you are finally here! This is the place! You walk up to the bartender, who smiles. This has to be them. You start to describe the drink to them and they interrupt. "A Swamp Bombing. Of course, that's my specialty." You ask if they can make it to go, prompting a bit of a chuckle. "Sure, why not?"

Just as they're about to start making it, thô, you stop them and say you'll have one here after all. As long as you've come all this way, you might as well try it. You're amazed at how quickly and gracefully their trained hands move, flipping bottles and shaking various containers. Before you know it, they've set a drink before you and closed another container to take with you. You taste it expecting something incredible. It's alright, but you doubt it was worth all this trouble.]])
worktxt[2] = _([[You walk into the bar and know instantly that you are finally here! This is the place! You walk up to the bartender, who smiles. This has to be him. You start to describe the drink to them and he interrupts. "A Swamp Bombing. Of course, that's my specialty." You ask if he can make it to go, prompting a bit of a chuckle. "Sure, why not?"

Just as he's about to start making it, thô, you stop him and say you'll have one here after all. As long as you've come all this way, you might as well try it. You're amazed at how quickly and gracefully his trained hands move, flipping bottles and shaking various containers. Before you know it, he's set a drink before you and closed another container to take with you. You taste it expecting something incredible. It's alright, but you doubt it was worth all this trouble.]])
worktxt[3] = _([[You walk into the bar and know instantly that you are finally here! This is the place! You walk up to the bartender, who smiles. This has to be her. You start to describe the drink to her and she interrupts. "A Swamp Bombing. Of course, that's my specialty." You ask if she can make it to go, prompting a bit of a chuckle. "Sure, why not?"

Just as she's about to start making it, thô, you stop her and say you'll have one here after all. As long as you've come all this way, you might as well try it. You're amazed at how quickly and gracefully her trained hands move, flipping bottles and shaking various containers. Before you know it, she's set a drink before you and closed another container to take with you. You taste it expecting something incredible. It's alright, but you doubt it was worth all this trouble.]])

finishedtxt = _([["Ahh! I was just thinking how much I wanted one of those drinks! I'm so glad that you managed to find it. You sure seemed to take your time thô." You give him his drink and tell him that it wasn't easy, and how many systems you had to go thru. "Hmm. That is quite a few systems. No reason for you to be this late thô." He takes a sip from his drink. "Ahh! That is good thô. I suppose you'll be wanting your payment. You did go thru a lot of trouble. Very well, I suppose the extra effort makes up for the late delivery. I promised {credits}, so here you go."

Considering the amount of effort that you went thru, you feel almost cheated. You don't feel like arguing with the snobby aristocrat to try to get a bonus, thô, so you just leave him to his drink without another word. It's probably the most that anyone's ever paid for a drink like that anyway.]])

log_text = _([[You delivered a special drink called a Swamp Bombing to an aristocrat.]])


function create()
   misn.setNPC( _("Drinking Aristocrat"), "neutral/unique/aristocrat.png", bar_desc )

   startplanet, startsys = planet.cur()

   prevPlanets[1] = startplanet
   prevPlanets.__save = true

   numjumps = 0

   -- chooses the planet
   clueplanet, cluesys = getclueplanet(1, 3)
   prevPlanets[#prevPlanets+1] = clueplanet
end

function accept ()
   if not tk.yesno("", fmt.f(ask_text,
         {planet=clueplanet:name(), system=cluesys:name()})) then
      tk.msg("", no_text)
      misn.finish()

   else
      misn.accept()

      landmarker = misn.markerAdd(cluesys, "low", clueplanet)

      -- mission details
      misn.setTitle(misn_title)
      misn.setReward(fmt.credits(payment))
      misn.setDesc(misn_desc)

      tk.msg("", fmt.f(yes_text, {credits=fmt.credits(payment)}))

      -- how many systems you'll have to run thru
      numclues = 1
      numexwork = 2

      -- final bartender data
      fintendergen = rnd.rnd(1,3)

      -- hooks
      landhook = hook.land ("land", "bar")
      takeoffhook = hook.takeoff ("takeoff")
   end
end

function land ()
   if planet.cur() == clueplanet then
      if numclues > 0 then   -- first clue
         numclues = numclues - 1
         numjumps = numjumps + 1

         -- next planet
         clueplanet, cluesys = getclueplanet(1, 3)
         misn.markerMove(landmarker, cluesys, clueplanet)
         prevPlanets[#prevPlanets+1] = clueplanet

         tk.msg("", fmt.f(cluetxt,
               {planet=clueplanet:name(), system=cluesys:name()}))

      else
         if not foundexwork then   -- find out that it's a bartender's specialty
            foundexwork = true
            numexwork = numexwork - 1
            numjumps = numjumps + 1

            -- next planet
            clueplanet, cluesys = getclueplanet(1, 5)
            misn.markerMove(landmarker, cluesys, clueplanet)
            prevPlanets[#prevPlanets+1] = clueplanet

            tk.msg("", fmt.f(moreinfotxt[fintendergen],
                  {planet=clueplanet:name(), system=cluesys:name()}))

         else   -- find another bar that the bartender used to work at
            if numexwork > 0 then
               numexwork = numexwork - 1

               -- next planet
               clueplanet, cluesys = getclueplanet(1, 5)
               misn.markerMove(landmarker, cluesys, clueplanet)
               prevPlanets[#prevPlanets+1] = clueplanet

               tk.msg("", fmt.f(exworktxt,
                     {planet=clueplanet:name(), system=cluesys:name()}))

            elseif not hasDrink then  -- get the drink
               hasDrink = true

               tk.msg("", worktxt[fintendergen])

               misn.markerMove(landmarker, startsys, startplanet)
            end
         end
      end
   elseif hasDrink and planet.cur() == startplanet then
      tk.msg("", fmt.f(finishedtxt, {credits=fmt.credits(payment)}))
      player.pay( payment )

      hook.rm(landhook)
      hook.rm(takeoffhook)
      addMiscLog( log_text )
      misn.finish( true )
   end
end

function getclueplanet ( mini, maxi )
   local planets = {}

   getsysatdistance(system.cur(), mini, maxi,
      function(s)
         for i, v in ipairs(s:planets()) do
            if not isPrevPlanet(v) and v:services()["bar"] and v:canLand() then
               planets[#planets + 1] = {v, s}
            end
         end
         return false
      end)
   if #planets == 0 then
      misn.finish(false)
   end
   local index = rnd.rnd(1, #planets)

   return planets[index][1], planets[index][2]
end

function isPrevPlanet ( passedPlanet )
   for i = 1, #prevPlanets, 1 do
      if prevPlanets[i] == passedPlanet then
         return true
      end
   end
end

function takeoff ()
   if hasDrink then
      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system) and give the Swamp Bombing to the aristocrat at the bar"),
               {planet=startplanet:name(), system=startsys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)
   else
      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system) and look for the special drink that the Aristocrat wants at the bar"),
               {planet=clueplanet:name(), system=cluesys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)
   end
end

function abort()
   misn.finish()
end
