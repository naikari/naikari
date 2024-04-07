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
   news.add("Empire", _("Celebrating the Empire"),
         _([[Today marks the glorious 600th anniversary of the creation of the Galactic Empire, when the first great Galactic Emperor expanded humanity from our humble blue homeworld into space. That original homeworld, Romulus in the Alpha Leonis system, remains the center of the Galactic Empire to this day. There, billions of Imperial citizens gathered today to celebrate the occasion with great national pride.]]),
         exp)

   var.push("music_ambient_playnext", "intro")
   music.stop()

   evt.finish(true)
end
