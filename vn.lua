--[[pod_format="raw",created="2024-05-24 21:24:51",modified="2025-02-25 23:01:25",revision=1980]]
vn = create_gui()
vn._images={}
vn.choices={}

-- color utilities
local function get_rgba(c)
	local m=0x5000+4*c
	return peek(m+2),peek(m+1),peek(m),peek(m+3)
end
local nearest_color_mindist = 255*255+255*255+255*255+1
local function nearest_color(r,g,b)
	local mindist=nearest_color_mindist
	local nc=0
	for pc=0,63 do
		local r2,g2,b2 = get_rgba(pc)
		local rdiff,gdiff,bdiff=r-r2,g-g2,b-b2
		local dist = rdiff*rdiff+gdiff*gdiff+bdiff*bdiff
		if dist<mindist then
			mindist=dist
			nc=pc
		end
	end
	return nc
end
local function mix_colors(c1,c2,a)
	local r1,g1,b1 = get_rgba(c1)
	local r2,g2,b2 = get_rgba(c2)
	local r,g,b = r1*(1-a)+r2*a, g1*(1-a)+g2*a, b1*(1-a)+b2*a
	return nearest_color(r,g,b)
end

local function apply_colortable_row(data,row,table_number)
	table_number = table_number or 0
	local address = 0x8000+4096*table_number+64*row
	--memmap(address,data:copy())
	for i=0,#data-1 do
		poke(address+i,data[i])
	end
end
local function generate_colortable_row(a,c2)
	local colordata = userdata("u8",64)
	for c1=0,63 do
		colordata:set(c1,c1==c2 and c2 or a==0 and c1 or a==1 and c2 or mix_colors(c1,c2,a))
	end
	return colordata
end
local colortable_cache={}
local function get_cached_colortable_row(a,c2)
	if(not colortable_cache[c2])colortable_cache[c2]={}
	if(not colortable_cache[c2][a])colortable_cache[c2][a]=generate_colortable_row(a,c2)
	--error(pod(colortable_cache[c2][a]))
	return colortable_cache[c2][a]
end
function vn.clear_color_cache()
	colortable_cache={}
end

local function palt_apply(t)
	if type(t)=="number" then
		palt(t,true)
	elseif type(t)=="table" then
		for c,a in pairs(t) do
			if a==0 then
				palt(c,true)
			elseif a==1 then
				palt(c,false)
			else
				apply_colortable_row(get_cached_colortable_row(a,c),c,0)
			end
		end
	end
end
local function palt_reset(t)
	if type(t)=="number" then
		palt(t,false)
	elseif type(t)=="table" then
		for c in pairs(t) do
			palt(c,false)
		end
	end
end

-- utility functions

local function print_wrap(text,x,y,c, wrap,text_shadow)
	local words = split(text," ",false)
	local lastx,lasty=x,y
	for word in all(words) do
		local wordx,wordy = print(word,lastx,-999,c)
		if wordx>=wrap then
			lastx=x
			lasty+=10
		end
		if text_shadow!=nil then
			print(word,lastx+1,lasty,text_shadow)
			print(word,lastx,lasty+1,text_shadow)
			print(word,lastx+1,lasty+1,text_shadow)
		end
		lastx=print(word.." ",lastx,lasty,c)
	end
	return lastx,lasty+10
end

local function nineslice(skin,x,y,w,h)
	local img = type(skin)=="userdata" and skin or skin[1]
	local t = skin.t
	local pw = img:width()/3
	local ph = img:height()/3
	
	local pw2 = min(pw,w/2)
	local ph2 = min(ph,h/2)
	
	local sx1,sx2,sx3 = 0, pw, pw*3-pw2
	local sy1,sy2,sy3 = 0, ph, ph*3-ph2
	local dx1,dx2,dx3 = x, x+pw, x+w-pw2
	local dy1,dy2,dy3 = y, y+ph, y+h-ph2
	if(t!=nil) palt_apply(t)

	
	sspr(img, sx1,sy1, pw2,ph2, dx1,dy1)
	if(w>pw*2)sspr(img, sx2,sy1, pw2,ph2, dx2,dy1, w-pw*2,ph2)
	sspr(img, sx3,sy1, pw2,ph2, dx3,dy1)
	
	if h>ph*2 then
		sspr(img, sx1,sy2, pw2,ph2, dx1,dy2, pw,h-ph*2)
		if(w>pw*2)sspr(img, sx2,sy2, pw2,ph2, dx2,dy2, w-pw*2,h-ph*2)
		sspr(img, sx3,sy2, pw2,ph2, dx3,dy2, pw,h-ph*2)
	end
	
	sspr(img, sx1,sy3, pw2,ph2, dx1,dy3)
	if(w>pw*2)sspr(img, sx2,sy3, pw2,ph2, dx2,dy3, w-pw*2,ph2)
	sspr(img, sx3,sy3, pw2,ph2, dx3,dy3)
	
	if(t!=nil) palt_reset(t)
end

local function _to_px(n,size)
	if math.type(n)=="float" then
		return n*size
	else
		return n
	end
end

function vn:draw()
	palt(0)
	for image in all(vn._images) do
		local t = image.t or 0
		if(t!=nil) palt_apply(t)
		
		local img = image[1]
		local x = _to_px(image.position.x,self.width)-_to_px(image.anchor.x,img:width())
		local y = _to_px(image.position.y,self.height)-_to_px(image.anchor.y,img:height())
		spr(img,x,y)
		
		if(t!=nil) palt_reset(t)
	end
	--palt()
end

local co
function vn.Start(func)
	co = cocreate(func)
	vn:click()
end

local messageBox = vn:attach{
	x=0;y=0;width=200;height=60;
	width_rel=1.0;
	vjustify="bottom";
	justify="center";
	message=""; typewriter=""; log={};
	color=7;
	text_shadow=0;
	skin=nil, padding=2
}
vn.messageBox = messageBox

local nameBox = vn:attach{
	x=0;y=-60;width=80;height=16;
	vjustify="bottom";
	justify="left";
	name="";
	color=7;text_shadow=0;
	skin=nil, padding=2
}
vn.nameBox = nameBox

local function on_resize()
	local width = 480
	local display = get_display()
	if(display) width = display:width()
	if width>400 then
		messageBox.width_rel=nil
		messageBox.width=400
	else
		messageBox.width_rel=1.0
	end
end
on_event("resize",on_resize)
on_resize()

function messageBox:draw()
	if self.skin then
		nineslice(self.skin,0,0,self.width,self.height)
	else
		rect(0,0,self.width-1,self.height-1)
	end
	local padding, vpadding = self.padding, self.vpadding or self.padding
	print_wrap(self.message,padding,vpadding,self.color,self.width-padding*2,self.text_shadow)
end
function nameBox:draw()
	if(self.name=="") return
	if self.skin then
		nineslice(self.skin,0,0,self.width,self.height)
	else
		rect(0,0,self.width-1,self.height-1)
	end
	local padding, vpadding = self.padding, self.vpadding or self.padding
	print_wrap(self.name,padding,vpadding,self.color,self.width-padding*2,self.text_shadow)
end
function nameBox:update()
	if(self.name=="") return
	self.x=messageBox.sx
end
function messageBox:update()
	if #self.typewriter>0 then
		self.message ..= self.typewriter:sub(1,1)
		self.typewriter = self.typewriter:sub(2)
	end
end
function messageBox:showMessage(name,message)
	if getmetatable(name)==vn.Character then
		if(name.color)nameBox.color=name.color
		name = name.name
	elseif name=="error" then
		nameBox.color=8
	end
	if #self.message>0 then
		add(self.log, name..": "..self.message)
	end
	nameBox.name=name
	self.message=""
	self.typewriter=message
end
function messageBox:clearMessage()
	nameBox.name=""
	self.message=""
	self.typewriter=""
end
function messageBox:hasMessage()
	return self.message!="" or self.typewriter!=""
end

function vn:update()

end

function vn:click()
	if #messageBox.typewriter>0 then
		messageBox.message..=messageBox.typewriter
		messageBox.typewriter=""
	elseif co then
		local alive,info = coresume(co)
		if not alive and info then
			messageBox:showMessage("error",info)
			messageBox.color=8
		end
	end
end

function vn.createChoices(table)
	local choices={}
	local choiceIndex=0
	local selection = {choice=nil}
	local choiceArea = vn:attach{
		x=vn.choices.x or 0;
		y=vn.choices.y or -vn.messageBox.height-1;
		width=vn.choices.width or 100;
		height=12;
		justify=vn.choices.justify or "right";
		vjustify=vn.choices.vjustify or "bottom";
	}
	function createChoice(key,func)
		local index = choiceIndex
		local choiceButton = choiceArea:attach{
			x=0;y=index*14;width_rel=1.0;height=12;
			cursor=5;
			choice=key;choiceFunction=func;
		}
		choiceArea.height = index*14+12
		choiceIndex+=1
		function choiceButton:draw()
			local i = index%#vn.choices+1
			local choice = vn.choices[i] or vn.choices
			if choice.skin then
				nineslice(choice.skin,0,0,self.width,self.height)
			else
				rect(0,0,self.width-1,self.height-1)
			end
			local text_shadow = choice.text_shadow or 0
			local padding, vpadding = choice.padding or 2, choice.vpadding or choice.padding or 2
			print_wrap(self.choice,padding,vpadding,choice.color or 7,self.width-padding*2,text_shadow)
		end
		function choiceButton:click()
			--self.choice="CLICKED"
			selection.choice=self.choiceFunction
			for choice in all(choices) do
				--vn:detach(choice)
				choice:detach()
			end
			choiceArea:detach()
		end
		return choiceButton
	end
	for key,func in pairs(table) do
		add(choices,createChoice(key,func))
	end
	return selection
end

-- class Point

local Point = {__index={x=nil;y=nil}}
setmetatable(Point,{
	__call=function(self,table)
		self=setmetatable({},Point)
		if(not table) return self
		
		self.x = type(table.x)=="number" and table.x or type(table[1])=="number" and table[1] or nil
		self.y = type(table.y)=="number" and table.y or type(table[2])=="number" and table[2] or nil
	
		return self
	end;
})
vn.Point = Point
function Point.__index.setFrom(p1,p2)
	if(getmetatable(p1)!=Point)p1=Point(p1)
	if(getmetatable(p2)!=Point)p2=Point(p2)
	if(p2.x!=nil)p1.x=p2.x
	if(p2.y!=nil)p1.y=p2.y
	return p1
end

-- class Character

local Character = {
	__call=function(self,message)
		--messageBox:showMessage(self.name,tostr(messageBox.typewriter))
		if(messageBox:hasMessage()) yield()
		print(message)
		messageBox:showMessage(self,message)
	end;
	__index={};
}
vn.Character = Character
setmetatable(Character,{
	__call=function(self,table)
		for key,value in pairs(table) do
			if getmetatable(value)==vn.Image then
				value.character=table
				value.name=key
			end
		end
		table.name = table[1] or ""
		table.color = table.color or 7
		setmetatable(table,Character)
		return table
	end;
})

function Character.__index:_find_image()
	for i,image in pairs(vn._images) do
		if image.character == self then
			return image
		end
	end
end
function Character.__index:hide()
	local image = self:_find_image()
	if image then
		image:hide()
	end
end

-- class Image
local function replace_character_image(self)
	for i,image in pairs(vn._images) do
		if image.character == self.character then
			vn._images[i] = self
			return
		end
	end
end

local Image = {
	__call=function(self,message)
		-- show image
		if self.character then
			self.character(message)
			replace_character_image(self)
		else
			print("NO CHARACTER")
		end
	end;
	__index={};
}
vn.Image=Image
setmetatable(Image,{
	__call=function(self,table)
		self=setmetatable(table,Image)
		self.position=Point{0,0}
		self.anchor=Point{0,0}:setFrom(self.anchor)
		return self
	end;
})
function Image.__index:show(position)
	if(messageBox:hasMessage()) yield()
	messageBox:clearMessage()
	if self.character then
		replace_character_image(self)
	else
		for i,image in pairs(vn._images) do
			if image == self then
				return
			end
		end
	end
	if position then
		self.position:setFrom(position)
		if position.anchor then
			self.anchor:setFrom(position.anchor)
		end
	end
	add(vn._images,self)
end
function Image.__index:hide()
	if(messageBox:hasMessage()) yield()
	messageBox:clearMessage()
	del(vn._images,self)
end

-- other functions

function vn.choice(table)
	local selection = vn.createChoices(table)
	while not selection.choice do
		yield()
	end
	messageBox:clearMessage()
	selection.choice()
end

vn.say=Character{}