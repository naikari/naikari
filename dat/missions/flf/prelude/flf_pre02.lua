--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Plight of the Frontier">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>15</priority>
  <chance>100</chance>
  <location>Bar</location>
  <cond>faction.playerStanding("FLF") &gt;= 0 and var.peek("flfbase_intro") == 2</cond>
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

--

   This is the second "prelude" mission leading to the FLF campaign.
   stack variable flfbase_intro:
      1 - The player has turned in the FLF agent or rescued the Dvaered
            crew. Conditional for dv_antiflf02
      2 - The player has rescued the FLF agent. Conditional for
            flf_pre02
      3 - The player has found the FLF base for the Dvaered, or has
            betrayed the FLF after rescuing the agent. Conditional for
            dv_antiflf03

--]]

local fmt = require "fmt"
require "missions/flf/flf_common"


why_text = _([[You approach and greet the man with a friendly gesture, but he is unmoved and maintains his icy stare. After spending what feels like an eternity looking into his piercing gaze, he finally speaks up.

"I don't trust you," he bluntly states. "I doubt anyone here trusts you. You may have helped out one of our own, but I don't know your motives. You could be a spy or assassin for all I know." The man pauses, then briefly closes his eyes as he lets out a sigh before opening them again. "That said, if the higher-ups have decided to trust you, I guess there's nothing I can do about it. No matter. You can't stop the FLF even if you have ill intent. Not fully."

You pause, unsure of what to say in response. After what feels like a lifetime, he finally speaks up again. "What are your intentions? Why are you here?"]])

answer_text = {}
answer_text.help = _([[You tell the man that you have heard of the struggles of the FLF and want to help. The main frowns. "Who the hell do you think you are? Do you think you, an outsider who doesn't even understand the struggles of the Frontier, are going to be our savior? Why are you people always so damn full of yourselves?!" Unsure of what to say, your eyes shift from his gaze to the floor below you. Despite this, you can feel his eyes on you as strongly as ever.

"Let's get one thing straight: you're not going to be the one to fly in and cure all our problems any more than you're going to fly in and destroy us. We've been working hard to put a stop to the Dvaered oppression for a long time now. If you have any part at all in finally defeating the Dvaereds, it will be on the back of the many of us who have fought and died already, who collectively built this guerrilla force."

He sighs once again, then stands up. "That said, if you really do want to help, you need to understand our struggles properly." You look back into his eyes and see a distrustful, yet somewhat less hostile, glare. "I'm willing to show you personally what's going on in the Frontier. Well? Are you ready to listen to what I have to say?"]])
answer_text.neutral = _([[You tell the man that you are just a fellow pilot who helped someone in need. You say that you are neutral on the conflict between House Dvaered and the FLF and promise not to rat out the FLF to the authorities. He frowns and his face becomes filled with rage. "Neutral?! How could you be neutral in this conflict? Do you have any idea what the Dvaereds do to us day after day in the Frontier? What they aspire to do if only we would get out of the way? Do you know nothing about our struggles?" You knew you weren't trusted, but you certainly didn't expect this level of anger. You open your mouth to answer, but not knowing what to say, you close it again and your eyes shift to the floor below you. Around you, you hear murmurs of agreement; it seems his outburst has attracted an audience, and this audience is firmly against you.

The man lets out another sigh, then stands up. His expression has reverted again from one of intense anger to one of firm distrust. "If it were up to me, I'd exile you from this station right now if not imprison you. Since I can't do that, though, I'll show you exactly what's going on in the Frontier, what the Dvaereds do to us, what the Dvaereds plan to do to us, and why we need to resist them. I'm sick and tired of outsiders like you who have no idea just how horrible the Dvaereds are." The offer takes you by surprise. You stand there silently, transfixed by the man's eyes which, now that you think about it, have a touch of pain and sadness to them. You consider his sudden offer. "Well?" he says, breaking you out of your trance. "I'm doing you a pretty big damn favor with this offer. Are you gonna take me up on it or not?"]])
answer_text.learn = _([[You tell the man that you don't know much about the Frontier or the FLF, given your background having been raised in the Empire, and that you wish to learn more about the Frontier and the struggles of the FLF. As he raises an eyebrow, you add that you have no ill intent and won't tell anyone about Sindbad. The man pauses. "Odd. I never would have expected an Imperial to admit their own ignorance on the matter. Maybe there's hope for you after all.

"I gotta say, though, if you really want to learn about the Frontier and what we're fighting for, this is entirely the wrong place for that." He pauses, then stands up. "I'll tell you what: this is a bit of a pain in the ass, but I don't have any important work to do at the moment, so I can guide you around the Frontier and show you what's at stake for us. Are you interested?"]])

return_text = {}
return_text.help = _([[Flint gets out of his seat and shoots a glare at you that's starting to become familiar. "I see you're back. Have you changed your mind about my offer to show you what's going on in the Frontier?"]])
return_text.neutral = return_text.help
return_text.learn = _([["Oh, it's you. Have you changed your mind about my offer to introduce the Frontier and its struggles to you?" Flint stands expectantly as he waits for your response.]])

response_no = {}
response_no.help = _([[The man frowns, then silently returns to his seat and crosses his arms.]])
response_no.neutral = response_no.help
response_no.learn = _([[You thank the man, but say you are currently busy with something else. He raises an eyebrow. "You're really turning me down like that? Whatever," he says as he sits back down. "Let me know if you change your mind."]])

response_yes = {}
response_yes.help = _([[The man grins. "Perfect. I'll show you just what our stakes are, what we fight for, and what we're up against. And most importantly, maybe I can get you to chuck that shitty pretentiousness of yours out the window.

"I suppose as good as place to start as any would be my homeworld, {planet}. Maybe that will give you the slightest inkling of how rich our society is. Too many people like you think that we're helpless barbarians who need to be uplifted and saved by the Emperor's oh so glorious rear end, and I'm sick and tired of that.

"The name's Flint, by the way." You likewise tell Flint your own name. "I'll meet you at the landing bay. I would fly my own ship, but since you're not officially a part of the FLF, we'll have an easier time if I join you on your ship. Should avoid confrontations with the Dvaereds and allow us to get up close without getting them on our tails. Don't you even think about trying anything funny. See you soon."

As Flint walks toward the landing bay, you ponder what exactly you did that made him so upset. You figure you'll find out soon enough from him, though, and resolve to listen as well as you can.]])
response_yes.neutral = _([["Good. You'll see soon why being neutral in this conflict is unacceptable. More importantly, I'll find out if you can be trusted in the slightest.

"Our first stop will be my homeworld, {planet}. Maybe that'll give you the slightest inkling of what's at stake for us. I'm so sick and tired of you Imperials acting like this conflict is a minor event when it's so much more than that.

"The name's Flint, by the way. Flint as in if you try to turn me over to the Dvaereds, I'll light a fire in your ass." As the FLF soldiers around you chuckle at Flint's remark, you tell Flint your own name, then reaffirm that you won't double-cross him. "Good. I'll meet you at the landing bay. I would fly my own ship, but you being neutral means that we can avoid detection from the Dvaereds and I can give you more of a close-up view. Besides, I don't want to get into a fight with you as my only wingmate. I don't trust you. At least if I'm on your ship, I can kill you and steal the ship, eh?" You let out a nervous laugh as he turns and walks toward the direction of the landing bay. You begin to wonder just what he's going to show you that he thinks will put you on the side of the FLF, what exactly they hate so much about House Dvaered. You wanted to avoid picking sides, but you decide that at least there's no risk with seeing his point of view.]])
response_yes.learn = _([["I'm not used to having someone who actually wants to learn of our struggles, but I'll do my best to enlighten you. Don't you forget, though, I'm doing you a favor. I think as good a place to start as any is my homeworld, {planet}.

"Oh, my name's Flint, by the way. And, uh, this should go without saying, but I still don't trust you, and I'm prepared to defend myself if I need to. We FLF soldiers are pretty damn good with a laser gun." He playfully winks. You laugh nervously, introduce yourself in turn, and promise you won't do anything funny. "Good," he responds with a stern look. "I'll be waiting at the landing bay when you're ready."

Flint turns away, waves, and walks toward the landing bay. Despite the threat, you detect that Flint trusts you at least a little, and you let out a sigh in relief. This tour of the Frontier should prove enlightening indeed.]])

homeworld_text = {}
homeworld_text.help = {}
homeworld_text.help[1] = _([[As you begin to enter the atmosphere, you notice Flint looking up at a Dvaered formation nearby. "Damn Dvaereds, acting like they own the place.…" The fleet slowly fades from view as you enter the planet's atmosphere. Flint sighs and looks down at the oceanic world. You also look down and are taken in by the beauty of it, voicing this on reflex. Flint sighs with annoyance.

"You said you wanted to 'help', right? So you'd better not be treating this like a damn field trip. I don't know what you see, but what I see is my homeworld which is in danger of being conquered by the Dvaereds." An awkward silence fills your cockpit as landing completes.]])
homeworld_text.help[2] = _([["Ok, I want you to keep your mouth shut, follow me, and listen," Flint tells you as soon as you finish landing procedures. Not wanting to make him more upset than he already is, you comply. He softly introduces you to several people he seems to know as "a potential new recruit to the cause". Everyone he talks to reacts to this news with relief, with some of them talking about the threat the Dvaereds pose and personal experiences they've had recently with the Dvaereds.

One story stands out to you in particular: an adolescent, no older than 16, mentions their mother who was an official Frontier peace-keeping volunteer. She was accused of being with the FLF after getting into an argument with a Dvaered pilot who was harassing a civilian, and during the argument, the Dvaered opened fire and killed her.]])
homeworld_text.help[3] = _([[Eventually, Flint finishes introducing you to people. You walk back to the spaceport with him in silence.

When you arrive at the spaceport and Flint starts to return to your ship, Flint tells you that your next stop will be {planet} and that he's ready to leave when you are.]])
homeworld_text.neutral = {}
homeworld_text.neutral[1] = _([[As you begin to enter the atmosphere, you notice Flint looking up at a Dvaered formation nearby. "Damn Dvaereds, acting like they own the place.…" The fleet slowly fades from view as you enter the planet's atmosphere. Flint sighs and looks down at the oceanic world.

A moment of silence passes before Flint begins to speak. "I'm going to introduce you to some of the people we fight for." Nervous, you express concern with being out in the open as a part of the FLF. Flint facepalms in response. "God damn, it's like Dvaered propaganda has a direct connection to your brain. Why the hell would you think we'd get anything other than a warm reception as a part of the FLF?"]])
homeworld_text.neutral[2] = _([[Unsure of what else to say, you stammer out an apology for assuming. Flint sighs. "See, this is the problem with you Imperials. You hear the propaganda and you never take a moment to question it, consider that the whole 'terrorist' moniker isn't something most in the Frontier agree with.

"Well, no matter. I'll drill some sense into you by introducing you to some of the actual people who are suffering because of what the Dvaereds are doing, shit the Empire doesn't care about. Listen carefully to what they're saying and actually try to think about how it feels in our shoes."]])
homeworld_text.neutral[3] = _([[When you finish landing procedures, Flint wastes no time. He softly introduces you to several people he seems to know as "a potential new recruit to the cause". Everyone he talks to reacts to this news with relief, with some of them talking about the threat House Dvaered poses and personal experiences they've had recently with Dvaered officers.

One story stands out to you in particular: an adolescent, no older than 16, mentions their mother who was an official Frontier peace-keeping volunteer. She was accused of being with the FLF after getting into an argument with a Dvaered pilot who was harassing a civilian, and during the argument, the Dvaered opened fire and killed her.]])
homeworld_text.neutral[4] = _([[Eventually, Flint finishes introducing you to people. He speaks to you as you and he walk back toward the spaceport. "See? We're not hated or feared here. We're the only protectors the Frontier has."

When you arrive at the spaceport and Flint starts to return to your ship, Flint tells you that your next stop will be {planet} and that he's ready to leave when you are.]])
homeworld_text.learn = {}
homeworld_text.learn[1] = _([[As you begin to enter the atmosphere, you notice Flint looking up at a Dvaered formation nearby. "Damn Dvaereds, acting like they own the place.…" The fleet slowly fades from view as you enter the planet's atmosphere. Flint sighs and looks down at the oceanic world. You ask if he could tell you about his homeworld, and he raises his eyebrows in mild surprise. "Huh, I didn't expect that one. Most people just see it and think, 'That's pretty, look at the oceans!' I swear most pilots see planets as little more than refueling stations.

"It's home to a special algae that we use as medicine, and it's both vital to the health of people in the entire Frontier and in need of delicate conservation, which we've balanced for centuries. But it's more than that. It's my home. Our home. We can't let the Dvaereds take it away from us."]])
homeworld_text.learn[2] = _([[You muse about how living here must be hard since it's right next to Dvaered territory. Flint nods. "It's not as bad as Jorlan, but we do get more than our fair share of Dvaered assholes here. Speaking of, I'd like to introduce you to some folks I know."

After you finish landing, Flint softly introduces you to several people as "a potential new recruit to the cause". Everyone he talks to reacts to this news with relief, with some of them talking about the threat the Dvaereds pose and personal experiences they've had recently with them.

One story stands out to you in particular: an adolescent, no older than 16, mentions their mother who was an official Frontier peace-keeping volunteer. She was accused of being with the FLF after getting into an argument with a Dvaered pilot who was harassing a civilian, and during the argument, the Dvaered opened fire and killed her.]])
homeworld_text.learn[3] = _([[Eventually, Flint finishes introducing you to people. You thank Flint for helping you properly understand some of the struggles of the Frontier, and he raises his eyebrows in surprise again. "Oh! Uh, you're welcome," he says.

When you arrive at the spaceport and Flint starts to return to your ship, Flint tells you that your next stop will be {planet} and that he's ready to leave when you are.]])

jorlan_text = {}
jorlan_text.help = {}
jorlan_text.help[1] = _([[You land on Jorlan, a rocky, lifeless planet. "This place has basically no atmosphere," Flint explains. "The Santa Maria was possibly one of the most unlucky surviving colony ships, but hey, they managed to colonize this place. A lot of the Frontier's materials come from here now. Who would've thought?"

Flint leads you over to a loading bay where he greets a worker in a familiar way, and the worker greets him in return. The worker looks at you curiously and asks who you are. Flint grins in a way that makes his amusement obvious to you, but not so obvious to the worker. "{player} here said they want to volunteer. Let's show {player} the ropes, eh?"]])

jorlan_text.help[2] = _([[Flint and the worker direct you to assist in taking several crates containing goods off of a ship and transporting them to various destinations, mostly delivering supplies to mine workers. "This is the boring stuff we do every day," Flint explains. "You probably don't hear much about it where you're from, do you?" You sheepishly shake your head. You, Flint, and the worker finish delivering all of the goods where they need to go, and you and Flint part ways with the worker as Flint takes you to a room with a large glass ceiling revealing what for lack of a better word you might call a "sky".

"That's the main reason I wanted to take you here, but there's one more reason: right next to here is where the Dvaereds chose to build that damn station." He points up and you see that the Dvaered outpost, Raglan Outpost, is clearly visible. You ask why the Dvaereds would build an outpost there. "The official explanation is that it's to 'expand trade relations and help protect from pirates'," he responds. "But we all know that's bullshit. There's hardly any pirates in this part of the Frontier, and as you just saw, Dvaereds don't exactly help us on the ground. Not only that, the Frontier Council had no real say in its construction." He looks at you and you stare blankly back, unsure where he's going with this. "All this station does is spread the Dvaereds' presence deep into Frontier space. So tell me: for what purpose would the Dvaereds want more of their ships inside of Frontier territory?"]])
jorlan_text.help[3] = _([[Your eyes widen as you realize what Flint is saying. Flint grins for a moment, before his expression becomes serious again. "Invasion," he says. "The Dvaereds for a long time now have wanted to expand their territory into the Frontier.

"The Frontier was lucky, in a way. The Faction Wars kept hyperspace travel out of the Frontier for a long while, and so when the Empire rose to power, we retained our autonomy without having to fight for it. We enjoyed a sort of status, the First Growth colonies, the seniors of space flight, if you will, so the Empire decreed that we were to remain independent. But now, things have changed. The Empire's old promise is still technically valid, but the Empire's grip in this region is essentially gone, and even if the Empire had any real control here, they don't really give a shit about a promise that most of the galaxy has forgotten about."]])
jorlan_text.help[4] = _([[Flint grins. "But there's one thing the Dvaereds didn't count on, one thing stopping them from successfully invading the Frontier: our fighting spirit! Our final stop will be {planet}. Feel free to take a look around here if you like. When you're ready, I'll show you the strength of our undying commitment to fight the Dvaereds, and who you'll be up against if you betray us. The higher-ups of Sindbad may be the brains of the FLF, but the people on the ground are its blood, muscle, and heart."]])
jorlan_text.neutral = {}
jorlan_text.neutral[1] = _([[You land on Jorlan, a rocky, lifeless planet. "This place has basically no atmosphere," Flint explains. "The Santa Maria was possibly one of the most unlucky surviving colony ships, but hey, they managed to colonize this place. A lot of the Frontier's materials come from here now. Who would've thought?

Flint leads you over to a loading bay where he greets a worker in a familiar way, and the worker greets him in return. The worker looks at you curiously and asks if you're a volunteer. You stammer for an answer as Flint grins with amusement. "Well, {player}? Are you going to help us?" Unsure of what to say, you sheepishly agree to help them.]])

jorlan_text.neutral[2] = _([[You assist Flint and the worker in taking several crates containing goods off of a ship and transporting them to various destinations, mostly delivering supplies to mine workers. "This is the boring stuff we do every day," Flint explains before letting out a grin. "You probably don't hear about this where you're from, huh? Did you really think we spend all our time getting into fights?" You sheepishly help to deliver all of the goods where they need to go, unable to answer. After finishing the job, you and Flint part ways with the worker as Flint takes you to a room with a large glass ceiling revealing what for lack of a better word you might call a "sky".

"That's the main reason I wanted to take you here, but there's one more reason: right next to here is where the Dvaereds chose to build that damn station." He points up and you see that the Dvaered outpost, Raglan Outpost, is clearly visible. You ask why the Dvaereds would build an outpost there. "The official explanation is that it's to 'expand trade relations and help protect from pirates'," he responds. "But we all know that's bullshit. There's hardly any pirates in this part of the Frontier, and as you just saw, Dvaereds don't exactly help us on the ground. Not only that, the Frontier Council had no real say in its construction." He looks at you. "All this station does is spread the Dvaereds' presence deep into Frontier space. So tell me: for what purpose would the Dvaereds want more of their ships inside of Frontier territory?"]])
jorlan_text.neutral[3] = _([[Unsure of what he's getting at, you say honestly that you don't know what the purpose could be, acknowledging that you can't think of any good reason for it. "Damn, you really are as naïve as you look, aren't you?" He sighs. "They're planning an invasion." You stare blankly, unsure of what to say, then look up at the station and then back to him. You non-noncommittally acknowledge the possibility. Indeed, it does make sense that the outpost would serve that purpose well. Flint sighs and continues. "The Dvaereds have wanted to expand their territory into the Frontier for a long time now.

"The Frontier was lucky, in a way. The Faction Wars kept hyperspace travel out of the Frontier for a long while, and so when the Empire rose to power, we retained our autonomy without having to fight for it. We enjoyed a sort of status, the First Growth colonies, the seniors of space flight, if you will, so the Empire decreed that we were to remain independent. But now, things have changed. The Empire's old promise is still technically valid, but the Empire's grip in this region is essentially gone, and even if the Empire had any real control here, they don't really give a damn about a promise that most of the galaxy has forgotten about."]])
jorlan_text.neutral[4] = _([[Flint looks toward you. "The one thing stopping the Dvaereds from successfully invading the Frontier is the thing they didn't count on: our fighting spirit. Sindbad may be the brains of the FLF, but those of us who work on the ground are its blood, muscle, and heart!"

You notice a poorly contained burst of passion from Flint, which piques your interest. Wondering what other FLF soldiers are really like, you ask Flint if he could show you that fighting spirit. Surprised, Flint stares at you for a moment, as if evaluating you. "Huh, that's the first good sign I've seen from you this whole trip. Maybe this trip wasn't a waste after all. Alright, I'll take you to {planet} and introduce you to some of my comrades. I'm ready when you are."]])
jorlan_text.learn = {}
jorlan_text.learn[1] = _([[You land on Jorlan, a rocky, lifeless planet. "This place has basically no atmosphere," Flint explains. "The Santa Maria was possibly one of the most unlucky surviving colony ships, but hey, they managed to colonize this place. A lot of the Frontier's materials come from here now. Who would've thought?

Flint leads you over to a loading bay where he greets a worker in a familiar way, and the worker greets him in return. The worker looks at you curiously and asks who you are. "{player} here wants to learn the ropes," Flint answers. He then directs his attention at you. "{player}, come help us out. I'd bet you probably don't hear much about this work we do where you're from."]])

jorlan_text.learn[2] = _([[You assist Flint and the worker in taking several crates containing goods off of a ship and transporting them to various destinations, mostly delivering supplies to mine workers. "This is the boring stuff we do every day," Flint explains. You nod and help to deliver all of the goods where they need to go. After finishing the job, you and Flint part ways with the worker as Flint takes you to a room with a large glass ceiling revealing what for lack of a better word you might call a "sky".

"That's the main reason I wanted to take you here, but there's one more reason: right next to here is where the Dvaereds chose to build that damn station." He points up and you see that the Dvaered outpost, Raglan Outpost, is clearly visible. You ask why the Dvaereds would build an outpost there. "The official explanation is that it's to 'expand trade relations and help protect from pirates'," he responds. "But we all know that's bullshit. There's hardly any pirates in this part of the Frontier, and as you just saw, Dvaereds don't exactly help us on the ground. Not only that, the Frontier Council had no real say in its construction." He looks at you. "All this station does is spread the Dvaereds' presence deep into Frontier space. So tell me: for what purpose would the Dvaereds want more of their ships inside of Frontier territory?"]])
jorlan_text.learn[3] = _([[Your eyes widen as you realize what Flint is saying. "Invasion," he says. "The Dvaereds for years have wanted to expand their territory into the Frontier.

"The Frontier was lucky, in a way. The Faction Wars kept hyperspace travel out of the Frontier for a long while, and so when the Empire rose to power, we retained our autonomy without having to fight for it. We enjoyed a sort of status, the First Growth colonies, the seniors of space flight, if you will, so the Empire decreed that we were to remain independent. But now, things have changed. The Empire's old promise is still technically valid, but the Empire's grip in this region is essentially gone, and even if the Empire had any real control here, they wouldn't risk the little power they have left for the sake of a promise that most of the galaxy has forgotten about."]])
jorlan_text.learn[4] = _([[Flint grins. "But there's one thing the Dvaereds didn't count on, one thing stopping them from successfully invading the Frontier: our fighting spirit! Our final stop will be {planet}. Feel free to take a look around here if you like. When you're ready, I'll show you the strength of our undying commitment to fight the Dvaereds! The higher-ups of Sindbad may be the brains of the FLF, but the people on the ground are its blood, muscle, and heart."]])

norpin_text = {}
norpin_text[1] = _([[As you exit your ship after landing, several faces warmly greet Flint and some begin to question who you are. Flint explains that you're a former Imperial who wants to join the cause. Most of them laugh at the statement. "We'll see about that," one of them says. "But hey, not much you can do here even if you have ill intent. The Dvaereds already know we hate their guts here."

Flint turns to you. "Ah, yeah, that's right, I should introduce you. These are some of my comrades. They work here at the shipyard." You introduce yourself, and Flint chats with them for a little longer before they go back to their jobs.]])
norpin_text[2] = _([[The two of you begin approaching the bar. "You may have heard rumors that the shipyard here supplies ships for us," Flint says. "That's actually true, but this shipyard also supplies ships for the Frontier volunteer peacekeeping force. That's another reason the Dvaereds put Raglan Outpost where they did. It's a choke point; right now, it makes it much harder for FLF ships to be supplied by this shipyard, which is why we also build ships on Sindbad. But if the Dvaereds go to war with the Frontier officially, that will be the case for Frontier ships as well.

"The Dvaereds are scared of us, as they should be." You and Flint reach the bar, where you see someone in a Dvaered military outfit harassing a visibly nervous bartender, accompanied by another person in a Dvaered military outfit. "Well, apparently this guy clearly isn't scared enough… but that's just about to change. Pay close attention, {player}."]])
norpin_text[3] = _([[As if on cue, a group of three visibly angry patrons steps up behind the Dvaered soldiers. "It seems we have ourselves a problem here," one of them blurts out as the bartender sighs in relief and turns to look away from the scene.

The Dvaered soldiers turn to face the patrons. "Oh yeah? You'd dare talk to someone of my standing like that? I'll have you know—" One of the patrons interrupts the soldier with a punch in the face, and a scuffle breaks out between the three patrons and the two soldiers. Eventually, a fourth and fifth patron join the scuffle against the Dvaered soldiers. Overwhelmed, the Dvaered soldiers flee from the bar, Flint grins, and the bartender finally turns back around, feigning ignorance.

With the commotion over, Flint walks over to the patrons who started the scene, greets them, and gives them all high-fives. It seems they know each other, and he introduces you to them.]])
norpin_text[4] = _([[You and Flint walk out of the bar with the group. Flint speaks to you. "That's not the biggest part of our job, of course, but it's certainly the hardest. We don't let the Dvaered oppressors intimidate us or our Frontier brethren. So then, {player}, what do you think?" You think about your answer for a moment, but you don't have long before you and the group spot the same two Dvaered soldiers you spotted at the bar. "Get away from the group," he says to you. "This could get ugly and we'll probably be separated. Don't worry about me, I've got plenty of connections here and I'll be able to get off with my own ship no problem." He grins. "I'm sure I'll see you again, one way or another."

You do as he says and leave the group, placing yourself inconspicuously on a bench a distance away. You manage to do this not a moment too soon, it seems, as immediately afterwards the Dvaereds take notice of the group. You hear some back and forth, but can't make out what is being said. What you do notice, however, is the Dvaereds drawing what appear to be laser guns.]])
norpin_text[5] = _([[The FLF group immediately responds by drawing their own laser guns and before you know it, a gunfight ensues. Someone from the FLF side is hit first, taking a bolt to the leg, followed by one of the Dvaereds getting hit in the stomache, knocking him out. You immediately see a difference between the two sides as while Flint helps his now limping comrade escape while the others continue drawing attention from the uninjured Dvaered, the uninjured Dvaered continues shooting the remainder of the FLF group without so much as a glance to the injured Dvaered.

Flint and his injured comrade soon escape the scene, and the others in the FLF group run off in a different direction shortly after. Seeing this, the uninjured Dvaered pursues them, leaving his comrade lying on the ground.

Now alone, you decide to go off on your own business, wondering how things will go the next time you meet Flint.]])

motive_text = {}
motive_text.help = _("To help the FLF")
motive_text.neutral = _("Just helping a pilot in need")
motive_text.learn = _("To learn about the Frontier's struggle")

npc_desc = _("This man eyes you with a very icy stare. It seems he doesn't trust you.")

misn_title = _("Plight of the Frontier")
misn_desc = {}
misn_desc.help = _([[You angered an FLF soldier called Flint when you told him that you seek to help the Frontier. In response, he offered to "show you personally what's going on in the Frontier". He said that he hopes to "get you to chuck that shitty pretentiousness of yours out the window".]])
misn_desc.neutral = _([[You angered an FLF soldier called Flint when you told him that you're neutral in the conflict between the FLF and House Dvaered. In response, he offered to show you what's going on in the Frontier. He said that you will "see soon why being neutral in this conflict is unacceptable".]])
misn_desc.learn = _([[You surprised an FLF soldier called Flint when you told him that you wish to learn more about the Frontier and the struggles of the FLF. In response, he offered to give you a tour of the Frontier. "I'm not used to having someone who actually wants to learn of our struggles, but I'll do my best to enlighten you."]])

log_text = _("An FLF soldier named Flint showed you around the frontier so that you could understand the struggles of the Frontier better. You ended up separated from him as he got involved in a gunfight with Dvaered soldiers on {planet}.")


function create ()
   homepla, homesys = planet.get("Cetrat")
   invpla, invsys = planet.get("Jorlan")
   resistpla, resistsys = planet.get("Norpin II")

   -- Variable storing the player's motive. Can be "help", "neutral",
   -- or "learn". nil indicates that the player hasn't given a reason
   -- yet.
   motive = nil

   -- Stage variable to keep track of what planet is next.
   stage = 1

   misn.setNPC(_("A skeptical man"), "flf/unique/flint.png", npc_desc)
end


function accept ()
   local text
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

      text = answer_text[motive]
   else
      text = return_text[motive]
   end

   if tk.yesno("", text) then
      misn.accept()
      tk.msg("", fmt.f(response_yes[motive], {planet=homepla:name()}))

      misn.setTitle(misn_title)
      misn.setDesc(misn_desc[motive])
      misn.setReward(_("None"))

      local osd_desc = {
         fmt.f(_("Land on {planet} ({system} system)"),
            {planet=homepla:name(), system=homesys:name()}),
         fmt.f(_("Land on {planet} ({system} system)"),
            {planet=invpla:name(), system=invsys:name()}),
         fmt.f(_("Land on {planet} ({system} system)"),
            {planet=resistpla:name(), system=resistsys:name()}),
      }
      misn.osdCreate(misn_title, osd_desc)

      marker = misn.markerAdd(homesys, "plot")

      hook.land("land")
   else
      tk.msg("", response_no[motive])
      misn.finish()
   end
end


function land ()
   if stage == 1 and planet.cur() == homepla then
      for i, s in ipairs(homeworld_text[motive]) do
         if i == #homeworld_text[motive] then
            s = fmt.f(s, {player=player.name(), planet=invpla:name()})
         end
         tk.msg("", s)
      end

      stage = 2
      misn.osdActive(2)
      misn.markerMove(marker, invsys)
   elseif stage == 2 and planet.cur() == invpla then
      for i, s in ipairs(jorlan_text[motive]) do
         if i == #jorlan_text[motive] then
            s = fmt.f(s, {player=player.name(), planet=resistpla:name()})
         end
         tk.msg("", s)
      end

      stage = 3
      misn.osdActive(3)
      misn.markerMove(marker, resistsys)
   elseif stage == 3 and planet.cur() == resistpla then
      for i, s in ipairs(norpin_text) do
         if i == #norpin_text then
            s = fmt.f(s, {player=player.name(), planet=resistpla:name()})
         end
         tk.msg("", s)
      end

      flf_addLog(fmt.f(log_text, {planet=resistpla:name()}))
      misn.finish(true)
   end
end

