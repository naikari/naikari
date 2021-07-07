--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Plight of the Frontier">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>2</priority>
  <chance>100</chance>
  <location>Bar</location>
  <cond>var.peek("flfbase_intro") == 2</cond>
  <planet>Sindbad</planet>
 </avail>
 <notes>
  <done_misn name="Deal with the FLF agent">If you return Gregar to Sindbad</done_misn>
  <campaign>Join the FLF</campaign>
 </notes>
</mission>
--]]
--[[

   Plight of the Frontier

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
require "missions/flf/flf_common"


why_text = _([[You approach and greet the man with a friendly gesture, but he is unmoved and maintains his icy stare. After spending what feels like an eternity staring into his piercing gaze, he finally speaks up.

"I don't trust you," he bluntly states. "I doubt anyone here trusts you. You may have helped out one of our own, but I don't know your motives. You could be a spy or assassin for all I know." The man pauses, then briefly closes his eyes as he lets out a sigh before opening them again. "That said, if the higher-ups have decided to trust you, I guess there's nothing I can do about it. No matter. You can't stop the FLF even if you have ill intent. Not fully."

You pause, unsure of what to say in response. After what feels like a lifetime, he finally speaks up again. "What are your intentions? Why are you here?"]])

answer_text = {}
answer_text.help = _([[You tell the man that you have heard of the struggles of the FLF and want to help. The main frowns. "Who the hell do you think you are? Do you think you, an outsider who doesn't even understand the struggles of the Frontier, are going to be our savior? Why are you people always so damn full of yourselves?!" Unsure of what to say, your eyes shift from his gaze to the floor below you. Despite this, you can feel his eyes on you as strongly as ever.

"Let's get one thing straight: you're not going to be the one to fly in and cure all our problems any more than you're going to fly in and destroy us. We've been working hard to put a stop to the Dvaered oppression for a long time now. If you have any part at all in finally defeating the Dvaereds, it will be on the back of the many of us who have fought and died already, who collectively built this guerrilla force."

He sighs once again, then stands up. "That said, if you really do want to help, you need to understand our struggles properly." You look back into his eyes, and you notice that they've changed somewhat. While they still convey a great degree of distrust, they don't seem to convey outright hostility as they previously did. He continues. "Let me show you personally what's going on in the Frontier. What do you say?"]])
answer_text.neutral = _([[You tell the man that you are just a fellow pilot who helped someone in need. You say that you are neutral on the conflict between House Dvaered and the FLF and promise not to rat out the FLF to the authorities. He frowns and his face becomes filled with rage. "Neutral?! How could you be neutral in this conflict? Do you have any idea what the Dvaereds do to us day after day in the Frontier? What they aspire to do if only we would get out of the way? Do you know nothing about our struggles?" You knew you weren't trusted, but you certainly didn't expect this level of anger. You open your mouth to answer, but not knowing what to say, you close it again and your eyes shift to the floor below you. Around you, you hear murmurs of agreement; it seems his outburst has attracted an audience, and this audience is firmly against you.

The man lets out another sigh, then stands up. His expression has reverted again from one of intense anger to one of firm distrust. "I'll show you exactly what's going on in the Frontier, what the Dvaereds do to us, what the Dvaereds plan to do to us, and why we need to resist them. I'm sick and tired of outsiders like you who have no idea just how horrible the Dvaereds are." The offer takes you by surprise. You stand there silently, transfixed by the man's eyes which, now that you think about it, have a touch of pain and sadness to them. You consider his sudden offer. "Well?" he says, breaking you out of your trance. "Will you let me show you what's going on in the Frontier?"]])
answer_text.learn = _([[You tell the man that you don't know much about the Frontier or the FLF, given your background having been raised in the Empire, and that you wish to learn more about the Frontier and the struggles of the FLF. As he raises an eyebrow, you add that you have no ill intent and won't tell anyone about Sindbad. The man pauses. "Odd. I never would have expected an Imperial to admit their own ignorance on the matter. Maybe there's hope for you after all.

"I'll tell you what: why don't I help you out on what you're after? I can show you personally what's going on in the Frontier and what we do. We usually aren't in the business of educating people, but a genuine willingness to learn from an outsider is a real breath of fresh air. Are you ready right now?]])

return_text = {}
return_text.help = _([["I see you're back. Have you changed your mind about letting me show you what's going on in the Frontier?"]])
return_text.neutral = return_text.help
return_text.learn = _([["Oh, hello again. Are you ready to go on a tour of the Frontier now?"]])

response_no = {}
response_no.help = _([[The man frowns, then silently returns to his seat and crosses his arms.]])
response_no.neutral = response_no.help
response_no.learn = _([[You thank the man, but say you are currently busy with something else. He sighs. "Well, that's understandable, I suppose. Feel free to talk to me later when you're ready."]])

response_yes = {}
response_yes.help = _([[The man grins. "Perfect. I'll show you just what our stakes are, what we fight for, and what we're up against. And most importantly, I'll find out if we can really trust you.

"I suppose as good as place to start as any would be my homeworld, %s. Maybe that will give you the slightest inkling of how rich our society is. Too many people like you think that we're helpless barbarians who need to be uplifted and saved by an Imperial savior, and I'm sick and tired of that.

"Oh, my name's Flint, by the way." You likewise tell Flint your own name. "I'll meet you at the landing bay. I would fly my own ship, but since you're not officially FLF yet, we'll have an easier time if I join you on your ship. Should avoid confrontations with the Dvaereds and allow us to get up-close without getting them on our tails. See you soon."

As Flint walks toward the landing bay, you ponder what exactly you did that made him so upset. You figure you'll find out soon enough from him, though, and resolve to listen as well as you can.]])
response_yes.neutral = _([["Good. You'll see soon why being neutral in this conflict is unacceptable. More importantly, I'll find out if you can be trusted in the slightest.

"Our first stop will be my homeworld, %s. Maybe that'll give you the slightest inkling of what's at stake for us. I'm so sick and tired of you Imperials acting like this conflict is a minor event when it's so much more than that.

"The name's Flint, by the way. Flint as in if you try to turn me over to the Dvaereds, I'll light a fire in your ass." You in turn tell Flint your own name, then reaffirm that you won't double-cross him. "Good. I'll meet you at the landing bay. I would fly my own ship, but you being neutral means that we can avoid detection from the Dvaereds and I can give you more of a close-up view. Besides, I don't want to get into a fight with you as my only wingmate. I don't trust you. At least if I'm on your ship, I can kill you and steal the ship, eh?" You let out a nervous laugh as he turns and walks toward the direction of the landing bay. You begin to wonder just what he's going to show you that he thinks will put you on the side of the FLF, what exactly they hate so much about House Dvaered. You wanted to avoid picking sides, but you decide that at least there's no risk with seeing his point of view.]])
response_yes.learn = _([["Good to hear! I'm not used to having someone who actually wants to learn of our struggles, but I'll do my best to enlighten you. I think as good a place to start as any is my homeworld, %s.

"Oh, my name's Flint, by the way. And, uh, this should go without saying, but I still don't fully trust you, and I'm prepared to defend myself if I need to. We FLF soldiers are pretty damn good with a laser gun." He playfully winks. You laugh a little and promise you won't do anything funny. "Good to hear!" he responds with a grin. "I'll be waiting on your ship when you're ready. See you soon!"

Flint turns away, waves, and walks toward the hangar. Despite the threat, you detect that Flint trusts you at least a little, and you let out a slight smile. This tour of the Frontier should prove enlightening indeed.]])

tohelp_homeworld = _([[As you begin docking procedures, you notice Flint looking up at a Dvaered formation nearby. "Damn Dvaereds, acting like they own the place...." You try to be friendly by agreeing that the Dvaereds should stop trying to assert authority over the Frontier and let the Frontier forces handle crime. Flint looks at you like you've grown two heads. "It's not... do you even see what they're doing? Just... just look, why don't you?" You take a closer look at the Dvaered fleet and them chasing a Frontier Lancelot. Flint continues. "They do this shit all the time, attack random Frontier on the pretense of 'fighting terrorism'. Makes me sick." Eventually, as they start to fade from view, the Dvaereds seemingly stop harassing the Frontier ship.

Flint looks at you and continues. "This is what's wrong with you, %s. You keep making assumptions about our situation that you seem to not even realize you're making. You need to shut up and listen to us." You quickly apologize, and Flint sighs. "Well, this is my homeworld. Beautiful, isn't it?" You nod and take a moment to appreciate the view as you land. It's a water world filled with all kinds of interesting life forms.]])

tohelp_homeworld_2 = _([[Flint continues. "But it's more than just beautiful. This planet is home to a special algae that can be used as medicine. We've been using it sustainably for generations. Outside pressures always try to get us to harvest more, but we refuse because we know that it will devastate the natural ecosystem these algae and many other organisms depend on.

"The Dvaereds don't care about the ecosystem at all. They would probably drill holes all over the seafloor to mine the scant ore deposits found on the surface. This beautiful world would just be another resource for their war industry."]])

motive_text = {}
motive_text.help = _("To help the FLF")
motive_text.neutral = _("Just helping a pilot in need")
motive_text.learn = _("To learn about the Frontier's struggle")

npc_desc = _("This man eyes you with a very icy stare. It seems he doesn't trust you.")


function create ()
   homepla, homesys = planet.get("Cetrat")
   misn.finish(false)

   -- Variable storing the player's motive. Can be "help", "neutral",
   -- or "learn". nil indicates that the player hasn't given a reason
   -- yet.
   motive = nil

   misn.setNPC(_("A skeptical man"), "flf/unique/flint.png", npc_desc)
end


function accept ()
   if motive == nil then
      local i, s = tk.choice(
            "", why_text, motive_text.help, motive_text.neutral,
            motive_text.learn)
      if s == motive_text.help then
         motive = "help"
      elseif s == motive_text.neutral then
         motive = "neutral"
      else
         motive = "learn"
      end
   end
end

