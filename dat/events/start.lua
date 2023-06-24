--[[
<?xml version='1.0' encoding='utf8'?>
<event name="start_event">
 <trigger>none</trigger>
</event>
--]]
function name()
   local names = {
      p_("shipname", "Aluminum Mallard"),
      p_("shipname", "Armchair Traveler"),
      p_("shipname", "Attitude Adjuster"),
      p_("shipname", "Canterbury"),
      p_("shipname", "Commuter"),
      p_("shipname", "Death Trap"),
      p_("shipname", "Eclipse"),
      p_("shipname", "Enterprise"),
      p_("shipname", "Firefly"),
      p_("shipname", "Fire Hazard"),
      p_("shipname", "Goïng Merry"),
      p_("shipname", "Gunboat Diplomat"),
      p_("shipname", "Heart of Lead"),
      p_("shipname", "Icarus"),
      p_("shipname", "Little Rascal"),
      p_("shipname", "Lusitania"),
      p_("shipname", "Millennium Falcon"),
      p_("shipname", "Myrmidon"),
      p_("shipname", "Opportunity"),
      p_("shipname", "Optimus Prime"),
      p_("shipname", "Outward Bound"),
      p_("shipname", "Pathfinder"),
      p_("shipname", "Planet Jumper"),
      p_("shipname", "Rocinante"),
      p_("shipname", "Rustbucket"),
      p_("shipname", "Serendipity"),
      p_("shipname", "Shove Off"),
      p_("shipname", "Sky Cutter"),
      p_("shipname", "Terminal Velocity"),
      p_("shipname", "Titanic"),
      p_("shipname", "Tobermoon"),
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

   local exp = time.get() + time.create(0, 250, 0)
   news.add("Empire", _("Remembering the Incident"),
         _([[Today marks the ten year anniversary of the Incident, where a mysterious cataclysmic explosion ripped through the heart of the Empire, destroying Earth and eradicating House Proteron. The Emperor has delivered a speech to commemorate the tragedy. "We mourn with sorrow the loss of many on that dreadful day, and the loss of our precious homeworld. We still don't know what caused the Incident for certain, but rest assured: the Empire will not let this happen again, and if terrorists are to blame, we will find them and bring them to justice."]]),
         exp)

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
