--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Sirius Bounty">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>19</priority>
  <cond>faction.get("Sirius"):playerStanding() &gt;= 0</cond>
  <planet>The Wringer</planet>
  <chance>100</chance>
  <location>Bar</location>
 </avail>
 <notes>
  <campaign>Academy Hack</campaign>
 </notes>
</mission>
--]]
--[[
-- This is the first mission in the Academy Hack minor campaign.
--]]

local fmt = require "fmt"
require "missions/sirius/common"


ask_text = _([[Curious about the young Fyrra man, you decide to find out why he is here. As you approach, he waves and greets you. "Well met, stranger. My name is Harja. I'm looking for a bounty hunter who can help me with this… problem I have. But nobody I've talked to so far seems interested! I thought this place was supposed to be filled with mercenaries and killers for hire. I can't believe how difficult this is!"

You instinctively raise an eyebrow, wondering why anyone would expect to find a bounty hunter in a place like this. Seemingly not noticing your expression, Harja continues. "Listen, I don't intend to bore you with my personal sob story, so let's just say there's someone I want dead, a dangerous criminal. This woman did something to me years ago that just can't go unpunished. I've got money, I'm willing to pay. All you need to do is locate her, and discreetly take her out. I don't care how you do it. I don't even care if you enjoy it. Just come back when she's dead, and I'll pay you {credits}. Do we have a deal?"]])

accept_text = _([["Great! I was about to give up hope that I would find anyone with enough guts to do this for me. Okay, so, let me tell you about your target. She's a member of the Serra echelon, and she's got long, brown hair and blue eyes." You blink as Harja mentions that his his target is Serra-class. Surely he must be joking. Possibly noticing your expression, Harja answers your unspoken question. "Don't be fooled by her class, stranger! I know for a fact that she cheated her way into the Serra echelon. I believe she'll be on {planet} in the {system} system right now. Come back here to me when she's dead, and I'll give you your reward."

Harja leaves the spacedock bar, satisfied that he's finally found someone to take his request. You stare in disbelief. You may not be a Siriusite yourself, but even you know well enough how sketchy it looks for a Fyrra-class Siriusite to try to assassinate a Serra-class Siriusite, and even if he's right, assassinating a Serra-class Siriusite could get you in serious trouble with the authorities if you're caught. You decide to do some investigating yourself and decide what to do when you get there.]])

approach_text = _([[You approach the young officer, determined to find out what you've gotten yourself involved with. She looks up, clearly not expecting you. "Good day, pilot." She seems quite polite, and nothing indicates that she is anything less than completely respectable. "Is there something I can help you with?" You introduce yourself and explain that in your travels you've come across a man who tried to hire you to murder her. When you mention that his name is Harja, the officer's eyes go wide.

"Are you sure? Unbelievable. Just unbelievable. I know the man you speak of, and I certainly don't count him as one of my friends. But I assure you, what he told you about me is a complete lie. Yes, there is bad blood between us. It's rather personal. But I'm sure you can see that my record is clean, or else I wouldn't have been accepted into the military.

"I appreciate that you used your better judgment instead of recklessly trying to attack me, which would have ended badly for at least one of us. You said Harja offered you {credits} for my death, yes? I will arrange for half that to be deposited into your account. Consider it a token of gratitude. Now, it seems I may have a situation to take care of.…" The officer excuses herself from the table. You are satisfied for now that you got paid without having to get your hands dirty. You just hope this won't come back to bite you in the butt one day.]])

-- Mission info stuff
harjaname = _("Fyrra Civilian")
harjadesc = _("You see a young Fyrra man with a determined expression on his face. You wonder what he could possibly be doing in a place like this.")
joannename = _("Serra Military Officer")
joannedesc = _("This woman matches the description Harja gave you… and she's a military officer. You'd better talk to her and find out what's going on; there's no way assassinating a military officer will go well for you.")

misn_title = _("Questionable Bounty")
misn_desc = _([[A Siriusite named Harja has hired you to dispatch a "dangerous criminal" who supposedly committed some kind of crime against him. You are not convinced and have decided to do some investigating.]])

log_text = _([[A Siriusite named Harja hired you to kill a Sirius military officer, claiming that she was a "dangerous criminal". Rather than carrying out the mission, you told her about the plot, and she rewarded you by paying half what Harja would have paid for her death.]])


function create()
    destplanet, destsys = planet.get("Racheka")
    -- Note: this mission does not make system claims.

    credits = 400000

    misn.setNPC(harjaname, "sirius/unique/harja.png", harjadesc)
end


function accept()
    if not tk.yesno("", fmt.f(ask_text, {credits=fmt.credits(credits)})) then
        misn.finish()
    end

    misn.accept()

    tk.msg("", fmt.f(accept_text,
            {planet=destplanet:name(), system=destsys:name()}))

    misn.setTitle(misn_title)
    misn.setDesc(misn_desc)
    misn.setReward(fmt.credits(credits))

    local osd_msg = {
        fmt.f(_("Land of {planet} ({system} system) and locate Harja's target at the bar"),
            {planet=destplanet:name(), system=destsys:name()}),
    }
    misn.osdCreate(misn_title, osd_msg)
    misn.markerAdd(destsys, "low")

    hook.land("land")
    hook.load("land")
end


function land()
    if planet.cur() == destplanet then
        misn.npcAdd("talkJoanne", joannename, "sirius/unique/joanne.png", joannedesc, 19)
    end
end


function talkJoanne()
    tk.msg("", fmt.f(approach_text, {credits=fmt.credits(credits)}))
    player.pay(credits / 2)
    srs_addAcHackLog(log_text)
    misn.finish(true)
end


function abort()
    misn.finish(false)
end
