--[[pod_format="raw",created="2024-05-24 21:42:07",modified="2025-01-27 16:30:20",revision=614]]
ella=Character{"Ella",smile=Image{fetch"ella.pod",t=28}}

vn.messageBox.skin = Image{get_spr(1),t=30}
vn.messageBox.padding = 5

vn.Start(function()
	say "hello"
	say "world"
	
	ella.smile:show{x=200;y=10}
	
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
