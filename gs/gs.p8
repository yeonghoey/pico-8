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
	c.super=base
	c.new = function (self)
		o={}
		setmetatable(o,self)
		return o
	end

	setmetatable(c,base)
	return c
end

function norm(x,y)
	if x==0 and y==0 then
		return x,y
	else
		mag=sqrt(x*x+y*y)
		return x/mag,y/mag
	end
end
-->8
-- scenes

scene=class()

function scene:make(...)
	local scn=self:new()
	scn:init(...)
	return scn
end

function scene:init()
end

function scene:update()
end

function scene:draw()
end

--gscene: game scene
gscene=class(scene)

function gscene:init()
	self.bullets={}
	self.eships={}
	
	self:spawn_ps()
	-- test
	self:spawn_es(eship1,10,10)
	self:spawn_es(eship1,100,10)
	self:spawn_es(eship1,10,100)
	self:spawn_es(eship1,100,100)
	
	self:spawn_blt(10,10,1,0)
end

function gscene:update()
	for es in all(self.eships) do
		es:update(self)
	end
	for blt in all(self.bullets) do
		blt:update(self)
	end
	self.ps:update(self)
end

function gscene:draw()
	cls()
	for es in all(self.eships) do
		es:draw(self)
	end
	for blt in all(self.bullets) do
		blt:draw(self)
	end
	self.ps:draw(self)
end

function gscene:spawn_ps()
	local ps=pship:spawn(self,64,64)
	self.ps=ps
end

function gscene:spawn_es(estype,x,y)
	local es=estype:spawn(self,x,y)
	add(self.eships,es)
end

function gscene:spawn_blt(x,y,dx,dy)
	local blt=bullet:spawn(self,x,y,dx,dy)
	add(self.bullets,blt)
end

--tscene: title scene
tscene=class(scene)
-->8
-- gobject

gobject=class()

function gobject:spawn(scn,...)
	local go=self:new()
	go:init(scn,...)
	return go
end

function gobject:init(scn)
end

function gobject:update(scn)
end

function gobject:draw(scn)
end

-->8
-- ships

ship=class(gobject)
ship.radius=2

function ship:init(scn,x,y)
	self.hp=self.init_hp
	self.x=x
	self.y=y
	assert(self.col != nil)
	assert(self.spd != nil)
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

function pship:init(scn,...)
	self.super.init(self,scn,...)

	self.can=cannon:new()
	self.can:init()
end

function pship:update(scn)
	self.super.update(self,scn)
	self.can:update()
end

function pship:draw(scn)
	self.super.draw(self,scn)
	self.can:draw(self.x,self.y)
end

function pship:input()
	local dx=0
	local dy=0
	if (btn(0)) dx-=1
	if (btn(1)) dx+=1
	if (btn(2)) dy-=1
	if (btn(3)) dy+=1

	if dx!=0 and dy!=0 then
		-- digonal
		dx*=0.707
		dy*=0.707
	end

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
	return norm(px-x, py-y)
end
-->8
-- cannon

cannon=class()

function cannon:init()
	self.barrels={}
end

function cannon:update()
	if btnp(4) then
		self:rotate(false)
	end
	
	if btnp(5) then
		self:rotate(true)
	end
end

function cannon:draw(px,py)
	line(px,py+2,px,py+3,7)
end

function cannon:rotate(cw)
end


-- barrel
barrel=class()
barrel.dirs={{0,-1},{1,0},{0,1},{-1,0}}


-->8
-- bullet

bullet=class(gobject)
bullet.radius=1
bullet.spd=1
bullet.col=7

function bullet:init(scn,x,y,dx,dy)
	self.x=x
	self.y=y
	self.dx=dx
	self.dy=dy
end

function bullet:update(scn)
	local spd=self.spd
	self.x+=self.dx*spd
	self.y+=self.dy*spd
end

function bullet:draw(scn)
	local x=self.x
	local y=self.y
	local col=self.col
	pset(x,y,col)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
