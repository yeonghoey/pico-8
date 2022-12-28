pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- geometry survivor
-- by yeonghoey

function _init()
	current_scene=gscene:new()
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
	c.new = function (self,...)
		local o={}
		setmetatable(o,self)
		o:init(...)
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
	self:spawn_pship()
	-- test
	self:spawn_eship(eship1,10,10)
	self:spawn_eship(eship1,100,10)
	self:spawn_eship(eship1,10,100)
	self:spawn_eship(eship1,100,100)
end

function gscene:update()
	self:update_checkbullets()
	self:update_eships()
	self:update_bullets()
	self:update_pship()
end

function gscene:draw()
	cls()
	self:draw_eships()
	self:draw_bullets()
	self:draw_pship()
end

function gscene:spawn_pship()
	local ps=pship:new(self,64,64)
	self.ps=ps
end

function gscene:spawn_eship(estype,x,y)
	local es=estype:new(self,x,y)
	add(self.eships,es)
end

function gscene:spawn_bullet(x,y,dx,dy)
	local blt=bullet:new(self,x,y,dx,dy)
	add(self.bullets,blt)
end

function gscene:update_pship()
	self.ps:update(self)
end

function gscene:update_eships()
	for es in all(self.eships) do
		es:update(self)
	end
end

function gscene:update_bullets()
	for blt in all(self.bullets) do
		blt:update(self)
	end
end

function gscene:update_checkbullets()
	for blt in all(self.bullets) do
		for es in all(self.eships) do
			if self:checkbullet(blt,es) then
				self:on_hit(blt,es)
			end
		end
	end
end

function gscene:on_hit(blt,es)
	del(self.bullets,blt)
	es:hit(blt)
	if es:is_destroyed() then
		del(self.eships,es)
	end
end

function gscene:checkbullet(blt,es)
	local bx,by=blt.x,blt.y
	local ex,ey=es.x,es.y
	local er=es.radius
	return
		bx>=ex-er and
		bx<=ex+er and
		by>=ey-er and
		by<=ey+er
end

function gscene:draw_pship()
	self.ps:draw(self)
end

function gscene:draw_eships()
	for es in all(self.eships) do
		es:draw(self)
	end
end

function gscene:draw_bullets()
	for blt in all(self.bullets) do
		blt:draw(self)
	end
end

--tscene: title scene
tscene=class(scene)
-->8
-- ships

ship=class()
ship.radius=2

function ship:init(gscn,x,y)
	self.hp=self.init_hp
	self.x=x
	self.y=y
	assert(self.col != nil)
	assert(self.spd != nil)
end

function ship:update(gscn)
	local dx,dy = self:input(gscn)
	local spd=self.spd
	self.x+=dx*spd
	self.y+=dy*spd
end

function ship:input(gscn)
	return 0,0
end

function ship:draw(gscn)
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

function pship:init(gscn,...)
	self.super.init(self,gscn,...)
	self.cannon=cannon:new()
end

function pship:update(gscn)
	self.super.update(self,gscn)
	self.cannon:update(self,gscn)
end

function pship:draw(gscn)
	self.super.draw(self,gscn)
	self.cannon:draw(self,gscn)
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

function eship:hit(blt)
	self.hp-=1
end

function eship:is_destroyed()
	return self.hp<=0
end

-- eship1
eship1=class(eship)
eship1.init_hp=1
eship1.col=8
eship1.spd=0.2

function eship1:input(gscn)
	local x=self.x
	local y=self.y
	local px=gscn.ps.x
	local py=gscn.ps.y	
	return norm(px-x, py-y)
end
-->8
-- cannon

cannon=class()

function cannon:init()
	self.barrels={}
	self.cd_duration=30
	self.cd=self.cd_duration
	self:add_barrel()
end

function cannon:update(ps,gscn)
	self:update_rotate()
	self:update_fire(ps,gscn)
end

function cannon:draw(ps,gscn)
	for b in all(self.barrels) do
		b:draw(ps,gscn)
	end
end

function cannon:add_barrel()
	local b=barrel:new()
	local ri=1
	local n=#self.barrels
	if n>0 then
		local lb=self.barrels[n]
		ri=lb:next_ri()
	end
	b:init(ri)
	add(self.barrels,b)
end

function cannon:update_rotate()
	if btnp(4) then
		self:rotate(-1)
	end
	if btnp(5) then
		self:rotate(1)
	end
end

function cannon:update_fire(ps,gscn)
	self.cd-=1
	if self.cd>0 then
		return
	end

	self.cd=self.cd_duration
	for b in all(self.barrels) do
		b:fire(ps,gscn)
	end
end

function cannon:rotate(cw)
	for b in all(self.barrels) do
		b:rotate(cw)
	end
end


-- barrel
barrel=class()
barrel.col=7
barrel.dirs={
	{0,-1},
	{1,0},
	{0,1},
	{-1,0}
}

function barrel:init(ri)
	self.ri=ri
end

function barrel:rotate(cw)
	self.ri=self:next_ri(cw)
end

function barrel:fire(ps,gscn)
	local x,y=self:aimp(ps,4)
	local dx,dy=self:dir()
	gscn:spawn_bullet(x,y,dx,dy)
end

function barrel:next_ri(cw)
	local ri=self.ri
	local nri=ri+cw
	local n=#barrel.dirs
	if (nri<1) nri=n
	if (nri>n) nri=1
	return nri
end

function barrel:draw(ps,gscn)
	local x0,y0=self:aimp(ps,3)
	local x1,y1=self:aimp(ps,4)
	local col=self.col
	line(x0,y0,x1,y1,col)
end

function barrel:aimp(ps,k)
	local px,py=ps.x,ps.y
	local dx,dy=self:dir()
	return px+dx*k,py+dy*k
end

function barrel:dir()
	local ri=self.ri
	local dir=self.dirs[ri]
	return unpack(dir)
end
-->8
-- bullet

bullet=class()
bullet.radius=1
bullet.spd=2
bullet.col=7

function bullet:init(gscn,x,y,dx,dy)
	self.x=x
	self.y=y
	self.dx=dx
	self.dy=dy
end

function bullet:update(gscn)
	local spd=self.spd
	self.x+=self.dx*spd
	self.y+=self.dy*spd
end

function bullet:draw(gscn)
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
