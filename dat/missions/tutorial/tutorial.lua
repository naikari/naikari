--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Tutorial">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>1</priority>
  <location>None</location>
 </avail>
 <notes>
  <campaign>Tutorial</campaign>
 </notes>
</mission>
--]]
--[[

   This mission is a tutorial for players, but is also written to be a
   tutorial for mission writers.

   Naikari missions are written in the Lua programming language.
   There is documentation on Naikari's Lua API on the Naikari website:

      https://naikari.github.io/lua/

   At the top of each mission is an embedded XML tag. This is necessary
   to tell the game meta-information about the mission, such as where it
   should appear, what priority it should have compared to other
   missions, and whether it is "unique" (that is, a mission that the
   player can only complete once). It also identifies the unique name
   used internally by the game to keep track of the different missions.

   In the case of this mission, it will never appear on its own under
   any circumstances, has maximum priority, and is unique. It is started
   by dat/events/start.lua.

   MISSION: Point of Sale
   DESCRIPTION:
      Basic introduction presented to the player at the start of the
      game, teaching basic controls and directing the player to Ian
      Structure to begin the story and continue learning how to play the
      game.

--]]

--[[
   require statements go here. Most missions should include the fmt
   module, which provides useful functions for formatting text.
--]]
local fmt = require "fmt"


--[[
Multi-paragraph or long dialog strings should go here, each with an
identifiable name. You can see here that we wrap strings that are
displayed to the player with `_()`. This is a call to gettext, which
enables localization. The _() call should be used directly on the
string, as shown here, instead of on a variable, so that the script
which figures out what all the translatable text is can find it.
(Alternatively, you can store the untranslated version while still
allowing gettext to know about the string by using `N_()` around the
string and then later usin `_()` on the variable that contains it.)

Note the local keyword used on these variables; this means that the
variable will not be persisted between game sessions, which is useful
for these kinds of text variables since it ensures the player won't be
shown outdated text.

When writing dialog, write it like a book (in the present-tense), with
paragraphs and quotations and all that good stuff. Use a double line
break, as shown below, for new paragraphs. Use quotation marks as would
be standard in a book. However, do *not* quote the player speaking;
instead, paraphrase what the player generally says, as shown below.

In most cases, you should use double-brackets for your multi-paragraph
dialog strings, as shown below.

One thing to keep in mind: the player can be any gender, so keep all
references to the player gender-neutral. If you need to use a
third-person pronoun for the player, singular "they" is the best choice.

You may notice instances of words within curly braces ({}) sprinkled
throughout the text. These are portions that will be filled in later by
the mission via the `fmt.f()` function.
--]]
local intro_text  = _([["Welcome to space, {player}, and congratulations on your purchase," the salesperson who sold you the {shipname} says over the radio. "I am sure your new ship will serve you well! Here at Exacorp, our ships are prized for their reliability and affordability. I promise, you won't be disappointed!" You barely resist the temptation to roll your eyes at the remark; you really only bought this ship because it was the only one you could afford. Still, you tactfully thank the salesperson.]])

local movement_text = _([["Now, so that your test flight goes as smoothly as possible, I will explain the controls of your state-of-the art Exacorp starship! There are two basic modes: keyboard flight, and mouse flight.

"To move via keyboard flight, rotate your ship with {leftkey} and {rightkey}, and thrust to move your ship forward with {accelkey}. You can also use {reversekey} to rotate your ship to the direction opposite of your current movement, which can be useful for bringing your vessel to a stop.

"To move via mouse flight, you must first enable it by pressing {mouseflykey}. While mouse flight is enabled, your ship will automatically turn toward your #bmouse pointer#0, like magic! You can then thrust either with {accelkey}, as you would in keyboard flight, or you can alternatively use the #bmiddle mouse button#0 or either of the #bextra mouse buttons#0.

"Why don't you give both systems a try? Experiment with the flight controls as much as you'd like, then fly over to where {planet} is. You see it on your screen, right? It's the planet right next to you. I've hilighted it for you on your minimap."]])

local landing_text = _([["I see you have a great handle on the controls of your new Exacorp ship! It's a perfect fit for you, don't you think? Your control of the vessel is absolutely stunning, magnificent!

"You may continue to practice flying for as long as you need. When you are ready, please land on {planet} to finalize your paperwork; you can land double-clicking on {planet} or by pressing {landkey}. I will be waiting for you at the spaceport!"]])

local land_text = _([[You watch as the ship – your ship – automatically guides you safely thru the atmosphere and into the planet's space port, then touches down at an empty spot reserved for you. As soon as the hatch opens and you step out, an exhausted dock worker greets you and makes you sign a form. "Just the standard waiver," she explains. After you sign, she pushes some buttons and you stare as you see robotic drones immediately getting to work checking your ship for damage and ensuring your fuel tanks are full. Noticing your expression, the worker lets out a chuckle. "First time landing, eh?" she quips. "It'll all be normal to you before long."

"Ah, there you are, {player}!" the voice of the salesperson interrupts, prompting the worker to roll her eyes and walk off. You look in the direction of the voice and see the obnoxiously dressed salesperson, wearing a huge grin. "I see your Exacorp starship is serving you well. Now, if you would follow me, we can finalize that paperwork."]])

local finish_text = _([[The salesperson makes you sign dozens of forms: tax forms, waivers, indemnity agreements, and much more that you aren't given enough time to process. When you finish, the salesperson pats you on the back. "You have made an excellent choice, {player}! I'm sure you'll be making millions of credits in no time.

"In fact, I know just where to start. A gentleman at the bar by the name of Ian Structure is looking for a hired hand, and I assure you, he pays good rates! I've told him about you and he said he would be thrilled to hire you for a mission!" The salesperson offers their hand and, not wanting to be combative, you shake it. "Good luck, {player}!" the salesperson says before swiftly escorting you out of their office.

You figure you might as well meet this man the salesperson mentioned at the #bSpaceport Bar#0 and see if the job is worthwhile.]])

local misn_title = _("Point of Sale")
local misn_desc = _("You have purchased a new ship from Exacorp and are in the process of finalizing the sale.")


--[[ 
The create() function runs immediately when the mission is created. It
is responsible for setting the mission up to be initially presented to
the player, generally by either spawning an NPC or by spawning an entry
in the Mission Computer. Regardless of what it does, it is mandatory for
this function to be defined.
--]]
function create()
   -- Set our mission parameters. These are global variables which will
   -- be persisted even if the game is reloaded.
   start_planet, missys = planet.get("Kikero")
   stage = 1

   -- Immediately call accept()
   accept()
end

--[[
The accept() function runs when the player approaches the mission's NPC,
or when the player selects the mission in the Mission Computer and
clicks the "Accept" button. It is responsible for actually adding the
mission to the player's missions in the Ship Computer, and in many
cases, it is also responsible for checking whether the player really
wants to accept it, and whether they actually can.

If the mission is truly accepted by the player and can be accepted by
the player, run misn.accept() to transfer the mission into the player's
active missions. Otherwise, run misn.finish() to keep the mission
available for the player to attempt to accept the mission again.
--]]
function accept()
   misn.accept()

   misn.setTitle(misn_title)
   misn.setDesc(misn_desc)
   misn.setReward(_("None"))

   create_osd()

   misn.markerAdd(missys, "low", start_planet)

   timer_greeting_hook = hook.timer(1, "timer_greeting")
   timer_hook = hook.timer(5, "timer")
   hook.land("land")
   hook.enter("enter")
end


function create_osd()
   local osd_desc = {
      fmt.f(_("Fly to {planet} ({system} system) with the movement keys ({accelkey}, {leftkey}, {reversekey}, {rightkey}) or with mouse flight (enabled with {mouseflykey})"),
         {planet=start_planet:name(), system=missys:name(),
            accelkey=naik.keyGet("accel"), leftkey=naik.keyGet("left"),
            reversekey=naik.keyGet("reverse"), rightkey=naik.keyGet("right"),
            mouseflykey=naik.keyGet("mousefly")}),
      fmt.f(_("Land on {planet} ({system} system) by double-clicking it or pressing {landkey}"),
         {planet=start_planet:name(), system=missys:name(),
            landkey=naik.keyGet("land")}),
   }

   misn.osdCreate(misn_title, osd_desc)
   misn.osdActive(stage)
end


function timer_greeting()
   tk.msg("", fmt.f(intro_text,
         {player=player.name(), shipname=player.pilot():name()}))
   tk.msg("", fmt.f(movement_text,
         {leftkey=fmt.keyGetH("left"), rightkey=fmt.keyGetH("right"),
            accelkey=fmt.keyGetH("accel"), reversekey=fmt.keyGetH("reverse"),
            mouseflykey=fmt.keyGetH("mousefly"), planet=start_planet:name()}))
end


function timer()
   hook.rm(timer_hook)
   timer_hook = hook.timer(1, "timer")

   -- Recreate OSD in case key binds have changed.
   create_osd()

   if stage == 1 and system.cur() == missys
         and player.pos():dist(start_planet:pos()) <= start_planet:radius() then
      stage = 2

      tk.msg("", fmt.f(landing_text,
            {planet=start_planet:name(),
               target_planet_key=fmt.keyGetH("target_planet"),
               landkey=fmt.keyGetH("land")}))
      create_osd()
   end
end


function enter()
   hook.rm(timer_hook)
   timer_hook = hook.timer(1, "timer")
end


function land()
   hook.rm(timer_hook)
   if planet.cur() ~= start_planet then
      return
   end

   tk.msg("", fmt.f(land_text, {player=player.name()}))
   tk.msg("", fmt.f(finish_text, {player=player.name()}))
   misn.finish(true)
end
