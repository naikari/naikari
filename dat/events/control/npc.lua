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
   emp_mil_restricted = _("Imperial Officer"),
   emp_mil_eye = _("Imperial Officer"),
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
   _("An Imperial officer sits idly at one of the tables."),
   _("This Imperial officer seems somewhat spaced-out."),
   _("An Imperial officer drinking alone."),
   _("An Imperial officer sitting at the bar."),
   _("This Imperial officer is idly reading the news terminal."),
   _("This officer seems bored with everything but their drink."),
   _("This officer seems to be relaxing after a hard day's work."),
   _("An Imperial officer sitting in the corner."),
}
mil_desc.emp_mil_eye = mil_desc.emp_mil_restricted
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
   _([["Don't try to fly into the inner nebula. I've known people who tried, and none of them came back."]]),
}

msg_lore["Independent"] = {
   _([["Don't listen to those conspiracy theories about the Incident. We don't know what happened, sure, but why on Earth would someone blow up… you know, Earth… on purpose?"]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
   _([["I won't lie, the Soromid freak me the hell out. Something's just… fishy about them. You know what I mean?"]]),
}

msg_lore["Empire"] = {
   _([["Things are getting worse every year. What happened to the Empire? We used to be the lords and masters over the whole galaxy!"]]),
   _([["Did you know that House Za'lek was originally a Great Project initiated by the Empire? There was also a Project Proteron, but that one didn't go so well."]]),
   _([["The Emperor lives on a giant supercruiser in Gamma Polaris. It's said to be the biggest ship in the galaxy! I wish I could have one."]]),
   _([["Don't pay attention to the naysayers. The Empire is still strong. Have you ever seen a Peacemaker up close? I doubt any ship fielded by any other power could stand up to one."]]),
   _([["I don't know who did it, but believe me, the Incident was no accident! It was definitely a terrorist attack orchestrated by those disloyal Great Houses in an effort to take down the Empire."]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
   _([["I wouldn't travel north of Alteris if I were you, unless you're a good fighter! That area of space has really gone down the drain since the Incident."]]),
}

msg_lore["Dvaered"] = {
   _([["My great-great-great-grandfather fought in the Dvaered Revolts! We still have the holovids he made. I'm proud to be a Dvaered!"]]),
   _([["You'd better not mess with the Dvaered. Our military is the largest and strongest in the galaxy. Nobody can stand up to us!"]]),
   _([["House Dvaered? House? The Empire is weak and useless, we don't need them anymore! I say we declare ourselves an independent faction today. What are they going to do, subjugate us? We all know how well that went last time! Ha!"]]),
   _([["I'm thinking about joining the military. Every time I see or hear news about those rotten FLF bastards, it makes my blood boil! They should all be pounded into space dust!"]]),
   _([["FLF terrorists? I'm not too worried about them. You'll see, High Command will have smoked them out of their den soon enough, and then the Frontier will be ours."]]),
   _([["If you ask me, those FLF terrorists caused the Incident. They have a clear motive: they wanted to create that nebula so they would have a place to hide. Damn criminals…"]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
}

msg_lore["Sirius"] = {
   _([["Greetings, traveler. May Sirichana's wisdom guide you as it guides me."]]),
   _([["I once met one of the Touched in person. Well, it wasn't really a meeting, our eyes simply met… but that instant alone was awe-inspiring."]]),
   _([["My cousin was called to Mutris a year ago. He must be in Crater City by now. And one day, he will become one of the Touched!"]]),
   _([["Some people say Sirius society is unfair because our echelons are determined by birth. But even though we are different, we are all followers of Sirichana. Spiritually, we are equal."]]),
   _([["We are officially part of the Empire, but everyone knows that's only true on paper. The Emperor has no influence on these systems. We follow Sirichana, and no one else."]]),
   _([["I hope to meet one of the Touched one day!"]]),
   _([["The Incident was the righteous divine judgment of Sirichana. He laid judgment on House Proteron for their intrusion into His plan, and He punished the Empire for having started that so-called 'Great Project'."]]),
   _([["I don't think the Incident is an isolated event. The explosion of Sol was just the first of many. Soon, all who do not follow Sirichana will fall just as Earth did, and only we, His devoted servants, will remain."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
}

msg_lore["Soromid"] = {
   _([["Can you believe it? I was going to visit Sorom to find my roots, and then boom! It got vaporized hours before I was set to arrive! Even now, years later, I still can't believe I came so close to losing my life."]]),
   _([["Yes, it's true, our military ships are alive. Us normal folk don't get to own bioships though, we have to make do with synthetic constructs just like everyone else."]]),
   _([["Everyone knows that we Soromid altered ourselves to survive the deadly conditions on Sorom during the Great Quarantine. What you don't hear so often is that billions of us died from the therapy itself. We paid a high price for survival."]]),
   _([["Between you and me, I think House Proteron is to blame for the Incident. Think about it: they were just mobilizing their troops to attack the Empire, then poof! A huge explosion happens to occur right at their most likely invasion point. I don't know how it happened, but they must have accidentally vaporized themselves and the core of the Empire as they attempted their assault."]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
   _([["Sometimes I worry a little about the growing anti-Soromid sentiment. We never really did fully move away from the Empire's stigmatization of us during the Great Quarantine."]]),
   _([["I don't trust the Empire, so I'm frankly glad it's in decline. First we had the Great Quarantine, and then the Incident wiped out our homeworld. I'm not saying the Empire caused the Incident on purpose, but considering Sol was at the center of it and the Empire controlled all of Sol, I'm sure the Empire is at least partially to blame."]]),
   _([["They don't teach about the Great Quarantine in the Empire, do they? A few centuries ago, there was a deadly disease outbreak on our homeworld, Sorom, and the Empire condemned us to die. It was only through the use of dangerous experimental gene treatments that we were able to survive, and even then, the Empire tried to kill us when we returned to space disease-free."]]),
}

msg_lore["Za'lek"] = {
   _([["I would be delighted to discover the secrets of the Incident. Rumors abound, but through the discovery of more data, we can uncover the true answer."]]),
   _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
   _([["I'll admit that the living Soromid ships are marginally interesting, but truly, they can't beat the best synthetic technology."]]),
   _([["I don't know why we even bother sending our research results to the Empire anymore. Everyone knows it's just charity at this point."]]),
   _([["I would love to get my hands on a genuine Proteron ship one day! They've always been a danger to the galaxy, but I'd be lying if I said their ship tech wasn't incredible."]]),
}

msg_lore["Thurion"] = {
   _([["Did you know that even the slightest bit of brain damage can lead to death during the upload process? That's why we're very careful to not allow our brains to be damaged, even a little."]]),
   _([["My father unfortunately hit his head when he was young, so he couldn't be safely uploaded. It's okay, though; he had a long and fulfilling life, for a non-uploaded human, that is."]]),
   _([["One great thing once you're uploaded is that you can choose to forget things you don't want to remember. My great-grandfather had a movie spoiled for him before he could watch it, so once he got uploaded, he deleted that memory and watched it with a fresh perspective. Cool, huh?"]]),
   _([["The best part of our lives is after we're uploaded, but that doesn't mean we live boring lives before then. Pre-upload life continues to offer many wonders and marvels."]]),
   _([["Being uploaded allows you to live forever, but that doesn't mean you're forced to. Any uploaded Thurion can choose to end their own life if they want, though few have chosen to do so."]]),
   _([["Uploading is a choice in our society. No one is forced to do it. It's just that, well, what kind of person would turn down the chance to live a second life on the network?"]]),
   _([["We were lucky to not get touched by the Incident. In fact, we kind of benefited from it. The nebula that resulted gave us a great cover and sealed off the Empire from us."]]),
   _([["I think you're from the outside, aren't you? That's awesome! I've never met a foreigner before. What's it like outside the nebula?"]]),
   _([["The Soromid have a rough history. Have you read up on it? First the Empire confined them to a deadly planet and doomed them to extinction. Then, when they overcame those odds, the Incident blew up their homeworld. The fact that they're still thriving now despite that is phenomenal, I must say."]]),
}

msg_lore["Proteron"] = {
   _([["The old Empire will pay for blowing up Sol. We all know they did it on purpose."]]),
   _([["The obsolete old Empire knew we were destined to replace them, so they blew up Sol in an effort to wipe us out. But they weren't thorough enough, and we won't forgive them!"]]),
   _([["Personally I think the old Empire has been weakened by Sorofreak influence. Those damn freaks have been a scourge on the galaxy ever since they flooded into it."]]),
   _([["It is our destiny as Proteron to rule the galaxy. We are the rightful successor to the Empire. We will take what is ours."]]),
   _([["One of my co-workers was spreading lies about us Proteron causing the Incident. Naturally, I reported him to the police, and they took him away. I'd bet he was a secret Sorofreak sympathizer trying to bring down the great Proteron Empire."]]),
   _([["We must all work hard to ensure our destiny as Proteron is fulfilled."]]),
   _([["The Empire is weak and obsolete, and they know it. That's why they went so low as to blow Earth up to try to get rid of us."]]),
   _([["I'm thinking of enlisting in the military so I can join the fight against the Sorofreak elite and the traitorous old Empire."]]),
   _([["It's time for natural selection to take its course. We Proteron are strong, and it's time for us to crush the weak."]]),
}

msg_lore["Frontier"] = {
   _([["We value our autonomy. We don't want to be ruled by those Dvaered Warlords! Can't they just shoot at each other instead of threatening us? If it wasn't for the Liberation Front…"]]),
   _([["Have you studied your galactic history? The Frontier worlds were the first to be colonized by humans. That makes our worlds the oldest human settlements in the galaxy, now that Earth is gone."]]),
   _([["We don't have much here in the Frontier, other than our long history leading directly back to Earth. But I don't mind. I'm happy living here, and I wouldn't want to move anywhere else."]]),
   _([["You know the Frontier Liberation Front? They're the guerrilla movement that fights for the Frontier. I hope they can continue to hold out."]]),
   _([["The Incident? Oh, I don't think about it too much. It's a tragedy, but we have enough of our own problems to deal with as-is."]]),
   _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
}

msg_lore["FLF"] = {
   _([["Have you ever wondered about our chances of actually winning over the Dvaereds? Sometimes I worry a little."]]),
   _([["I was in charge of a bombing run recently. The mission was a success, but I lost a lot of comrades in the process. I wish I could bring them back, but in lieu of that, I fight for their honor as well as my own."]]),
   _([["They'll always label us as 'terrorists'. It's nothing more than Dvaered propaganda designed to divide us. We are fighting for the Frontier against the Dvaereds, and the Dvaereds won't ever be OK with that."]]),
   _([["It's important not to forget the action needed on the ground. Fighting is a part of our work, yes, but we also have to preserve a Frontier worth protecting."]]),
}

msg_lore["Pirate"] = {
   _([["I may be a pirate who blows up ships and steals for a living, but that inner nebula still kind of freaks me out."]]),
   _([["I was around before Haven was destroyed, you know! Funny times. All the pirates were panicking and the Empire was cheering thinking that we were done for. Ha! As if! It barely even made a difference. We just relocated to New Haven and resumed business as usual."]]),
   _([["You know, I got into this business by accident to tell the truth. But what can you do? I could get a fake ID and pretend to be someone else but I'd get caught eventually. Might as well make the best of what I have now."]]),
   _([["One of my favorite things to do is buy a fake ID and then deliver as much contraband as I can before I get caught. It's great fun, and finding out that my identity's been discovered gives me a rush!"]]),
   _([["If you ask me, the Incident was some sort of alien dimensional phenomenon. I heard rumors of ghost ships flying about that look like nothing humanity has ever invented. Whether the Incident was intentional or just an accidental slip-up, I don't know."]]),
}

-- Gameplay tip messages.
-- ALL NPCs have a chance to say one of these lines instead of a lore message.
-- So, make sure the tips are always faction neutral.
msg_tip = {
   _([["I heard you can set your weapons to only fire when your target is in range, or just let them fire when you pull the trigger. Sounds handy!"]]),
   string.format( _([["Did you know that if a planet doesn't like you, you can often bribe the spaceport operators and land anyway? Just hail the planet with %s, and click the bribe button! Careful though, it doesn't always work."]]), tutGetKey("hail") ),
   _("\"Are you trading commodities? You can hold down #bctrl#0 to buy 50 of them at a time, and #bshift#0 to buy 100. And if you press them both at once, you can buy 500 at a time! You can actually do that with outfits too, but why would you want to buy 50 laser cannons?\""),
   _([["If you're on a mission you just can't beat, you can open the ship computer and abort the mission. There's no penalty for doing it, so don't hesitate to try the mission again later."]]),
   _([["Afterburners can speed you up a lot, but when they get hot they don't work as well anymore. Don't use them carelessly!"]]),
   _([["If you're new to the galaxy, I recommend you buy a map or two. It can make exploration a bit easier."]]),
   _([["Scramblers and jammers make it harder for missiles to track you. They can be very handy if your enemies use missiles."]]),
   string.format( _([["If you're having trouble with overheating weapons or outfits, you can press %s twice to put your ship into Active Cooldown; that'll dissipate all heat from your ship and also refill your rocket ammunition. Careful though, your energy and shields won't recharge while you do it!"]]), tutGetKey("autobrake") ),
   _([["You know how time speeds up when Autonav is on, but then goes back to normal when enemies are around? Turns out you can't disable the return to normal speed entirely, but you can control what amount of danger triggers it. Really handy if you want to ignore enemies that aren't actually hitting you."]]),
   _([["Flying bigger ships is awesome, but it's a bit tougher than flying smaller ships. There's so much more you have to do for the same actions, time just seems to fly by faster. I guess the upside of that is that you don't notice how slow your ship is as much."]]),
   _([["Mining can be an easy way to earn some extra credits, but every once in a while an asteroid will just randomly explode for no apparent reason, so you have to watch out for that. Yeah, I don't know why they do that either."]]),
   _([["Different ships should be built and piloted differently. One of the hardest lessons I learned as a pilot was to stop worrying so much about the damage my ship was taking in battle while piloting a large ship. These ships are too slow for dodging, so you need to learn to just take the hits and focus your attention on firing back at your enemies."]]),
   _([["Don't forget to have your target selected. Even if you have forward-facing weapons, the weapons will swivel a bit to track your target. But it's absolutely essential for turreted weapons."]]),
   _([["The '¢' symbol is the official galactic symbol for credits. Supposedly it comes from the currency symbol of an ancient Earth civilization. It's sometimes expressed with SI prefixes: 'k¢' for thousands of credits, 'M¢' for millions of credits, and so on."]]),
   _([["If you're piloting a medium ship, I'd recommend you invest in at least one turreted missile launcher. I had a close call a few days ago where a bomber nearly blew me to bits outside the range of my Laser Turrets. Luckily I just barely managed to escape to a nearby planet. I've not had that problem ever since I equipped a turreted missile launcher."]]),
   _([["These computer symbols can be confusing sometimes! I've figured it out, though: #F+#0 means friendly, #N~#0 means neutral, #H!!#0 means hostile, #R*#0 means restricted, and #I=#0 means uninhabited but landable."]]),
   _([["This can be a bit dangerous, but if you ever run out of fuel in a system with nothing to land on and no friendly pilots willing to refuel you, pirates will often be willing to sell you some of their fuel. You just have to bribe them first. It'll put a drain on your credits, but at least you can make it out alive!"]]),
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
