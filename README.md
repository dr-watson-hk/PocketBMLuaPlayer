# PocketBMLuaPlayer
 
PocketBM is a beat making app for PlayDate. This project is the source code for playing back beat files created by PocketBM.

The format of a beat file is just plain JSON so nothing fancy here, just some codes for decoding JSON, setting up synths and filling in MIDI notes in the sequencer for playback.

Here is an example of using the player code in your project:


import "beatmachine.lua"

BeatMachine.Create()

BeatMachine.LoadBeat('beats/demo.bmf')

BeatMachine.PlayTheBeat(0)


C version: https://github.com/dr-watson-hk/PocketBMPlayer


Credits:

SquidGod - Lua Playdate Template: https://github.com/SquidGodDev/playdate-template



--------------------------------------------------------------------------------
Copyright (C) Khors Media

Permission to use, copy, modify, and/or distribute this software for any
purpose without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
