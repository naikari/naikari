--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Land Tutorial Event">
 <trigger>land</trigger>
 <chance>100</chance>
</event>
--]]
--[[

   Tutorial Event

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


time_dilation_text = _([[Captain T. Practice pipes up. "Ah, I see you have purchased your first large ship! Congratulations! There are some important things you should know about large ships, so let me explain.

"You may notice that the ship you bought has a 'Time Constant' rating. See, when operating a larger ship, you have to expend more time and effort performing the basic operations of the ship, causing your perception of time to speed up. Time Constant is simply a measure of how fast you will perceive the passage of time compared to a typical small ship; for example, a Time Constant rating of 200%% means that time appears to pass twice as fast as typical small ships.

"This, and the slower speed of your ship, may make it difficult to use forward-facing weapons as well as on smaller ships. For the largest classes - Destroyers, Freighters, and up - I would generally recommend use of turreted weapons, which will automatically aim at your opponent, rather than forward-facing weapons. That's of course up to you, though, and there are certainly some Destroyers and light Cruisers which operate best with forward weapons. Feel free to experiment!]])
time_dilation_log = _([[All ships have a "Time Constant" rating, which indicates how fast you subjectively perceive time passing. A Time Constant of 100%% is the standard speed of a typical small ship.

Partly because of their higher Time Constant and partly because of their slow speed, Destroyers, Freighters, and other ships in their weight class of heavier generally fare best with turrets rather than forward-facing weapons. There are exceptions to this rule, however.]])


function create ()
   hook.ship_buy("ship_buy")
   hook.takeoff("takeoff")
end


function ship_buy(shp)
   if not var.peek("tutorial_time_dilation") then
      if class == "Freighter" or class == "Armored Transport"
            or class == "Corvette" or class == "Destroyer"
            or class == "Cruiser" or class == "Carrier" then
         if var.peek("_tutorial_passive_active") then
            tk.msg("", time_dilation_text)
         end
         addTutLog(time_dilation_log, N_("Time Constant"))
         var.push("tutorial_time_dilation", true)
      end
   end
end


function takeoff ()
   evt.finish()
end

