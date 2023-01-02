pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
cls()

function _init()
	spawn_scene()
end

function _update()
	scene:update()
end

function _draw()
	scene:draw()
end
-->8
-- core
tclass=(function()
	local f
	f=function(s,o)
		o=o or {}
		setmetatable(o,s)
		s.__index=s
		s.__call=f
		return o
	end
	return f({},{
		new=function(s,...)
			local o=s()
			o:init(...)
			return o
		end,
	})
end)()

tfsm=tclass{
	start=function(s,init_state)
		assert(s.state==nil)
		s.state=init_state
		s[s.state].enter(s)
	end,
	trans=function(s,to)
		local st=s.state
		s[st].exit(s)
		s[to].enter(s)
		s.state=to
	end,
	update=function(s)
		local re=true
		while re do
			re=s[s.state].update(s)
		end
	end,
	draw=function(s)
		s[s.state].draw(s)
	end,
}

noop=function()end

tstate=tclass{
	enter=noop,
	update=noop,
	draw=noop,
	exit=noop,
}

tevent=tclass{
	init=function(s)
		s.ls={}
	end,
	add=function(s,f)
		add(s.ls,f)
	end,
	del=function(s,f)
		del(s.ls,f)
	end,
	invoke=function(s,...)
		for f in all(s.ls) do
			f(...)
		end
	end,
}

-- self func:foreach helper
sf={}
setmetatable(sf,{
	__index=function(t,key)
		t[key]=function(s)
			return s[key](s)
		end
		return t[key]
	end
})

function norm(x,y)
	if x==0 and y==0 then
		return x,y
	else
		mag=sqrt(x*x+y*y)
		return x/mag,y/mag
	end
end


-->8
-- types
tscene=tfsm{
	init=function(s)
		s:start("title")
	end,
}

tscene["title"]=tstate{
	update=function(s)
		if	btnp(5) then
			s:trans("main")
		end
	end,
	draw=function(s)
		cls()
		print("press ❎ to start")
	end,
}

tscene["main"]=tstate{
	enter=function(s)
		spawn_game()
	end,
	update=function(s)
		game:update()
	end,
	draw=function(s)
		cls()
		game:draw()
	end,
}


tgame=tfsm{
	init=function(s)
		spawn_area()
		spawn_pship(64,64)
		-- test
		spawn_eship(teship1,10,10)
		spawn_eship(teship1,100,10)
		spawn_eship(teship1,10,100)
		spawn_eship(teship1,100,100)
		s:start("play")
	end,
}

tgame["play"]=tstate{
	update=function(s)
		check_bullets()
		check_eships()
		foreach(eships,sf.update)
		foreach(bullets,sf.update)
		area:update()
		pship:update()
	end,
	draw=function(s)
		foreach(eships,sf.draw)
		foreach(bullets,sf.draw)
		area:draw()
		pship:draw()
	end,
}


tarea=tfsm{
	col=5,
	thickness=3,

	init=function(s)
		s.x0=0
		s.y0=0
		s.x1=127
		s.y1=127
		s:start("main")
	end,
	
	out=function(s,x,y,os)
		local os=os or 0
		os+=s.thickness
		return 
			x<s.x0+os or
			x>s.x1-os or
			y<s.y0+os or
			y>s.y1-os 
	end,
}

tarea["main"]=tstate{
	draw=function(s)
		for i=1,s.thickness do
			if i%2==1 then
				rect(
					s.x0+i-1,s.y0+i-1,
					s.x1-i+1,s.y1-i+1,
					s.col)
			end
		end
	end,
}


tship=tfsm{
	init_hp=1,
	rad=2,
	col=0,
	spd=0,
	bump=3,
	
	init_ship=function(s,arg)
		s.hp=s.init_hp
		s.x=arg.x
		s.y=arg.y
		s.on_hit=tevent:new()
		s.on_collide=tevent:new()
		s.on_destroy=tevent:new()
	end,
	
	hit=function(s,damage)
		s.hp-=damage
		s.justdamaged=true
		s.on_hit:invoke(s)
		if s.hp<=0 then
			s.on_destroy:invoke(s)
		end
	end,

	collide=function(s,dx,dy)
		s.hp-=1
		s.justdamaged=true
		s.on_collide:invoke(s)
		if s.hp<=0 then
			s.on_destroy:invoke(s)
		else
			s:move(dx,dy,s.bump)
		end
	end,
	
	move=function(s,dx,dy,spd)
		local nx=s.x+dx*spd
		local ny=s.y+dy*spd
		if area:out(nx,ny,s.rad) then
			s.x-=dx*s.bump
			s.y-=dy*s.bump
			sfx(sfx_bump)
		else
			s.x,s.y=nx,ny
		end
	end,

	render=function(s,col)
		local hp=s.hp
		local x=s.x
		local y=s.y
		local r=s.rad
		local col=col or s.col	
		if hp > 2 then
			circfill(x,y,r,col)
		elseif hp == 2 then
			pset(x,y,col)
			circ(x,y,r,col)
		elseif hp == 1 then
			circ(x,y,r,col)
		end
	end,
}


tpship=tship{
	init_hp=2,
	col=7,
	spd=1,
	
	init=function(s,arg)
		s:init_ship(arg)
		s.cannon=tcannon:new()
		s:start("alive")
	end,

	move_input=function(s)
		local dx=0
		local dy=0
		if (btn(0)) dx-=1
		if (btn(1)) dx+=1
		if (btn(2)) dy-=1
		if (btn(3)) dy+=1
		if dx!=0 and dy!=0 then
			dx*=0.707
			dy*=0.707
		end
		return dx,dy
	end,
}

tpship["alive"]=tstate{
	enter=function(s)
		s.damaged=false
	end,
	update=function(s)
		local dx,dy=s:move_input()
		s:move(dx,dy,s.spd)
		s.cannon:update()
	end,
	trans=function(s)
		if s.justdamaged then
			return "invincible"
		end
	end,
	draw=function(s)
		s:render()
		s.cannon:draw()
	end,
}

tpship["invincible"]=tstate{
	enter=function(s)
		s.invincible_t=invincible_d
	end,
	update=function(s)
		s.invincible_t-=1
	end,
	trans=function(s)
		if s.invincible_t<=0 then
			return "alive"
		end
	end,
	draw=function(s)
		local col=s.col
		if (s.invincible_t%2) col=0
		s:render(col)
	end,
}


tcannon=tfsm{
	init=function(s)
		s.barrels={}
		s:add_barrel()
		s:start("active")
	end,
	
	add_barrel=function(s)
		local di=1
		local n=#s.barrels
		if n>0 then
			local lb=s.barrels[n]
			di=lb:nextdi(1)
		end
		local b=tbarrel:new{di=di}
		add(s.barrels,b)
	end,
	
	update_rotate=function(s)
		if(btnp(4)) s:rotate(-1)
		if(btnp(5)) s:rotate(1)
	end,
	
	rotate=function(s,cw)
		for b in all(s.barrels) do
			b:rotate(cw)
		end
	end,

	update_fire=function(s)
		s.cooldown_t-=1
		if s.cooldown_t>0 then
			return
		end
		s.cooldown_t=cooldown_d
		foreach(s.barrels,sf.fire)
	end,
}

	
tcannon["active"]=tstate{
	enter=function(s)
		s.cooldown_t=cooldown_d
	end,
	update=function(s)
		s:update_rotate()
		s:update_fire()
	end,
	draw=function(s)
		foreach(s.barrels,sf.draw)
	end,
}


tbarrel=tfsm{
	col=7,
	dirs={ -- n/e/s/w
		{0,-1},{1,0},{0,1},{-1,0},
	},

	init=function(s,arg)
		s.di=arg.di
		s:start("active")
	end,
	
	nextdi=function(s,cw)
		local n=#s.dirs
		local ndi=s.di+cw
		if (ndi<1) ndi=n
		if (ndi>n) ndi=1
		return ndi
	end,
	
	dirpos=function(s,k)
		local px=pship.x
		local py=pship.y
		local dx,dy=s:dir()
		return px+dx*k,py+dy*k
	end,
	
	dir=function(s)
		return unpack(s.dirs[s.di])
	end,
	
	rotate=function(s,cw)
		s.di=s:nextdi(cw)
	end,
	
	fire=function(s)
		local x,y=s:dirpos(4)
		local dx,dy=s:dir()
		spawn_bullet(x,y,dx,dy)
		sfx(sfx_fire)
	end,

}

tbarrel["active"]=tstate{
	draw=function(s,di)
		local x0,y0=s:dirpos(3)
		local x1,y1=s:dirpos(4)
		local col=s.col
		line(x0,y0,x1,y1,col)
	end,
}

tbullet=tfsm{
	rad=1,
	spd=2,
	col=7,
	damage=1,

	init=function(s,arg)
		s.x=arg.x
		s.y=arg.y
		s.dx=arg.dx
		s.dy=arg.dy
		s:start("moving")
	end,
	
	move=function(s)
		s.x+=s.dx*s.spd
		s.y+=s.dy*s.spd
	end,
	
	render=function(s)
		local x=s.x
		local y=s.y
		local col=s.col
		pset(x,y,col)
	end,
}

tbullet["moving"]=tstate{
	update=function(s)
		s:move(s.dx,s.dy,s.spd)
	end,
	draw=function(s)
		s:render()
	end,
}


teship1=tship{
	init_hp=3,
	col=8,
	spd=0.2,

	init=function(s,arg)
		s:init_ship(arg)
		s:start("alive")
	end,

	move_input=function(s)
		local x=s.x
		local y=s.y
		local px=pship.x
		local py=pship.y
		return norm(px-x,py-y)
	end,
}

teship1["alive"]=tstate{
	update=function(s)
		local dx,dy=s:move_input()
		s:move(dx,dy,s.spd)
	end,
	draw=function(s)
		s:render()
	end,
}
-->8
-- globals

function spawn_scene()
	scene=tscene:new()
end

function spawn_game()
	eships={}
	bullets={}
	reset_gameparams()
	game=tgame:new()
end

function reset_gameparams()
	cooldown_d=30
	invincible_d=30
end

function spawn_area()
	area=tarea:new()
end

function spawn_pship(x,y)
	pship=tpship:new{x=x,y=y}
	pship.on_hit:add(
		on_hit_pship)
	pship.on_collide:add(
		on_collide_pship)
end

function spawn_eship(
		teship,x,y)
	local e=teship:new{x=x,y=y}
	e.on_destroy:add(
		on_destroy_eship)
	add(eships,e)
end

function	spawn_bullet(
		x,y,dx,dy)
	local b=tbullet:new{
			x=x,y=y,dx=dx,dy=dy}
	add(bullets,b)
end

function on_hit_pship(p)
	sfx(sfx_hit)
end

function on_collide_pship(p,e)
	sfx(sfx_collide)
end
	
function on_destroy_pship(p)
end

function on_destroy_eship(e)
	del(eships,e)
	sfx(sfx_destroy)
end

function check_bullets()
	for b in all(bullets) do
		if area:out(b.x,b.y) then
			del(bullets,b)
		else
			for e in all(eships) do
				if overlap(b,e) then
					e:hit(b.damage)
					del(bullets,b)
				end
			end		
		end
	end
end

function check_eships(s)
	local p=pship
	for e in all(eships) do
		if overlap(p,e) then
			local dx,dy=norm(
				p.x-e.x, p.y-e.y)
			p:collide(dx,dy)
			e:collide(-dx,-dy)
		end
	end
end

function overlap(a,b)
	local ax,ay=a.x,a.y
	local bx,by=b.x,b.y
	local ar=a.rad or 0
	local br=b.rad or 0
	return
		abs(ax-bx)<=ar+br and
		abs(ay-by)<=ar+br
end
-->8
-- constants

-- sfx
sfx_destroy=0
sfx_fire=1
sfx_bump=2
sfx_hit=3
sfx_collide=4

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003605028050270502c0503205035050360502f0502d0502c0503c0502b0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000230500000034050370503a0503c0503f0503f050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003b0503705028050290501f0501c0501a0501905020050270502a0503300035000380003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000340503a05017650236501665018650236502d6503305000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000196501a6301c6301f6401662032650346201e64018650136502464013640176401b6501065013650166503b600186201e600136002360013600286000f6001a6000000000000000000000000000
