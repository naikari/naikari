--[[
<?xml version='1.0' encoding='utf8'?>
<event name="start_event">
 <trigger>none</trigger>
</event>
--]]
function name()
   local names = {
      p_("shipname", "Aluminum Mallard"),
      p_("shipname", "Armchair Traveller"),
      p_("shipname", "Attitude Adjuster"),
      p_("shipname", "Commuter"),
      p_("shipname", "Death Trap"),
      p_("shipname", "Eclipse"),
      p_("shipname", "Exitprise"),
      p_("shipname", "Firefly"),
      p_("shipname", "Fire Hazard"),
      p_("shipname", "Gunboat Diplomat"),
      p_("shipname", "Heart of Lead"),
      p_("shipname", "Icarus"),
      p_("shipname", "Little Rascal"),
      p_("shipname", "Myrmidon"),
      p_("shipname", "Opportunity"),
      p_("shipname", "Outward Bound"),
      p_("shipname", "Pathfinder"),
      p_("shipname", "Planet Jumper"),
      p_("shipname", "Rustbucket"),
      p_("shipname", "Serendipity"),
      p_("shipname", "Shove Off"),
      p_("shipname", "Sky Cutter"),
      p_("shipname", "Terminal Velocity"),
      p_("shipname", "Titanic MCCCXII"),
      p_("shipname", "Vagabond"),
      p_("shipname", "Vindicator"),
      p_("shipname", "Windjammer"),
   }
   return names[rnd.rnd(1,#names)]
end


function create()
   local pp = player.pilot()
   pp:rename(name()) -- Assign a random name to the player's ship.

   jump.setKnown("Hakoi", "Eneguoz")
   var.push("player_formation", "circle")

   -- Give all GUIs
   -- XXX: Would be better to remove these outfits and the association,
   -- but they're so tightly integrated atm (with no other way to define
   -- GUIs as usable) that I'm implementing it this way for now.
   player.outfitAdd( "GUI - Brushed" )
   player.outfitAdd( "GUI - Slim" )
   player.outfitAdd( "GUI - Slimv2" )
   player.outfitAdd( "GUI - Legacy" )

   hook.timer(1.0, "timer_tutorial")
end

function timer_tutorial()
   naev.missionStart("Tutorial")
   evt.finish(true)
end
