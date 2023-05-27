local formation = require "scripts/formation"

local escorthelper = {}


function escorthelper.playerform()
   local form_names = {}
   for k, v in ipairs(formation.keys) do
      form_names[k] = v:gsub("_", " "):gsub("^%l", string.upper)
   end

   form_names[#form_names+1] = "None"

   local choice = tk.choice("Formation", "Choose a formation.",
                            table.unpack(form_names))

   player.pilot():memory().formation = formation.keys[choice]
   var.push("player_formation", formation.keys[choice])
end


function escorthelper.issue_orders()
   local c_attack_target = _("&Attack Target")
   local c_formation = _("Hold &Formation")
   local c_return = _("&Return To Ship")
   local c_clear = _("Cl&ear Orders")
   local c_cancel = _("&Cancel")
   local n, s = tk.choice(_("Escort Orders"),
         _("Select the order to give to your escorts."),
         c_attack_target, c_formation, c_return, c_clear, c_cancel)
   local order = nil
   local data = nil
   if s == c_attack_target then
      order = "e_attack"
      data = player.pilot():target()
      player.msg(string.format(_("#FEscorts:#0 Attacking %s."), data:name()))
   elseif s == c_formation then
      order = "e_hold"
      player.msg(_("#FEscorts#0: Holding formation."))
   elseif s == c_return then
      order = "e_return"
      player.msg(_("#FEscorts:#0 Returning to ship."))
   elseif s == c_clear then
      order = "e_clear"
      player.msg(_("#FEscorts:#0 Clearing orders."))
   end

   if order then
      for i, p in ipairs(player.pilot():followers()) do
         if p:exists() then
            player.pilot():msg(p, order, data)
         end
      end
   end
end


return escorthelper
