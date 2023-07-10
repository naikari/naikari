--[[
   Neo GUI

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

local eh = require "escorthelper"
local fmt = require "fmt"
local formation = require "formation"


function create ()
   -- Set default formation
   local savedform = var.peek("player_formation")
   player.pilot():memory().formation = savedform

   -- Colors
   col_black = colour.new(0, 0, 0)
   col_white = colour.new(1, 1, 1)
   col_bg = colour.new(0.2, 0.2, 0.2, 0.5)
   col_radar = colour.new(0, 0, 0, 0.5)
   col_bottombar = colour.new(0.2, 0.2, 0.2)
   col_outline1 = colour.new(0.1, 0.1, 0.1)
   col_outline2 = colour.new(0.25, 0.25, 0.25)
   col_text = colour.new(0.95, 0.95, 0.95)
   col_graytext = colour.new(0.7, 0.7, 0.7)
   col_cooldown = colour.new(76/255, 98/255, 176/255)
   col_lockon = colour.new(150/255, 141/255, 23/255)
   col_shield = colour.new(42/255, 57/255, 162/255)
   col_armor = colour.new(80/255, 80/255, 80/255)
   col_stress = colour.new(45/255, 48/255, 102/255)
   col_energy = colour.new(36/255, 125/255, 51/255)
   col_heat = colour.new(241/255, 88/255, 82/255)
   col_superheat = colour.new(241/255, 210/255, 42/255)
   col_speed = colour.new(236/255, 232/255, 78/255)
   col_overspeed = colour.new(249/255, 112/255, 62/255)
   col_ammo = colour.new(159/255, 93/255, 15/255)
   col_end_cooldown = colour.new(96/255, 109/255, 171/255)
   col_end_shield = colour.new(88/255, 96/255, 156/255)
   col_end_armor = colour.new(122/255, 122/255, 122/255)
   col_end_stress = colour.new(56/255, 88/255, 156/255)
   col_end_energy = colour.new(52/255, 172/255, 71/255)
   col_end_heat = colour.new(238/255, 136/255, 125/255)
   col_end_superheat = colour.new(252/255, 231/255, 158/255)
   col_end_speed = colour.new(247/255, 242/255, 194/255)
   col_end_overspeed = colour.new(250/255, 174/255, 144/255)
   col_end_ammo = colour.new(233/255, 131/255, 21/255)

   -- Images
   local function tex_open(name, sx, sy)
      local t = tex.open("gfx/gui/neo/" .. name, sx, sy)
      t:setWrap("clamp")
      return t
   end
   tex_barHeader = tex_open("barHeader.png")
   tex_barFrame = tex_open("barFrame.png")
   tex_barCircles = tex_open("barcircles.png")
   tex_circleBar = tex_open("circleBar.png")
   tex_iconShield = tex_open("iconShield.png")
   tex_iconArmor = tex_open("iconArmor.png")
   tex_iconStress = tex_open("iconStress.png")
   tex_iconEnergy = tex_open("iconEnergy.png")
   tex_iconHeat = tex_open("iconHeat.png")
   tex_iconSpeed = tex_open("iconSpeed.png")
   tex_iconWeapPrimary = tex_open("iconWeapPrimary.png")
   tex_iconWeapSecondary = tex_open("iconWeapSecondary.png")
   tex_iconWeapHeat = tex_open("iconWeapHeat.png")

   -- Common sizes
   screen_w, screen_h = gfx.dim()
   screen_padding = 24
   barHeader_w, barHeader_h = tex_barHeader:dim()
   barFrame_w, barFrame_h = tex_barFrame:dim()
   fontSize_small = gfx.fontSize(true)
   fontSize_default = gfx.fontSize()

   -- Bottom bar and view port
   bottombar_h = 28
   gui.viewport(0, bottombar_h, screen_w, screen_h - bottombar_h)

   -- Sidebar
   sidebar_padding = 4
   sidebar_w = barHeader_w + barFrame_w
   sidebar_x = screen_w - sidebar_w - screen_padding - 2*sidebar_padding

   -- Radar
   radar_w = sidebar_w + 2*sidebar_padding
   radar_h = 120
   gui.radarInit(false, radar_w, radar_h)

   -- FPS counter / TC % display
   fps_h = 3 * fontSize_default
   gui.fpsPos(screen_padding, screen_h - screen_padding - fps_h)

   -- OSD
   osd_x = screen_padding
   osd_y = screen_h - screen_padding - fps_h
   osd_w = 225
   osd_h = screen_h - bottombar_h - 2*screen_padding - fps_h
   gui.osdInit(osd_x, osd_y, osd_w, osd_h)

   -- Compensate for the extra pixels added to the OSD in C code
   -- (via osd_render()).
   osd_w = osd_w + 10

   -- Overlay
   local hbound = math.max(osd_w, sidebar_w + 2*sidebar_padding)
   gui.setMapOverlayBounds(screen_padding, screen_padding + hbound,
         screen_padding, screen_padding + hbound)

   -- On-screen messages
   gui.omsgInit(screen_w - 2*screen_padding - 2*hbound,
         screen_w / 2, screen_h / 2)

   -- Messages
   gui.mesgInit(screen_w/2 - screen_padding, screen_padding,
         bottombar_h + screen_padding)

   -- Initial updates
   update_ship()
   update_cargo()
   update_target()
   update_nav()
   update_faction()
   update_system()
end

function render(dt, dt_mod)
   render_sidebar()
   render_targetDisplay()
   render_bottombar()
end

function render_cooldown(percent, seconds)
end

function end_cooldown()
end

function update_ship()
   local p = player.pilot()

   -- Get the height of the weapset display. This depends on how many
   -- "change" type weapsets there are.
   -- First get the height of the header plus the spacing between it and
   -- the weapset indicators.
   player_ws_header_text = _("Weapon Set")
   player_ws_header_h = gfx.printDim(false, player_ws_header_text, sidebar_w)
   player_ws_h = player_ws_header_h + sidebar_padding

   -- Get what choices there are for weapsets to switch to.
   player_ws_choices = {}
   for i = 1, 10 do
      if p:weapsetType(i) == "change" then
         table.insert(player_ws_choices, i)
      end
   end

   -- Determine if the weapset choices will be one one or two rows, and
   -- calculate the number of weapsets per row.
   player_ws_row_h = 2 * fontSize_small
   if #player_ws_choices > 5 then
      player_ws_h = player_ws_h + 2*player_ws_row_h
      player_ws_toprow = math.ceil(#player_ws_choices / 2)
      player_ws_bottomrow = #player_ws_choices - player_ws_toprow
   else
      player_ws_h = player_ws_h + player_ws_row_h
      player_ws_toprow = #player_ws_choices
      player_ws_bottomrow = nil
   end

   -- Calculate how much space each weapset number gets.
   player_ws_toprow_spacing = 0
   player_ws_bottomrow_spacing = 0
   if player_ws_toprow ~= nil and player_ws_toprow > 0 then
      player_ws_toprow_spacing = sidebar_w / player_ws_toprow
   end
   if player_ws_bottomrow ~= nil and player_ws_bottomrow > 0 then
      player_ws_bottomrow_spacing = sidebar_w / player_ws_bottomrow
   end

   -- Record relevant pilot stats.
   local stats = p:stats()
   player_speed_max = stats.speed_max
   player_fuel_max = stats.fuel_max
end

function update_cargo()
   local p = player.pilot()

   cargo_carried = 0
   cargo_free = p:cargoFree()
   for i, c in ipairs(p:cargoList()) do
      cargo_carried = cargo_carried + c.q
   end
end

function update_target()
   target_p = player.pilot():target()
   if target_p == nil then
      return
   end

   target_faction = target_p:faction()

   target_tex = target_p:ship():gfx()
   target_tex_w, target_tex_h, target_tex_sw, target_tex_sh = target_tex:dim()

   local stats = target_p:stats()
   target_speed_max = stats.speed_max
end

function update_nav()
   local p = player.pilot()

   nav_planet, nav_system = p:nav()
   nav_dest, nav_dest_jumps = player.autonavDest()
   nav_system_display = p_("nav_system", "None")
   nav_dest_display = p_("nav_system", "None")
   if nav_system ~= nil then
      if nav_system:known() or nav_system:marked() then
         nav_system_display = nav_system:name()
      else
         nav_system_display = p_("system", "Unknown")
      end
      if nav_dest ~= nil then
         nav_dest_display = fmt.f(
            n_("{system} ({jumps} jump)", "{system} ({jumps} jumps)",
               nav_dest_jumps),
            {system=nav_dest:name(), jumps=fmt.number(nav_dest_jumps)})
      end
   end
end

function update_faction()
end

function update_system()
end

function mouse_move(x, y)
end

function mouse_click(button, x, y, state)
end


--[[
Render the header portion of a bar.

   @tparam number x Location X coördinate.
   @tparam number y Location Y coördinate.
   @tparam Tex icon Icon to use.
@func render_bar_header_raw
--]]
function render_bar_header_raw(x, y, icon)
   local ix = x + 2
   local iy = y + 2
   local iw = barHeader_w - 4
   local ih = barHeader_h - 4

   gfx.renderRect(x, y, barHeader_w, barHeader_h, col_black)
   gfx.renderTexRaw(icon, ix, iy, iw, ih, 1, 1, 0, 0, 1, 1)
   gfx.renderTex(tex_barHeader, x, y)
end


--[[
Render the bar portion of a bar.

If the argument passed to the text parameter is non-nil, text is
displayed over the bar and any arguments for the parameters that
follow it are ignored, so you can only use either the
reload/lock/icon/weapon number graphic *or* text, not both.

   @tparam number x Location X coördinate.
   @tparam number y Location Y coördinate.
   @tparam[opt] Colour col Color of the bar.
   @tparam[opt] Colour col_end Color of the tip of the bar.
   @tparam[opt] number pct Percent of the bar to fill.
      Only works if col is specified as well.
   @tparam[opt] string text Text to display over the bar.
   @tparam[opt] Tex ricon Icon to show in the reload meter. Must be
      nil to use the wnum parameter.
   @tparam[opt] Colour rcol Color of the reload meter.
   @tparam[opt] number rpct Percent of the reload meter to fill.
      Only works if rcol is specified as well.
   @tparam[opt] string wnum Weapon number to display. Should be a
      single digit.
   @tparam[opt] Colour hcol Color of the lock-on meter.
   @tparam[opt] number hpct Percent of the heat meter to fill.
      Only works if hcol is specified as well.
   @tparam[opt] Colour bgcol Color of the background (black by
      default).
   @tparam[opt] Colour subcol Color of the sub-bar.
   @tparam[opt] Colour subcol_end Color of the tip of the sub-bar.
   @tparam[opt] number subpct Percent of the sub-bar to fill.
      Only works if subcol, col, and pct are specified as well.
@func render_bar_raw
--]]
function render_bar_raw(x, y, col, col_end, pct, text, ricon, rcol, rpct, wnum,
      hcol, hpct, bgcol, subcol, subcol_end, subpct)
   local w = barFrame_w
   local h = barFrame_h
   local centerx = math.floor(x + w/2)
   local text_y = math.floor(y + h/2 - fontSize_small/2)

   gfx.renderRect(x, y, w, h, bgcol or col_black)
   if col ~= nil and pct ~= nil then
      local bw = math.floor(w * math.min(pct, 1))
      if bw >= 1 then
         gfx.renderRect(x, y, bw, h, col)
         gfx.renderRect(x + bw - 1, y, 1, h, col_end or col)

         if subcol ~= nil and subpct ~= nil then
            sbw = math.floor(bw * math.min(subpct, 1))
            if sbw >= 1 then
               gfx.renderRect(x, y, sbw, h, subcol)
               gfx.renderRect(x + sbw - 1, y, 1, h, subcol_end or subcol)
            end
         end
      end
   end

   if text ~= nil then
      local text_x = math.floor(x+w - gfx.printDim(true, text) - 8)
      gfx.print(true, text, text_x, text_y, col_text, w)
   end

   if ricon ~= nil or wnum ~= nil or (rcol ~= nil and rpct ~= nil)
         or (hcol ~= nil and hpct ~= nil) then
      local cw, ch = tex_barCircles:dim()
      local cx = math.floor(x + 4)
      local iw, ih = tex_circleBar:dim()
      local ix = cx
      local iy = y + 4

      gfx.renderTexRaw(tex_circleBar, ix, iy, iw, ih, 1, 1, 0, 0, 1, 1,
            col_black)
      if rcol ~= nil and rpct ~= nil then
         rpct = math.min(rpct, 1)
         local bh = ih * rpct
         if bh >= 1 then
            gfx.renderTexRaw(tex_circleBar, ix, iy, iw, bh, 1, 1, 0, 0, 1,
                  rpct, rcol)
         end
      end

      ix = math.floor(cx + cw/2)
      gfx.renderTexRaw(tex_circleBar, ix, iy, iw, ih, 1, 1, 0, 0, 1, 1,
            col_black)
      if hcol ~= nil and hpct ~= nil then
         if hpct > 1 then
            gfx.renderTexRaw(tex_circleBar, ix, iy, iw, ih, 1, 1, 0, 0, 1, 1,
                  hcol)
            hcol = col_superheat
            hpct = hpct - 1
         end
         hpct = math.min(hpct, 1)
         local bh = ih * hpct
         if bh >= 1 then
            gfx.renderTexRaw(tex_circleBar, ix, iy, iw, bh, 1, 1, 0, 0, 1,
                  hpct, hcol)
         end
      end

      gfx.renderTex(tex_barCircles, cx, y)

      if ricon ~= nil then
         local iw, ih = ricon:dim()
         local ix = math.floor(cx + cw/4 - iw/2)
         local iy = math.floor(y + h/2 - ih/2)
         gfx.renderTex(ricon, ix, iy)
      elseif wnum ~= nil then
         local tx = math.floor(cx)
         gfx.print(true, wnum, tx, text_y, col_text, cw/2 - 1, true)
      end

      if hcol ~= nil and hpct ~= nil then
         local iw, ih = tex_iconWeapHeat:dim()
         local ix = math.floor(cx + cw*3/4 - iw/2)
         local iy = math.floor(y + h/2 - ih/2)
         gfx.renderTex(tex_iconWeapHeat, ix, iy)
      end
   end

   gfx.renderTex(tex_barFrame, x, y)
end


--[[
Render a core stat bar.

   @tparam number x Location X coördinate.
   @tparam number y Location Y coördinate.
   @tparam Tex icon Icon to use for the stat.
   @tparam number pct Percent of the bar to fill.
   @tparam string text Text to display.
   @tparam[opt] Colour bgcol Color of the background.
   @tparam[opt] Colour subcol Color of the sub-bar.
   @tparam[opt] Colour subcol_end Color of the tip of the sub-bar.
   @tparam[opt] number subpct Percent of the sub-bar to fill.
      Only works if subcol, col, and pct are specified as well.
@func render_statBar
--]]
function render_statBar(x, y, icon, col, col_end, pct, text, bgcol,
      subcol, subcol_end, subpct)
   render_bar_header_raw(x, y, icon)
   render_bar_raw(x + barHeader_w, y, col, col_end, pct, text,
         nil, nil, nil, nil, nil, nil, bgcol, subcol, subcol_end, subpct)
end


--[[
Render a weapon bar.

   @tparam number x Location X coördinate.
   @tparam number y Location Y coördinate.
   @tparam table slot Slot returned by pilot.weapset() to render.
@func render_weapBar
--]]
function render_weapBar(x, y, slot)
   local o = outfit.get(slot.name)

   local mainbar_col = nil
   local mainbar_col_end = nil
   local mainbar_pct = nil
   local mainbar_txt = nil
   if slot.left ~= nil then
      mainbar_col = col_ammo
      mainbar_col_end = col_ammo_end
      mainbar_pct = slot.left_p
      mainbar_txt = fmt.number(slot.left) .. "/" .. fmt.number(slot.max_ammo)
   elseif slot.charge ~= nil then
      mainbar_col = col_cooldown
      mainbar_col_end = col_end_cooldown
      mainbar_pct = slot.charge
   end

   local reload_icon = nil
   if slot.level == 1 then
      reload_icon = tex_iconWeapPrimary
   elseif slot.level == 2 then
      reload_icon = tex_iconWeapSecondary
   end

   local reload_col
   local reload
   if slot.lockon ~= nil then
      reload_col = col_lockon
      reload = slot.lockon
   else
      reload_col = col_cooldown
      reload = slot.cooldown
   end

   render_bar_header_raw(x, y, o:icon())
   render_bar_raw(x + barHeader_w, y, mainbar_col, mainbar_col_end,
         mainbar_pct, mainbar_txt, reload_icon, reload_col, reload,
         slot.instant, col_heat, slot.temp)
end


--[[
Render an activated outfit bar.

   @tparam number x Location X coördinate.
   @tparam number y Location Y coördinate.
   @tparam table active Activated outfit returned by pilot.actives() to
      render.
@func render_weapBar
--]]
function render_activeOutfitBar(x, y, active)
   local o = outfit.get(active.name)

   local pct = 0
   local text = p_("activated_outfit", "Off")
   local reload = 1
   local heat = 0
   if active.state == "on" then
      pct = active.duration or 1
      text = p_("activated_outfit", "On")
   elseif active.state == "cooldown" then
      pct = 0
      text = p_("activated_outfit", "Cooling")
      reload = 1 - active.cooldown
      heat = 1
   end

   if active.temp ~= nil then
      heat = active.temp
   end

   render_bar_header_raw(x, y, o:icon())
   render_bar_raw(x + barHeader_w, y, col_cooldown, col_end_cooldown, pct,
         text, nil, col_cooldown, reload, active.weapset, col_heat, heat)
end


function render_pilotStats(x, y, p, max_speed)
   local armor_pct, shield_pct, stress, disabled = p:health()
   local armor, shield = p:health(true)
   if disabled then
      stress = 100
   end
   local energy_pct = p:energy()
   local energy = p:energy(true)
   local temp = p:temp()
   local heat = math.max(0, (temp-250) / (500-250))
   local speed = p:vel():mod()

   y = y - barFrame_h
   render_statBar(x, y, tex_iconShield, col_shield, col_end_shield,
         shield_pct / 100, string.format(_("%.0f GJ"), shield))

   y = y - barFrame_h
   local icon = tex_iconArmor
   if stress >= 100 then
      icon = tex_iconStress
   end
   render_statBar(x, y, icon, col_armor, col_end_armor,
         armor_pct / 100, string.format(_("%.0f GJ"), armor), nil,
         col_stress, col_end_stress, stress / 100)

   y = y - barFrame_h
   render_statBar(x, y, tex_iconEnergy, col_energy, col_end_energy,
         energy_pct / 100, string.format(_("%.0f GJ"), energy))

   y = y - barFrame_h
   local col = col_heat
   local col_end = col_end_heat
   local bg_col = nil
   if heat > 1 then
      col = col_superheat
      col_end = col_end_superheat
      bg_col = col_heat
      heat = math.min(1, heat - 1)
   end
   render_statBar(x, y, tex_iconHeat, col, col_end, heat,
         string.format(p_("temperature", "%.0f K"), temp), bg_col)

   y = y - barFrame_h
   local col = col_speed
   local col_end = col_end_speed
   local pct = speed / max_speed
   local bg_col = nil
   if speed > max_speed then
      col = col_overspeed
      col_end = col_end_overspeed
      pct = pct - 1
      bg_col = col_speed
   end
   render_statBar(x, y, tex_iconSpeed, col, col_end, pct,
         format_speed(speed), bg_col)

   return x, y
end


function render_weapsetDisplay(x, y)
   y = y - sidebar_padding - player_ws_header_h
   gfx.print(false, player_ws_header_text, x, y, col_text,
         sidebar_w, true)

   y = y - player_ws_row_h - sidebar_padding
   local current = player.pilot():activeWeapset()
   for i, w in ipairs(player_ws_choices) do
      local wx, wy, spacing
      if i <= player_ws_toprow then
         spacing = player_ws_toprow_spacing
         wx = x + (i-1)*spacing
         wy = y
      else
         spacing = player_ws_bottomrow_spacing
         wx = x + (i-player_ws_toprow-1)*spacing
         wy = y - player_ws_row_h
      end

      local col = col_graytext
      if w == current then
         col = col_text
      end

      -- Weapset 10 is printed as weapset "0".
      if w == 10 then
         w = 0
      end

      gfx.print(true, tostring(w), wx, wy, col, spacing, true)
   end
end


function render_sidebar()
   local p = player.pilot()
   local ws_name, ws_list = p:weapset(true)
   local actives_list = p:actives(true)
   local w = sidebar_w
   local h = (5*barFrame_h + 2*sidebar_padding + player_ws_h
         + #ws_list*barFrame_h + #actives_list*barFrame_h)
   local x = sidebar_x
   local y = screen_h - h - screen_padding - 2*sidebar_padding

   -- Render radar.
   local rx = x
   local ry = screen_h - radar_h - screen_padding
   local should_render = true
   if screen_h - bottombar_h - 2*screen_padding - h >= radar_h then
      y = y - radar_h
   else
      rx = x - radar_w
      should_render = not gui.overlayOpen()
   end
   if should_render then
      gfx.renderRect(rx, ry, radar_w, radar_h, col_radar)
      gui.radarOpen()
      gui.radarRender(rx, ry)
      gfx.renderRect(rx, ry, radar_w, radar_h, col_outline1, true)
      gfx.renderRect(rx + 1, ry + 1, radar_w - 2, radar_h - 2, col_outline2,
            true)
   end

   -- Render background.
   gfx.renderRect(x, y, w + 2*sidebar_padding, h + 2*sidebar_padding, col_bg)
   gfx.renderRect(x, y, w + 2*sidebar_padding, h + 2*sidebar_padding,
         col_outline1, true)
   gfx.renderRect(x + 1, y + 1, w + 2*sidebar_padding - 2,
         h + 2*sidebar_padding - 2, col_outline2, true)
   x = x + sidebar_padding
   y = y + sidebar_padding + h

   -- Render stat bars.
   x, y = render_pilotStats(x, y, p, player_speed_max)

   -- Render weapset display.
   render_weapsetDisplay(x, y)
   y = y - player_ws_h - 2*sidebar_padding

   -- Render weapons.
   for i, slot in ipairs(ws_list) do
      y = y - barFrame_h
      render_weapBar(x, y, slot)
   end

   -- Render activated outfits.
   for i, slot in ipairs(actives_list) do
      y = y - barFrame_h
      render_activeOutfitBar(x, y, slot)
   end
end


function render_pilotIcon(x, y, d, p, tex, tex_sw, tex_sh)
   local r = d / 2
   local ir = 0.9 * r
   local xcenter = x + r
   local ycenter = y + r
   local dir = p:dir()

   -- Render background.
   gfx.renderRect(x, y, d, d, col_black)

   -- Render direction line.
   local rdir = math.rad(dir)
   local x2 = xcenter + ir*math.cos(rdir)
   local y2 = ycenter + ir*math.sin(rdir)
   gfx.renderLine(xcenter, ycenter, x2, y2, col_white)

   -- Render ship image.
   local sx, sy = tex:spriteFromDir(dir)
   local wh = 2 * ir
   local aspect = tex_sw / tex_sh
   local draw_w = tex_sw
   local draw_h = tex_sh
   if aspect >= 1 then
      if tex_sw > wh then
         draw_w = wh
         draw_h = wh/tex_sw * tex_sh
      end
   else
      if tex_sh > wh then
         draw_h = wh
         draw_w = wh/tex_sh * tex_sw
      end
   end
   gfx.renderTexRaw(tex, xcenter - draw_w/2, ycenter - draw_h/2,
         draw_w, draw_h, sx, sy, 0, 0, 1, 1)
end


function render_targetDisplay()
   if target_p == nil or not target_p:exists() then
      return
   end

   local w = sidebar_w
   local name = target_p:getPrefix() .. target_p:name() .. "#0"
   local name_h = gfx.printDim(false, name, w)
   local f_text = target_faction:name()
   local f_text_h = gfx.printDim(true, f_text, w)
   local icon_d = 48
   local dist_w = w - icon_d - sidebar_padding
   local dist_header_text = p_("gui", "Distance:")
   local dist_header_text_h = gfx.printDim(true, dist_header_text, dist_w)
   local dist = player.pilot():pos():dist(target_p:pos())
   local dist_text = format_distance(dist)
   local dist_text_h = gfx.printDim(true, dist_text, dist_w)
   local dist_h = math.max(icon_d,
         dist_header_text_h + sidebar_padding + dist_text_h)
   local h = (name_h + sidebar_padding + f_text_h + sidebar_padding
         + dist_h + sidebar_padding + 5*barFrame_h)

   local x = sidebar_x - w - 2*sidebar_padding
   local y = bottombar_h + screen_padding

   -- Render background.
   gfx.renderRect(x, y, w + 2*sidebar_padding, h + 2*sidebar_padding, col_bg)
   gfx.renderRect(x, y, w + 2*sidebar_padding, h + 2*sidebar_padding,
         col_outline1, true)
   gfx.renderRect(x + 1, y + 1, w + 2*sidebar_padding - 2,
         h + 2*sidebar_padding - 2, col_outline2, true)
   x = x + sidebar_padding
   y = y + sidebar_padding + h

   -- Render header text.
   y = y - name_h
   gfx.print(false, name, x, y, col_text, w)

   y = y - sidebar_padding - f_text_h
   gfx.print(true, f_text, x, y, col_text, w)

   -- Render icon and distance.
   y = y - sidebar_padding
   render_pilotIcon(x, y - icon_d, icon_d, target_p, target_tex,
         target_tex_sw, target_tex_sh)

   gfx.print(true, dist_header_text, x + icon_d + sidebar_padding,
         y - dist_header_text_h, col_text, dist_w)
   gfx.print(true, dist_text, x + icon_d + sidebar_padding,
         y - dist_header_text_h - sidebar_padding - dist_text_h, col_text,
         dist_w)
   y = y - dist_h - sidebar_padding

   -- Render stat bars.
   x, y = render_pilotStats(x, y, target_p, target_speed_max)
end


function render_bottombar()
   gfx.renderRect(0, 0, screen_w, bottombar_h, col_bottombar)
   gfx.renderRect(0, bottombar_h - 1, screen_w, 1, col_outline1)
   gfx.renderRect(0, bottombar_h - 2, screen_w, 1, col_outline2)

   local credits, credits_t = player.credits(2)
   local fuel = player.fuel()
   local jumps = player.jumps()
   local fueltext = fmt.f(
      n_("{fuel:.0f}/{maxfuel:.0f} kL ({jumps} jump)",
         "{fuel:.0f}/{maxfuel:.0f} kL ({jumps} jumps)",
         jumps),
      {fuel=fuel, maxfuel=player_fuel_max, jumps=fmt.number(jumps)})

   local texts = {
      fmt.f(_("#nDate:#0 {date}"), {date=time.get():str()}),
      fmt.f(_("#nCredits:#0 {credits}"), {credits=credits_t}),
      fmt.f(_("#nCargo:#0 {carried}/{capacity} kt"),
         {carried=cargo_carried, capacity=cargo_carried+cargo_free}),
      fmt.f(_("#nCurrent System:#0 {system}"), {system=system.cur():name()}),
      fmt.f(_("#nNext System:#0 {system}"), {system=nav_system_display}),
      fmt.f(_("#nDestination:#0 {system}"), {system=nav_dest_display}),
      fmt.f(_("#nFuel:#0 {fuel}"), {fuel=fueltext}),
   }

   local total_text_w = 0
   local text_w_list = {}
   for i, s in ipairs(texts) do
      local w = gfx.printDim(true, s)
      text_w_list[i] = w
      total_text_w = total_text_w + w
   end
   local x = 8
   local y = math.floor(bottombar_h/2 - fontSize_small/2)
   local free_space = screen_w - 2*x - total_text_w
   local space_per_text = free_space / (#texts-1)

   for i, s in ipairs(texts) do
      gfx.print(true, s, x, y, col_text)
      x = x + text_w_list[i] + space_per_text
   end
end


function format_distance(dist)
   if dist < 1000 then
      return string.format(_("%.0f mAU"), dist)
   elseif dist < 1e6 then
      return string.format(_("%.1f AU"), dist / 1000)
   elseif dist < 1e9 then
      return string.format(_("%.1f kAU"), dist / 1e6)
   elseif dist < 1e12 then
      return string.format(_("%.1f MAU"), dist / 1e9)
   elseif dist < 1e15 then
      return string.format(_("%.1f GAU"), dist / 1e12)
   else
      return string.format(_("%.1f TAU"), dist / 1e15)
   end
end


function format_speed(speed)
   if speed < 1000 then
      return string.format(_("%.0f mAU/s"), speed)
   elseif speed < 1e6 then
      return string.format(_("%.1f AU/s"), speed / 1000)
   elseif speed < 1e9 then
      return string.format(_("%.1f kAU/s"), speed / 1e6)
   elseif speed < 1e12 then
      return string.format(_("%.1f MAU/s"), speed / 1e9)
   elseif speed < 1e15 then
      return string.format(_("%.1f GAU/s"), speed / 1e12)
   else
      return string.format(_("%.1f TAU/s"), speed / 1e15)
   end
end

