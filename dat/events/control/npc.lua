--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Spaceport Bar NPC">
 <trigger>land</trigger>
 <priority>100</priority>
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
require "events/tutorial/tutorial_common"


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
      faction = "Pirate",
      text = {
         _([["You know, I got into this business by accident to tell the truth. But what can you do? I could get a fake ID and pretend to be someone else but I'd get caught eventually. Might as well make the best of what I have now."]]),
         _([["One of my favorite things to do is buy a fake ID and then deliver as much contraband as I can before I get caught. It's great fun, and finding out that my identity's been discovered gives me a rush!"]]),
      },
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
   hook.takeoff("leave")
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
   local choice_practice = p_("bartender", "Combat Practice")
   local choice_nothing = p_("bartender", "Nothing")

   local choice_n, choice = tk.choice("", greeting,
      choice_mission,
      choice_practice,
      choice_nothing)

   if choice == choice_mission then
      bartender_mission()
   elseif choice == choice_practice then
      bartender_combat_practice()
   end
end


function bartender_mission()
   -- Use misnhelper.setBarHint within the bartender_mission custom hook
   -- to set a hint for a mission.
   var.push("_bartender_mission_count", 0)
   naik.hookTrigger("bartender_mission")
   hook.safe("bartender_mission_safe")
end


function bartender_mission_safe()
   local count = var.peek("_bartender_mission_count")
   if count == 0 then
      var.pop("_bartender_ready")
      if planet.cur():services()["missions"] then
         tk.msg("", _([["Hm, I'm sorry, I don't see anything in your active missions I'd be able to help you with right now. If you want to start a new mission, try looking around here at the #bSpaceport Bar#0, or you could take a look at the #bMission Computer#0."]]))
      else
         tk.msg("", _([["Hm, I'm sorry, I don't see anything in your active missions I'd be able to help you with right now. If you want to start a new mission, try looking around here at the #bSpaceport Bar#0. If you can't find one, you could search for a planet which has a #bMission Computer#0 and look there."]]))
      end
   elseif count == 1 then
      local name = var.peek("_bartender_mission_name_1")
      local hint = var.peek("_bartender_mission_hint_1")
      tk.msg(name, hint)
   else
      local names = {}
      local hints = {}
      for i = 1, count do
         names[i] = var.peek(string.format("_bartender_mission_name_%d", i))
         hints[i] = var.peek(string.format("_bartender_mission_hint_%d", i))
      end

      local msg = _([["I'll do my best! Which mission would you like guidance on?"]])
      local choice_n, choice = tk.list("", msg, table.unpack(names))

      if choice_n ~= nil then
         tk.msg(choice, hints[choice_n])
      end
   end

   -- Pop all bartender mission hint variables.
   var.pop("_bartender_mission_count")
   for i = 1, count do
      var.pop(string.format("_bartender_mission_name_%d", i))
      var.pop(string.format("_bartender_mission_hint_%d", i))
   end
end


function bartender_combat_practice()
   if not player.misnActive("Combat Practice") then
      if tk.yesno("", _([["You want to start a combat session? I can launch some AI-powered drones in this system for you to practice against. There's no risk of death, and you can choose what you want to fight against."]])) then
         naik.missionStart("Combat Practice")
      end
   else
      local msg = fmt.f(_([["You've already started a combat practice session. If you want to change it, you can abort it from your Ship Computer. You can access that by pressing {infokey}."]]),
         {infokey=tutGetKey("info")})
      tk.msg("", msg)
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
