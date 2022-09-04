function dv_addAntiFLFLog( text )
   shiplog.create("dv_antiflf", p_("log", "Dvaered Anti-FLF Campaign"))
   shiplog.append("dv_antiflf", text)
end
