--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Spaceport Bar NPC">
 <trigger>land</trigger>
 <chance>100</chance>
</event>
--]]

--[[
-- Event for creating random characters in the spaceport bar.
-- The random NPCs will tell the player things about the Naikari
-- universe in general, about their faction, or about the game itself.
--]]

require "events/tutorial/tutorial_common"
local portrait = require "portrait"

-- Factions which will NOT get generic texts if possible.  Factions
-- listed here not spawn generic civilian NPCs or get aftercare texts.
-- Meant for factions which are either criminal (FLF, Pirate) or unaware
-- of the main universe (Thurion, Proteron).
nongeneric_factions = {"Pirate", "FLF", "Thurion", "Proteron"}

-- Special names for certain factions' civilian NPCs (to replace the
-- generic "{faction} Civilian" naming normally used).
civ_name = {
   FLF = _("Frontier Civilian"),
   Pirate = p_("individual", "Pirate"),
}

-- Land-restricted NPC names for the spaceport bar. This correlates
-- land restriction function names (returned by planet.restriction())
-- with what NPCs on planets with those restrictions should be called.
-- Appearance in this table also implicitly causes portrait.getMil() to
-- be used for selecting a portrait instead of portrait.get().
mil_name = {
   emp_mil_restricted = _("Empire Officer"),
   emp_mil_omega = _("Empire Officer"),
   emp_mil_wrath = _("Empire Officer"),
   srs_mil_restricted = _("Sirius Officer"),
   srs_mil_mutris = _("Sirius Officer"),
   dv_mil_restricted = _("Dvaered Officer"),
   dv_mil_command = _("Dvaered Officer"),
   srm_mil_restricted = _("Soromid Officer"),
   zlk_mil_restricted = _("Za'lek Scientist"),
   zlk_ruadan = _("Za'lek Scientist"),
   flf_sindbad = _("FLF Soldier"),
   ptn_mil_restricted = _("Proteron Officer"),
   pir_clanworld = p_("individual", "Pirate"),
}

-- Civilian descriptions for the spaceport bar.
-- These descriptions will be picked at random, and may be picked
-- multiple times in one generation. Remember that any description can
-- end up with any portrait, so don't make any assumptions about th
-- appearance of the NPC!
civ_desc = {
   _("This person seems to be here to relax."),
   _("There is a civilian sitting on one of the tables."),
   _("There is a civilian sitting there, looking somewhere else."),
   _("A worker sits at one of the tables, wearing a name tag saying \"Go away\"."),
   _("A civilian sits at the bar, seemingly serious about the cocktails on offer."),
   _("There is a civilian sitting in the corner."),
   _("A civilian feverishly concentrating on a fluorescing drink."),
   _("A civilian drinking alone."),
   _("This person seems friendly enough."),
   _("A civilian sitting at the bar."),
   _("This person is idly browsing a news terminal."),
   _("A worker sits and drinks instead of working."),
   _("A worker slouched against the bar, nursing a drink."),
   _("This worker seems bored with everything but their drink."),
}

-- Same as civ_desc, but for particular factions (replacing the default
-- civ_desc table), organized by faction name.
pciv_desc = {}
pciv_desc["Pirate"] = {
   _("This pirate seems to be here to relax."),
   _("There is a pirate sitting on one of the tables."),
   _("There is a pirate sitting there, looking somewhere else."),
   _("A pirate sits at the bar, seemingly serious about the cocktails on offer."),
   _("There is a pirate sitting in the corner."),
   _("A pirate feverishly concentrating on a fluorescing drink."),
   _("A pirate drinking alone."),
   _("A pirate sitting at the bar."),
   _("This pirate is idly browsing a news terminal."),
   _("A worker sits and drinks instead of working."),
   _("A worker slouched against the bar, nursing a drink."),
   _("This pirate seems bored with everything but their drink."),
}

-- Same as civ_desc, but for land-restricted NPCs, organized by land
-- restriction function name.
mil_desc = {}
mil_desc.emp_mil_restricted = {
   _("An Empire officer sits idly at one of the tables."),
   _("This Empire officer seems somewhat spaced-out."),
   _("An Empire officer drinking alone."),
   _("An Empire officer sitting at the bar."),
   _("This Empire officer is idly reading the news terminal."),
   _("This officer seems bored with everything but their drink."),
   _("This officer seems to be relaxing after a hard day's work."),
   _("An Empire officer sitting in the corner."),
}
mil_desc.emp_mil_omega = mil_desc.emp_mil_restricted
mil_desc.emp_mil_wrath = mil_desc.emp_mil_restricted
mil_desc.srs_mil_restricted = {
   _("A Sirius officer sits idly at one of the tables."),
   _("This Sirius officer seems somewhat spaced-out."),
   _("A Sirius officer drinking alone."),
   _("A Sirius officer sitting at the bar."),
   _("This Sirius officer is idly reading the news terminal."),
   _("This officer seems bored with everything but their drink."),
   _("This officer seems to be relaxing after a hard day's work."),
   _("A Sirius officer sitting in the corner."),
}
mil_desc.srs_mil_mutris = mil_desc.srs_mil_restricted
mil_desc.dv_mil_restricted = {
   _("A Dvaered officer sits idly at one of the tables."),
   _("This Dvaered officer seems somewhat spaced-out."),
   _("A Dvaered officer drinking alone."),
   _("A Dvaered officer sitting at the bar."),
   _("This Dvaered officer is idly reading the news terminal."),
   _("This officer seems bored with everything but their drink."),
   _("This officer seems to be relaxing after a hard day's work."),
   _("A Dvaered officer sitting in the corner."),
   _("A Dvaered officer suspiciously glancing around, as if expecting to be attacked by FLF terrorists at any moment."),
}
mil_desc.dv_mil_command = mil_desc.dv_mil_restricted
mil_desc.srm_mil_restricted = {
   _("A Soromid officer sits idly at one of the tables."),
   _("This Soromid officer seems somewhat spaced-out."),
   _("A Soromid officer drinking alone."),
   _("A Soromid officer sitting at the bar."),
   _("This Soromid officer is idly reading the news terminal."),
   _("This officer seems bored with everything but their drink."),
   _("This officer seems to be relaxing after a hard day's work."),
   _("A Soromid officer sitting in the corner."),
}
mil_desc.zlk_mil_restricted = {
   _("A Za'lek scientist sits idly at one of the tables."),
   _("This Za'lek scientist seems somewhat spaced-out."),
   _("A Za'lek scientist drinking alone."),
   _("A Za'lek scientist sitting at the bar."),
   _("This Za'lek scientist is idly reading the news terminal."),
   _("This scientist seems bored with everything but their drink."),
   _("This scientist seems to be relaxing after a hard day's work."),
   _("A Za'lek scientist sitting in the corner."),
}
mil_desc.zlk_ruadan = mil_desc.zlk_mil_restricted
mil_desc.flf_sindbad = {
   _("An FLF soldier sits idly at one of the tables."),
   _("This FLF soldier seems somewhat spaced-out."),
   _("An FLF soldier drinking alone."),
   _("An FLF soldier sitting at the bar."),
   _("This FLF soldier is idly reading the news terminal."),
   _("This FLF soldier seems to be relaxing for the moment."),
   _("An FLF soldier sitting in the corner."),
   _("An FLF soldier drinking with a group of comrades."),
}
mil_desc.ptn_mil_restricted = {
   _("A Proteron officer sits idly at one of the tables."),
   _("A Proteron officer drinking alone."),
   _("A Proteron officer sitting at the bar."),
   _("This Proteron officer is idly reading the news terminal."),
   _("This officer seems bored with everything but their drink."),
   _("This officer seems to be relaxing after a hard day's work."),
   _("A Proteron officer sitting in the corner."),
   _("A nervous-looking Proteron officer gently sips a drink while reading government propaganda."),
}
mil_desc.pir_clanworld = pciv_desc["Pirate"]

-- Lore messages. These come in general and factional varieties.
-- General lore messages will be said by non-faction NPCs, OR by faction
-- NPCs if they have no factional text to say. When adding factional
-- text, make sure to add it to the table of the appropriate faction.
-- Does your faction not have a table? Then just add it. The script will
-- find and use it if it exists. Make sure you spell the faction name
-- exactly the same as in faction.xml though!
msg_lore = {}
msg_lore["general"] = {
   _([["I heard the nebula is haunted! My uncle told me he saw one of the ghost ships himself over in Arandon."]]),
   _([["I don't believe in those nebula ghost stories. The people who spread them are just trying to scare you."]]),
   _([["Have you seen that ship the Emperor lives on? It's huge! But if you ask me, it looks a bit like a… No, never mind."]]),
   _([["They say Eduard Manual Goddard is drifting in space somewhere, entombed amidst a cache of his inventions! What I wouldn't give to rummage through there.…"]]),
   _([["Don't try to fly into the inner nebula. I've known people who tried, and none of them came back."]]),
   _([["Sometimes I look at the stars and wonder… are we the only sentient species in the universe?"]]),
   _([["Hey, you ever wonder why we're here?" You respond that it's one of the great mysteries of the universe. Why are we here? Are we the product of some cosmic coincidence or is there some great cosmic plan for us? You don't know, but it sometimes keeps you up at night. As you say this, the citizen stares at you incredulously. "What?? No, I mean why are we in here, in this bar?"]]),
   _([["Don't be fooled by those distances your ship's instruments show you; the places you travel through are actually about 100,000 times larger on average. Unbelievable, I know! But traveling through systems in any reasonable amount of time would require traveling significantly faster than the speed of light, so every modern ship uses quantum triangulation to slip our ships through naturally occurring miniature dark matter wormholes, and since these are the same for every ship, your ship's computer is able to calculate a consistent position in an artificial 2-D space. Pretty cool, don't you think?"]]),
   _([["I've been a pilot long enough to remember the days when ships were sold completely bare with no defenses built-in. Something about regulatory agencies not allowing them to bundle restricted weapons. Thankfully they eventually saw sense and now you can fly a new ship right away without having to worry that a pirate is going to blow you to smithereens."]]),
   _([["Did you know that the Galactic Common Time system almost did away with terms like 'hours' and 'seconds'? It's true! The guy who originally proposed the system wanted to rename seconds to 'Standard Time Units' and call galactic hours 'Standard Time Periods'. What's more, he wanted us all to use the abbreviations 'STU', 'STP', and 'SCU' to refer to seconds, hours, and cycles! There were massive protests back then, believe it or not, and many planets threatened to not adopt the system, so they relented and simply reused 'hours' and 'seconds' for the new time definitions."]]),
}

msg_lore["Independent"] = {
   _([["We're not part of any of the galactic superpowers. We can take care of ourselves!"]]),
   _([["Sometimes I worry that our lack of a standing military leaves us vulnerable to attack. I hope nobody will get any ideas about conquering us!"]]),
   _([["I find it rather odd that anyone would answer to some bureaucrat who doesn't even live on the same planet as them. What a strange universe we live in."]]),
   _([["Don't listen to those conspiracy theories about the Incident. We don't know what happened, sure, but why on Earth would someone blow up… you know, Earth… on purpose?"]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
   _([["I heard the Soromid lost their homeworld Sorom in the Incident. Its corpse can still be found in Basel."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
}

msg_lore["Empire"] = {
   _([["Things are getting worse by the cycle. What happened to the Empire? We used to be the lords and masters over the whole galaxy!"]]),
   _([["Did you know that House Za'lek was originally a Great Project initiated by the Empire? Well, now you do! There was also a Project Proteron, but that didn't go so well."]]),
   _([["The Emperor lives on a giant supercruiser in Gamma Polaris. It's said to be the biggest ship in the galaxy! I totally want one."]]),
   _([["I'm still waiting for my pilot license application to get through. Oh well, it's only been half a cycle, I just have to be patient."]]),
   _([["Between you and me, the laws the Council passes can get really ridiculous! Most planets find creative ways of ignoring them.…"]]),
   _([["Don't pay attention to the naysayers. The Empire is still strong. Have you ever seen a Peacemaker up close? I doubt any ship fielded by any other power could stand up to one."]]),
   _([["I don't know who did it, but believe me, the Incident was no accident! It was definitely a terrorist attack orchestrated by those disloyal Great Houses in an effort to take down the Empire."]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
   _([["I heard the Soromid lost their homeworld Sorom in the Incident. Its corpse can still be found in Basel."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
   _([["I wouldn't travel north of Alteris if I were you, unless you're a good fighter! That area of space has really gone down the drain since the Incident."]]),
}

msg_lore["Dvaered"] = {
   _([["Our Warlord is currently fighting for control over another planet. We all support him unconditionally, of course! Of course.…"]]),
   _([["My great-great-great-grandfather fought in the Dvaered Revolts! We still have the holovids he made. I'm proud to be a Dvaered!"]]),
   _([["I've got lots of civilian commendations! It's important to have commendations if you're a Dvaered."]]),
   _([["You better not mess with House Dvaered. Our military is the largest and strongest in the galaxy. Nobody can stand up to us!"]]),
   _([["House Dvaered? House? The Empire is weak and useless, we don't need them anymore! I say we declare ourselves an independent faction today. What are they going to do, subjugate us? We all know how well that went last time! Ha!"]]),
   _([["I'm thinking about joining the military. Every time I see or hear news about those rotten FLF bastards, it makes my blood boil! They should all be pounded into space dust!"]]),
   _([["FLF terrorists? I'm not too worried about them. You'll see, High Command will have smoked them out of their den soon enough, and then the Frontier will be ours."]]),
   _([["Did you know that House Dvaered was named after a hero of the revolt? At least that's what my grandparents told me."]]),
   _([["If you ask me, those FLF terrorists caused the Incident. They have a clear motive: they wanted to create that nebula so they would have a place to hide. Damn criminals…"]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
   _([["I heard the Soromid lost their homeworld Sorom in the Incident. Its corpse can still be found in Basel."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
}

msg_lore["Sirius"] = {
   _([["Greetings, traveler. May Sirichana's wisdom guide you as it guides me."]]),
   _([["I once met one of the Touched in person. Well, it wasn't really a meeting, our eyes simply met… but that instant alone was awe-inspiring."]]),
   _([["They say Sirichana lives and dies like any other man, but each new Sirichana is the same as the last. How is that possible?"]]),
   _([["My cousin was called to Mutris a cycle ago. He must be in Crater City by now. And one day, he will become one of the Touched!"]]),
   _([["Some people say Sirius society is unfair because our echelons are determined by birth. But even though we are different, we are all followers of Sirichana. Spiritually, we are equal."]]),
   _([["House Sirius is officially part of the Empire, but everyone knows that's only true on paper. The Emperor has nothing to say in these systems. We follow Sirichana, and no-one else."]]),
   _([["You can easily tell the different echelons apart. Every Sirius citizen and soldier wears clothing appropriate to his or her echelon."]]),
   _([["I hope to meet one of the Touched one day!"]]),
   _([["The Incident was the righteous divine judgment of Sirichana. He laid judgment on House Proteron for their intrusion into his plan, and he punished the Empire for having started that so-called 'Great Project'."]]),
   _([["I heard the Soromid lost their homeworld Sorom in the Incident. Its corpse can still be found in Basel."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
}

msg_lore["Soromid"] = {
   _("Hello. Can I interest you in one of our galaxy famous cosmetic gene treatments? You look like you could use them.…"),
   _([["Can you believe it? I was going to visit Sorom to find my roots, and then boom! It got burnt to a crisp! Even now, cycles later, I still can't believe it."]]),
   _([["Yes, it's true, our military ships are alive. Us normal folk don't get to own bioships though, we have to make do with synthetic constructs just like everyone else."]]),
   _([["Everyone knows that we Soromid altered ourselves to survive the deadly conditions on Sorom during the Great Quarantine. What you don't hear so often is that billions of us died from the therapy itself. We paid a high price for survival."]]),
   _([["Our cosmetic gene treatments are even safer now for non-Soromids, with a rate of survival of 99.4%!"]]),
   _([["We have been rebuilding and enhancing our bodies for so long, we've practically evolved into a new species."]]),
   _([["Between you and me, I think House Proteron is to blame for the Incident. Think about it: they were just mobilizing their troops to attack the Empire, then poof! A huge explosion happens to occur right at their most likely invasion point. I don't know how it happened, but they must have accidentally vaporized themselves and the core of the Empire as they attempted their assault."]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
}

msg_lore["Za'lek"] = {
   _([["It's not easy, dancing to those scientists' tunes. They give you the most impossible tasks! Like, where am I supposed to get a triple redundant helitron converter? Honestly."]]),
   _([["The Soromids? Hah! We Za'lek are the only true scientists in this galaxy."]]),
   _([["I don't understand why we bother sending our research results to the Empire. These asshats can't understand the simplest formulas!"]]),
   _([["Do you know why many optimization algorithms require your objective function to be convex? It's not only because of the question of local minima, but also because if your function is locally concave around the current iterate, the next one will lead to a greater value of your objective function. There are still too many people who don't know this!"]]),
   _([["There are so many algorithms for solving the non-linear eigenvalues problem, I never know which one to choose. Which one do you prefer?"]]),
   _([["I recently attended a very interesting conference about the history of applied mathematics before the space age. Even in those primitive times, people used to do numerical algebra. They didn't even have quantic computers back at that time! Imagine: they had to wait for hours to solve a problem with only a dozen billion degrees of freedom!"]]),
   _([["Last time I had to solve a deconvolution problem, its condition number was so high that its inverse reached numerical zero on Octuple Precision!"]]),
   _([["I am worried about my sister. She's on trial for 'abusive self-citing' and the public prosecutor has requested a life sentence."]]),
   _([["They opened two professor positions on precision machining in Atryssa Central Manufacturing Lab, and none in Bedimann Advanced Process Lab, but everyone knows that the BAPL needs reinforcement ever since three of its professors retired last cycle. People say it's because a member of Atryssa's lab posted a positive review of the president of the Za'lek central scientific recruitment committee."]]),
   _([["Even if our labs are the best in the galaxy, other factions have their own labs as well. For example, Dvaer Prime Lab for Advanced Mace Rocket Studies used to be very successful until it was nuked by mistake by a warlord during an invasion of the planet."]]),
   _([["I would be delighted to discover the secrets of the Incident. Rumors abound, but through the discovery of more data, we can uncover the true answer."]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
}

msg_lore["Thurion"] = {
   _([["Did you know that even the slightest bit of brain damage can lead to death during the upload process? That's why we're very careful to not allow our brains to be damaged, even a little."]]),
   _([["My father unfortunately hit his head when he was young, so he couldn't be safely uploaded. It's okay, though; he had a long and fulfilling life, for a non-uploaded human, that is."]]),
   _([["One great thing once you're uploaded is that you can choose to forget things you don't want to remember. My great-grandfather had a movie spoiled for him before he could watch it, so once he got uploaded, he deleted that memory and watched it with a fresh perspective. Cool, huh?"]]),
   _([["The best part of our lives is after we're uploaded, but that doesn't mean we lead boring lives before then. We have quite easy and satisfying biological lives before uploading."]]),
   _([["Being uploaded allows you to live forever, but that doesn't mean you're forced to. Any uploaded Thurion can choose to end their own life if they want, though few have chosen to do so."]]),
   _([["Uploading is a choice in our society. No one is forced to do it. It's just that, well, what kind of person would turn down the chance to live a second life on the network?"]]),
   _([["We were lucky to not get touched by the Incident. In fact, we kind of benefited from it. The nebula that resulted gave us a great cover and sealed off the Empire from us."]]),
   _([["We don't desire galactic dominance. That being said, we do want to spread our way of life to the rest of the galaxy, so that everyone can experience the joy of being uploaded."]]),
   _([["I think you're from the outside, aren't you? That's awesome! I've never met a foreigner before. What's it like outside the nebula?"]]),
   _([["We actually make occasional trips outside of the nebula, though only rarely, and we always make sure to not get discovered by the Empire."]]),
   _([["The Soromid have a rough history. Have you read up on it? First the Empire confined them to a deadly planet and doomed them to extinction. Then, when they overcame those odds, the Incident blew up their homeworld. The fact that they're still thriving now despite that is phenomenal, I must say."]]),
}

msg_lore["Proteron"] = {
   _([["The old Empire will pay for blowing up Sol. We all know they did it on purpose."]]),
   _([["The obsolete old Empire knew we were destined to replace them, so they blew up Sol in an effort to wipe us out. But they weren't thorough enough, and we won't forgive them!"]]),
   _([["Personally I think the old Empire has been weakened by Soromid influence. Those damn freaks have been a scourge on the galaxy ever since they flooded into it."]]),
   _([["It is our destiny as Proteron to rule the galaxy. We are the rightful successor to the Empire. We will take what is ours."]]),
   _([["One of my co-workers was spreading lies about us Proteron causing the Incident. Naturally, I reported him to the police, and they took him away. I'd bet he was a secret Soromid sympathizer trying to bring down the great Proteron Empire."]]),
   _([["We must all work hard to ensure our destiny as Proteron is fulfilled."]]),
   _([["The Empire is weak and obsolete, and they know it. That's why they went so low as to blow Earth up to try to get rid of us."]]),
   _([["I'm thinking of enlisting in the military so I can join the fight against the Soromid elite and the traitorous old Empire."]]),
}

msg_lore["Frontier"] = {
   _([["We value our autonomy. We don't want to be ruled by those Dvaered Warlords! Can't they just shoot at each other instead of threatening us? If it wasn't for the Liberation Front…"]]),
   _([["Have you studied your galactic history? The Frontier worlds were the first to be colonized by humans. That makes our worlds the oldest human settlements in the galaxy, now that Earth is gone."]]),
   _([["We have the Dvaered encroaching on our territory on one side, and the Sirius zealots on the other. Sometimes I worry that in a few decacycles, the Frontier will no longer exist."]]),
   _([["Have you visited the Frontier Museum? They've got a scale model of a First Growth colony ship on display in one of the big rooms. Even scaled down like that, it's massive! Imagine how overwhelming the real ones must have been."]]),
   _([["There are twelve true Frontier worlds, because twelve colony ships successfully completed their journey in the First Growth. But did you know that there were twenty colony ships to begin with? Eight of them never made it. Some are said to have mysteriously disappeared. I wonder what happened to them?"]]),
   _([["We don't have much here in the Frontier, other than our long history leading directly back to Earth. But I don't mind. I'm happy living here, and I wouldn't want to move anywhere else."]]),
   _([["You know the Frontier Liberation Front? They're the guerrilla movement that fights for the Frontier. I hope they can continue to hold out."]]),
   _([["The Incident? Oh, I don't think about it too much. It's a tragedy, but we have enough of our own problems to deal with as-is."]]),
   _([["I heard the Soromid lost their homeworld Sorom in the Incident. Its corpse can still be found in Basel."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
}

msg_lore["FLF"] = {
   _([["I can't stand Dvaereds. I just want to wipe them all off the map. Don't you?"]]),
   _([["One of these days, we will completely rid the Frontier of Dvaered oppressors. Mark my words!"]]),
   _([["Have you ever wondered about our chances of actually winning over the Dvaereds? Sometimes I worry a little."]]),
   _([["I was in charge of a bombing run recently. The mission was a success, but I lost a lot of comrades in the process. I wish I could bring them back, but in lieu of that, I fight for their honor as well as my own."]]),
   _([["It's true that lots of Frontier officials fund our operations. They have to keep it all hush-hush for political reasons, but no one in the Frontier wants the Dvaered to be allowed to do what they're doing."]]),
   _([["They'll always label us as 'terrorists'. It's nothing more than Dvaered propaganda designed to divide us. We are fighting for the Frontier against the Dvaereds, and the Dvaereds won't ever be OK with that."]]),
}

msg_lore["Pirate"] = {
   _([["Hi mate. Money or your life! Heh heh, just messing with you."]]),
   _([["Hey, look at these new scars I got!"]]),
   _([["Have you heard of the Pirates' Code? They're more guidelines than rules.…"]]),
   _([["My gran once said to me, 'Never trust a pirate.' Well, she was right! I got a pretty credit chip out of her wallet last time I saw her, and I'd do it again."]]),
   _([["I don't understand why some pirates talk like 16th-century Earth pirates even though that planet is literally dead."]]),
   _([["I may be a pirate who blows up ships and steals for a living, but that inner nebula still kind of freaks me out."]]),
   _([["Damn Empire stopped my heist a few days ago. Just wait till they see me again.…"]]),
   _([["There's a pirate clanworld I really wanted to get to, but they wouldn't let me in because I'm a 'small-time pirate'! Sometimes I think I'll never make it in this line of work.…"]]),
   _([["I was around before Haven was destroyed, you know! Funny times. All the pirates were panicking and the Empire was cheering thinking that we were done for. Ha! As if! It barely even made a difference. We just relocated to New Haven and resumed business as usual."]]),
   _([["You know, I got into this business by accident to tell the truth. But what can you do? I could get a fake ID and pretend to be someone else but I'd get caught eventually anyway. Might as well make the best of what I have now."]]),
   _([["One of my favorite things to do is buy a fake ID and then deliver as much contraband as I can before I get caught. It's great fun, and finding out that my identity's been discovered gives me a rush!"]]),
   _([["Back when I started out in this business all you could do was go around delivering packages for other people. Becoming a pirate was real hard back then, but I got so bored I became a pirate anyway. Nowadays things are way more exciting for normies, but I don't regret my choice one bit!"]]),
   _([["The Skull and Bones used to sell garbage ships. I mean, don't get me wrong, they still worked great, but they were always in terrible shape when you bought them, like they'd just come out of a meat grinder: scrappy and thrown together hulls that barely held together, outdated core systems, and the engines would barely even propel you through space. Back then you had to immediately get to work replacing everything in your 'new' ship just so they would function. It's much better nowadays, thankfully."]]),
}

-- Gameplay tip messages.
-- ALL NPCs have a chance to say one of these lines instead of a lore message.
-- So, make sure the tips are always faction neutral.
msg_tip = {
   _([["I heard you can set your weapons to only fire when your target is in range, or just let them fire when you pull the trigger. Sounds handy!"]]),
   string.format( _([["Did you know that if a planet doesn't like you, you can often bribe the spaceport operators and land anyway? Just hail the planet with %s, and click the bribe button! Careful though, it doesn't always work."]]), tutGetKey("hail") ),
   _([["These new-fangled missile systems! You can't even fire them unless you get a target lock first! But the same thing goes for your opponents. You can actually make it harder for them to lock on to your ship by equipping scramblers or jammers. Scout class ships are also harder to target."]]),
   _([["You know how you can't change your ship or your equipment on some planets? Well, it seems you need an outfitter to change equipment, and a shipyard to change ships! Bet you didn't know that."]]),
   _("\"Are you trading commodities? You can hold down #bctrl#0 to buy 50 of them at a time, and #bshift#0 to buy 100. And if you press them both at once, you can buy 500 at a time! You can actually do that with outfits too, but why would you want to buy 50 laser cannons?\""),
   _([["If you're on a mission you just can't beat, you can open the information panel and abort the mission. There's no penalty for doing it, so don't hesitate to try the mission again later."]]),
   _([["Some weapons have a different effect on shields than they do on armor. Keep that in mind when equipping your ship."]]),
   _([["Afterburners can speed you up a lot, but when they get hot they don't work as well anymore. Don't use them carelessly!"]]),
   _([["There are passive outfits and active outfits. The passive ones modify your ship continuously, but the active ones only work if you turn them on. You usually can't keep an active outfit on all the time, so you need to be careful only to use it when you need it."]]),
   _([["If you're new to the galaxy, I recommend you buy a map or two. It can make exploration a bit easier."]]),
   _([["Scramblers and jammers make it harder for missiles to track you. They can be very handy if your enemies use missiles."]]),
   string.format( _([["If you're having trouble with overheating weapons or outfits, you can press %s twice to put your ship into Active Cooldown; that'll dissipate all heat from your ship and also refill your rocket ammunition. Careful though, your energy and shields won't recharge while you do it!"]]), tutGetKey("autobrake") ),
   _([["If you're having trouble shooting other ships face on, try outfitting with turrets or use an afterburner to avoid them entirely!"]]),
   _([["You know how time speeds up when Autonav is on, but then goes back to normal when enemies are around? Turns out you can't disable the return to normal speed entirely, but you can control what amount of danger triggers it. Really handy if you want to ignore enemies that aren't actually hitting you."]]),
   _([["Flying bigger ships is awesome, but it's a bit tougher than flying smaller ships. There's so much more you have to do for the same actions, time just seems to fly by faster. I guess the upside of that is that you don't notice how slow your ship is as much."]]),
   _([["I know it can be tempting to fly the big and powerful ships, but don't underestimate smaller ones! Given their simpler designs and lesser crew size, you have a lot more time to react with a smaller vessel. Some are even so simple to pilot that time seems to slow down all around you!"]]),
   _([["Mining can be an easy way to earn some extra credits, but every once in a while an asteroid will just randomly explode for no apparent reason, so you have to watch out for that. Yeah, I don't know why they do that either."]]),
   _([["Rich folk will pay extra to go on an offworld sightseeing tour in a luxury yacht. I don't get it personally; it's all the same no matter what ship you're in."]]),
   _([["Different ships should be built and piloted differently. One of the hardest lessons I learned as a pilot was to stop worrying so much about the damage my ship was taking in battle while piloting a large ship. These ships are too slow for dodging, not to mention so complicated that they reduce your reaction time, so you need to learn to just take the hits and focus your attention on firing back at your enemies."]]),
   _([["Remember that when you pilot a big ship, you perceive time passing a lot faster than you do when you pilot a small ship. It can be easy to forget just how slow these larger ships are when you're frantically trying to depressurize the exhaust valve while also configuring the capacitance array. In a way the slow speed of the ship becomes a pretty huge relief!"]]),
   _([["There's always an exception to the rule, but I wouldn't recommend using forward-facing weapons on larger ships. Large ships' slower turn rates aren't able to keep up with the dashing and dodging of smaller ships, and aiming is harder anyway what with how complex these ships are. Turrets are much better; they aim automatically and usually do a very good job!"]]),
   _([["Don't forget to have your target selected. Even if you have forward-facing weapons, the weapons will swivel a bit to track your target. But it's absolutely essential for turreted weapons."]]),
   _("\"Did you know that you can automatically follow a pilot with Autonav? It's true! Just #bleft-click#0 the pilot to target them and then #bright-click#0 your target to follow! I like to use this feature for escort missions. It makes them a lot less tedious.\""),
   _([["The '¢' symbol is the official galactic symbol for credits. Supposedly it comes from the currency symbol of an ancient Earth civilization. It's sometimes expressed with SI prefixes: 'k¢' for thousands of credits, 'M¢' for millions of credits, and so on."]]),
   _([["If you're piloting a medium ship, I'd recommend you invest in at least one turreted missile launcher. I had a close call a few days ago where a bomber nearly blew me to bits outside the range of my Laser Turrets. Luckily I just barely managed to escape to a nearby planet. I've not had that problem ever since I equipped a turreted missile launcher."]]),
   _([["These computer symbols can be confusing sometimes! I've figured it out, though: #F+#0 means friendly, #N~#0 means neutral, #H!!#0 means hostile, #R*#0 means restricted, and #I=#0 means uninhabited but landable. I wish someone had told me that!"]]),
   _([["This can be a bit dangerous, but if you ever run out of fuel in a system with nothing to land on and no friendly pilots willing to refuel you, pirates will often be willing to sell you some of their fuel. You just have to bribe them first. It'll put a drain on your credits, but at least you can make it out alive!"]]),
   _([["A lot of interfaces that give you a bunch of images to select and a button to click also allow you to right-click on the images. Here at the bar, right-clicking on one of us is the same as clicking the 'Approach' button. Give it a try!"]]),
   _([["Launchers and fighter bays have their mass listed as a range rather than just a flat mass because the ammo has its own mass. When they're empty, their mass is the minimum mass, and when they're full, their mass is the maximum mass."]]),
   _([["Those new combat practice missions in the mission computer are real handy! You can even fight against Proteron ship look-alikes, but don't be fooled; they're not the real deal."]]),
}

-- Jump point messages.
-- For giving the location of a jump point in the current system to the player for free.
-- All messages must contain exactly one %s, this is the name of the target system.
-- ALL NPCs have a chance to say one of these lines instead of a lore message.
-- So, make sure the tips are always faction neutral.
msg_jmp = {
   _([["Hi there, traveler. Is your system map up to date? Just in case you didn't know already, let me give you the location of the jump from here to %s. I hope that helps."]]),
   _([["Quite a lot of people who come in here complain that they don't know how to get to %s. I travel there often, so I know exactly where the jump point is. Here, let me show you."]]),
   _([["So you're still getting to know about this area, huh? Tell you what, I'll give you the coordinates of the jump to %s. Check your map next time you take off!"]]),
   _([["True fact, there's a direct jump from here to %s. Want to know where it is? It'll cost you! Ha ha, just kidding. Here you go, I've added it to your map."]]),
   _([["There's a system just one jump away by the name of %s. I can tell you where the jump point is. There, I've updated your map. Don't mention it."]]),
}

-- Mission hint messages. Each element should be a table containing the mission name and the corresponding hint.
-- ALL NPCs have a chance to say one of these lines instead of a lore message.
-- So, make sure the hints are always faction neutral.
msg_mhint = {
   {"Baron", _([["There's this obnoxious baron who bought the entire Ulios system for himself. I hear he flies a Proteron Kahan from before the Incident and sends people he hires on wild goose chases to find all sorts of weird trinkets. I don't envy the folks that work for him; he sounds like a real pain."]])},
   {"Empire Recruitment", _([["Apparently the Empire is trying to recruit new pilots into their shipping division. That might be a worthwhile opportunity if you want to make some credits!"]])},
   {"Hitman", _([["There are often shady characters hanging out in the Alteris system. I'd stay away from there if I were you, someone might offer you a dirty kind of job!"]])},
   {"Racing Skills 1", _([["There's a bunch of folks who organize races from time to time. You have to fly a Yacht class ship to take part in them. I totally want to join one of those races some day."]])},
   {"Shadowrun", _([["Apparently there's a woman who regularly turns up on planets in and around the Klantar system. I wonder what she's looking for."]])},
}

-- Event hint messages. Each element should be a table containing the event name and the corresponding hint.
-- Make sure the hints are always faction neutral.
msg_ehint = {
   {"FLF/DV Derelicts", _([["Clashes between the FLF and Dvaered patrols can get quite intense. Sometimes when things get real bad the Dvaered forces will enlist the help of willing civilians."]])},
}

-- Mission after-care messages. Each element should be a table containing the mission name and a line of text.
-- This text will be said by NPCs once the player has completed the mission in question.
-- Make sure the messages are always faction neutral.
msg_mdone = {
   {"Baron", _([["Some thieves broke into a museum on Varia and stole a holopainting! Most of the thieves were caught, but the one who carried the holopainting offworld is still at large. No leads."]])},
   {"Destroy the FLF base!", _([["The Dvaered scored a major victory against the FLF recently. They went into Sigur and blew the hidden base there to bits! I bet that was a serious setback for the FLF."]])},
   {"Nebula Satellite", _([["Heard some reckless scientists got someone to put a satellite inside the nebula for them. I thought everyone with half a brain knew to stay out of there, but oh well."]])},
   {"Racing Skills 2", _([["You won one of the big races? That's awesome! I'd love to join a race some day."]])},
   {"Shadow Vigil", _([["Did you hear? There was some big incident during a diplomatic meeting between the Empire and the Dvaered. Nobody knows what exactly happened, but both diplomats died. Now both sides are accusing the other of foul play. Could get ugly."]])},
}

-- Event after-care messages. Each element should be a table containing the event name and a line of text.
-- This text will be said by NPCs once the player has completed the event in question.
-- Make sure the messages are always faction neutral.
msg_edone = {
   {"Animal trouble", _([["What? You had rodents sabotage your ship? Damn, you're lucky to be alive. If it had hit the wrong power line…"]])},
   {"Test Engine Troubles", _([[That really happened to you with an experimental engine?! You're lucky to be alive! No way I'd ever use one of those things even if you paid me.]])},
}


function create()
   local num_npc = rnd.rnd(1, 5)
   npcs = {}
   for i = 0, num_npc do
      spawnNPC()
   end

   -- End event on takeoff.
   hook.takeoff( "leave" )
end

-- Spawns an NPC.
function spawnNPC()
   -- Select a faction for the NPC. NPCs may not have a specific faction.
   local npcname = _("Civilian")
   local factions = {}
   local func = nil
   for i, _ in pairs(msg_lore) do
      factions[#factions + 1] = i
   end

   local nongeneric = false

   local f = planet.cur():faction()
   local planfaction = f ~= nil and f:nameRaw() or nil
   local fac = "general"
   local select = rnd.rnd()
   if planfaction ~= nil then
      for i, j in ipairs(nongeneric_factions) do
         if j == planfaction then
            nongeneric = true
            break
         end
      end

      if nongeneric or select >= (0.5) then
         fac = planfaction
      end
   end

   -- Append the faction to the civilian name, unless there is no faction.
   if fac ~= "general" then
      npcname = civ_name[fac] or string.format(_("%s Civilian"), _(fac))
   end

   local restriction = planet.cur():restriction()
   local milname = mil_name[restriction]
   local image
   local desc
   if milname ~= nil then
      npcname = milname

      -- Select a military portrait and description.
      image = portrait.getMil(planfaction)
      local descriptions = mil_desc[restriction]
      desc = descriptions[rnd.rnd(1, #descriptions)]
   else
      -- Select a civilian portrait and description.
      image = portrait.get(fac)
      local desclist = pciv_desc[fac] or civ_desc
      desc = desclist[rnd.rnd(1, #desclist)]
   end

   -- Select what this NPC should say.
   select = rnd.rnd()
   local msg
   if select < 0.2 then
      -- Jump point message.
      msg, func = getJmpMessage(fac)
   elseif select <= 0.55 then
      -- Lore message.
      msg = getLoreMessage(fac)
   elseif select <= 0.8 then
      -- Gameplay tip message.
      msg = getTipMessage(fac)
   else
      -- Mission hint message.
      if not nongeneric then
         msg = getMissionLikeMessage(fac)
      else
         msg = getLoreMessage(fac)
      end
   end
   local npcdata = {name = npcname, msg = msg, func = func, image = portrait.getFullPath(image)}

   id = evt.npcAdd("talkNPC", npcname, image, desc, 100)
   npcs[id] = npcdata
end

-- Returns a lore message for the given faction.
function getLoreMessage(fac)
   -- Select the faction messages for this NPC's faction, if it exists.
   local facmsg = msg_lore[fac]
   if facmsg == nil or #facmsg == 0 then
      facmsg = msg_lore["general"]
      if facmsg == nil or #facmsg == 0 then
         evt.finish(false)
      end
   end

   -- Select a string, then remove it from the list of valid strings. This ensures all NPCs have something different to say.
   local select = rnd.rnd(1, #facmsg)
   local pick = facmsg[select]
   table.remove(facmsg, select)
   return pick
end

-- Returns a jump point message and updates jump point known status accordingly. If all jumps are known by the player, defaults to a lore message.
function getJmpMessage(fac)
   -- Collect a table of jump points in the system the player does NOT know.
   local mytargets = {}
   seltargets = seltargets or {} -- We need to keep track of jump points NPCs will tell the player about so there are no duplicates.
   for i, j in ipairs(system.cur():jumps()) do
      if not j:known() and not j:hidden() and not seltargets[j] then
         table.insert(mytargets, j)
      end
   end

   if #mytargets == 0 then -- The player already knows all jumps in this system.
      return getLoreMessage(fac), nil
   end

   -- All jump messages are valid always.
   if #msg_jmp == 0 then
      return getLoreMessage(fac), nil
   end
   local retmsg =  msg_jmp[rnd.rnd(1, #msg_jmp)]
   local sel = rnd.rnd(1, #mytargets)
   local myfunc = function()
                     mytargets[sel]:setKnown(true)
                     mytargets[sel]:dest():setKnown(true, false)
                  end

   -- Don't need to remove messages from tables here, but add whatever jump point we selected to the "selected" table.
   seltargets[mytargets[sel]] = true
   return retmsg:format(mytargets[sel]:dest():name()), myfunc
end

-- Returns a tip message.
function getTipMessage(fac)
   -- All tip messages are valid always.
   if #msg_tip == 0 then
      return getLoreMessage(fac)
   end
   local sel = rnd.rnd(1, #msg_tip)
   local pick = msg_tip[sel]
   table.remove(msg_tip, sel)
   return pick
end

-- Returns a mission hint message, a mission after-care message, OR a lore message if no missionlikes are left.
function getMissionLikeMessage(fac)
   if not msg_combined then
      msg_combined = {}

      -- Hints.
      -- Hint messages are only valid if the relevant mission has not been completed and is not currently active.
      for i, j in pairs(msg_mhint) do
         if not (player.misnDone(j[1]) or player.misnActive(j[1])) then
            msg_combined[#msg_combined + 1] = j[2]
         end
      end
      for i, j in pairs(msg_ehint) do
         if not(player.evtDone(j[1]) or player.evtActive(j[1])) then
            msg_combined[#msg_combined + 1] = j[2]
         end
      end

      -- After-care.
      -- After-care messages are only valid if the relevant mission has been completed.
      for i, j in pairs(msg_mdone) do
         if player.misnDone(j[1]) then
            msg_combined[#msg_combined + 1] = j[2]
         end
      end
      for i, j in pairs(msg_edone) do
         if player.evtDone(j[1]) then
            msg_combined[#msg_combined + 1] = j[2]
         end
      end
   end

   if #msg_combined == 0 then
      return getLoreMessage(fac)
   else
      -- Select a string, then remove it from the list of valid strings. This ensures all NPCs have something different to say.
      local sel = rnd.rnd(1, #msg_combined)
      local pick
      pick = msg_combined[sel]
      table.remove(msg_combined, sel)
      return pick
   end
end

function talkNPC(id)
   local npcdata = npcs[id]

   if npcdata.func then
      -- Execute NPC specific code
      npcdata.func()
   end

   tk.msg( "", npcdata.msg )
end

--[[
--    Event is over when player takes off.
--]]
function leave ()
   evt.finish()
end
