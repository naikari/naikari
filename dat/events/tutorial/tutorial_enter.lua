--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Enter Tutorial Event">
 <trigger>enter</trigger>
 <chance>100</chance>
 <flags>
  <unique />
 </flags>
 <notes>
  <requires name="Continued Tutorial"/>
 </notes>
</event>
--]]
--[[
   Enter Tutorial Event

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

require "events/tutorial/tutorial_common"


nofuel_text = _([[You swear to yourself as you see that you're out of fuel with no place to land. How can you get fuel now? Just as you're thinking this, Captain T. Practice shows up. "I see you've run out of fuel and don't have a place to land! But don't worry, you can still refuel. It'll just be a little harder and more costly.

See you can hail any other pilot either by #bdouble-clicking#0 on them, or by targeting them with %s and pressing %s. Once you've hailed them, you can request to be refueled. This isn't likely to work on military ships, but many civilians and traders will happily sell you some of their fuel for a nominal fee. When you find someone willing to refuel you, you will need to stop your ship, which you can do easily with %s, and wait for them to reach your ship and finish the fuel transfer.

"If there aren't any civilians or traders in the area, there's one other way: if you hail a pirate, you can usually bribe them to convince them to leave you alone. After you've bribed them, there's a good chance they'll be willing to sell you fuel as well if you hail them again! While having to trust a pilot isn't ideal, it's at least better than being stuck in open space with no rescue.

"Good luck!" Captain T. Practice terminates the communication. It looks like you'll have to talk to the other pilots in the system.…]])
nofuel_log = _([[You can hail any other pilot by either double-clicking on them, or by targeting them with the Target Nearest key (T by default) and then pressing the Hail Target key (Y by default). From there, you can ask to be refueled. Most military ships will not be willing to help you, but many civilians and traders will be willing to sell you some fuel for a nominal fee. When you find someone willing to refuel you, you need to stop your ship, which you can do with the Autobrake key (Ctrl+B by default), and wait for them to reach your ship and finish the fuel transfer.

If there are no civilians or traders in the system, you can alternatively attempt to get fuel from a pirate. To do so, you must first hail them and offer a bribe, and if you successfully bribe them, they will often be willing to refuel you if you hail them again and ask for it.]])

hostile_presence_text = _([[Captain T. Practice shows up again. "It seems you've entered a system with hostile pilots! This is the first of many, I'm afraid, so it's important that you know what to do to protect yourself.

"Obviously, one thing you can do is fight, assuming you have the capability. However, if you're outnumbered or unable to fight, there's still one more thing you can do: if you either #bdouble-click#0 on a hostile pilot, or target them with %s and then press %s, you can open the communication window, where you can bribe the pilot so that they stop attacking you. This usually works with pirate scum, though it may be less effective against other factions.

"You can always check the faction presences of a given system by pressing %s to open the starmap. On the right, you will see a list of all factions present in the currently selected system, along with a number indicating how strong their presence is. This can help you stay out of hostile systems in the first place, if you wish.

"However you choose to do, stay safe!"]])
hail_hostile_log = _([[You can hail a hostile pilot either by double-clicking on the pilot, or by targeting them with the Target Nearest Hostile key (R by default) and pressing the Hail key (Y by default). From there, you can bribe the pilot so that they stop attacking you. This is particularly effective against pirates.]])
hostile_presence_log = _([[You can check faction the presences of a given known system by pressing the Star Map key (M by default) and selecting the system on the map. Each faction present in the system is listed on the right, along with a number indicating how strong their presence is.]])

nebu_volat_text = _([[You begin to notice your shielding equipment behaving somewhat erratically as you see Captain T. Practice show up on your view screen. "Exploring the nebula, eh? It seems you're in a portion of the nebula with some volatility. Specifically, the system you're in has a volatility rating of %g GW. That means you are right now constantly taking that amount of damage. Your shields repel 85%% of the damage due to the unique qualities of shielding, but your armor does not; if you run out of shields, your armor will begin to rapidly lose its integrity. For this reason, you should try not to be put in a situation where your shields are inactive.

"You can see the volatility of the nebula in any given system via the starmap, which you can open by pressing %s. Information about the selected system, which includes volatility, can be found in the bottom-left. Try not to go too far into the nebula, and if you see your shields starting to drop, I advise you retreat to where you came from immediately. Stay safe!"]])
nebu_volat_log = _([[Systems with a nebula volatility rating constantly cause damage to ships within them. The volatility rating corresponds to the damage they constantly inflict. Shields repel 85% of the damage inflicted on them, but armor, if left without shields, will take full damage and rapidly start to lose its integrity.]])
map_volat_log = _([[You can see the volatility of the nebula in any given system via the starmap, which you can open by pressing the Star Map key (M by default). Information about the selected system, which includes nebula volatility, can be found in the bottom-left.]])


function create ()
   -- Delay the event by a bit so it doesn't happen in the middle of
   -- the transition between the systems.
   hook.timer(3, "timer")
   hook.jumpout("jumpout")
end


function timer ()
   local sys = system.cur()
   local nebu_dens, nebu_volat = sys:nebula()
   local landable_planets = false

   if not var.peek("tutorial_nofuel") and player.jumps() == 0 then
      for i, pl in ipairs(planet.getAll()) do
         if pl:system() == sys and pl:canLand() then
            landable_planets = true
            break
         end
      end
   end

   if not var.peek("tutorial_nofuel") and not landable_planets
         and player.jumps() == 0 then
      if var.peek("_tutorial_passive_active") then
         tk.msg("", nofuel_text:format(
                  tutGetKey("target_next"), tutGetKey("hail"),
                  tutGetKey("autobrake")))
      end
      addTutLog(nofuel_log, N_("Hailing"))
      var.push("tutorial_nofuel", true)
   elseif not var.peek("tutorial_hostile_presence")
         and sys:presence("hostile") > 0 then
      if var.peek("_tutorial_passive_active") then
         tk.msg("", hostile_presence_text:format(
                  tutGetKey("target_hostile"), tutGetKey("hail"),
                  tutGetKey("starmap")))
      end
      addTutLog(hail_hostile_log, N_("Combat"))
      addTutLog(hostile_presence_log, N_("Navigation"))
      var.push("tutorial_hostile_presence", true)
   elseif not var.peek("tutorial_nebula_volatility") and nebu_volat > 0 then
      if var.peek("_tutorial_passive_active") then
         tk.msg("", nebu_volat_text:format(nebu_volat, tutGetKey("starmap")))
      end
      addTutLog(nebu_volat_log, N_("Nebula"))
      addTutLog(map_volat_log, N_("Nebula"))
      var.push("tutorial_nebula_volatility", true)
   end

   evt.finish()
end


function jumpout ()
   -- In the unlikely event that a player leaves the system too quickly
   -- to see a message before jumping out, this prevents it from showing
   -- the message to prevent weirdness of looking like it's referring to
   -- a system that it isn't.
   evt.finish()
end

