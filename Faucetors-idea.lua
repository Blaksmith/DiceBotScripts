-- Script by CttCJim
-- For seintjie's dicebot, developed on v3.3.9
-- jreinsch@gmail.com
-- Be a bro: BTC 1JP3tHhToThgS81Wu8P8wD7Ymu29YB3upT

chance=20 --sets your chance for placing a bet
basebet = 1


nextbet=basebet -- sets your first bet.

bethigh=true -- bet high when true, bet low when false

enablezz=true -- set to true to use high/low switching 
-- settings from advanced mode

enablesrc=true -- set to true to use stop/reset conditions 
-- settings from advanced mode

losscount = 0 -- to count until set of losses
waitforwin = 0 -- Wait for a win after gambit
prerolllimit = 4 -- length of loss set before gambit
gambit = 0 -- flag for when doing 3-bet runs
multiplier = 2 -- multiplier for gambit bets
gambitcount = 0 -- number of gambit bets performed currently
gambitmult = 0 -- gambit multiplier/counter
gambitlimit = 2 -- number of gambit bets to make

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

function dobet()

	if win then
		if gambit == 0 then -- win, regular roll
			losscount = 0
			waitforwin = 0
		else -- win, gambit roll; reset everything
			gambitcount=0
			gambit=0
			gambitmult = 0
			nextbet = basebet
			losscount = 0
			waitforwin = 0			
		end
	else -- lost last roll
		if gambit == 0 then -- lose, regular roll
			losscount = losscount + 1
			if losscount >= prerolllimit and waitforwin == 0 then -- turn on the gambit
				gambit = 1
				gambitcount=1
				gambitmult = gambitmult + 1
				nextbet = basebet * (multiplier^gambitmult)
				losscount = 0 -- primed for after the gambit
			end
		else -- lose, gambit roll
			if gambitcount<gambitlimit and waitforwin == 0 then -- next bet is another gambit
				gambitcount = gambitcount + 1
			else -- gambit set over; go back to base bet but preserve gambitmult
				nextbet = basebet
				gambitcount = 0
				gambit = 0
				waitforwin = 1
			end		
		end
	end
	
	sleep(0.5)

end