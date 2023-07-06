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
   col_bg = colour.new(0.2, 0.2, 0.2, 0.5)
   col_outline1 = colour.new(0.1, 0.1, 0.1)
   col_outline2 = colour.new(0.25, 0.25, 0.25)
   col_text = colour.new(0.95, 0.95, 0.95)
   col_cooldown = colour.new(76/255, 98/255, 176/255)
   col_lockon = colour.new(150/255, 141/255, 23/255)
   col_shield = colour.new(42/255, 57/255, 162/255)
   col_armour = colour.new(80/255, 80/255, 80/255)
   col_energy = colour.new(36/255, 125/255, 51/255)
   col_heat = colour.new(80/255, 27/255, 24/255)
   col_stress = colour.new(45/255, 48/255, 102/255)
   col_ammo = colour.new(159/255, 93/255, 15/255)
   col_end_cooldown = colour.new(96/255, 109/255, 171/255)
   col_end_shield = colour.new(88/255, 96/255, 156/255)
   col_end_armour = colour.new(122/255, 122/255, 122/255)
   col_end_energy = colour.new(52/255, 172/255, 71/255)
   col_end_heat = colour.new(188/255, 63/255, 56/255)
   col_end_stress = colour.new(56/255, 88/255, 156/255)
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
   screen_padding = 8
   barHeader_w, barHeader_h = tex_barHeader:dim()
   barFrame_w, barFrame_h = tex_barFrame:dim()
   fontSize_small = gfx.fontSize(true)

   -- Sidebar
   sidebar_padding = 4
   sidebar_w = barHeader_w + barFrame_w
   sidebar_x = screen_w - sidebar_w - screen_padding
end

function render(dt, dt_mod)
end

function render_cooldown(percent, seconds)
end

function end_cooldown()
end

function update_target()
end

function update_nav()
end

function update_faction()
end

function update_cargo()
end

function update_ship()
   local p = player.pilot()
   player_weapons = p:weapset(true)
   player_actives = p:actives(true)
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
   local iw = w - 4
   local ih = h - 4

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
   @tparam Colour col Color of the bar.
   @tparam Colour col_end Color of the tip of the bar.
   @tparam number pct Percent of the bar to fill.
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
@func render_bar_raw
--]]
function render_bar_raw(x, y, col, col_end, pct, text, ricon, rcol, rpct, wnum,
      hcol, hpct)
   local w = barFrame_w
   local h = barFrame_h
   local bw = math.floor(w * pct)
   local centerx = math.floor(x + w/2)
   local text_y = math.ceil(y + h/2 - fontSize_small/2)

   gfx.renderRect(x, y, w, h, col_black)
   gfx.renderRect(x, y, bw, h, col)
   gfx.renderRect(x + bw - 1, y, 1, h, col_end)

   if text ~= nil then
      local text_x = math.floor(x+w - gfx.printDim(true, text) - 4)
      gfx.print(true, text, text_x, text_y, col_text, w)
   end

   if ricon ~= nil or wnum ~= nil or (rcol ~= nil and rpct ~= nil)
         or (hcol ~= nil and hpct ~= nil) then
      local cw, ch = tex_barCircles:dim()
      local cx = math.floor(x + 4)

      if rcol ~= nil and rpct ~= nil then
         rpct = math.min(0, math.max(rpct, 1))
         local iw, ih = tex_circleBar:dim()
         local ix = cx
         local iy = y + 4
         gfx.renderTexRaw(tex_circleBar, ix, iy, iw, ih, 1, 1, 0, 0, 1, 1,
               col_black)
         gfx.renderTexRaw(tex_circleBar, ix, iy, iw, ih * rpct, 1, 1, 0, 0,
               1, rpct, rcol)
      end

      if hcol ~= nil and hpct ~= nil then
         hpct = math.min(0, math.max(hpct, 1))
         local iw, ih = tex_circleBar:dim()
         local ix = math.floor(cx + cw/2)
         local iy = y + 4
         gfx.renderTexRaw(tex_circleBar, ix, iy, iw, ih, 1, 1, 0, 0, 1, 1,
               col_black)
         gfx.renderTexRaw(tex_circleBar, ix, iy, iw, ih * hpct, 1, 1, 0, 0,
               1, hpct, hcol)
      end

      gfx.renderTex(tex_barCircles, cx, y)

      if ricon ~= nil then
         local iw, ih = ricon:dim()
         local ix = math.floor(cx + cw/4 - iw/2)
         local iy = math.floor(y + h/2 - ih/2)
         gfx.renderTex(ricon, ix, iy)
      elseif wnum ~= nil then
         local tx = math.floor(cx + cw/4)
         gfx.print(true, wnum, tx, text_y, col_text, math.floor(cw/4), true)
      end

      if hcol ~= nil and hpct ~= nil then
         local iw, ih = tex_iconHeat:dim()
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
@func render_statBar
--]]
function render_statBar(x, y, icon, col, col_end, pct, text)
   render_bar_header_raw(x, y, icon)
   render_bar_raw(x + barHeader_w, y, col, col_end, pct, text)
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

   local mainbar_col = col_cooldown
   local mainbar_col_end = col_end_cooldown
   local mainbar_pct = 0
   local mainbar_txt = nil
   if slot.left ~= nil then
      mainbar_col = col_ammo
      mainbar_col_end = col_ammo_end
      mainbar_pct = slot.left_p
      mainbar_txt = fmt.number(slot.left) .. "/" .. fmt.number(slot.max_ammo)
   elseif slot.charge ~= nil then
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
   local heat = 0
   if active.state == "on" then
      pct = 1
   elseif active.state == "cooldown" then
      pct = active.cooldown
      heat = 1
   end

   render_bar_header_raw(x, y, o:icon())
   render_bar_raw(x + barHeader_w, y, col_cooldown, col_end_cooldown, pct,
         nil, nil, nil, nil, active.weapset, col_heat, heat)
end


function render_sidebar()
   local header_text = _("Weapon Set")
   local wset_header_h = gfx.printDim(false, header_text, sidebar_w)

   local x = sidebar_x
end

