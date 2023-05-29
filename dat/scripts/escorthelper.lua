local escorthelper = {}


function escorthelper.playerform()
   -- We construct our own list of forms rather than relying on the one
   -- supplied by formation.lua since we need to preserve a reasonable
   -- ordering.
   local forms = {
      "circle",
      "cross",
      "buffer",
      "vee",
      "wedge",
      "echelon_left",
      "echelon_right",
      "column",
      "wall",
      "fishbone",
      "chevron",
      -- nil (for "None" choice) marks the end of where looping happens,
      -- and then we have an extra entry for "Cancel".
      nil,
      player.pilot():memory().formation,
   }
   local form_names = {
      buffer = p_("formation", "&Buffer"),
      chevron = p_("formation", "C&hevron"),
      circle = p_("formation", "Circle (&O)"),
      column = p_("formation", "C&olumn"),
      cross = p_("formation", "Cross (&X)"),
      echelon_left = p_("formation", "Echelon &Left"),
      echelon_right = p_("formation", "Echelon &Right"),
      fishbone = p_("formation", "&Fishbone"),
      vee = p_("formation", "&Vee"),
      wall = p_("formation", "&Wall"),
      wedge = p_("formation", "Wed&ge"),
   }

   local choices = {}
   for i, f in ipairs(forms) do
      choices[i] = form_names[f]
   end
   table.insert(choices, p_("formation", "&None"))
   table.insert(choices, _("&Cancel"))

   local choice = tk.choice("Formation", "Choose a formation.",
         table.unpack(choices))

   player.pilot():memory().formation = forms[choice]
   var.push("player_formation", forms[choice])
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
