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

   This event manages news articles, creäting new ones and deleting old
   ones as needed.

--]]

local fmt = require "fmt"


--[[
A list of conditional articles. Each is a table with the following keys:
   "title": The title of the article.
   "text": The text of the article.
   "tag": The tag of the article (must be unique).
   "mission": Name of a mission which must be available to take.
      (optional)
   "done": Name of a mission which must be done. (optional)
   "cond": Function returning whether to add the article. (optional)
   "delcond": Function returning whether to remove the article.
      (optional)
--]]
cond_articles = {
   {
      title = _("Criminal Activity Rumors in The Wringer"),
      text = _([[Rumors abound that The Wringer, a small neglected station in Sirius space, is crawling with dangerous criminals, including crime lords and assassins. Sirius authorities, however, claim that these rumors are unfounded. "People exaggerate," one Sirius officer said. "The Wringer is a hellhole where petty criminals are common, but it's not exactly teeming with professional assassins. Any truly dangerous criminal knows that there's nothing for them at that awful place."]]),
      tag = "mhint_Sirius Bounty",
      mission = "Sirius Bounty",
      cond = function()
         return faction.get("Sirius"):playerStanding() >= 0
      end,
      delcond = function()
         return faction.get("Sirius"):playerStanding() < 0
      end,
   },
   {
      title = _("Mysterious Woman Spotted"),
      text = _([[A mysterious woman has been spotted scouting the areä within and around the Klantar system in Dvaered space. When approached by the media and asked who or what she is searching for, she declined to comment.]]),
      tag = "mhint_Shadowrun",
      mission = "Shadowrun",
   },
   {
      title = _("Assassins in Alteris"),
      text = _([[Law-abiding traders are warned to stay clear of the Alteris system due to an influx of assassins in the areä. Authorities suspect that corrupt businessmen are hiring these assassins in an effort to illegally stifle competition. An Imperial investigation is underway.]]),
      tag = "mhint_Hitman 2",
      mission = "Hitman 2",
   },
   {
      title = _("Em 1 Offers Business Opportunities"),
      text = _([[Analysts have noted tremendous opportunities on Em 1 (Hakoi system). "It's a great start for new pilots," a top analyst said. "Safe, and with many business opportunities."]]),
      tag = "mhint_Tutorial Part 2",
      mission = "Tutorial Part 2",
      cond = function()
         return planet.cur() ~= planet.get("Em 1")
      end,
   },
   {
      title = _("Em 1 Remains a Great Start"),
      text = _([[Analysts continue to proudly recommend Em 1 (Hakoi system) to new pilots seeking good payment. "What better way to start your piloting journey than in a safe, prosperous system like Hakoi?" a top analyst noted.]]),
      tag = "mhint_Tutorial Part 3",
      mission = "Tutorial Part 3",
      done = "Tutorial Part 2",
      cond = function()
         return planet.cur() ~= planet.get("Em 1")
      end,
   },
   {
      title = _("Em 5 Experiences New Growth"),
      text = _([[Economists note an uptick in economic activity and recommend all pilots seek out new opportunities on Em 5 (Hakoi system). Safe but prosperous, the Hakoi system is tough to beat, and its prosperity is expected to continue for the foreseeable future.]]),
      tag = "mhint_Tutorial Part 4",
      mission = "Tutorial Part 4",
      done = "Tutorial Part 3",
      cond = function()
         return planet.cur() ~= planet.get("Em 5")
      end,
   },
   {
      title = _("Empire Seeks New Recruits"),
      text = _([[The Empire is on the lookout for talented new recruits into its shipping division. "The Empire offers good pay and fantastic opportunities," a spokesperson said. "It doesn't hurt to approach one of the Empire Lieutenants seeking talent. Join the Empire today!"]]),
      tag = "mhint_Empire Recruitment",
      mission = "Empire Recruitment",
      done = "Tutorial Part 4",
   },
   {
      title = _("Imperial Investigation Rumors"),
      text = _([[Rumors abound that the Imperial investigation into the sudden appearance of pirates in the Hakoi system is headquartered at Emperor's Fist (Gamma Polaris system), the capital of the Empire. Many interpret this as an indication that the pirates may be a small part of a larger problem that could threaten intergalactic stability. Imperial officials have declined to comment.]]),
      tag = "mhint_Undercover in Hakoi",
      mission = "Undercover in Hakoi",
      done = "Empire Recruitment",
      cond = function()
         return (faction.playerStanding("Empire") >= 10
            and faction.playerStanding("Dvaered") >= 0
            and var.peek("es_misn") ~= nil
            and var.peek("es_misn") >= 3)
      end,
      delcond = function()
         return (faction.playerStanding("Empire") < 10
            or faction.playerStanding("Dvaered") < 0)
      end,
   },
   {
      title = _("Enthusiasts Organize Racing"),
      text = _([[A group of enthusiasts have begun to organize informal racing events all across the galaxy. "Just a hobby," one of the organizers said, "but there's a small prize if you win. Racing is a lot of fun!" Those wishing to attend a race are encouraged to seek out organizers at the Spaceport Bar.]]),
      tag = "mhint_Racing Skills 1",
      mission = "Racing Skills 1",
      done = "The Space Family",
   },
   {
      title = _("Melendez Sponsors Race Events"),
      text = _([[Races organized by a group of enthusiasts have really caught on all across the galaxy, leading to sponsorship of huge sums of prize money from Melendez Corporation. "It's exciting," one of the organizers said. "We still run the casual races for people who are new to the sport, but Melendez really offers a big check to the winners of the competitive races! Competition is high, and that's something I really like seeing." Those wishing to attend a race are encouraged to seek out organizers at the Spaceport Bar.]]),
      tag = "mhint_Racing Skills 2",
      mission = "Racing Skills 2",
      done = "Racing Skills 1",
      cond = function()
         return not var.peek("racing_done")
      end,
      delcond = function()
         return var.peek("racing_done")
      end,
   },
   {
      title = _("Mercenary Registrations Skyrocket"),
      text = _([[Many pilots are realizing just how lucrative the life of a mercenary can be. "Missions that require a Mercenary License pay a lot of money," one analyst explained. "The cost of the Mercenary License may seem high, but it will easily pay for itself ten times over by granting access to so many lucrative missions. Not to mention, doïng mercenary missions for militaries around the galaxy is a quick way to gain access to restricted areäs." A Mercenary License can be obtained simply by purchasing it at any outfitter, just like all other licenses.]]),
      tag = "mhint_Patrol",
      cond = function()
         return (player.numOutfit("Mercenary License") <= 0
               and player.credits() >= outfit.price("Mercenary License"))
      end,
      delcond = function()
         return (player.numOutfit("Mercenary License") > 0)
      end,
   },
   {
      title = _("Dvaered and FLF Clash"),
      text = _([[An increased incidence of confrontation between Dvaered and FLF forces has been reported as of late in the north edge of Dvaered space, particularly between Frontier space and the Outer Nebula. Civilians in the areä are advised to be on high alert.]]),
      tag = "mhint_Take the Dvaered crew home",
      mission = "Take the Dvaered crew home",
      cond = function()
         return (faction.get("Dvaered"):playerStanding() >= 0
            and faction.get("Pirate"):playerStanding() < 0
            and not player.misnDone("Deal with the FLF agent")
            and not player.misnActive("Deal with the FLF agent")
            and player.numOutfit("Mercenary License") > 0)
      end,
      delcond = function()
         return (player.misnDone("Deal with the FLF agent")
            or faction.get("Dvaered"):playerStanding() < 0
            or faction.get("Pirate"):playerStanding() >= 0)
      end,
   },
   {
      title = _("Za'lek Students Test Engine Technology"),
      text = _([[Students all over Za'lek space have been designing new experimental engine designs as part of a new government funded program. These students seek pilots willing to test fly their experimental engine designs for a substantial sum of credits.]]),
      tag = "mhint_Za'lek Test",
      mission = "Za'lek Test",
      cond = function()
         return (player.numOutfit("Mercenary License") > 0
            and faction.playerStanding("Za'lek") >= 5
            and not var.peek("zalek_test_done"))
      end,
      delcond = function()
         return (var.peek("zalek_test_done")
            or faction.playerStanding("Za'lek") < 5)
      end,
   },
   {
      title = _("Anti-Soromid Sentiment Grows"),
      text = _([[Anti-Soromid sentiment has been surging on Durea in the Capricorn system lately, an anonymous reporter finds. Rumors abound that Durea may be harboring terrorists belonging to the notorious hate group, the Imperyan Brotherhood. An Imperial representative reassured us that the Empire does not tolerate the organization. "This criminal organization is a remnant of a shameful time in our history. While we do not have jurisdiction over the Capricorn system, the full force of the Empire will come down on any Imperyan Brotherhood members who enter Imperial space, and hate crimes will not be tolerated."]]),
      tag = "mhint_Coming of Age",
      mission = "Coming of Age",
      done = "Coming Out",
      cond = function()
         return (var.peek("comingout_time") == nil
            or time.get() >= time.fromnumber(var.peek("comingout_time")) + time.create(0, 20, 0))
      end,
   },
}


function create()
   -- Special event articles
   if player.misnDone("Nebula Satellite")
         and not var.peek("nebu_probe_published") then
      local t = var.peek("nebu_probe_launch")
      local delay = time.create(1, 0, 0)
      if t == nil or time.get() - time.fromnumber(t) > delay then
         local exp = time.get() + time.create(0, 250, 0)
         news.add("Generic", _("Scientists Befuddled By Nebula Composition"),
               _([[A team of scientists which launched a special probe to monitor the Nebula have finally published their results, and their research raises more questions than it answers. The research team notes that the composition of the Nebula is especially surprising. "Its composition doesn't match what we expected from that region of space," explained one of the researchers. "It's as if a whole lot of material teleported into the region out of nowhere." The researchers were unable to conclusively determine the reason for the strange composition of the Inner Nebula, and scientists now rigorously debate where this mysterious anomalous material comes from.]]),
               exp)
         var.push("nebu_probe_published", true)
      end
   end

   -- Generated articles
   local publish_interval = time.create(0, 30, 0)
   local last_news = var.peek("_news_last")
   local narticles = #news.get("Generic")
   local f = planet.cur():faction()
   if f ~= nil then
      narticles = narticles + #news.get(f:nameRaw())
   end
   if (narticles <= 0 or last_news == nil
            or time.get() - time.fromnumber(last_news) > publish_interval)
         and narticles < 5
         and (narticles < 2 or rnd.rnd() < 0.5) then
      generate_article()
   end

   cleanup_articles()
   evt.finish()
end


function cleanup_articles()
   local f = planet.cur():faction()

   -- Proteron don't get generic articles.
   if f == faction.get("Proteron") then
      for i, a in ipairs(news.get()) do
         if a:faction() == "Generic" then
            a:rm()
         end
      end
   end

   -- Remove mission hints that aren't relevant anymore.
   for i, at in ipairs(cond_articles) do
      if (at.mission ~= nil and player.misnDone(at.mission))
            or (at.delcond ~= nil and at.delcond()) then
         if at.tag ~= nil then
            for j, a in ipairs(news.get(at.tag)) do
               a:rm()
            end
         else
            warn(fmt.f(_("Conditional news entry {index} ({title}) has no tag!"),
                  {index=i, title=at.title}))
         end
      end
   end
end


function generate_article()
   local avail_cond_articles = {}
   for i, a in ipairs(cond_articles) do
      if a.tag ~= nil then
         local existing_articles = news.get(a.tag) or {}
         if #existing_articles <= 0
               and (a.mission == nil
                  or (not player.misnDone(a.mission)
                     and not player.misnActive(a.mission)))
               and (a.done == nil or player.misnDone(a.done))
               and (a.cond == nil or a.cond())
               and (a.faction == nil or a.faction == "Generic"
                  or faction.get(a.faction) == planet.cur():faction()) then
            avail_cond_articles[#avail_cond_articles + 1] = a
         end
      else
         warn(fmt.f(_("Conditional news entry {index} ({title}) has no tag!"),
               {index=i, title=a.title}))
      end
   end

   if #avail_cond_articles > 0 then
      var.push("_news_last", time.get():tonumber())
      local rmdate = time.get() + time.create(0, 120, 0)
      local a = avail_cond_articles[rnd.rnd(1, #avail_cond_articles)]
      local article = news.add(a.faction or "Generic", a.title, a.text, rmdate)
      article:bind(a.tag)
   end
end
