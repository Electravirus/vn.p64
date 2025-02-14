--[[pod_format="raw",created="2024-05-24 21:24:51",modified="2025-02-14 05:51:22",revision=1321]]
vn = create_gui()
vn._images={}
vn.choices={}

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
	
	local sx1,sx2,sx3 = 0, pw, pw*2
	local sy1,sy2,sy3 = 0, ph, ph*2
	local dx1,dx2,dx3 = x, x+pw, x+w-pw
	local dy1,dy2,dy3 = y, y+ph, y+h-ph	
	if(t!=nil) palt(t,true)

	sspr(img, sx1,sy1, pw,ph, dx1,dy1)
	sspr(img, sx2,sy1, pw,ph, dx2,dy1, w-pw*2,ph)
	sspr(img, sx3,sy1, pw,ph, dx3,dy1)
	
	sspr(img, sx1,sy2, pw,ph, dx1,dy2, pw,h-ph*2)
	sspr(img, sx2,sy2, pw,ph, dx2,dy2, w-pw*2,h-ph*2)
	sspr(img, sx3,sy2, pw,ph, dx3,dy2, pw,h-ph*2)
	
	sspr(img, sx1,sy3, pw,ph, dx1,dy3)
	sspr(img, sx2,sy3, pw,ph, dx2,dy3, w-pw*2,ph)
	sspr(img, sx3,sy3, pw,ph, dx3,dy3)
	
	if(t!=nil) palt(t,false)
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
		palt(t,true)
		
		local img = image[1]
		local x = _to_px(image.position.x,self.width)-_to_px(image.anchor.x,img:width())
		local y = _to_px(image.position.y,self.height)-_to_px(image.anchor.y,img:height())
		spr(img,x,y)
		
		palt(t,false)
	end
	--palt()
end

local co
function vn.Start(func)
	co = cocreate(func)
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
function messageBox:update()
	if #self.typewriter>0 then
		self.message ..= self.typewriter:sub(1,1)
		self.typewriter = self.typewriter:sub(2)
	end
end
function messageBox:showMessage(name,message)
	if #self.message>0 then
		add(self.log, name..": "..self.message)
	end
	self.message=""
	self.typewriter=message
end
function messageBox:clearMessage()
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

Point = {__index={x=nil;y=nil}}
setmetatable(Point,{
	__call=function(self,table)
		self=setmetatable({},Point)
		if(not table) return self
		
		self.x = type(table.x)=="number" and table.x or type(table[1])=="number" and table[1] or nil
		self.y = type(table.y)=="number" and table.y or type(table[2])=="number" and table[2] or nil
	
		return self
	end;
})
function Point.__index.setFrom(p1,p2)
	if(getmetatable(p1)!=Point)p1=Point(p1)
	if(getmetatable(p2)!=Point)p2=Point(p2)
	if(p2.x!=nil)p1.x=p2.x
	if(p2.y!=nil)p1.y=p2.y
	return p1
end

-- class Character

Character = {
	__call=function(self,message)
		--messageBox:showMessage(self.name,tostr(messageBox.typewriter))
		if(messageBox:hasMessage()) yield()
		print(message)
		messageBox:showMessage(self.name,message)
	end;
	__index={};
}
setmetatable(Character,{
	__call=function(self,table)
		for key,value in pairs(table) do
			if getmetatable(value)==Image then
				value.character=table
				value.name=key
			end
		end
		table.name = table[1] or ""
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

Image = {
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

function choice(table)
	local selection = vn.createChoices(table)
	while not selection.choice do
		yield()
	end
	messageBox:clearMessage()
	selection.choice()
end

say=Character{}