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
answer_text.help = _([[You tell the man that you have heard of the struggles of the FLF and want to help fight the Dvaered. The main frowns. "OK, first of all, who the hell do you think you are? Do you think you, an outsider who doesn't even understand the struggles of the Frontier, are going to be our savior? Why are you people always so damn full of yourselves?!" Unsure of what to say, your eyes shift from his gaze to the floor below you. Despite this, you can feel his eyes on you as strongly as ever.

"Let's get one thing straight: you're not going to be the one to fly in and cure all our problems any more than you're going to fly in and destroy us. We've been working hard to save the Frontier for a long time now. If you have any part at all in this, it will be on the back of the many of us who have worked on this project all this time, and who actually have a stake in it."

He sighs once again, then stands up. "That said, if you really do want to help, you need to understand our struggles properly. So I'll tell you what: I'm about to go on some errands in a couple hours, and I'm willing to take you with me. Well? Will you still help, knowing that it's not going to be the ridiculous action fantasy you believe in?"]])
answer_text.neutral = _([[You tell the man that you are just a fellow pilot who helped someone in need. You say that you are neutral on the conflict between House Dvaered and the FLF and promise not to rat out the FLF to the authorities. He frowns and his face becomes filled with rage. "Neutral?! How could you be neutral in this? We in the Frontier are just struggling to live our damn lives! You seriously believe the Dvaered propaganda about us as a 'terrorist organization' without question?!" You knew you weren't trusted, but you certainly didn't expect this level of anger. You open your mouth to answer, but not knowing what to say, you close it again and your eyes shift to the floor below you. Around you, you hear murmurs of agreement; it seems his outburst has attracted an audience, and this audience is firmly against you.

The man lets out another sigh, then stands up. "If it were up to me, I'd exile you from this station right now if not imprison you. Since I can't do that, though, I'll give you a deal. I'm about to go on some errands in the Frontier in a couple hours. Just the everyday stuff the Dvaereds don't tell you we're involved with." The offer takes you by surprise, as does the mention of "everyday stuff" which the Dvaereds don't talk about. Could it be that the FLF does something other than fighting Dvaered ships? You stand there silently, transfixed by the man's eyes as you consider his sudden offer. "Well?" he says, breaking you out of your trance. "I'm doing you a pretty big damn favor with this offer. Are you gonna take me up on it or not?"]])
answer_text.learn = _([[You tell the man that you don't know much about the Frontier or the FLF, given your background having been raised in the Empire, and that you wish to learn more about the Frontier and the struggles of the FLF. The man raises an eyebrow. "Uh, what? You said it yourself, the Frontier is what we're fighting for. Up here in the nebula is entirely the wrong place to learn about our struggle. Didn't you consider going to, you know, the Frontier?"

You open your mouth to speak, but Flint raises his hand in indication that he doesn't want to hear it. "Look, assuming you're not lying to me, you have the right idea. But we're busy in the FLF. We're not here to be your damn teacher." He pauses, then stands up. "I'll tell you what: this is a bit of a pain in the ass, but since I have work to do in the Frontier that'll teach you a thing or two, you can accompany me on some errands. Are you interested?"]])

return_text = {}
return_text.help = _([[Flint gets out of his seat and shoots a glare at you that's starting to become familiar. "I see you're back. Have you changed your mind about my offer to accompany me on my errands in the Frontier?"]])
return_text.neutral = return_text.help
return_text.learn = _([["The offer to have you accompany me on those errands is still on the table. Have you changed your mind?"]])

response_no = {}
response_no.help = _([[The man frowns, then silently returns to his seat and crosses his arms.]])
response_no.neutral = response_no.help
response_no.learn = _([[You thank the man, but say you are currently busy with something else. He raises an eyebrow. "You're really turning me down like that? Whatever," he says as he sits back down. "Let me know if you change your mind. I'll be leaving in an hour, so make it quick."]])

response_yes = {}
response_yes.help = _([[The man grins. "Perfect. Maybe I can get you to chuck that shitty pretentiousness of yours out the window and show you what the FLF is really about. We'll first be going to my homeworld, {planet}, to help out on the algae farm. So yeah, not the exciting combat I'm sure a mercenary type like you was expecting.

"The name's Flint, by the way." You likewise tell Flint your own name. "I'll meet you at the landing bay. I would fly my own ship, but since you're not officially a part of the FLF, we'll have an easier time if I join you on your ship. Should avoid confrontations with the Dvaereds and allow us to make better time. Don't you even think about trying anything funny. See you soon."

As Flint walks toward the landing bay, you ponder his words. So-called "algae farming" was not at all what you expected to do with the FLF, given its reputation in Dvaered space, but you resolve to find out why this is apparently so important to him.]])
response_yes.neutral = _([["Good. Let's nip that shitty perception you have of what we're about in the bud. We'll first be going to my homeworld, {planet}, to help out on the algae farm. Yeah, not exactly the violence you expect from us based on the distorted picture the Dvaereds give you, eh?

"The name's Flint, by the way. Flint as in if you try to turn me over to the Dvaereds, I'll light a fire in your ass." As the FLF soldiers around you chuckle at Flint's remark, you tell Flint your own name, then promise that you won't double-cross him. "Good. I'll meet you at the landing bay. I would fly my own ship, but you being neutral means that we can avoid detection from the Dvaereds and make better time. Besides, I don't trust you to have my back. At least if I'm on your ship, I can kill you and steal the ship, eh?" You let out a nervous laugh as he turns and walks toward the direction of the landing bay. You begin to wonder just what this so-called "algae farm" is about. You thought the FLF was just a military group, but you decide to keep an open mind.]])
response_yes.learn = _([["Alright, then. I'm sure this'll be the learning experience you were looking for. Don't you forget, though, I'm doing you a favor. Our destination is my homeworld, {planet}. I'll let you do the flying.

"Oh, my name's Flint, by the way. And, uh, this should go without saying, but I still don't trust you, and I'm prepared to defend myself if I need to. We FLF soldiers are pretty damn good with a laser gun." He playfully winks. You laugh nervously, introduce yourself in turn, and promise you won't do anything funny. "Good," he responds with a stern look. "I'll be waiting at the landing bay when you're ready."

Flint turns away, waves, and walks toward the landing bay. Despite the threat, you detect that Flint at least isn't openly hostile, and you let out a sigh in relief. You wonder what sort of "errands" he's taking you on.]])

homeworld_text = {}
homeworld_text.help = {}
homeworld_text.help[1] = _([[As you begin to enter the atmosphere, you notice Flint looking up at a Dvaered formation nearby. "Damn Dvaereds, acting like they own the place.…" The fleet slowly fades from view as you enter the planet's atmosphere. Flint sighs and looks down at the oceanic world. You also look down and are taken in by the beauty of it, voicing this on reflex. Flint sighs with annoyance.

"You said you wanted to 'help', right? So you'd better not be treating this like a damn field trip. I don't know what you see, but what I see is my home that can't function in intergalactic affairs properly because the damn Dvaereds are always harassing us." An awkward silence fills your cockpit as landing completes.]])
homeworld_text.help[2] = _([["Ok, I want you to keep your mouth shut and follow our instructions at the algae farm," Flint tells you as soon as you finish landing procedures. Not wanting to make him more upset than he already is, you comply. As you arrive at the algae farm, Flint softly introduces you as "a potential new recruit to the cause" who wants to volunteer. The workers react with surprise, but appreciation, and you are assigned a task which you perform without protest, even though it's one that you find dull.

While you work, you hear a harrowing tale from one of the workers, who appears to be an adolescent, no older than 16. Their mother, who was an official Frontier peace-keeping volunteer, was accused of being with the FLF after getting into an argument with a Dvaered pilot who was harassing a civilian, and during the argument, the Dvaered opened fire and killed her.]])
homeworld_text.help[3] = _([[Eventually, the work is finished and you leave the site covered in some kind of sludge-like substance and feeling incredibly tired, but you see that Flint is in high spirits, despite being similarly dirty. "It feels great to help on the farm," Flint remarks. "Knowing I'm helping save lives and protect our way of life. So many outsiders just don't appreciate the real work on the ground." You don't feel so sure of that statement, but tactfully decide to keep this to yourself.

When you arrive at the spaceport and Flint starts to return to your ship, Flint tells you that your next stop will be {planet} and that he's ready to leave when you are.]])
homeworld_text.neutral = {}
homeworld_text.neutral[1] = _([[As you begin to enter the atmosphere, you notice Flint looking up at a Dvaered formation nearby. "Damn Dvaereds, acting like they own the place.…" The fleet slowly fades from view as you enter the planet's atmosphere. Flint sighs and looks down at the oceanic world. "Well, right now our objective is to help out at the algae farm."

Nervous, you express concern with being out in the open as a part of the FLF. Flint facepalms in response. "God damn, it's like Dvaered propaganda has a direct connection to your brain. Why the hell would you think we'd get anything other than a warm reception as a part of the FLF?"]])
homeworld_text.neutral[2] = _([[Unsure of what else to say, you stammer out an apology for assuming. Flint sighs. "See, this is the problem with you Imperials. You hear the propaganda and you never take a moment to question it, consider that the whole 'terrorist' moniker isn't something most in the Frontier agree with.

"Well, no matter. I'll drill some sense into you by showing you directly. Everyone here knows that I'm a part of the FLF, and everyone appreciates that. Pay close attention while we're at the farm and even you should be able to see it."]])
homeworld_text.neutral[3] = _([[When you finish landing procedures, Flint wastes no time. As you arrive at the algae farm, Flint softly introduces you as "a potential new recruit to the cause" who wants to volunteer. The workers react with surprise, but appreciation, and you are assigned a series of tasks as they make small talk with Flint, who openly talks about his exploits with the FLF. Just as Flint said, it's clear that they all know that he's a part of the FLF and consider that to be a positive quality.

Among the smalltalk, you hear a harrowing tale from one of the workers, who appears to be an adolescent, no older than 16. Their mother, who was an official Frontier peace-keeping volunteer, was accused of being with the FLF after getting into an argument with a Dvaered pilot who was harassing a civilian, and during the argument, the Dvaered opened fire and killed her. Surprisingly to you, all of the workers exclusively blame the Dvaered officers, hoping the FLF manages to drive them out one day.]])
homeworld_text.neutral[4] = _([[Eventually, the work is finished and you leave the site incredibly dirty and a bit exhausted from the work, but your focus is entirely on the number of familiar greetings you see as you and Flint walk around.

When you arrive at the spaceport and Flint starts to return to your ship, Flint tells you that your next stop will be {planet} and that he's ready to leave when you are.]])
homeworld_text.learn = {}
homeworld_text.learn[1] = _([[As you begin to enter the atmosphere, you notice Flint looking up at a Dvaered formation nearby. "Damn Dvaereds, acting like they own the place.…" The fleet slowly fades from view as you enter the planet's atmosphere. Flint sighs and looks down at the oceanic world. You ask if he could tell you about his homeworld, and he raises his eyebrow, a gesture you've seen before. "Uh, I don't mean to be rude, but you do know you can just read the spaceport planet description, right? That's what it's for, so you can learn about it.

"But, I mean, if you want to know what this planet is to me personally? It's my home. It's that simple. And we have a lot of trouble with exports thanks to the damn Dvaereds all over the place, always harassing innocent people and accusing them of being 'FLF terrorists'. I don't even want to think about what they'd do if they annexed us. Probably would destroy everything we have so they could mine that shitty ore beneath the surface."]])
homeworld_text.learn[2] = _([[After you finish landing, Flint takes you to what looks like some sort of algae farm, where he softly introduces you to workers as "a potential new recruit to the cause" and explains that you're volunteering for the algae farm. The workers note their surprise at an outsider volunteer, but nonetheless you are welcomed and assigned a number of tasks before you know it.

While you work, you hear a harrowing tale from one of the workers, who appears to be an adolescent, no older than 16. Their mother, who was an official Frontier peace-keeping volunteer, was accused of being with the FLF after getting into an argument with a Dvaered pilot who was harassing a civilian, and during the argument, the Dvaered opened fire and killed her.]])
homeworld_text.learn[3] = _([[Eventually, the work is finished and you leave the site incredibly dirty, but nonetheless in high spirits. When you arrive at the spaceport and Flint starts to return to your ship, he tells you that your next stop will be {planet} and that he's ready to leave when you are.]])

jorlan_text = {}
jorlan_text.help = {}
jorlan_text.help[1] = _([[You land on Jorlan, a rocky, lifeless planet. "This place has basically no atmosphere," Flint explains. "The Santa Maria was possibly one of the most unlucky surviving colony ships, but hey, they managed to colonize this place. A lot of the Frontier's materials come from here now. Who would've thought?"

Flint leads you over to a loading bay where he greets a worker in a familiar way, and the worker greets him in return. The worker looks at you curiously and asks who you are. Flint grins in a way that makes his amusement obvious to you, but not so obvious to the worker. "{player} here said they want to volunteer. Let's show {player} the ropes, eh?"]])

jorlan_text.help[2] = _([[You assist Flint and the worker in taking several crates containing goods off of a ship and transporting them to various destinations, mostly delivering supplies to mine workers. It's again a tedious job, but you somehow feel better about it seeing all the smiles of the people you deliver the goods to, like you're a part of something important. Perhaps this is the joy Flint felt back at the algae farm.

After finishing the job, you and Flint part ways with the worker. You sheepishly thank Flint as you and he walk into a room with a large glass ceiling revealing what for lack of a better word you might call a "sky". Flint looks up as if instinctively, and you in turn also look up, leading you to see how plainly visible Raglan Outpost, the nearby Dvaered outpost, is. You wonder aloud why the Dvaereds would build an outpost there.

"The official explanation is that it's to 'expand trade relations and help protect from pirates'," Flint responds. "But we all know that's bullshit. There's hardly any pirates in this part of the Frontier, and as you just saw, Dvaereds don't exactly help us on the ground. Not only that, the Frontier Council had no real say in its construction." He looks at you. "All this station does is spread the Dvaereds' presence deep into Frontier space. So tell me: for what purpose would the Dvaereds want more of their ships inside of Frontier territory?"]])
jorlan_text.help[3] = _([[Your eyes widen as you realize what Flint is saying. Flint grins for a moment, before his expression becomes serious again. "Invasion," he says. "The Dvaereds for a long time now have wanted to expand their territory into the Frontier.

"The Frontier was lucky, in a way. The Faction Wars kept hyperspace travel out of the Frontier for a long while, and so when the Empire rose to power, we retained our autonomy without having to fight for it. We enjoyed a sort of status, the First Growth colonies, the seniors of space flight, if you will, so the Empire decreed that we were to remain independent. But now, things have changed. The Empire's old promise is still technically valid, but the Empire's grip in this region is essentially gone, and even if the Empire had any real control here, they don't really give a shit about a promise that most of the galaxy has forgotten about."]])
jorlan_text.help[4] = _([[Flint grins. "Our fighting spirit won't flounder, though. One of these days, that damn station will be gone, and we'll drive out the Dvaereds once and for all." Flint looks at you as he continues speaking. "You know what, you've been helpful enough that I'm willing to show you that fighting spirit. It's what you thought was all the FLF is about, eh?" You blush at the remark as Flint lets out a laugh. "Alright, I think I've sufficiently fixed that shitty perception of yours.

"You weren't entirely wrong that fighting is a big part of what we do. You had the scope all wrong, but yeah, we do use guns and muscle to protect our home and keep it safe. Take us to {planet} as our last destination and I'll introduce you to some of my comrades, the kind of folks you'll likely be working with the most."]])
jorlan_text.neutral = {}
jorlan_text.neutral[1] = _([[You land on Jorlan, a rocky, lifeless planet. "This place has basically no atmosphere," Flint explains. "The Santa Maria was possibly one of the most unlucky surviving colony ships, but hey, they managed to colonize this place. A lot of the Frontier's materials come from here now. Who would've thought?

Flint leads you over to a loading bay where he greets a worker in a familiar way, and the worker greets him in return. The worker looks at you curiously and asks if you're a volunteer. You stammer out an affirmative answer as Flint grins with amusement. "{player} here doesn't know the ropes yet," Flint says in an almost teasing tone. "New to the FLF and all that. We'll show them a good time, eh?"]])

jorlan_text.neutral[2] = _([[You assist Flint and the worker in taking several crates containing goods off of a ship and transporting them to various destinations, mostly delivering supplies to mine workers. After finishing the job, you and Flint part ways with the worker as you wander into a room with a large glass ceiling revealing what for lack of a better word you might call a "sky". Flint looks up as if by instinct. "Raglan Outpost," he mutters. "One of these days, that damn station will go up in smoke, I swear."

You ask why the Dvaereds would build an outpost there. "The official explanation is that it's to 'expand trade relations and help protect from pirates'," he responds. "But we all know that's bullshit. There's hardly any pirates in this part of the Frontier, and as you just saw, Dvaereds don't exactly help us on the ground. Not only that, the Frontier Council had no real say in its construction." He looks at you. "All this station does is spread the Dvaereds' presence deep into Frontier space. So tell me: for what purpose would the Dvaereds want more of their ships inside of Frontier territory?"]])
jorlan_text.neutral[3] = _([[Unsure of what he's getting at, you say honestly that you don't know what the purpose could be, acknowledging that you can't think of any good reason for it. "Damn, you really are as naïve as you look, aren't you?" He sighs. "They're planning an invasion." You stare blankly, unsure of what to say, then look up at the station and then back to him. You noncommittally acknowledge the possibility. Indeed, it does make sense that the outpost would serve that purpose well. Flint sighs and continues. "The Dvaereds have wanted to expand their territory into the Frontier for a long time now.

"The Frontier was lucky, in a way. The Faction Wars kept hyperspace travel out of the Frontier for a long while, and so when the Empire rose to power, we retained our autonomy without having to fight for it. We enjoyed a sort of status, the First Growth colonies, the seniors of space flight, if you will, so the Empire decreed that we were to remain independent. But now, things have changed. The Empire's old promise is still technically valid, but the Empire's grip in this region is essentially gone, and even if the Empire had any real control here, they don't really give a damn about a promise that most of the galaxy has forgotten about."]])
jorlan_text.neutral[4] = _([[Flint looks toward you. "The one thing stopping the Dvaereds from successfully invading the Frontier is the thing they didn't count on: our fighting spirit. You know, that thing the Dvaereds call 'terrorism'. Look, you don't know shit about why we fight the Dvaereds, do you? So I'll tell you what: I'll show you directly by taking you to {planet} and introducing you to some of my comrades. You may still yet be a lost cause, but you did willingly help out with my errands, and besides, it's only a small detour, and there's no way you'd be able to do anything funny there with my comrades all around.

"So, {planet} will be our last stop. I'm ready when you are."]])
jorlan_text.learn = {}
jorlan_text.learn[1] = _([[You land on Jorlan, a rocky, lifeless planet. "This place has basically no atmosphere," Flint explains. "The Santa Maria was possibly one of the most unlucky surviving colony ships, but hey, they managed to colonize this place. A lot of the Frontier's materials come from here now. Who would've thought?

Flint leads you over to a loading bay where he greets a worker in a familiar way, and the worker greets him in return. The worker looks at you curiously and asks who you are. "{player} here wants to learn the ropes and volunteer to help us out," Flint answers. The worker looks at you slightly confused, but nonetheless offers you her hand, which you shake.]])

jorlan_text.learn[2] = _([[You assist Flint and the worker in taking several crates containing goods off of a ship and transporting them to various destinations, mostly delivering supplies to mine workers. After finishing the job, you and Flint part ways with the worker as Flint takes you to a room with a large glass ceiling revealing what for lack of a better word you might call a "sky". Flint looks up as if instinctively, and you in turn also look up, leading you to see how plainly visible Raglan Outpost, the nearby Dvaered outpost, is. You wonder aloud why the Dvaereds would build an outpost there.

"The official explanation is that it's to 'expand trade relations and help protect from pirates'," Flint responds. "But we all know that's bullshit. There's hardly any pirates in this part of the Frontier, and as you just saw, Dvaereds don't exactly help us on the ground. Not only that, the Frontier Council had no real say in its construction." He looks at you. "All this station does is spread the Dvaereds' presence deep into Frontier space. So tell me: for what purpose would the Dvaereds want more of their ships inside of Frontier territory?"]])
jorlan_text.learn[3] = _([[Your eyes widen as you realize what Flint is saying. "Invasion," he says. "The Dvaereds for years have wanted to expand their territory into the Frontier.

"The Frontier was lucky, in a way. The Faction Wars kept hyperspace travel out of the Frontier for a long while, and so when the Empire rose to power, we retained our autonomy without having to fight for it. We enjoyed a sort of status, the First Growth colonies, the seniors of space flight, if you will, so the Empire decreed that we were to remain independent. But now, things have changed. The Empire's old promise is still technically valid, but the Empire's grip in this region is essentially gone, and even if the Empire had any real control here, they wouldn't risk the little power they have left for the sake of a promise that most of the galaxy has forgotten about."]])
jorlan_text.learn[4] = _([[Flint grins. "Our fighting spirit won't flounder, though. One of these days, that damn station will be gone, and we'll drive out the Dvaereds once and for all." Flint looks at you as he continues speaking. "You know what, you've been helpful enough that I'm willing to show you that fighting spirit. Take us to {planet} as our last destination. There's nothing we need to do there in particular, but I trust you just enough to introduce you to some of my comrades."]])

norpin_text = {}
norpin_text[1] = _([[As you exit your ship after landing, several faces warmly greet Flint and some begin to question who you are. Flint explains that you're a former Imperial who wants to join the cause. Most of them laugh at the statement. "We'll see about that," one of them says. "But hey, not much you can do here even if you have ill intent. The Dvaereds already know we hate their guts here."

Flint turns to you. "Ah, yeah, that's right, I should introduce you. These are some of my comrades. They work here at the shipyard." You introduce yourself, and Flint chats with them for a little longer before they go back to their jobs.]])
norpin_text[2] = _([[The two of you begin approaching the bar. "You may have heard rumors that the shipyard here supplies ships for us," Flint says. "That's actually true, but this shipyard also supplies ships for the Frontier volunteer peacekeeping force. That's another reason the Dvaereds put Raglan Outpost where they did. It's a choke point; right now, it makes it much harder for FLF ships to be supplied by this shipyard, which is why we also build ships on Sindbad. But if the Dvaereds go to war with the Frontier officially, that will be the case for Frontier ships as well.

"The Dvaereds are scared of us, as they should be." You and Flint reach the bar, where you see someone in a Dvaered military outfit harassing a visibly nervous bartender, accompanied by another person in a Dvaered military outfit. "Well, clearly this asshole isn't scared enough.…"]])
norpin_text[3] = _([[As if on cue, a group of three visibly angry patrons steps up behind the Dvaered soldiers. "It seems we have ourselves a problem here," one of them blurts out as the bartender sighs in relief and turns to look away from the scene.

The Dvaered soldiers turn to face the patrons. "Oh yeah? You'd dare talk to someone of my standing like that? I'll have you know—" One of the patrons interrupts the soldier with a punch in the face, and a scuffle breaks out between the three patrons and the two soldiers. Eventually, a fourth and fifth patron join the scuffle against the Dvaered soldiers. Overwhelmed, the Dvaered soldiers flee from the bar, Flint grins, and the bartender finally turns back around, feigning ignorance.

With the commotion over, Flint walks over to the patrons who started the scene, greets them, and gives them all high-fives. It seems they know each other, and he introduces you to them.]])
norpin_text[4] = _([[You and Flint walk out of the bar with the group. Flint speaks to you. "That's not the biggest part of our job, of course, but it's certainly the hardest. We don't let the Dvaered oppressors intimidate us or our Frontier brethren." Suddenly you and the group spot the same two Dvaered soldiers you spotted at the bar. "Get away from the group," Flint says to you. "This could get ugly and we'll probably be separated. There's no way in hell I trust you enough to not hinder us in this situation. Don't worry about me, I've got plenty of connections here and I'll be able to get off with my own ship no problem." He grins. "I'm sure I'll see you again, one way or another."

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
         else
            s = fmt.f(s, {player=player.name()})
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
         else
            s = fmt.f(s, {player=player.name()})
         end
         tk.msg("", s)
      end

      stage = 3
      misn.osdActive(3)
      misn.markerMove(marker, resistsys)
   elseif stage == 3 and planet.cur() == resistpla then
      for i, s in ipairs(norpin_text) do
         s = fmt.f(s, {player=player.name(), planet=resistpla:name()})
         tk.msg("", s)
      end

      flf_addLog(fmt.f(log_text, {planet=resistpla:name()}))
      misn.finish(true)
   end
end

