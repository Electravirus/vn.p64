--[[pod_format="raw",created="2024-05-24 21:42:07",modified="2025-02-18 02:41:49",revision=1366]]
ella=Character{"Ella",smile=Image{fetch"ella.pod",t=28,anchor={0.5,0.5}}}
bg=Image{fetch"bg.pod",anchor={0.5,1.0}}

vn.messageBox.skin = Image{get_spr(1),t={[30]=0;[1]=0.75}}
vn.messageBox.padding = 5
vn.choices={skin=Image{get_spr(2),t={[30]=0;[5]=0.75}}}

vn.Start(function()
	bg:show{0.5;1.0}
	say "hello"
	say "world"
	
	ella.smile:show{x=0.5;y=0.5}
	ella "Hi I'm Ella"
	
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
