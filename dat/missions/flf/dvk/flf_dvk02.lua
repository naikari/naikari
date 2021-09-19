--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="FLF Pirate Alliance">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>10</priority>
  <chance>30</chance>
  <done>Diversion from Raelid</done>
  <location>Bar</location>
  <faction>FLF</faction>
  <cond>faction.playerStanding("FLF") &gt;= 30</cond>
 </avail>
 <notes>
  <campaign>Save the Frontier</campaign>
 </notes>
</mission>
--]]
--[[

   Pirate Alliance

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

require "numstring"
local fleet = require "fleet"
require "missions/flf/flf_common"


text = {}

intro_text = _([[Benito looks up at you and sighs. It seems she's been working on a problem for a long while.

"Hello again, %s. Sorry I'm such a mess at the moment. I just don't know what to do about this problem we have." You ask what the problem is. "Pirates. The damn pirates are making things difficult for us. Activity has picked up in the %s system and we don't know why.

"Pirates are usually just sort of a double-edged sword for us, but in this region of space they're nothing bug a nuisance. They're enemies to both us and the Dvaereds, but there's no Dvaereds in that region, just us and occasionally some Empire ships. And that's on our most direct route to Frontier space. If pirates are going to be giving us even more trouble there than before, that could slow down – or worse, wreck – our operations."]])

ask_text = _([[You remark that it's strange that pirates are there in the first place. "Yes!" Benito says. "It makes no sense! Pirates are always after civilians and traders to steal their credits and cargo, so why would they be there? We don't carry much cargo, the Empire doesn't carry much cargo… it just doesn't add up!

"My only guess is that maybe they're trying to find our hidden jump to Gilligan's Light, and if that's the case, that could be tremendously bad news. I'm not worried about the damage pirates can do to the Frontier; they've been prevalent in Frontier space for a long while. But if they start attacking Gilligan's Light, that could leave the Frontier in a vulnerable position that the Dvaereds can take advantage of!

"But I just don't have any ideas. Do you have any ideas, %s?"]])

ask_again_text = _([["I still don't have any ideas for what to do about those pirates. Do you, %s?"]])

yes_text = _([[You think about the problem for a moment, then suggest to Benito that it might be best to intimidate or bribe the pirates so they leave FLF ships alone. Benito stares off into space for a moment. "Hm… well, we don't have money to throw around bribing pilots, so that's off the table. But I don't think we have the numbers to really intimidate a pirate presence that large without giving the Dvaereds an opening to exploit, so we can't do that either." You ask Benito if it might be possible to bribe the pirates with a future favor. Her eyes widen. "A favor… that's it! %s, that's a perfect idea!

"Truth is, we have an operation we need to conduct that just isn't possible right now without some major help. I think the pirates can help us out and might see it as an opportunity. It's rather risky, if we give it a shot, we just might kill two birds with one stone.

"Alright, it's settled then. I need your help. I will join you on your ship; please take me to the %s system and hail them. We might have to board and intimidate them before they'll listen, so be prepared for that." You give Benito a thumbs-up and invite her into your cockpit. Time to get into some aggressive negotiations.…]])

text[4] = _([["That's too bad. I understand where you're coming from, though. Please feel free to return if you are willing to take on this mission at a later date."]])

text[5] = _([[A scraggly-looking pirate appears on your viewscreen. You realize this must be the leader of the group. "Bwah ha ha!" he laughs. "That has to be the most pathetic excuse for a ship I've ever seen!" You try to ignore his rude remark and start to explain to him that you just want to talk. "Talk?" he responds. "Why would I want to talk to a normie like you? Why, I'd bet my mates right here could blow you out of the sky even without my help!"
    The pirate immediately cuts his connection. Well, if these pirates won't talk to you, maybe it's time to show him what you're made of. Destroying just one or two of his escorts should do the trick.]])

text[6] = _([[As the Pirate Kestrel is blown out of the sky, it occurs to you that you have made a terrible mistake. Having killed off the leader of the pirate group, you have lost your opportunity to negotiate a trade deal with the pirates. You shamefully transmit your result to Benito via a coded message and abort the mission. Perhaps you will be given another opportunity later.]])

text[7] = _([[The pirate leader comes on your screen once again. "Lucky shot, normie!" he says before promptly terminating the connection once again. Perhaps you need to destroy some more of his escorts so he can see you're just a bit more than a "normie".]])

text[8] = _([[The pirate comes on your view screen once again, but his expression has changed this time. He's hiding it, but you can tell that he's afraid of what you might do to him. You come to the realization that he is finally willing to talk and suppress a sigh of relief.
    "L-look, we got off on the wrong foot, eh? I've misjudged you lot. I guess FLF pilots can fight after all."]])

text[9] = _([[You begin to talk to the pirate about what you and the FLF are after, and the look of fear on the pirate's face fades away. "Supplies? Yeah, we've got supplies, alright. But it'll cost you! Heh, heh, heh..." You inquire as to what the cost might be. "Simple, really. We want to build another base in the %s system. We can do it ourselves, of course, but if we can get you to pay for it, even better! Specifically, we need another %s of ore to build the base. So you bring it back to the Anger system, and we'll call it a deal!
    "Oh yeah, I almost forgot; you don't know how to get to the Anger system, now, do you? Well, since you've proven yourself worthy, I suppose I'll let you in on our little secret." He transfers a file to your ship's computer. When you look at it, you see that it's a map showing a single hidden jump point. "Now, away with you! Meet me in the %s system when you have the loot."]])

text[10] = _([["Ha, you came back after all! Wonderful. I'll just take that ore, then." You hesitate for a moment, but considering the number of pirates around, they'll probably take it from you by force if you refuse at this point. You jettison the cargo into space, which the Kestrel promptly picks up with a tractor beam. "Excellent! Well, it's been a pleasure doing business with you. Send your mates over to the new station whenever you're ready. It should be up and running in just a couple periods or so. And in the meantime, you can consider yourselves one of us! Bwa ha ha!"
    You exchange what must for lack of a better word be called pleasantries with the pirate, with him telling a story about a pitifully armed Mule he recently plundered and you sharing stories of your victories against Dvaered scum. You seem to get along well. You then part ways. Now to report to Benito....]])

text[11] = _([[You greet Benito in a friendly manner as always, sharing your story and telling her the good news before handing her a chip with the map data on it. She seems pleased. "Excellent," she says. "We'll begin sending our trading convoys out right away. We'll need lots of supplies for our next mission! Thank you for your service, %s. Your pay has been deposited into your account. It will be a while before we'll be ready for your next big mission, so you can do some missions on the mission computer in the meantime. And don't forget to visit the Pirate worlds yourself and bring your own ship up to par!
    "Oh, one last thing. Make sure you stay on good terms with the pirates, yeah? The next thing you should probably do is buy a Skull and Bones ship; pirates tend to respect those who use their ships more than those who don't. And make sure to destroy Dvaered scum with the pirates around! That should keep your reputation up." You make a mental note to do what she suggests as she excuses herself and heads off.]])

comm_pirate = _("Har, har, har! You're hailing the wrong ship, buddy. Latest word from the boss is you're a weakling just waiting to be plundered!")
comm_pirate_friendly = _("I guess you're not so bad after all!")
comm_boss_insults = {}
comm_boss_insults[1] = _("You call those weapons? They look more like babies' toys to me!")
comm_boss_insults[2] = _("What a hopeless weakling!")
comm_boss_insults[3] = _("What, did you really think I would be impressed that easily?")
comm_boss_insults[4] = _("Keep hailing all you want, but I don't listen to weaklings!")
comm_boss_insults[5] = _("We'll have your ship plundered in no time at all!")
comm_boss_incomplete = _("Don't be bothering me without the loot, you hear?")

misn_title = _("Pirate Talks")
misn_desc = _("You are to seek out pirates in the %s system and try to convince them to become trading partners with the FLF.")
misn_reward = _("Supplies for the FLF")

npc_name = _("Benito")
npc_desc = _("You see exhaustion on Benito's face. Perhaps you should see what's up.")

osd_title   = _("Pirate Alliance")
osd_desc    = {}
osd_desc[1] = _("Fly to the %s system")
osd_desc[2] = _("Find pirates and try to talk to (hail) them")
osd_desc["__save"] = true

osd_apnd    = {}
osd_apnd[3] = _("Destroy some of the weaker pirate ships, then try to hail the Kestrel again")
osd_apnd[4] = _("Bring %s of Ore to the Pirate Kestrel in the %s system")

osd_final   = _("Return to FLF base")
osd_desc[3] = osd_final

log_text = _([[You helped the Pirates to build a new base in the Anger system and established a trade alliance between the FLF and the Pirates. Benito suggested that you should buy a Skull and Bones ship from the pirates and destroy Dvaered ships in areas where pirates are to keep your reputation with the pirates up. She also suggested you may want to upgrade your ship now that you have access to the black market.]])


function create ()
   missys = system.get("Tormulex")
   missys2 = system.get("Anger")
   if not misn.claim(missys) then
      misn.finish(false)
   end

   asked = false

   misn.setNPC(npc_name, "flf/unique/benito.png", npc_desc)
end


function accept ()
   local txt = ask_again_text

   if not asked then
      txt = ask_text
      tk.msg("", intro_text:format(player.name(), missys:name()))
   end

   if tk.yesno("", txt:format(player.name())) then
      tk.msg( "", yes_text:format( player.name() ) )

      misn.accept()

      osd_desc[1] = osd_desc[1]:format( missys:name() )
      misn.osdCreate( osd_title, osd_desc )
      misn.setTitle( misn_title )
      misn.setDesc( misn_desc:format( missys:name() ) )
      marker = misn.markerAdd( missys, "plot" )
      misn.setReward( misn_reward )

      stage = 0
      pirates_left = 0
      boss_hailed = false
      boss_impressed = false
      boss = nil
      pirates = nil
      boss_hook = nil

      ore_needed = 40
      credits = 300000
      reputation = 1
      pir_reputation = 10
      pir_starting_reputation = faction.get("Pirate"):playerStanding()

      hook.enter( "enter" )
   else
      tk.msg("", text[4])
      misn.finish()
   end
end


function pilot_hail_pirate ()
   player.commClose()
   if stage <= 1 then
      player.msg( comm_pirate )
   else
      player.msg( comm_pirate_friendly )
   end
end


function pilot_hail_boss ()
   player.commClose()
   if stage <= 1 then
      if boss_impressed then
         stage = 2
         local standing = faction.get("Pirate"):playerStanding()
         if standing < 25 then
            faction.get("Pirate"):setPlayerStanding( 25 )
         end

         if boss ~= nil then
            boss:changeAI( "pirate" )
            boss:setHostile( false )
            boss:setFriendly()
         end
         if pirates ~= nil then
            for i, j in ipairs( pirates ) do
               if j:exists() then
                  j:changeAI( "pirate" )
                  j:setHostile( false )
                  j:setFriendly()
               end
            end
         end

         tk.msg( "", text[8] )
         tk.msg( "", text[9]:format(
            missys2:name(), tonnestring( ore_needed ), missys2:name() ) )

         player.outfitAdd( "Map: FLF-Pirate Route" )
         if marker ~= nil then misn.markerRm( marker ) end
         marker = misn.markerAdd( missys2, "plot" )

         osd_desc[4] = osd_apnd[4]:format( tonnestring( ore_needed ), missys2:name() )
         osd_desc[5] = osd_final
         misn.osdCreate( osd_title, osd_desc )
         misn.osdActive( 4 )
      else
         if boss_hailed then
            player.msg( comm_boss_insults[ rnd.rnd( 1, #comm_boss_insults ) ] )
         else
            boss_hailed = true
            if stage <= 0 then
               tk.msg( "", text[5] )
               osd_desc[3] = osd_apnd[3]
               osd_desc[4] = osd_final
               misn.osdCreate( osd_title, osd_desc )
               misn.osdActive( 3 )
            else
               tk.msg( "", text[7] )
            end
         end
      end
   elseif player.pilot():cargoHas( "Ore" ) >= ore_needed then
      tk.msg( "", text[10] )
      stage = 3
      player.pilot():cargoRm( "Ore", ore_needed )
      hook.rm( boss_hook )
      hook.land( "land" )
      misn.osdActive( 5 )
      if marker ~= nil then misn.markerRm( marker ) end
   else
      player.msg( comm_boss_incomplete )
   end
end


function pilot_death_pirate ()
   if stage <= 1 then
      pirates_left = pirates_left - 1
      stage = 1
      boss_hailed = false
      if pirates_left <= 0 or rnd.rnd() < 0.25 then
         boss_impressed = true
      end
   end
end


function pilot_death_boss ()
   tk.msg( "", text[6] )
   misn.finish( false )
end


function enter ()
   if stage <= 1 then
      stage = 0
      if system.cur() == missys then
         pilot.clear()
         pilot.toggleSpawn( false )
         local r = system.cur():radius()
         local vec = vec2.new( rnd.rnd( -r, r ), rnd.rnd( -r, r ) )

         boss = pilot.add( "Pirate Kestrel", "Pirate", vec, nil, {ai="pirate_norun"} )
         hook.pilot( boss, "death", "pilot_death_boss" )
         hook.pilot( boss, "hail", "pilot_hail_boss" )
         boss:setHostile()
         boss:setHilight()

         pirates_left = 4
         pirates = fleet.add( pirates_left, "Hyena", "Pirate", vec, _("Pirate Hyena"), {ai="pirate_norun"} )
         for i, j in ipairs( pirates ) do
            hook.pilot( j, "death", "pilot_death_pirate" )
            hook.pilot( j, "hail", "pilot_hail_pirate" )
            j:setHostile()
         end

         misn.osdActive( 2 )
      else
         osd_desc[3] = osd_final
         osd_desc[4] = nil
         misn.osdCreate( osd_title, osd_desc )
         misn.osdActive( 1 )
      end
   elseif stage <= 2 then
      if system.cur() == missys2 then
         local r = system.cur():radius()
         local vec = vec2.new( rnd.rnd( -r, r ), rnd.rnd( -r, r ) )

         boss = pilot.add( "Pirate Kestrel", "Pirate", vec, nil, {ai="pirate_norun"} )
         hook.pilot( boss, "death", "pilot_death_boss" )
         boss_hook = hook.pilot( boss, "hail", "pilot_hail_boss" )
         boss:setFriendly()
         boss:setHilight()
         boss:setVisible()
      end
   end
end


function land ()
   if stage >= 3 and planet.cur():faction() == faction.get( "FLF" ) then
      tk.msg( "", text[11]:format( player.name() ) )
      diff.apply( "Fury_Station" )
      diff.apply( "flf_pirate_ally" )
      player.pay( credits )
      flf_setReputation( 50 )
      faction.get("FLF"):modPlayer( reputation )
      faction.get("Pirate"):modPlayerSingle( pir_reputation )
      flf_addLog( log_text )
      misn.finish( true )
   end
end


function abort ()
   faction.get("Pirate"):setPlayerStanding( pir_starting_reputation )
   local hj1 = nil
   local hj2 = nil
   hj1, hj2 = jump.get( "Tormulex", "Anger" )
   hj1:setKnown( false )
   hj2:setKnown( false )
   misn.finish( false )
end

