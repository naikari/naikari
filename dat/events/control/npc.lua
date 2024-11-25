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

local fmt = require "fmt"
local portrait = require "portrait"
require "jumpdist"


--[[
NPC messages. Each is a table with the following keys:
   "faction": The faction it appears with or a list of them. (optional)
   "exclude_faction": Like "faction", but prevents appearance.
      (optional)
   "text": The text of the message. Can also be a list.
   "cond": function returning whether the message can be used.
      (optional)
--]]
local messages = {
   {
      text = {
         _([["I'm still not used to the randomly exploding asteroids. You'll just be passing thru an asteroid field, minding your own business, and then boom! The asteroid blows up. I wonder why they do that."]]),
         _([["I wonder if we're really alone in the universe. We've never discovered alien life, but maybe we just haven't looked hard enough."]]),
      },
   },
   {
      exclude_faction = {"Thurion", "Proteron", "Pirate", "Za'lek"},
      text = {
         _([["I heard the Nebula is haunted! My uncle told me he saw one of the ghost ships himself over in Arandon."]]),
         _([["I don't believe in those Nebula ghost stories. The people who spread them are just trying to scare you."]]),
         _([["Don't try to fly into the Inner Nebula. I've known people who tried, and none of them came back."]]),
         _([["As horrible as the Incident was, it's a good thing that we don't have to worry about House Proteron anymore. That's the one silver lining to it."]]),
      },
   },
   {
      exclude_faction = {"Thurion", "Proteron"},
      text = {
         _([["Don't listen to those conspiracy theories about the Incident. We don't know what happened, sure, but why on Earth would someone blow up… you know, Earth… on purpose?"]]),
         _([["I wonder if there's anything left in the Inner Nebula. Supposedly everything blew up, but what if some artifact survived that was impervious to it?"]]),
      },
   },
   {
      exclude_faction = {"Sirius", "Za'lek", "Thurion", "Proteron", "Pirate"},
      text = _([["I wonder why the Siriusites are all so devout. I heard they have these special priestly people walking around. I wonder what's so special about them."]]),
      cond = function()
         local p = planet.cur()
         return (p:faction() ~= faction.get("Sirius")
            and p ~= planet.get("The Wringer") and p ~= planet.get("Sanctity"))
      end,
   },
   {
      exclude_faction = {"Soromid", "Za'lek", "Thurion", "Proteron", "Pirate"},
      text = _([["The Soromid fly organic ships! I heard their ships grow and improve as you use them. That's so weird."]]),
      cond = function()
         return planet.cur():faction() ~= faction.get("Soromid")
      end,
   },
   {
      text = _([["What? You had rodents sabotage your ship? Damn, you're lucky to be alive. If it had hit the wrong power line…"]]),
      cond = function()
         return player.evtDone("Animal trouble")
      end,
   },
   {
      faction = "Independent",
      text = {
         _([["I won't lie, the Soromid freak me the hell out. Something's just… fishy about them. You know what I mean?"]]),
         _([["I worry about big genetics, you know? All those gene manipulators, it just isn't natural."]]),
         _([["I've been spending a lot of time around the Soromid lately. It's nice to be back home. Not like I really mind being around the Soromid, of course. Fine people, the Soromid. They just start giving you the creeps after a while, know what I mean?"]]),
      },
   },
   {
      faction = "Goddard",
      text = {
         _([["We're very proud of the Goddard ship here. If you haven't already, you should consider buying one!"]]),
         _([["Everyone's all about carriers these days, but let me tell you, when you're up close to a Goddard, it had better be on your side or you'll be blown to space dust in seconds."]]),
         _([["I feel like we get unfairly overlooked. Sure, we only control one system, but that has to count for something."]]),
         _([["Lots of my contemporaries won't tell it straight, but come on, we're not really a Great House because of our engineering. It's the Dvaereds. The Empire doesn't want to share a border with them, so they granted us autonomy. We're just a buffer for them."]]),
      },
   },
   {
      faction = "Empire",
      text = {
         _([["Things are getting worse every year. What happened to the Empire? We used to be the lords and masters over the whole galaxy!"]]),
         _([["Did you know that House Za'lek was originally a Great Project initiated by the Empire? There was also a Project Proteron, but that one didn't go so well."]]),
         _([["Don't pay attention to the naysayers. The Empire is still strong. Have you ever seen a Peacemaker up close? I doubt any ship fielded by any other power could stand up to one."]]),
         _([["I don't know who did it, but believe me, the Incident was no accident! It was definitely a terrorist attack orchestrated by those disloyal Great Houses in an effort to take down the Empire."]]),
         _([["I wouldn't travel north of Alteris if I were you, unless you're a good fighter! That area of space has really gone down the drain since the Incident."]]),
      },
   },
   {
      faction = "Empire",
      text = {
         _([["This thing with pirates showing up in Hakoi worries me. I have a feeling something bad is going to happen to the Empire, but I hope I'm wrong."]]),
         _([["Those damn pirates are in Hakoi now. What happened to the Empire? We used to be the strongest in all the universe, and now what, we can't stop a few criminals from getting in?"]]),
      },
      cond = function()
         return player.misnDone("Tutorial Part 4")
      end
   },
   {
      faction = "Dvaered",
      text = {
         _([["My great-great-great-grandfather fought in the Dvaered Revolts! We still have the holovids he made. I'm proud to be a Dvaered!"]]),
         _([["You'd better not mess with the Dvaered. Our military is the largest and strongest in the galaxy. Nobody can stand up to us!"]]),
         _([["House Dvaered? House? The Empire is weak and useless, we don't need them anymore! I say we declare ourselves an independent faction today. What are they going to do, subjugate us? We all know how well that went last time! Ha!"]]),
         _([["I'm thinking about joining the military. Every time I see or hear news about those rotten FLF bastards, it makes my blood boil! They should all be pounded into space dust!"]]),
         _([["FLF terrorists? I'm not too worried about them. You'll see, High Command will have smoked them out of their den soon enough, and then the Frontier will be ours."]]),
         _([["If you ask me, those FLF terrorists caused the Incident. They have a clear motive: they wanted to create that nebula so they would have a place to hide. Damn criminals…"]]),
      },
   },
   {
      faction = "Sirius",
      text = {
         _([["Greetings, traveler. May Sirichana's wisdom guide you as it guides me."]]),
         _([["Even thô the echelons are different, we are all followers of Sirichana. Spiritually, we are equal."]]),
         _([["We are officially part of the Empire, but everyone knows that's only true on paper. The Emperor has no influence on these systems. We follow Sirichana, and no one else."]]),
         _([["The Incident was the righteous divine judgment of Sirichana. He laid judgment on House Proteron for their intrusion into His plan, and He punished the Empire for having started that so-called 'Great Project'."]]),
         _([["I don't think the Incident is an isolated event. The explosion of Sol was just the first of many. Soon, all who do not follow Sirichana will fall just as Earth did, and only we, His devoted servants, will remain."]]),
      },
   },
   {
      faction = "Sirius",
      text = {
         _([["I once met one of the Touchèd in person. Well, it wasn't really a meeting, our eyes simply met… but that instant alone was awe-inspiring."]]),
         _([["My cousin was called to Mutris a year ago. He must be in Crater City by now. And one day, he will become one of the Touchèd!"]]),
         _([["I hope to meet one of the Touchèd one day!"]]),
      },
      cond = function()
         local restriction = planet.cur():restriction()
         return (restriction == nil or restriction == "land_lowclass"
               or restriction == "land_hiclass")
      end,
   },
   {
      faction = "Za'lek",
      text = {
         _([["I would be delighted to discover the secrets of the Incident. Rumors abound, but thru the discovery of more data, we can uncover the true answer."]]),
         _([["I'll admit that the living Soromid ships are marginally interesting, but truly, those primitive lifeforms can't beat the best synthetic technology."]]),
         _([["I don't know why we even bother sending our research results to the Empire anymore. Those idiots can't understand even the simplest of formulae."]]),
         _([["I would love to get my hands on a genuine Proteron ship one day! They were always a danger to the galaxy, of course, but I'd be lying if I said their ship tech wasn't incredible."]]),
         _([["Between you and me, for all the negative stuff the Empire says about House Proteron, they were geniuses. Considering all the stupidity that comes from the Empire, we might just be better off if it was House Proteron that survived the Incident instead."]]),
         _([["Between you and me, while I don't really begrudge our Dvaered neighbors, most of them are kind of stupid. If I have to explain the Goddard-Zak formula to a Dvaered again, I swear I'll lose a brain cell."]]),
         _([["My annual IQ test went well! It's to be expected, of course. We Za'lek pride ourselves on our intelligence."]]),
      },
   },
   {
      faction = "Soromid",
      text = {
         _([["Can you believe it? I was going to visit Sorom to find my roots, and then boom! It got vaporized hours before I was set to arrive! Even now, years later, I still can't believe I came so close to losing my life."]]),
         _([["Yes, it's true, our military ships are alive. Most civilians don't get to own bioships, thô, and have to make do with synthetic constructs just like everyone else."]]),
         _([["Everyone knows that we Soromid altered ourselves to survive the deadly conditions on Sorom during the Great Quarantine. What you don't hear so often is that billions of us died from the therapy itself. We paid a high price for survival."]]),
         _([["Between you and me, I think House Proteron is to blame for the Incident. Think about it: they were just mobilizing their troops to attack the Empire, then poof! A huge explosion happens to occur right at their most likely invasion point. I don't know how it happened, but they must have accidentally vaporized themselves and the core of the Empire as they attempted their assault."]]),
         _([["Sometimes I worry a little about the growing anti-Soromid sentiment. We never really did fully move away from the Empire's stigmatization of us during the Great Quarantine."]]),
         _([["I don't trust the Empire, so I'm frankly glad it's in decline. First we had the Great Quarantine, and then the Incident wiped out our homeworld. I'm not saying the Empire caused the Incident on purpose, but considering Sol was at the center of it and the Empire controlled all of Sol, I'm sure the Empire is at least partially to blame."]]),
         _([["They don't teach about the Great Quarantine in the Empire, do they? A few centuries ago, there was a deadly disease outbreak on our homeworld, Sorom, and the Empire condemned us to die. It was only thru the use of dangerous experimental gene treatments that we were able to survive, and even then, the Empire tried to kill us when we returned to space disease-free."]]),
         _([["It upsets me that there are still Proteron sympathizers, even after they got wiped out by the Incident. They were violent bigots. I don't give a damn how good their ships were, why are so many people willing to give that a pass?"]]),
      },
   },
   {
      faction = "Frontier",
      text = {
         _([["We value our autonomy. We don't want to be ruled by those Dvaered Warlords! Can't they just shoot at each other instead of threatening us? If it wasn't for the Liberation Front…"]]),
         _([["Have you studied your galactic history? The Frontier worlds were the first to be colonized by humans. That makes our worlds the oldest human settlements in the galaxy, now that Earth is gone."]]),
         _([["We don't have much here in the Frontier, other than our long history leading directly back to Earth. But I don't mind. I'm happy living here, and I wouldn't want to move anywhere else."]]),
         _([["You know the Frontier Liberation Front? They're the guerrilla movement that fights for the Frontier. I hope they can continue to hold out."]]),
         _([["The Incident? Oh, I don't think about it too much. It's a tragedy, but we have enough of our own problems to deal with as-is."]]),
      },
   },
   {
      faction = "FLF",
      text = {
         _([["Have you ever wondered about our chances of actually winning over the Dvaereds? Sometimes I worry a little."]]),
         _([["They'll always label us as 'terrorists'. It's nothing more than Dvaered propaganda designed to divide us. We are fighting for the Frontier against the Dvaereds, and the Dvaereds won't ever be OK with that."]]),
         _([["It's important not to forget the action needed on the ground. Fighting is a part of our work, yes, but we also have to preserve a Frontier worth protecting."]]),
      },
   },
   {
      faction = "Pirate",
      text = {
         _([["I may be a pirate who blows up ships and steals for a living, but that inner nebula still kind of freaks me out."]]),
         _([["I was around before Haven was destroyed, you know! Funny times. All the pirates were panicking and the Empire was cheering thinking that we were done for. Ha! As if! It barely even made a difference. We just relocated to New Haven and resumed business as usual."]]),
         _([["You know, I got into this business by accident to tell the truth. But what can you do? I could get a fake ID and pretend to be someone else but I'd get caught eventually. Might as well make the best of what I have now."]]),
         _([["One of my favorite things to do is buy a fake ID and then deliver as much contraband as I can before I get caught. It's great fun, and finding out that my identity's been discovered gives me a rush!"]]),
         _([["If you ask me, the Incident was some sort of alien dimensional phenomenon. I heard rumors of ghost ships flying about that look like nothing humanity has ever invented. Whether the Incident was intentional or just an accidental slip-up, I don't know."]]),
         _([["I sure am glad we don't have to go toe-to-toe with the Proteron. That wannabe empire was trying to start shit and then, boom! Sol blows up and takes the Proteron with it. Let me tell you, up close, their ships were terrifying. I'll take Imperial ships over them any day."]]),
      },
   },
   {
      faction = "Proteron",
      text = {
         _([["The old Empire will pay for blowing up Sol. We all know they did it on purpose."]]),
         _([["The inferior old Empire knew we were destined to replace them, so they blew up Sol in an effort to wipe us out. But they weren't thorough enough, and we won't forgive them!"]]),
         _([["Personally I think the old Empire has been weakened by Sorofreak influence. Those damn freaks have been a scourge on the galaxy ever since they flooded into it."]]),
         _([["It is our destiny as Proteron to rule the galaxy. We are the rightful successor to the Empire. We will take what is ours."]]),
         _([["One of my coworkers was spreading lies about us Proteron causing the Incident. Naturally, I reported him to the police, and they took him away. I'd bet he was a secret Sorofreak sympathizer trying to bring down the great Proteron Empire."]]),
         _([["We must all work hard to ensure our destiny as Proteron is fulfilled."]]),
         _([["The Empire is weak and obsolete, and they know it. That's why they went so low as to blow Earth up to try to get rid of us."]]),
         _([["I'm thinking of enlisting in the military so I can join the fight against the Sorofreak elite and the traitorous old Empire."]]),
         _([["It's time for natural selection to take its course. We Proteron are strong, and it's time for us to crush the weak."]]),
         _([["The Empire designed standard pilot interfaces to be colorblind-accessible. I hate it. Why should the 99.99% of normal people be expected to deal with these ugly colors and symbols just for a few cripples?"]]),
      },
   },
   {
      faction = "Thurion",
      text = {
         _([["We were lucky to not get touched by the explosion of Sol. In fact, we kind of benefited from it. The nebula that resulted gave us a great cover and sealed off the Empire from us."]]),
         _([["It's a good thing those Proteron folks got vaporized in the explosion of Sol. The Empire is scary, but House Proteron was always much, much worse."]]),
         _([["Oh, you're from the outside, aren't you? Tell me, what was it like out there?"]]),
      },
   },
   {
      faction = {"Empire", "Za'lek"},
      text = _([["Have you seen a Proteron ship before? Let me tell you, they were a sight to behold, way ahead of their time. There's still a few scattered thruout the galaxy that survived the Incident, but those are mostly owned by really wealthy aristocrats these days."]]),
   },
}

used_messages = {}


function create()
   -- Spawn bartender.
   local fac = planet.cur():faction()
   local facname = fac ~= nil and fac:nameRaw() or nil
   bartender = evt.npcAdd("talkBartender", _("Bartender"),
         portrait.get(facname),
         _("The bartender may be a helpful source of information."), 0)

   if planet.cur():blackmarket() then
      local num_dealers = rnd.rnd(0, 6)
      for i=1,num_dealers do
         spawnDealer()
      end
   end

   -- End event on takeoff.
   hook.takeoff( "leave" )
end


function spawnDealer()
   local outfits = {}
   local ships = {}
   local factions = {}
   local curplanet, cursys = planet.cur()
   local pirate_f = faction.get("Pirate")

   getsysatdistance(cursys, 0, 8,
      function(s)
         if s:presences()["Pirate"] then
            for i, p in ipairs(s:planets()) do
               local f = p:faction()
               if f ~= nil then
                  factions[f:nameRaw()] = true
               end
               for j, o in ipairs(p:outfitsSold()) do
                  if o:rarity() >= 2 then
                     table.insert(outfits, o)
                  end
               end
               for j, s in ipairs(p:shipsSold()) do
                  if s:rarity() >= 2 then
                     table.insert(ships, s)
                  end
               end
            end
         end
      end, nil, true)

   local npcdata = nil
   if rnd.rnd() < 0.1 and #dealer_maps > 0 then
      local map_choice = dealer_maps[rnd.rnd(1, #dealer_maps)]
      local o_name, offer_text, sold_text = table.unpack(map_choice)
      local outfit_choice = outfit.get(o_name)
      local price = outfit_choice:price()
      price = price + 0.2*price*rnd.sigma()
      local text = fmt.f(offer_text, {credits=fmt.credits(price)})
      npcdata = {msg=text, outfit=outfit_choice, price=price}
      npcdata.func = function(id, data)
            local plcredits, plcredits_str = player.credits(2)
            local text = (data.msg .. "\n\n"
                  .. fmt.f(_("You have {credits}."), {credits=plcredits_str}))
            if tk.yesno("", text) then
               if plcredits >= data.price then
                  tk.msg("", sold_text)
                  player.pay(-data.price, "adjust")
                  player.outfitAdd(data.outfit:nameRaw())
                  data.msg = getMessage("Pirate")
                  data.func = nil
               else
                  local s = fmt.f(_([["You're {credits} short. Don't test my patience."]]),
                        {credits=fmt.credits(data.price - plcredits)})
                  tk.msg("", s)
               end
            end
         end
   elseif rnd.rnd() < 0.5 and #outfits > 0 then
      local texts = {
         _([["Why, hello there! I have a fantastic outfit in my possession, a state-of-the-art {outfit}. This outfit is rare, but it's yours for only {credits}. Would you like it?"]]),
         _([["Ah, you look like just the kind of pilot who could use this {outfit} in my possession. It's an outfit that's rather hard to come by, I assure you, but for only {credits}, it's all yours. A bargain, don't you think?"]]),
         _([["Ah, come here, come here. As it happens, I have a rare {outfit} in my possession. You can't get this just anywhere, I assure you. For only {credits}, it's yours right now. What do you think?"]]),
         _([["Would you like yourself a nice rare outfit? For only {credits}, I can put this {outfit} in your hands right now. You'd better hurry, thô, because it's in high demand! What do you say?"]]),
      }
      local outfit_choice = outfits[rnd.rnd(1, #outfits)]
      local price = outfit_choice:price()
      price = price + 0.2*price*rnd.sigma()
      local text = fmt.f(texts[rnd.rnd(1, #texts)],
            {outfit=outfit_choice:name(), credits=fmt.credits(price)})
      npcdata = {msg=text, outfit=outfit_choice, price=price}
      npcdata.func = function(id, data)
            local plcredits, plcredits_str = player.credits(2)
            local text = (data.msg .. "\n\n"
                  .. fmt.f(_("You have {credits}."), {credits=plcredits_str}))
            if tk.yesno("", text) then
               if plcredits >= data.price then
                  local sold_texts = {
                     _([["Hehe, thanks! I'm transferring the {outfit} to your account. You'll see it in your outfits list."]]),
                     _([["Excellent! I'm sure you won't be disappointed. I'm transferring the {outfit} into your account now."]]),
                     _([["A wise decision. The {outfit} is now yours. You'll find it along with the rest of your outfits."]]),
                     _([["Good, good! I've transferred the {outfit} to your account. Pleasure doing business with you!"]]),
                  }
                  tk.msg("", fmt.f(sold_texts[rnd.rnd(1, #sold_texts)],
                        {outfit=data.outfit:name()}))
                  player.pay(-data.price, "adjust")
                  player.outfitAdd(data.outfit:nameRaw())
                  data.msg = getMessage("Pirate")
                  data.func = nil
               else
                  local s = fmt.f(_([["You're {credits} short. Don't test my patience."]]),
                        {credits=fmt.credits(data.price - plcredits)})
                  tk.msg("", s)
               end
            end
         end
   elseif #ships > 0 then
      local texts = {
         _([["Why, hello there! I have a fantastic ship in my possession, a state-of-the-art {ship}. This ship is rare, but it's yours for only {credits}. Would you like it?"]]),
         _([["Ah, you look like just the kind of pilot who could use this {ship} in my possession. It's a ship that's rather hard to come by, I assure you, but for only {credits}, it's all yours. A bargain, don't you think?"]]),
         _([["Ah, come here, come here. As it happens, I have a rare {ship} in my possession. You can't get this just anywhere, I assure you. Top-level clearance, but for only {credits}, it's yours right now. What do you think?"]]),
         _([["Would you like yourself a nice rare ship? For only {credits}, I can put this {ship} in your hands right now. You'd better hurry, thô, because it's in high demand! What do you say?"]]),
      }
      local ship_choice = ships[rnd.rnd(1, #ships)]
      local price = ship_choice:price()
      price = price + 0.2*price*rnd.sigma()
      local text = fmt.f(texts[rnd.rnd(1, #texts)],
            {ship=ship_choice:name(), credits=fmt.credits(price)})
      npcdata = {msg=text, ship=ship_choice, price=price}
      npcdata.func = function(id, data)
            local plcredits, plcredits_str = player.credits(2)
            local text = (data.msg .. "\n\n"
                  .. fmt.f(_("You have {credits}."), {credits=plcredits_str}))
            if tk.yesno("", text) then
               if plcredits >= data.price then
                  local sold_texts = {
                     _([["Hehe, thanks! I'm transferring the {ship} to your account."]]),
                     _([["Excellent! I'm sure you won't be disappointed. I'm transferring the {ship} into your account now."]]),
                     _([["A wise decision. The {ship} is now yours."]]),
                     _([["Good, good! I've transferred the {ship} to your account. Pleasure doing business with you!"]]),
                  }
                  tk.msg("", fmt.f(sold_texts[rnd.rnd(1, #sold_texts)],
                        {ship=data.ship:name()}))
                  player.pay(-data.price, "adjust")
                  player.addShip(data.ship:nameRaw())
                  data.msg = getMessage("Pirate")
                  data.func = nil
               else
                  local s = fmt.f(_([["You're {credits} short. Don't test my patience."]]),
                        {credits=fmt.credits(data.price - plcredits)})
                  tk.msg("", s)
               end
            end
         end
   end

   if npcdata ~= nil and player.credits() >= npcdata.price then
      local portrait_f = "Thief"
      if curplanet:faction() == pirate_f then
         portrait_f = "Pirate"
      end
      id = evt.npcAdd("talkNPC", _("Dealer"), portrait.get(portrait_f),
            _("This seems to be a dealer in the black market."), 100)
      npcs[id] = npcdata
   end
end


function getMessage(fac)
   local filtered_messages = {}
   for i, m in ipairs(messages) do
      local allowed_f = true
      if m.faction ~= nil then
         allowed_f = false
         if type(m.faction) == "table" then
            for j, f in ipairs(m.faction) do
               if f == fac then
                  allowed_f = true
                  break
               end
            end
         elseif m.faction == fac then
            allowed_f = true
         end
      end
      if m.exclude_faction ~= nil then
         if type(m.exclude_faction) == "table" then
            for j, f in ipairs(m.exclude_faction) do
               if f == fac then
                  allowed_f = false
                  break
               end
            end
         elseif m.exclude_faction == fac then
            allowed_f = false
         end
      end

      if allowed_f and (m.cond == nil or m.cond()) then
         if type(m.text) == "table" then
            for j, s in ipairs(m.text) do
               table.insert(filtered_messages, s)
            end
         else
            table.insert(filtered_messages, m.text)
         end
      end
   end

   -- If there are no choice strings, treat this as a failure and abort.
   if #filtered_messages <= 0 then
      warn(fmt.f(_("No NPC messages available for faction {faction}."),
            {faction=fac}))
      misn.finish(false)
   end

   -- See if any of the choice strings are unused (some should be in
   -- most cases).
   local unused_messages = {}
   for i, s in ipairs(filtered_messages) do
      local unused = true
      for j, s2 in ipairs(used_messages) do
         if s == s2 then
            unused = false
            break
         end
      end
      if unused then
         table.insert(unused_messages, s)
      end
   end

   if #unused_messages > 0 then
      local choice = unused_messages[rnd.rnd(1, #unused_messages)]
      table.insert(used_messages, choice)
      return choice
   end

   -- No unused messages, so just pick any message.
   return filtered_messages[rnd.rnd(1, #filtered_messages)]
end


function talkBartender(id)
   local greeting = _([["Hi! How can I help you?"]])

   local choice_mission = p_("bartender", "Mission Guidance")

   local choice_n, choice = tk.choice("", greeting,
      choice_mission)

   if choice == choice_mission then
      -- To implement bartender advice in a mission: in the
      -- bartender_mission hook, check if _bartender_ready is true, and
      -- if so, show the advice message(s) and pop _bartender_ready.
      var.push("_bartender_ready", true)
      naik.hookTrigger("bartender_mission")

      if var.peek("_bartender_ready") then
         var.pop("_bartender_ready")
         tk.msg("", _([["Hm, I'm sorry, I don't see anything in your active missions I'd be able to help you with right now. If you need to start a new mission and you don't see anything around the bar, why not take a look at the mission computer? You can find it on any planet with the Missions service by clicking on the Missions tab."]]))
      end
   end
end


function talkNPC(id)
   local npcdata = npcs[id]

   if npcdata.func then
      -- Execute NPC specific code
      npcdata.func(id, npcdata)
   else
      tk.msg("", npcdata.msg)
   end
end

--[[
--    Event is over when player takes off.
--]]
function leave ()
   evt.finish()
end
