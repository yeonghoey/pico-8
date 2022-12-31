pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
cls()

function _init()
	scene=new_scene()
end

function _update()
	scene:update()
end

function _draw()
	scene:draw()
end
-->8
-- core
function new_fsm()
	local states={}
	local noop=function()end
	local state_meta={
		__index={
			enter=noop,
			update=noop,
			draw=noop,
			exit=noop,		
			trans=noop,
		},
	}
	local entity_meta={
		__index={
			update=function(e)
				local st=e.state
				local to=states[st].trans(e)
				if to!=nil then
					states[st].exit(e)
					states[to].enter(e)
					e.state=to
				end
				states[e.state].update(e)
			end,
			draw=function(e)
				states[e.state].draw(e)
			end,
		},
	}
	return {
		add_state=function(s)
			local state=s.state
			assert(states[state]==nil)
			setmetatable(s,state_meta)
			states[state]=s
		end,
		new_entity=function(e)
			setmetatable(e,entity_meta)
			states[e.state].enter(e)
			return e
		end
	}
end
-->8
-- api
fsm=new_fsm()

function draw_title()
	cls()
	print("press ❎ to start")
end

function draw_main(game)
	cls()
	game:draw()
end

function draw_ship(ship)
	local hp=ship.hp
	local x=ship.x
	local y=ship.y
	local r=ship.r
	local col=ship.col	
	if hp > 2 then
		circfill(x,y,r,col)
	elseif hp == 2 then
		pset(x,y,col)
		circ(x,y,r,col)
	elseif hp == 1 then
		circ(x,y,r,col)
	end
end
-->8
-- scene
function new_scene()
	return fsm.new_entity{
		state="title",
	}
end

fsm.add_state{
	state="title",

	draw=function(e)
		draw_title()
	end,

	trans=function(e)
		if btnp(5) then
			return "main"
		end
	end,
}

fsm.add_state{
	state="main",

	enter=function(e)
		e.game=new_game()
	end,

	draw=function(e)
		draw_main(e.game)
	end,
}
-->8
-- game
function new_game()
	return fsm.new_entity{
		state="game",
		pship=new_pship(),
	}
end

fsm.add_state{
	state="game",

	update=function(e)
		e.pship:update()
	end,

	draw=function(e)
		e.pship:draw()
	end,
}

-->8
-- pship: player ship
function new_pship()
	return fsm.new_entity{
		state="pship",
		hp=2,
		x=64,
		y=64,
		r=2,
		col=7,
		spd=1,
	}
end

fsm.add_state{
	state="pship",

	draw=function(e)
		draw_ship(e)
	end,
}
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
