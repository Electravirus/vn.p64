--[[pod_format="raw",created="2024-05-24 21:42:07",modified="2025-02-14 00:27:09",revision=879]]
ella=Character{"Ella",smile=Image{fetch"ella.pod",t=28,anchor={0.5,1.0}}}

vn.messageBox.skin = Image{get_spr(1),t=30}
vn.messageBox.padding = 5

vn.Start(function()
	say "hello"
	say "world"
	
	ella.smile:show{x=0.5;y=1.0}
	
	choice{
		say"Where should I go?";	

		["Go North"]=function()
			say "We going north"
		end;
		["Go South"]=function()
			say "We going south"
		end;
	}
	ella:hide()
	say "after choice"
	
end)
