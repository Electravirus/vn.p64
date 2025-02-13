--[[pod_format="raw",created="2024-05-24 21:24:51",modified="2025-02-13 19:56:03",revision=884]]
vn = create_gui()
vn._images={}

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

function vn:draw()
	palt(0)
	for image in all(vn._images) do
		local t = image.t or 0
		palt(t,true)
		if image._position then
			local x,y = image._position.x, image._position.y
			spr(image[1],x,y)
		else
			spr(image[1])
		end
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
	function createChoice(key,func)
		local choiceButton = vn:attach{
			x=200;y=choiceIndex*30;width=100;height=20;
			choice=key;choiceFunction=func;
		}
		choiceIndex+=1
		function choiceButton:draw()
			rect(0,0,self.width-1,self.height-1)
			print(self.choice,2,2)
		end
		function choiceButton:click()
			--self.choice="CLICKED"
			selection.choice=self.choiceFunction
			for choice in all(choices) do
				--vn:detach(choice)
				choice:detach()
			end
		end
		return choiceButton
	end
	for key,func in pairs(table) do
		add(choices,createChoice(key,func))
	end
	return selection
end

-- class Character

Character = {
	__call=function(self,message)
		--messageBox:showMessage(self.name,tostr(messageBox.typewriter))
		if(messageBox:hasMessage()) yield()
		print(message)
		messageBox:showMessage(self.name,message)
	end;
}
Character.__index=Character
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

function Character:_find_image()
	for i,image in pairs(vn._images) do
		if image.character == self then
			return image
		end
	end
end
function Character:hide()
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
}
Image.__index=Image
function Image:show(position)
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
		if position.x and position.y then
			self._position = position
		end
	end
	add(vn._images,self)
end
function Image:hide()
	if(messageBox:hasMessage()) yield()
	messageBox:clearMessage()
	del(vn._images,self)
end
setmetatable(Image,{
	__call=function(self,table)
		setmetatable(table,Image)
		return table
	end;
})

function choice(table)
	local selection = vn.createChoices(table)
	while not selection.choice do
		yield()
	end
	messageBox:clearMessage()
	selection.choice()
end

say=Character{}