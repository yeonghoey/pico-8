pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- entry

cls()

function _init()
	main=tmain:new{}
end

function _update()
	main:update()
end

function _draw()
	main:draw()
end
-->8
-- core
tclass=(function()
	local ctor
	ctor=function(s,o)
		o=o or {}
		setmetatable(o,s)
		s.__index=s
		s.__call=ctor
		return o
	end
	return ctor({},{
		new=function(s,o)
			o=ctor(s,o)
			o:init()
			return o
		end,
		init=function(s)
		end,
	})
end)()

tfsm=tclass{
	entry=nil,
	states={},

	init=function(s)
		local ss={}
		for k,v in pairs(s.states) do
			ss[k]=v:new()
		end
		s.states=ss
		s.cur=nil
	end,
	current=function(s)
		if (s.cur==nil)	return nil
		return s.states[s.cur]
	end,

	start=function(s,o,entry)
		s.cur=entry or s.entry
		s.states[s.cur]:enter(s,o)
	end,
	trans=function(s,o,to)
		s.states[s.cur]:exit(s,o)
		s.cur=to
		s.states[s.cur]:enter(s,o)
	end,
	update=function(s,o)
		s.states[s.cur]:update(s,o)
	end,
	draw=function(s,o)
		s.states[s.cur]:draw(s,o)
	end,
}

tstate=tclass{
	init=function(s)end,
	enter=function(s,f,o)end,
	update=function(s,f,o)end,
	draw=function(s,f,o)end,
	exit=function(s,f,o)end,
}

tanim=tclass{
	frames={},
	length=nil,
	wrap="loop",

	init=function(s)
		s.org=nil
		s.t=1
	end,

	play=function(s,o)
		s:stop(o)
		s.org={}
		local maxn=1
		for k,v in pairs(s.frames) do
			maxn=max(maxn,#v)
			s.org[k]=o[k]
		end
		s.length=s.length or maxn
		s.t=1
	end,
	
	stop=function(s,o)
		if s.org==nil then
			return
		end
		for k,v in pairs(s.org) do
			o[k]=v
		end
		s.org=nil
	end,

	stopped=function(s)
		return s.org==nil
	end,

	update=function(s,o)
		if s:stopped() then
			return
		end
		if s.t>s.length then
			s:stop(o)
			return
		end
		for k,v in pairs(s.frames) do
			local wrap=v.wrap or s.wrap
			local wf=s[wrap]
			local i=wf(s.t,#v)
			o[k]=v[i]
		end
		s.t+=1
	end,

	-- wrap functions	
	loop=function(t,n)
		return (t-1)%n+1
	end,
	hold=function(t,n)
		return min(t,n)
	end,
}

tanimstate=tstate{
	frames=nil,
	length=nil,
	wrap=nil,
	finished=function(s,f,o)
	end,

	init=function(s)
		s.anim=tanim:new{
			frames=s.frames,
			length=s.length,
			wrap=s.wrap,
		}
	end,

	enter=function(s,f,o)
		s.anim:play(o)
	end,

	update=function(s,f,o)
		s.anim:update(o)
		if	s.anim:stopped() then
			s:finished(f,o)					
		end
	end,

	exit=function(s,f,o)
		s.anim:stop(o)
	end,
}

function normalized(x,y)
	if x==0 and y==0 then
		return x,y
	else
		mag=sqrt(x*x+y*y)
		return x/mag,y/mag
	end
end

function printc(str,x,y,col)
	print(str,
		x-#str*2,
		y-3,col)
end
-->8
-- game

tmain=tclass{
	init=function(s)
		money=0
		hud=thud:new{}
		game=tgame:new{}
		shop=tshop:new{}
		s.title=ttitle:new{}
		s.running=trunning:new{}
		s.shopping=tshopping:new{}
		s.state=s.title
	end,

	update=function(s)
		s.state:update()
	end,

	draw=function(s)
		s.state:draw()
	end,
}

ttitle=tclass{
	init=function(s)
		s.pressx=tlabel:new{
			str="press ❎ to start",
			align="center",
			x=64,
			y=32,
			col=7,
		}
	end,

	update=function(s)
		if btnp(5) then
			main.state=main.running
		end
	end,

	draw=function(s)
		cls()
		s.pressx:draw()
	end,
}

trunning=tclass{
	update=function(s)
		game:update()
		hud:update()
	end,

	draw=function(s)
		cls()
		game:draw()
		hud:draw()	
	end,
}

tshopping=tclass{
	update=function(s)
		shop:update()
	end,
	draw=function(s)
		game:draw()
		hud:draw()
		shop:draw()
	end,
}

tlabel=tclass{
	draw=function(s)
		local str=s.str
		local x=s.x
		local y=s.y
		local col=s.col
		if s.align=="center" then
			x=x-#str*2
		elseif s.align=="right" then
			x=x-#str*4
		end
		print(str,x,y,col)
	end,
}

tshop=tclass{
	mar_x=6,
	pad_x=4,
	y0=30,
	win_h=48,
	wincol=5,
	curcol=10,

	init=function(s)
		s.win_w=(128
			-s.mar_x*2
			-s.pad_x*2)/3
		s.cur=1
		s.items={
			{
				lines={
					"bullet","speed",
				},
				cost=2,
			},
			{
				lines={
					"cannon","+1",
				},
				cost=3,
			},
			{
				lines={
					"hp","+1",
				},
				cost=1
			},
		}
	end,
	
	update=function(s)
		if btnp(0) then
			s.cur-=1
		end
		if btnp(1) then
			s.cur+=1
		end
		s.cur=mid(1,s.cur,3)
	end,

	draw=function(s)
		s:draw_slot(1)
		s:draw_slot(2)
		s:draw_slot(3)
		s:draw_cursor()
		s:draw_guide()
	end,
	
	draw_slot=function(s,num)
		s:draw_window(num)
		s:draw_item(num)
	end,
	
	draw_window=function(s,num)
		rect(
			s:winarg(num,0,s.wincol))
		rectfill(
			s:winarg(num,1,0))
		rect(
			s:winarg(num,3,s.wincol))
	end,
	
	draw_item=function(s,num)
		local item=s.items[num]
		local x0,y0,x1,y1=
			s:winarg(num,0)
		s:draw_item_lines(
			item.lines,x0,y0,x1,y1)
		s:draw_item_cost(
			item.cost,x0,y0,x1,y1)
	end,
	
	draw_item_lines=function(s,
			lines,x0,y0,x1,y1)
		local n=#lines
		local xc=(x0+x1)/2+2
		local yc=y0+20
		for i=1,n do
			local yos=-n*3+(i-1)*6
			printc(lines[i],
				xc,yc+yos,s.wincol)
		end
	end,
	
	draw_item_cost=function(s,
			cost,x0,y0,x1,y1)
		local xc=(x0+x1)/2-2
		local yc=y0+35
		printc("● "..cost,
			xc,yc,s.wincol)
	end,

	draw_cursor=function(s)
		rect(
			s:winarg(
				s.cur,1,s.curcol))
		rect(
			s:winarg(
				s.cur,2,s.curcol))
	end,
	
	draw_guide=function(s)
		local x0,y0=80,86
		local x1,y1=x0+42,y0+16
		rectfill(x0,y0,x1,y1,
			s.wincol)
		rectfill(x0+1,y0+1,x1-1,y1-1,
			0)		
		print("confirm ❎",
			x0+2,y0+2,s.wincol)
		print("skip 🅾️",
			x0+14,y0+10,s.wincol)
	end,

	winarg=function(
			s,num,os,col)
		local x0=
			s.mar_x+
			s.pad_x*(num-1)+
			s.win_w*(num-1)+os
		local x1=x0+s.win_w-os*2
		local y0=s.y0+os
		local y1=y0+s.win_h-os*2
		return x0,y0,x1,y1,col
	end,
}

thud=tclass{
	init=function(s)
		s.money=tlabel_money:new{}		
		s.wave=tlabel_wave:new{}
	end,

	on_wave_start=function(s)
		local k=wave.num
		local n=#wavespecs
		s.wave.str="wave "..k.."/"..n
		s.wave:blink()
	end,
	
	update=function(s)
		s.money:update()
		s.wave:update()
	end,
	
	draw=function(s)
		s.money:draw()
		s.wave:draw()
	end,
}

tlabel_money=tlabel{
	str="● 0",
	align="left",
	x=3,
	y=3,
	col=5,
	
	update=function(s)
	end,
}

tlabel_wave=tlabel{
	str="wave 0/0",
	align="right",
	x=125,
	y=3,
	col=5,

	init=function(s)
		s.fsm=tlabel_wave_fsm:new{}
		s.fsm:start(s)
	end,
	
	update=function(s)
		s.fsm:update(s)
	end,
	
	blink=function(s)
		s.fsm:trans(s,"blinking")
	end,
}

tlabel_wave_fsm=tfsm{
	entry="idle",
	states={
		["idle"]=tstate{},
		["blinking"]=tanimstate{
			frames={
				col={
					5,5,5,5,5,
					10,10,10,10,10,
					5,5,5,5,5,
					10,10,10,10,10,
					5,5,5,5,5,
					10,10,10,10,10,
					5,5,5,5,5,
					10,10,10,10,10,
				}
			},
			finished=function(s,f,o)
				f:trans(o,"idle")
			end,
		}
	}
}

tgame=tclass{
	init=function(s)
		cannon_cooldown_duration=30
		invincible_duration=30
		area=tarea:new{}
		pship=tpship:new{
			hp=2,x=64,y=64,
		}
		eships={}
		bullets={}
		wave=twave:new{}
		wave:spawn_next()
	end,

	update=function(s)
		s:check_bullets()
		s:check_eships()
		for b in all(bullets) do
			b:update()
		end
		for e in all(eships) do
			e:update()
		end	
		pship:update()
	end,

	check_bullets=function(s)
		for b in all(bullets) do
			if area:out(b.x,b.y) then
				del(bullets,b)
			else
				for e in all(eships) do
					if s:overlap(b,e) then
						e:hit(b.damage)
						del(bullets,b)
					end
				end		
			end
		end
	end,

 check_eships=function(s)
		local p=pship
		for e in all(eships) do
			if s:overlap(p,e) then
				local dx,dy=normalized(
					p.x-e.x, p.y-e.y)
				p:collide(dx,dy)
				e:collide(-dx,-dy)
			end
		end
	end,

	overlap=function(s,a,b)
		local ax,ay=a.x,a.y
		local bx,by=b.x,b.y
		local ar=a.radius or 0
		local br=b.radius or 0
		return
			abs(ax-bx)<=ar+br and
			abs(ay-by)<=ar+br
	end,

	draw=function(s)
		area:draw()
		for b in all(bullets) do
			b:draw()
		end
		for e in all(eships) do
			e:draw()
		end	
		pship:draw()
	end,
}

twave=tclass{
	init=function(s)
		s.num=0
	end,

	spawn_next=function(s)
		s.num+=1
		if s.num<=#wavespecs then
			local spec=wavespecs[s.num]
			for arg in all(spec) do
				s:spawn_eship(unpack(arg))
			end
			s:on_wave_start()
		else	
			s:on_clear()
		end
	end,

 spawn_eship=function(s,
 	teship0,hp,x,y)
		add(eships,teship0:new{
			hp=hp,x=x,y=y,
		})
	end,
	
	on_wave_start=function(s)
		hud:on_wave_start()
	end,

	on_clear=function(s)
	end,
}

tarea=tclass{
	x0=12,
	y0=12,
	x1=112,
	y1=112,
	col=5,
	thickness=3,

	out=function(s,x,y,os)
		local os=os or 0
		os+=s.thickness
		return
			x<s.x0+os or
			x>s.x1-os or
			y<s.y0+os or
			y>s.y1-os
	end,
	
	draw=function(s)
		for i=1,s.thickness do
			if i%2==1 then
				rect(
					s.x0+i-1,s.y0+i-1,
					s.x1-i+1,s.y1-i+1,
					s.col)
			end
		end
	end
}

tship=tclass{
	radius=2,
	bump=3,

	hit=function(s,damage)
		s.hp-=damage
		s:on_hit()
		if s.hp<=0 then
			s:on_destroy()
		end
	end,

	collide=function(s,dx,dy)
		s.hp-=1
		s:on_collide()
		if s.hp<=0 then
			s:on_destroy()
		else
			s:move(dx,dy,s.bump)
		end
	end,
	
	on_hit=function(s)
 		sfx(sfx_hit)
	end,
	
	on_collide=function(s)
		if s==pship then
			sfx(sfx_collide)
		end
	end,

	on_destroy=function(s)
		if s!=pship then
			del(eships,s)
			sfx(sfx_destroy)
			if #eships==0 then
				wave:spawn_next()
			end
		end
	end,

	move=function(s,dx,dy,spd)
		local nx=s.x+dx*spd
		local ny=s.y+dy*spd
		local r=s.radius
		if area:out(nx,ny,r) then
			s.x-=dx*s.bump
			s.y-=dy*s.bump
			sfx(sfx_bump)
		else
			s.x,s.y=nx,ny
		end
	end,

	draw=function(s)
		local hp=s.hp
		local x=s.x
		local y=s.y
		local r=s.radius
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
	col=7,
	spd=1,
	
	init=function(s)
		s.cannon=tcannon:new{}
	end,

	update=function(s)
		local dx,dy=s:input()
		s:move(dx,dy,s.spd)
		s.cannon:update()
	end,

	input=function(s)
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
	
	draw=function(s)
		tship.draw(s)
		s.cannon:draw()
	end,
}

tcannon=tclass{
	init=function(s)
		s.barrels={}
		s.cooldown=
			cannon_cooldown_duration
		s:add_barrel()
	end,
	
	update=function(s)
		s:update_rotate()
		s:update_fire()
	end,
	
	draw=function(s)
		for b in all(s.barrels) do
			b:draw()
		end
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
		s.cooldown-=1
		if s.cooldown>0 then
			return
		end
		s.cooldown=
			cannon_cooldown_duration
		for b in all(s.barrels) do
			b:fire()
		end
	end,
}

tbarrel=tclass{
	col=7,
	dirs={
		{0,-1},{1,0},{0,1},{-1,0},
	},
	
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
		local b=tbullet:new{
			x=x,y=y,dx=dx,dy=dy,
		}
		add(bullets,b)
		sfx(sfx_fire)
	end,
	
	draw=function(s,di)
		local x0,y0=s:dirpos(3)
		local x1,y1=s:dirpos(4)
		local col=s.col
		line(x0,y0,x1,y1,col)
	end,
}

tbullet=tclass{
	radius=1,
	spd=2,
	col=7,
	damage=1,

	update=function(s)
		s:move(s.dx,s.dy,s.spd)
	end,

	move=function(s)
		s.x+=s.dx*s.spd
		s.y+=s.dy*s.spd
	end,
	
	draw=function(s)
		local x=s.x
		local y=s.y
		local col=s.col
		pset(x,y,col)
	end,
}

teship=tship{}

teship1=teship{
	col=8,
	spd=0.2,
	
	update=function(s)
		local dx,dy=s:to_pship()
		s:move(dx,dy,s.spd)
	end,

	to_pship=function(s,x,y)
		local px=pship.x
		local py=pship.y
		return normalized(
			px-s.x,py-s.y)
	end
}
-->8
-- data

wavespecs={}

wavespecs[1]={
	{teship1,1,20,20},
	{teship1,1,100,20},
	{teship1,1,20,100},
	{teship1,1,100,100},
}

wavespecs[2]={
	{teship1,2,20,20},
	{teship1,2,100,20},
	{teship1,2,20,100},
	{teship1,2,100,100},
}

wavespecs[3]={
	{teship1,3,20,20},
	{teship1,3,100,20},
	{teship1,3,20,100},
	{teship1,3,100,100},
}

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
0001000000000340500f0500f0502365016620110201f0501b1202715000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000196501a6301c6301f6401662032650346201e64018650136502464013640176401b6501065013650166503b600186201e600136002360013600286000f6001a6000000000000000000000000000
