pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
cls()

root={}

function _init()
	root.scene=scene:new()
end

function _update()
	root.scene:update()
end

function _draw()
	root.scene:draw()
end
-->8
-- utils
class=(function()
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

fsm=class{
	init=function(s,start)
		assert(s.state==nil)
		s.state=start
		s[s.state].enter(s)
	end,
	update=function(s)
		s[s.state].update(s)
		local st=s.state
		local to=s[st].trans(s)
		if to!=nil then
			s[st].exit(s)
			s[to].enter(s)
			s.state=to
		end
	end,
	draw=function(s)
		s[s.state].draw(s)
	end,
}

noop=function()end

state=class{
	enter=noop,
	update=noop,
	draw=noop,
	exit=noop,
	trans=noop,
}

event=class{
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
-- classes
scene=fsm{
	init=function(s)
		fsm.init(s,"title")
	end,

	["title"]=state{
		draw=function(s)
			cls()
			print("press ❎ to start")
		end,
		trans=function(s)
			if(btnp(5)) return "main"
		end,
	},

	["main"]=state{
		enter=function(s)
			s.game=game:new()
		end,
		update=function(s)
			s.game:update()
		end,
		draw=function(s)
			cls()
			s.game:draw()
		end,
	}
}

game=fsm{
	init=function(s)
		s.eships={}
		s.bullets={}

		s.on_hit_pship=
			function(p)
				sfx(3)
			end
			
		s.on_destroy_pship=
			function(p)
				--todo
			end

		s.on_destroy_eship=
			function(e)
				del(s.eships,e)
				sfx(0)
			end,

		s:spawn_area()
		s:spawn_pship(64,64)
		-- test
		s:spawn_eship(eship1,10,10)
		s:spawn_eship(eship1,100,10)
		s:spawn_eship(eship1,10,100)
		s:spawn_eship(eship1,100,100)
		fsm.init(s,"play")
	end,
	
	spawn_area=function(s)
		s.area=area:new()
	end,
	
	spawn_pship=function(s,x,y)
		local p=pship:new{
			game=s,x=x,y=y
		}
		p.on_hit:add(
			s.on_hit_pship)
		s.pship=p		
	end,
	
	spawn_eship=function(
			s,eshipt,x,y)
		local e=eshipt:new{
			game=s,x=x,y=y,
		}
		e.on_destroy:add(
			s.on_destroy_eship)
		add(s.eships,e)
	end,
	
	spawn_bullet=function(
			s,x,y,dx,dy)
		add(s.bullets,bullet:new{
			x=x,y=y,dx=dx,dy=dy,
		})
	end,
	
	check_bullets=function(s)
		for b in all(s.bullets) do
			if s.area:out(b.x,b.y) then
				del(s.bullets,b)
			else
				for e in all(s.eships) do
					if s:collide(b,e) then
						e:hit(b.damage)
						del(s.bullets,b)
					end
				end		
			end
		end
	end,

	check_eships=function(s)
		local p=s.pship
		for e in all(s.eships) do
			if s:collide(p,e) then
				printh("♥")
				p:hit(1)
				e:hit(1)
			end
		end
	end,

	collide=function(s,a,b)
		local ax,ay=a.x,a.y
		local bx,by=b.x,b.y
		local ar=a.rad or 0
		local br=b.rad or 0
		return
			abs(ax-bx)<=ar+br and
			abs(ay-by)<=ar+br
	end,
	
	["play"]=state{
		update=function(s)
			s:check_bullets()
			s:check_eships()
			foreach(s.eships,sf.update)
			foreach(s.bullets,sf.update)
			s.area:update()
			s.pship:update()
		end,
		draw=function(s)
			foreach(s.eships,sf.draw)
			foreach(s.bullets,sf.draw)
			s.area:draw()
			s.pship:draw()
		end,
	}
}

area=fsm{
	thickness=3,
	col=5,

	init=function(s)
		s.x0=0
		s.y0=0
		s.x1=127
		s.y1=127
		fsm.init(s,"main")
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

	["main"]=state{
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
}

ship=fsm{
	init_hp=1,
	rad=2,
	col=0,
	spd=0,
	bump=3,
	
	init=function(s,arg)
		s.game=arg.game
		s.hp=s.init_hp
		s.x=arg.x
		s.y=arg.y
		s.on_hit=event:new()
		s.on_destroy=event:new()
		fsm.init(s,arg.start)
	end,
	
	hit=function(s)
		s.hp-=1
		s.on_hit:invoke(s)
		if s.hp<=0 then
			s.on_destroy:invoke(s)
		end
	end,

	move=function(s)
		local dx,dy=s:move_input()
		local nx=s.x+dx*s.spd
		local ny=s.y+dy*s.spd
		local area=s.game.area
		if area:out(nx,ny,s.rad) then
			s.x-=dx*s.bump
			s.y-=dy*s.bump
			sfx(2)
		else
			s.x,s.y=nx,ny
		end
	end,

	render=function(s)
		local hp=s.hp
		local x=s.x
		local y=s.y
		local r=s.rad
		local col=s.col	
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

pship=ship{
	init_hp=2,
	col=7,
	spd=1,
	
	init=function(s,arg)
		arg.start="alive"
		ship.init(s,arg)
		s.cannon=cannon:new{
			game=arg.game,
			pship=s,
			cooldown=30,
		}
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

	["alive"]=state{
		update=function(s)
			s:move()
			s.cannon:update()
		end,
		draw=function(s)
			s:render()
			s.cannon:draw()
		end,
	}
}

cannon=fsm{
	init=function(s,arg)
		s.game=arg.game
		s.pship=arg.pship
		s.cooldown=arg.cooldown
		s.barrels={}
		s:add_barrel()
		fsm.init(s,"active")
	end,
	
	add_barrel=function(s)
		local di=1
		local n=#s.barrels
		if n>0 then
			local lb=s.barrels[n]
			di=lb:nextdi(1)
		end
		local b=barrel:new{
			game=s.game,
			pship=s.pship,
			di=di
		}
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
		s.cooldown_t=s.cooldown
		foreach(s.barrels,sf.fire)
	end,
	
	["active"]=state{
		enter=function(s)
			s.cooldown_t=s.cooldown
		end,
		update=function(s)
			s:update_rotate()
			s:update_fire()
		end,
		draw=function(s)
			foreach(s.barrels,sf.draw)
		end,
	}
}

barrel=fsm{
	dirs={ -- n/e/s/w
		{0,-1},{1,0},{0,1},{-1,0},
	},
	col=7,

	init=function(s,arg)
		s.game=arg.game
		s.pship=arg.pship
		s.di=arg.di
		fsm.init(s,"active")
	end,
	
	nextdi=function(s,cw)
		local n=#barrel.dirs
		local ndi=s.di+cw
		if (ndi<1) ndi=n
		if (ndi>n) ndi=1
		return ndi
	end,
	
	dirpos=function(s,k)
		local px=s.pship.x
		local py=s.pship.y
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
		s.game:spawn_bullet(
			x,y,dx,dy)
		sfx(1)
	end,
	
	["active"]=state{
		draw=function(s,di)
			local x0,y0=s:dirpos(3)
			local x1,y1=s:dirpos(4)
			local col=s.col
			line(x0,y0,x1,y1,col)
		end,
	}
}

bullet=fsm{
	rad=1,
	spd=2,
	col=7,
	damage=1,
	
	init=function(s,arg)
		s.x=arg.x
		s.y=arg.y
		s.dx=arg.dx
		s.dy=arg.dy
		fsm.init(s,"moving")
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
	
	["moving"]=state{
		update=function(s)
			s:move()
		end,
		draw=function(s)
			s:render()
		end,
	}
}

eship1=ship{
	init_hp=1,
	col=8,
	spd=0.2,

	init=function(s,arg)
		arg.start="alive"
		ship.init(s, arg)
	end,

	move_input=function(s)
		local x=s.x
		local y=s.y
		local px=s.game.pship.x
		local py=s.game.pship.y
		return norm(px-x,py-y)
	end,

	["alive"]=state{
		update=function(s)
			s:move()
		end,
		draw=function(s)
			s:render()
		end,
	}
}


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
