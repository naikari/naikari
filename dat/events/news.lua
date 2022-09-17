--[[
<?xml version='1.0' encoding='utf8'?>
<event name="News Handler">
 <trigger>land</trigger>
 <chance>100</chance>
</event>
--]]
--[[

   News Handler Event

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

--

   This event manages news articles, creating new ones and deleting old
   ones as needed.

--]]

local fmt = require "fmt"


mhint_articles = {
   {
      title = _("Empire Seeks New Recruits"),
      text = _([[The Empire is on the lookout for talented new recruits into its shipping division. "The Empire offers good pay and fantastic opportunities," a spokesperson said. "It doesn't hurt to approach one of the Empire Lieutenants seeking talent. Join the Empire today!"]]),
      mission = "Empire Recruitment",
      done = "Tutorial Part 4",
      faction = "Empire",
   },
}


function create()
   local publish_interval = time.create(0, 120, 0)
   local last_news = var.peek("_news_last")
   local narticles = #news.get()
   if (last_news == nil
            or time.fromnumber(last_news) - time.get() > publish_interval)
         and narticles < 5
         and (narticles < 2 or rnd.rnd() < 0.5) then
      generate_article()
   end

   cleanup_articles()
   evt.finish()
end


function cleanup_articles()
   local f = planet.cur():faction()

   -- Proteron and other factions don't share articles.
   if f == faction.get("Proteron") then
      for i, a in ipairs(news.get()) do
         if a:faction() ~= "Proteron" then
            a:rm()
         end
      end
   else
      for i, a in ipairs(news.get("Proteron")) do
         a:rm()
      end
   end

   -- Thurion articles aren't shared with other factions.
   if f ~= faction.get("Thurion") then
      for i, a in ipairs(news.get("Thurion")) do
         a:rm()
      end
   end

   -- Remove mission hints that aren't relevant anymore.
   for i, at in ipairs(mhint_articles) do
      if player.misnDone(at.mission) then
         local tag = string.format("mhint_%s", at.mission)
         for j, a in ipairs(news.get(tag)) do
            a:rm()
         end
      end
   end
end


function generate_article()
   local avail_mhint_articles = {}
   for i, a in ipairs(mhint_articles) do
      if not player.misnDone(a.mission) and not player.misnActive(a.mission)
            and (a.done == nil or player.misnDone(a.done))
            and (a.cond == nil or a.cond()) then
         avail_mhint_articles[#avail_mhint_articles + 1] = a
      end
   end

   if #avail_mhint_articles > 0 then
      var.push("_news_last", time.get():tonumber())
      local rmdate = time.get() + time.create(0, 360, 0)
      local a = avail_mhint_articles[rnd.rnd(1, #avail_mhint_articles)]
      news.add(a.faction, a.title, a.text, rmdate)
   end
end
