--[[
<?xml version='1.0' encoding='utf8'?>
<event name="start_event">
 <trigger>none</trigger>
</event>
--]]
function name()
   local names = {
      p_("shipname", "Battlestar"),
      p_("shipname", "Canterbury"),
      p_("shipname", "Death Star"),
      p_("shipname", "Enterprise"),
      p_("shipname", "Firefly"),
      p_("shipname", "Going Merry"),
      p_("shipname", "Lusitania"),
      p_("shipname", "Millennium Falcon"),
      p_("shipname", "Rocinante"),
      p_("shipname", "Titanic"),
      p_("shipname", "Tobermoon"),
      p_("shipname", "Vindicator"),
   }
   return names[rnd.rnd(1,#names)]
end


function create()
   local pp = player.pilot()
   pp:rename(name()) -- Assign a random name to the player's ship.

   var.push("player_formation", "circle")

   local exp = time.get() + time.create(0, 250, 0)
   news.add("Empire", _("Remembering the Incident"),
         _([[Today marks the ten year anniversary of the Incident, where a mysterious cataclysmic explosion ripped thru the heart of the Empire, destroying Earth and eradicating House Proteron. The Emperor has delivered a speech to commemorate the tragedy. "We mourn with sorrow the loss of many on that dreadful day, and the loss of our precious homeworld. We still don't know what caused the Incident for certain, but rest assured: the Empire will not let this happen again, and if terrorists are to blame, we will find them and bring them to justice."]]),
         exp)

   var.push("music_ambient_playnext", "intro")
   music.stop()

   evt.finish(true)
end
