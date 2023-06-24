--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Seek And Destroy (FLF)">
 <avail>
  <priority>42</priority>
  <cond>player.numOutfit("Mercenary License") &gt; 0</cond>
  <chance>250</chance>
  <location>Computer</location>
  <faction>Dvaered</faction>
 </avail>
</mission>
--]]
--[[

   Variant of the Seek and Destroy mission that targets FLF ships.

--]]

require "missions/neutral/seek_and_destroy"


clue_text = {
   _([[The pilot tells you that {pilot} is supposed to have business in {system} soon.]]),
   _([["I've heard that {pilot} likes to hang around in {system}."]]),
   _([["You can probably catch {pilot} in {system}."]]),
   _([["I would suggest going to {system} and taking a look there. That's where {pilot} was last time I heard."]]),
   _([["If I was looking for {pilot}, I would look in the {system} system. That's probably a good bet."]]),
   _([["Oh, I know that terrorist scum. Bad memories. If I were you, I'd check the {system} system. Good luck!"]]),
}

noclue_text = {
   _([[This person has never heard of {pilot}. It seems you will have to ask someone else.]]),
   _([["{pilot}? Who's {pilot}?"]]),
   _([["Sorry, I have no idea where {pilot} is."]]),
   _([["I haven't a clue where {pilot} is."]]),
   _([["I don't give a damn about {pilot}. Go away."]]),
   _([["{pilot}? Don't know, don't care."]]),
   _([[When you ask about {pilot}, you are promptly told to get lost.]]),
   _([["I've not seen {pilot}, no."]]),
}

money_text = {
   _([["Well, I don't offer my services for free. Pay me {credits} and I'll tell you where to look for {pilot}"]]),
   _([["Ah, yes, I think I know where {pilot} is. I'll tell you for just {credits}. A good deal, don't you think?"]]),
   _([["{pilot}? Yes, I know {pilot}. I can tell you where they were last heading, but it'll cost you. {credits}. Deal?"]]),
   _([["Ha ha ha! Yes, I've seen {pilot} around! Will I tell you where? Heck no! Not unless you pay me, of course. Let's see… {credits} should be sufficient."]]),
   _([["I tell you what: give me {credits} and I'll tell you where {pilot} is. Otherwise, get lost!"]]),
}

payclue_text = {
   _("The pilot tells you that {pilot} is supposed to have business in {system} soon."),
   _([["{pilot} likes to hang around in {system}. Go there and I'm sure you'll find them. Whether or not you can actually defeat {pilot}, on the other hand… heh, not my problem!"]]),
   _([["{system} is definitely your best bet. {pilot} spends a lot of time there."]]),
   _([["{system} is the last place {pilot} was heading to. Go quickly and you just might catch up."]]),
   _([["Heh, thanks for the business! {system} is where you can find {pilot}."]]),
}

scared_text = {
   _([["OK, OK, I'll tell you! You can find {pilot} in the {system} system. Don't shoot at me, please!"]]),
   _([["D-dont shoot, please! OK, I'll tell you. I heard that {pilot} is in the {system} system. Honest!"]]),
   _([[The pilot's eyes widen as you threaten their life, and they immediately comply, telling you that {pilot} can be found in the {system} system.]]),
}

intimidated_text = {
   _([["Stop shooting, please! I'll tell you! {pilot} is in the {system} system! I swear!"]]),
   _([[As you make it clear that you have no problem with blasting them to smithereens, the pilot begs you to let them live and tells you that {pilot} is supposed to have business in {system} soon.]]),
   _([["OK, OK, I get the message! The {system} system! {pilot} is in the {system} system! Just leave me alone!"]]),
}

cold_text = {
   _([[When you ask for information about {pilot}, they tell you that this FLF pilot has already been killed by someone else.]]),
   _([["Didn't you hear? That terrorist's dead. Got blown up in an asteroid field is what I heard."]]),
   _([["Ha ha, you're still looking for {pilot}? You're wasting your time; that outlaw's already been taken care of."]]),
   _([["Ah, sorry, that target's already dead. Blown to smithereens by a mercenary. I saw the scene, though! It was glorious."]]),
   _([["Er, someone else already killed {pilot}, but if you like, I could show you a picture of their ship exploding! It was quite a sight to behold."]]),
}
enemy_cold_text = {
   _([["{pilot} is dead, asshole. One of you mercenary types killed them."]]),
   _([["One of you bounty hunters kills {pilot} and now you want to rub it in? Piss off!"]]),
   _([["Where is {pilot}? Dead! Deceased! Killed by a cold-blooded killer like you!"]]),
   _([["So you're one of the assholes who went after {pilot} and got them killed! For what, a few damn credits? People like you are what's wrong in this universe!"]]),
}

noinfo_text = {
   _([[The pilot asks you to give them one good reason to give you that information.]]),
   _([["What if I know where your target is and I don't want to tell you, eh?"]]),
   _([["Piss off! I won't tell anything to the likes of you!"]]),
   _([["And why exactly should I give you that information?"]]),
   _([["And why should I help you, eh? Get lost!"]]),
   _([["Piss off and stop asking questions about {pilot}, asshole!"]]),
}

misn_desc = _([[A dangerous FLF terrorist known as {pilot} is wanted dead or alive by {faction} authorities, last seen in the {system} system. Any mercenary who can track down and eliminate this terrorist will be awarded substantially.

Mercenaries who accept this mission are advised to go to the indicated system and talk to others in the area, either by hailing pilots while out in space or by talking to people on planets in the system, if applicable.]])

misn_title = {
   _("Seek and Destroy: Small Terrorist Bounty ({system} system)"),
   _("Seek and Destroy: Difficult Terrorist Bounty ({system} system)"),
}
ship_choices = {
   {"Vendetta", "Lancelot"},
   {"Pacifier"},
}
base_reward = {
   600000,
   1600000,
}

target_faction = faction.get("FLF")
name_func = pilot_name

virtual_allies = {
   "Frontier",
}

enemy_know_chance = 0.2
enemy_tell_chance = 0.5
neutral_know_chance = 0.2
neutral_tell_chance = 0.25
ally_know_chance = 0.9
ally_tell_chance = 0

fearless_factions = {
   "FLF",
}
loyal_factions = {
   "FLF",
   "Frontier",
}
