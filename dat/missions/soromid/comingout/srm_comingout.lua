--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Coming Out">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>2</priority>
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

require "numstring"
require "missions/soromid/common"


title = {}
text = {}

ask_text = _([[The stranger looks up at you as you approach. Their voice is deeper than you expected from their appearance as they nervously speak.

"Oh! Uh, h-hi! Nice to meet you. I'm... gee, I was just thinking of what name to go by, what are the odds?" They let out a nervous laugh. "I suppose I'll go by 'C' for now since I'm not sure yet about the name. I, uh, definitely don't want to give out my deadname anymore. They/them pronouns please." You likewise introduce yourself and, taking their lead, note your own pronouns. They seem like a nice person, so you start chatting. You learn that C recently found out that they're transgender and was just now trying to sort out their feelings about their gender. At some point, the fact that you're a pilot comes up, which causes C to perk up. "Oh! Maybe you could help me with my other problem, then!

"See, I was running a few errands for my parents here in Soromid space, but I don't have my piloting license yet, so I hired someone else to give me a ride. He said something about needing to get some 'personal things' sorted and that he would be back in just a few hectoseconds. Well, it's been almost a period now and he hasn't come back. I was going to look for a new pilot after sorting out my feelings about my gender for a bit, but you seem really nice. Could you be my transport? I would just need you to take me to a series of points in Soromid space. I haven't paid my previous transport yet, so I can give the payment to you instead. Does that sound like something you'd be interested in doing?"]])

no_text = _([["Oh, ok.... I guess you must be busy. No worries, I'll try to find someone else later."]])

ask_again_text = _([["Oh! Hi again! I still could use your help getting around to some places in Soromid space. What do you say?"]])

yes_text = _([[C seems relieved when you tell them that you'd be happy to help transport them. "Thank you so much," they say. They show you the destinations they need to go to so you can input them on your mission computer. "The order doesn't matter," they say. "I just need to get to all of these destinations, and then I need a transport to my home planet, %s."]])

dest_text = {}
dest_text[1] = _([[You arrive at your first destination after a trip that involved a pretty sizable amount of conversation. "Thank you for helping me with this," C says as you begin to approach. "And thanks for, um, not ignoring the pronouns I requested." Taken aback, you tell C that it's how you expect to be treated and that you wouldn't want to deny someone else's humanity by not recognizing something as fundamental to themself as their gender. C smiles at this.

When you land, C takes off and goes to do whatever they need to do. By the time you've finished docking procedures, they return with a cheery look on their face. "Someone just called me 'ma'am'!" they explain excitedly. "That's the first time! I don't know what it is. I guess part of it might have been because I didn't speak. Either way, it felt really validating." You congratulate them. "Thank you! You know what? I'm going to start using she/her pronouns, I think." You give a nod and a smile, and mentally note to yourself to modify how you refer to her from now on.]])

dest_text[2] = _([[You have many long conversations with C about a number of topics during the trip to this location, including piloting. At some point during the trip, your experience as a pilot came up and you told C about your adventures. As you begin to enter the atmosphere, Chelsea speaks up again. "You know, you're an inspiration." You feel yourself blushing a little. She continues. "To travel all the way from Empire space into Soromid space really is quite huge! And all those places you've been to along the way! You're exactly the kind of pilot I want to be." You only half-jokingly suggest that maybe they should collaborate on a mission when she gets her piloting license. She softly giggles.

This time, you finish docking procedures before C finishes her errands at this location, so you head off on your own for a while. When you get back, you see C has returned, looking slightly sadder than usual, so you ask how her errands went. "Oh, it was fine," she says. "It's just, someone misgendered me while I was there." You ask if she's OK. "Yeah, I'm fine," she affirms. "It wasn't intentional and they corrected themself right after. It just kind of sucks, you know? Just because I look and sound a little different from society's expectation for what a woman is, people assume I'm a man." Hearing this, you tell her that you're always available to talk with her since you've begun to view her as a friend. She smiles. "Thank you. I appreciate it."]])

dest_text[3] = _([[The trip to this destination was filled with conversation, and you and C have learned a lot about each other. C mentioned several names she was considering, then after some deliberation, came to an answer. "I think I like 'Chelsea'," she said.

Now, as you dock, Chelsea has a very happy look on her face. She goes to do whatever she needs to do with a positive attitude and judging by how she looks when she returns, it seems to have gone well.]])

dest_text[4] = _([[At this point, talking to Chelsea has become a very natural thing for you. You've gotten used to the constant chatter with your new friend to the point that when she goes off on her errands at this location, the quiet feels strange in comparison.

When Chelsea returns, you notice that she looks happy, yet almost half-sad at the same time. Just when you were about to ask what's wrong, she speaks up. "Well, I guess the only place to go is back to my home planet, huh?" You nervously laugh, then say it'll almost feel unfamiliar with her not with you in the ship. "You're a really great friend," she says. Her smile grows and the sadness fades. "We should definitely stay in touch after that." You agree. "Actually," she muses, "I think I'd like to come out to my parents. They don't know I'm transgender yet. Can you go with me? Having you there while I come out to them would be a big help." You smile and agree to the request. "Thank you," she responds. "It means a lot."]])

home_text = _([[As you approach Chelsea's parents' home, you can tell that she's nervous about the whole thing. You assure her that everything will be alright.

She greets her parents and hands them something you don't know anything about, and she introduces you to them. "This is my new friend," she says. "The guy I started with kind of left me somewhere and didn't come back, but %s here helped me the rest of the way."

Her father perks up. "Are you sure he left you? Maybe he just got lost."

An awkward pause follows before Chelsea's mother intervenes. "Well the important thing is that everything went alright in the end." She smiles at Chelsea, then turns to look at you. "And hey, it's nice that you managed to make a friend along the way!" You smile back.]])

home_text_2 = _([[Chelsea briefly pauses and glances at you. You nod encouragingly. "Um, I also managed to do some self-reflection. I'm, um... I'm transgender. I'm changing my name to 'Chelsea' and I'm using she/her pronouns now."

Chelsea's father shrugs. "Whatever makes you happy," he says. "I might take some time getting used to the name." He lets out a slight chuckle. "But However you dress or whatever, that's fine by me."

Chelsea's mother then walks up to Chelsea and pulls her into a warm embrace before she can even react. You see tears starting to appear in Chelsea's eyes as she hugs back. "I'm proud of you for being you, Chelsea," her mother says. Chelsea tightens her grip.]])

home_text_3 = _([[After what seems like a permanent snapshot of the longest hug in human history, Chelsea and her mother let go each other, and Chelsea gives you a friendly hug. "Thank you for being here," she says. "I don't think I would have been able to come out about this without you."

After some further pleasantries, you leave Chelsea's parents' home. "Well," Chelsea says, "I guess you'll probably have to go now, but do come back again soon! Maybe by the time you return I'll have my pilot's license and can start on my journey to become a pilot! Oh, and also, let me give this to you." She hands over a credit chip. "That's the payment I owe you for helping me out. I'll see you later, ok?" You say goodbye and part ways. You'll have to remember to return soon and see how Chelsea's goal of obtaining her pilot's license is going.]])

misn_title = _("Coming Out")
misn_desc = _("Your new friend needs you to deliver them to a few locations, then return them to %s.")

npc_name = _("Quiet stranger")
npc_desc = _("A stranger is sitting quietly at a table alone and staring off into space.")

osd_desc    = {}
osd_desc[1] = _("Go to the %s system and land on the planet %s.")

log_text = _([[You have made a new friend, Chelsea. You helped transport her to complete some errands and also supported her in coming out as transgender to her parents. Chelsea has asked you to return to %s to visit soon.]])


function create ()
   homeplanet, homesys = planet.get("Durea")
   dests = { "Soromid Wards Alpha", "Jaxheen", "Agino", "Neurri" }
   markers = {}
   -- Note: This mission does not make system claims

   credits = 500000
   started = false
   chatter_index = 0

   misn.setNPC(npc_name, "soromid/unique/chelsea.png", npc_desc)
end


function accept ()
   local txt = started and ask_again_text or ask_text
   started = true

   if tk.yesno("", txt) then
      tk.msg("", yes_text:format(homeplanet:name()))

      misn.accept()

      misn.setTitle(misn_title)
      misn.setDesc(misn_desc:format(homeplanet:name()))
      misn.setReward(creditstring(credits))

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
         osd_desc[#osd_desc + 1] = string.format(
               _("Fly to the %s system and land on %s"), sys:name(),
               pl:name() )
      end
   else
      osd_desc[1] = string.format(
            _("Fly to the %s system and land on %s"), homesys:name(),
            homeplanet:name() )
   end

   misn.osdCreate( misn_title, osd_desc )
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
      tk.msg("", home_text:format(player.name()))
      tk.msg("", home_text_2)
      tk.msg("", home_text_3)
      player.pay(credits)

      local t = time.get():tonumber()
      var.push("comingout_time", t)

      srm_addComingOutLog(log_text:format(homeplanet:name()))

      misn.finish(true)
   end
end

