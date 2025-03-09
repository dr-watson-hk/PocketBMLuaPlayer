--[[

BSD Zero Clause License
=======================

Copyright (C) Khors Media

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.

--]]

local pd <const> = playdate
local gfx <const> = pd.graphics

import "beatmachine.lua"

BeatMachine.Create()
BeatMachine.LoadBeat('beats/cowb.bmf')
BeatMachine.PlayTheBeat(0)

pd.display.setRefreshRate(0)

function playdate.update()
	gfx.clear(gfx.kColorWhite)
	gfx.setColor(gfx.kColorBlack)

	BeatMachine.Update()

	local step = BeatMachine.sequence:getCurrentStep()

	local text = "Step: " .. step

	gfx.drawText(text, 10, 100)

	pd.drawFPS(10, 10)

end
