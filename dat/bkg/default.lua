prng_lib = require "prng"
prng = prng_lib.new()

nebulae = {
   "nebula01.png",
   "nebula02.png",
   "nebula03.png",
   "nebula04.png",
   "nebula05.png",
   "nebula06.png",
   "nebula07.png",
   "nebula08.png",
   "nebula09.png",
   "nebula10.png",
   "nebula11.png",
   "nebula12.png",
   "nebula13.png",
   "nebula14.png",
   "nebula15.png",
   "nebula16.png",
   "nebula17.png",
   "nebula19.png",
   "nebula34.webp",
   "nebula35.png",
}


function background ()

   -- We can do systems without nebula
   cur_sys = system.cur()
   local nebud, nebuv = cur_sys:nebula()
   if nebud > 0 then
      return
   end

   -- Start up PRNG based on system name for deterministic nebula
   prng:setSeed(cur_sys:name())

   -- Generate nebula
   background_nebula()
end


function background_nebula ()
   -- Set up parameters
   local path  = "gfx/bkg/"
   local nebula = nebulae[ prng:random(1,#nebulae) ]
   local img   = tex.open( path .. nebula )
   local w,h   = img:dim()
   local r     = prng:random() * cur_sys:radius()/2
   local a     = 2*math.pi*prng:random()
   local x     = r*math.cos(a)
   local y     = r*math.sin(a)
   local move  = 0.0001 + prng:random()*0.0001
   local scale = 1 + (prng:random()*0.5 + 0.5)*((2000+2000)/(w+h))
   if scale > 1.9 then scale = 1.9 end
   bkg.image( img, x, y, move, scale )
end
