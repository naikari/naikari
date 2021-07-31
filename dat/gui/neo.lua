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

local playerform = require "playerform"
local formation = require "formation"


function create ()
   -- Set default formation
   local savedform = var.peek("player_formation")
   player.pilot():memory().formation = savedform

   -- Get sizes
   screen_w, screen_h = gfx.dim()

   -- Colors
   col_bg = colour.new(0.2, 0.2, 0.2, 0.5)
   col_outline1 = colour.new(0.1, 0.1, 0.1)
   col_outline2 = colour.new(0.25, 0.25, 0.25)
   col_text = colour.new(0.95, 0.95, 0.95)
   col_shield = colour.new(42/255, 57/255, 162/255)
   col_armour = colour.new(80/255, 80/255, 80/255)
   col_energy = colour.new(36/255, 125/255, 51/255)
   col_heat = colour.new(80/255, 27/255, 24/255)
   col_stress = colour.new(45/255, 48/255, 102/255)
   col_ammo = colour.new(159/255, 93/255, 15/255)
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
   tex_iconShield = tex_open("iconShield.png")
   tex_iconArmor = tex_open("iconArmor.png")
   tex_iconEnergy = tex_open("iconEnergy.png")
   tex_iconHeat = tex_open("iconHeat.png")
   tex_iconSpeed = tex_open("iconSpeed.png")
end

