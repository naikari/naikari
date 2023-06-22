--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Coming Out">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>19</priority>
  <chance>20</chance>
  <location>Bar</location>
  <faction>Soromid</faction>
 </avail>
 <notes>
  <campaign>Coming Out</campaign>
 </notes>
</mission>
--]]
--[[

   Coming Out

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

--]]

local fmt = require "fmt"
require "missions/soromid/common"


ask_text = _([[The stranger looks up at you as you approach. Their voice is deeper than you expected from their appearance as they nervously speak. "Oh! Uh, h-hi! Nice to meet you. I'm… gee, I was just thinking of what name to go by, what are the odds?" They let out a nervous laugh. "I suppose I'll go by 'C' for now since I'm not sure yet about the name. I, uh, definitely don't want to give out my deadname anymore. They/them pronouns please." You likewise introduce yourself and, taking their lead, note your own pronouns. "Say, {player}, you're a pilot, aren't you? Maybe you can help me out.

"See, I was running a few errands here in Soromid space, but I don't have my piloting license yet, so I hired someone else to give me a ride. Well, turns out I started finding out that I'm transgender at the worst possible time. I started changing my appearance ever so slightly and he suddenly started being a transmisic asshole to me, constantly going on about how I'll 'never be a real woman', calling me a "pervert", "sick", and pretty much every other shitty thing you can think of for weeks on end until he dumped me here on this bar yesterday. 'Just a few minutes,' he said. Well, clearly he isn't coming back. I was going to look for a new pilot after I picked a name, but you seem really nice. Could you be my transport? I would just need you to take me to a series of points in Soromid space. I can give you the same payment I was going to give to my previous transport, {credits}. Does that sound like something you'd be interested in doing?"]])

no_text = _([["Oh, OK. I guess you must be busy. No worries, I'll try to find someone else later."]])

ask_again_text = _([["Oh! Hi again, {player}! I still could use your help getting around to some places in Soromid space in exchange for {credits}. What do you say?"]])

yes_text = _([[C seems relieved when you tell them that you'd be happy to help transport them. "Thank you so much," they say. They show you the destinations they need to go to so you can input them on your mission computer. "The order doesn't matter," they say. "I just need to get to all of these destinations, and then I need a transport to my home planet, {planet}." C shudders. "I sure hope my parents don't act like that asshole did.… Anyway, I'll be waiting on your ship."]])

dest_text = {}
dest_text[1] = _([[You arrive at your first destination with C after a relatively quiët, but pleasant trip. "Thank you for helping me with this," C says as you begin to approach. "And for treating me like a human being," they add with a mix of amusement and relief. You can't help but laugh slightly at the statement as you remark on how incredibly low the bar must be for you to be thanked for that. "I know, right? Well hey, the last guy didn't do that, so this is a nice change."

When you land, C takes off and goes to do whatever they need to do. By the time you've finished docking procedures, they return with a cheery look on their face. "Someone just called me 'ma'am'!" they explain excitedly. "That's the first time! It felt really validating. You know what? I'm going to start using she/her pronouns, I think." You give a nod and thank her for telling you.]])

dest_text[2] = _([[You have many long conversations with C about a number of topics during the trip to this location, including piloting. At some point during the trip, your experience as a pilot came up and you told C about your adventures. "You know, you're an inspiration," C remarks as you land. You feel yourself blushing a little as she continues. "To travel all the way from Empire space into Soromid space really is quite huge! And all those places you've been to along the way! You're exactly the kind of pilot I want to be."

This time, you finish docking procedures before C finishes her errands at this location, so you head off on your own for a while. When you get back, you see C has returned, looking slightly sadder than usual, so you ask how her errands went. "Oh, it was fine," she says. "It's just, someone misgendered me while I was there." You ask if she's OK. "Yeah, I'm fine," she affirms. "It wasn't intentional and they corrected themself right after. It just kind of sucks, you know? But you never assumed my gender. I appreciate that. I wish more people would do the same."]])

dest_text[3] = _([[The trip to this destination was a bit quiët compared to the last one as C spent most of the time thinking to herself about what name she wanted to use. She muttered several names she was considering, then after some deliberation, came to an answer. "I think I like 'Chelsea'," she said.

Now, as you dock, Chelsea has a very happy look on her face. She goes to do whatever she needs to do in high spirits and judging by how she looks when she returns, it seems to have gone well.]])

dest_text[4] = _([[You land at Chelsea's final destination and send her on her way as before. When she returns, she heaves a bit of a sigh. "Well, I guess the only place to go is back to my home planet, huh? It's funny, I haven't known you for that long, but I feel like you know me way better than anyone else. It's like I've been pretending to be someone else all my life, you know?

"Anyway, I guess it's time to go back to my home planet."]])

home_text = _([["It's so weird," Chelsea remarks as you begin landing procedures. "Coming out to you was easy, but coming out to my parents? Terrifying. I just hope they'll be accepting." When landing is finished and you and Chelsea step out onto the spaceport, she hands you the promised payment. "I hope we meet again some day, {player}. Come back here sometime; maybe I'll finally have my pilot license when you do!" You wish Chelsea good luck in coming out to her parents and in obtaining her pilot license as you part ways. Perhaps you should accept that invitation at some point in the future.]])

misn_title = _("Coming Out")
misn_desc = _([[You have been hired to transport someone who was stranded to several locations to run some errands:

{locations_list}

Afterwards, you are to return them to their homeworld, {planet} ({system} system)]])

npc_name = _("Quiët stranger")
npc_desc = _("A stranger is sitting quiëtly at a table alone and staring off into space.")

log_text = _([[You have met a woman, Chelsea, who recently came out as transgender. You helped transport her to complete some errands and then returned her to her homeworld. Chelsea has suggested meeting again in the future on {planet} ({system} system).]])


function create ()
   -- Note: This mission does not make system claims
   homeplanet, homesys = planet.get("Durea")
   dests = {"Soromid Wards Alpha", "Tummalin", "Agino", "Neurri"}
   dests["__save"] = true
   markers = {}
   markers["__save"] = true

   -- Make sure all planets are landable and that the player isn't on
   -- any of them.
   for i, pn in ipairs(dests) do
      local pl, sys = planet.getLandable(pn)
      if pl == nil or pl == planet.cur() then
         misn.finish(false)
      end
   end

   credits = 500000
   started = false
   chatter_index = 0

   misn.setNPC(npc_name, "soromid/unique/chelsea.png", npc_desc)
end


function accept ()
   local txt = started and ask_again_text or ask_text
   started = true

   if tk.yesno("", fmt.f(txt,
         {player=player.name(), credits=fmt.credits(credits)})) then
      tk.msg("", fmt.f(yes_text, {planet=homeplanet:name()}))

      misn.accept()

      local locations = {}
      for i, pn in ipairs(dests) do
         local pl, sys = planet.get(pn)
         table.insert(locations, fmt.f(_("{planet} ({system} system)"),
               {planet=pl:name(), system=sys:name()}))
      end

      misn.setTitle(misn_title)
      misn.setDesc(fmt.f(misn_desc,
            {locations_list=table.concat(locations, "\n"),
               planet=homeplanet:name(), system=homesys:name()}))
      misn.setReward(fmt.credits(credits))

      generate_osd()

      for i, pn in ipairs(dests) do
         local pl, sys = planet.get(pn)
         markers[pn] = misn.markerAdd(sys, "low")
      end

      hook.land("land")
   else
      tk.msg("", no_text)
      misn.finish()
   end
end


function generate_osd ()
   local osd_desc = {}
   if #dests > 0 then
      for i, pn in ipairs(dests) do
         local pl, sys = planet.get(pn)
         table.insert(osd_desc, fmt.f(_("Land on {planet} ({system} system)"),
               {planet=pl:name(), system=sys:name()}))
      end
   else
      osd_desc[1] = fmt.f(_("Land on {planet} ({system} system)"),
            {planet=homeplanet:name(), system=homesys:name()})
   end

   misn.osdCreate(misn_title, osd_desc)
end


function land ()
   if #dests > 0 then
      for i, pn in ipairs(dests) do
         local pl, sys = planet.get(pn)
         if pl == planet.cur() then
            tk.msg("", dest_text[1 + #dest_text - #dests])

            -- Remove the dest from the dests list, shift everything
            -- after it down.
            for j=i, #dests do
               dests[j] = dests[j + 1]
            end

            misn.markerRm(markers[pn])

            misn.osdDestroy()
            generate_osd()

            if #dests <= 0 then
               home_marker = misn.markerAdd(homesys, "low")
            end
         end 
      end
   elseif planet.cur() == homeplanet then
      tk.msg("", fmt.f(home_text, {player=player.name()}))
      player.pay(credits)

      local t = time.get():tonumber()
      var.push("comingout_time", t)

      srm_addComingOutLog(fmt.f(log_text,
            {planet=homeplanet:name(), system=homesys:name()}))

      misn.finish(true)
   end
end

