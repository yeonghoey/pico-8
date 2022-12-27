pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- geometry survivor
-- by yeonghoey

function _init()
	current_scene=gscene:make()
end

function _update()
	current_scene:update()
end

function _draw()
	current_scene:draw()
end
-->8
-- utils

function class(base)
	local c={}
	c.__index=c
	c.new = function (self)
		o={}
		setmetatable(o,self)
		return o
	end

	setmetatable(c,base)
	return c
end

function dir(v)
	if abs(v)<1 then
		return 0
	else
		return sgn(v)
	end
end
-->8
-- scenes

scene=class()

function scene:make()
	local s=self:new()
	s:init()
	return s
end

function scene:init()
end

function scene:update()
end

function scene:draw()
end

--tscene: title scene
tscene=class(scene)


--gscene: game scene
gscene=class(scene)


function gscene:init()
	self.ps=pship:spawn(self,64,64)
	self.eships={}	

	-- test
	local es=eship1:spawn(self,10,10)
	add(self.eships,es)
end

function gscene:update()
	for es in all(self.eships) do
		es:update(self)
	end
	self.ps:update(self)
end

function gscene:draw()
	cls()
	for es in all(self.eships) do
		es:draw(self)
	end
	self.ps:draw(self)
end
-->8
-- ships

ship=class()
ship.radius=2

function ship:spawn(scn,x,y)
	local s=self:new()
	s.hp=self.init_hp
	s.x=x
	s.y=y
	assert(s.col != nil)
	assert(s.spd != nil)
	s:init(scn)
	return s
end

function ship:init(scn)
end

function ship:update(scn)
	local dx,dy = self:input(scn)
	local spd=self.spd
	self.x+=dx*spd
	self.y+=dy*spd
end

function ship:input(scn)
	return 0,0
end

function ship:draw(scn)
	local hp=self.hp
	local x=self.x
	local y=self.y
	local r=self.radius
	local col=self.col
	
	if hp > 2 then
		circfill(x,y,r,col)
	elseif hp == 2 then
		pset(x,y,col)
		circ(x,y,r,col)
	elseif hp == 1 then
		circ(x,y,r,col)
	end
end


-- pship: player
pship=class(ship)
pship.init_hp=2
pship.col=7
pship.spd=1

function pship:input()
	local dx=0
	local dy=0
	if (btn(0)) dx-=1
	if (btn(1)) dx+=1
	if (btn(2)) dy-=1
	if (btn(3)) dy+=1
	return dx,dy
end


-- eship: enemy base
eship=class(ship)

-- eship1
eship1=class(eship)
eship1.init_hp=1
eship1.col=8
eship1.spd=0.2

function eship1:input(scn)
	local x=self.x
	local y=self.y
	local px=scn.ps.x
	local py=scn.ps.y	
	return dir(px-x), dir(py-y)
end
-->8
-- weapons

weapon=class()

function weapon:make(scn)
	local w=self:new()
	w:init(scn)
	return w
end

function weapon:init(scn)
end

function weapon:update(scn)
end

function weapon:draw(scn)
end


-- cannon
cannon=class(weapon)

function cannon:init(scn)
end

function cannon:update(scn)
end
-->8
-- bullets

bullet=class()

function bullet:make(scn,x,y)
	local b=self:new()
	b:init(scn)
	return b
end

function bullet:init(scn)
end

function bullet:update(scn)
end

function bullet:draw(scn)
end


-- nbullet: normal bullet
nbullet=class(bullet)

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
