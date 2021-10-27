--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Mission Template (mission name goes here)">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>4</priority>
  <chance>5</chance>
  <location>Bar</location>
 </avail>
</mission>
--]]
--[[

   Mission Template (mission name goes here)

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

--

   This is a Naikari mission template.
   In this document aims to provide a structure on which to build many
   Naikari missions and teach how to make basic missions in Naikari.
   Naikari missions are written in the Lua programming language.
   There is documentation on Naikari's Lua API on the Naikari website:

      https://naikari.github.io/lua/

   You can also study the source code of missions in
   [path_to_Naikari_folder]/dat/missions/.

   When creating a mission with this template, please erase the
   explanatory comments (such as this one) along the way, but retain the
   above license header and the MISSION and DESCRIPTION fields below,
   adapted to your mission. You must also ensure you check the XML
   portion at the top and that your mission has a unique name defined
   there (that name is not displayed to players, but is used to identify
   missions internally).

   MISSION: <NAME GOES HERE>
   DESCRIPTION: <DESCRIPTION GOES HERE>

--]]

-- require statements go here. Most missions should include the fmt
-- module, which is used for formatting text and is preferred over the
-- built-in string.format() in most cases.
-- dat/missions/neutral/common.lua provides the addMiscLog function,
-- which is typically used for non-factional unique missions.
local fmt = require "fmt"
require "missions/neutral/common"

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

One of those portions is {reward_sentence}, which will be replaced by
an entire sentence later on. This is necessary as we will be using
ngettext, which must be done inline. Pulling out the entire sentence is
necessary to ensure that translators have full capability to translate
the sentence properly.
--]]
ask_text = _([[As you approach the guy, he looks up in curiosity. You sit down and ask him how his day is. "Why, fine," he answers. "How are you?" You answer that you are fine as well and compliment him on his suit, which seems to make his eyes light up. "Why, thanks! It's my favorite suit! I had it custom tailored, you know.

"Actually, that reminds me! There was a special suit on {planet} in the {system} system, the last one I need to complete my collection, but I don't have a ship. You do have a ship, don't you? {reward_sentence} What do you say?"]])

ask_again_text = _([["Ah, it's you again! Have you changed your mind? Like I said, I just need transport to {planet} in the {system} system."]])

accept_text = _([["Fantastic! I knew you would do it! Like I said, I'll pay you as soon as we get there. No rush! Just bring me there when you're ready.]])

finish_text = _([[As you arrive on %s, your passenger reacts with glee. "I must sincerely thank you, kind stranger! Now I can finally complete my suit collection, and it's all thanks to you. Here is %s, as we agreed. I hope you have safe travels!"]])

misn_desc = _("A well-dressed man wants you to take him to {planet} in the {system} system so he get some sort of special suit.")
misn_log = _([[You helped transport a well-dressed man to %s so that he could buy some kind of special suit to complete his collection.]])


--[[ 
First you need to *create* the mission. This is *obligatory*.

You have to set the NPC and the description. These will show up at the
bar with the character that gives the mission and the character's
description.
--]]
function create ()
   -- Set our mission parameters.
   misplanet, missys = planet.get("Ulios")
   credits = 250000
   talked = false
   
   -- If we needed to claim a system, we would do that here with
   -- something like the following commented out statement. However,
   -- this mission won't be doing anything with the system itself (it
   -- only wants us to land somewhere), so we won't make a system claim
   -- for it.
   --if not misn.claim(missys) then misn.finish(false) end

   -- Give the name of the NPC and the portrait used. You can see all
   -- available portraits in artwork/gfx/portraits.
   misn.setNPC(
         _("A well-dressed man"),
         "neutral/unique/youngbusinessman.webp",
         _("This guy is wearing a nice suit."))
end


--[[
This is an *obligatory* part which is run when the player approaches the
character.

Run misn.accept() here to internally "accept" the mission. This is
required; if you don't call misn.accept(), the mission is scrapped.
This is also where mission details are set.
--]]
function accept ()
   -- Use different text if we've already talked to him before than if
   -- this is our first time.
   local text
   if talked then
      -- We use `fmt.f` here to fill in the variables.
      text = fmt.f(ask_again_text,
            {planet=misplanet:name(), system=missys:name()})
   else
      -- And also here. However, here we include mention of how many
      -- credits the player gets, and so it gets slightly more
      -- complicated. First, we get the reward sentence and store it
      -- in local variable reward_text, using fmt.f and n_() (alias to
      -- gettext.ngettext) to translate and format this portion. Then,
      -- we format `ask_text` as with `ask_again_text`, splicing in the
      -- extra sentence we just translated with ngettext.
      --
      -- In general, credits are best indicated with ¢, but writing out
      -- the words "credit" and "credits" as below is acceptable, too.
      local reward_text = fmt.f(
            n_("So I'll tell you what, give me a ride and I'll pay you {credits} credit for it!",
               "So I'll tell you what, give me a ride and I'll pay you {credits} credits for it!",
               credits),
            {credits=fmt.number(credits)}
      text = fmt.f(ask_text,
            {planet=misplanet:name(), system=missys:name(),
               reward_sentence=reward_text})
      talked = true
   end

   -- This will create the typical "Yes/No" dialogue. It returns true if
   -- yes was selected. 
   if tk.yesno("", text) then
      -- Followup text.
      tk.msg("", accept_text)

      -- Accept the mission
      misn.accept()

      -- Mission details:
      -- You should always set mission details right after accepting the
      -- mission.
      misn.setTitle(_("The Special Suit"))
      -- For reward, we are simply using `fmt.credits()` to display the
      -- number of credits the player will be getting. You can also
      -- choose to make the text some arbitrary string, e.g.
      -- `misn.setReward(_("A lotta money"))`, but in most cases simply
      -- displaying how many credits are earned is ideal.
      misn.setReward(fmt.credits(credits))
      misn.setDesc(fmt.f(misn_desc,
            {planet=misplanet:name(), system=missys:name()}))

      -- Markers indicate a target system on the map. It may not be
      -- needed depending on the type of mission you're writing.
      misn.markerAdd(missys, "low")

      -- The OSD shows your objectives. For style purposes, the OSD
      -- description should not contain end-of-sentence punctuation.
      local osd_desc = {}
      osd_desc[1] = fmt.f(_("Land on {planet} ({system} system)"),
            {planet=misplanet:name(), system=missys:name()})
      misn.osdCreate(_("The Special Suit"), osd_desc)

      -- This is where we would define any other variables we need, but
      -- we won't need any for this example.

      -- Hooks go here. We use hooks to cause something to happen in
      -- response to an event. In this case, we use a hook for when the
      -- player lands on a planet.
      hook.land("land")
   else
      -- Call misn.finish() with no arguments to end the conversation
      -- with the NPC without getting rid of him.
      misn.finish()
   end
end


-- This is our land hook function. Once `hook.land("land")` is called,
-- this function will be called any time the player lands.
function land ()
   -- First check to see if we're on our target planet.
   if planet.cur() == misplanet then
      -- Mission accomplished! Now we do an outro dialog and reward the
      -- player. Rewards are usually credits, as shown here, but
      -- other rewards can also be given depending on the circumstances.
      tk.msg("", finish_text:format(misplanet:name(), reward_text)

      -- Reward the player. Rewards are usually credits, as shown here,
      -- but other rewards can also be given depending on the
      -- circumstances.
      player.pay(credits)

      -- Add a log entry. This should only be done for unique missions.
      addMiscLog(misn_log:format(misplanet:name()))
      
      -- Finish the mission. Passing the `true` argument marks the
      -- mission as complete.
      misn.finish(true)
   end
end
