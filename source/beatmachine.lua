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
local snd <const> = pd.sound

import "scalemanager.lua"

BM_CONST =
{
	BM_TYPE_SAMPLE = 0,
	BM_TYPE_SINE = 1,
	BM_TYPE_SQUARE = 2,
	BM_TYPE_SAWTOOTH = 3,
	BM_TYPE_TRIANGLE = 4,
	BM_TYPE_NOISE = 5,
	BM_TYPE_POPHASE = 6,
	BM_TYPE_PODIGITAL = 7,
	BM_TYPE_POVOSIM = 8,
	BM_MAX_SOUND_TYPE = 9,
	BM_SAMLE_TRACKS = 10,
	BM_MAX_TRACK = 16,
	BM_MAX_STEP_COUNT = 1280,
	BM_MAX_BAR_NUMBER = 80,
	BM_MAX_COLOUR = 4,
	BM_STEPS_PER_BAR = 16,
	BM_BEATS_PER_BAR = 4,
	BM_STEPS_PER_BEAT = 4,
	BM_TRACK_NAME_SIZE = 7,
	BM_TRACK_LABEL_SIZE = 16,
	BM_TRACK_FILENAMEL_SIZE = 48,
	BM_CHORD_TRACK = 8,
	BM_MAX_NOTE_LENGTH = 64,
	BM_EXTRA_VOICE_FOR_CHORD = 2
}

BM_WAVEFORMS =
{
	snd.kWaveSine,
	snd.kWaveSquare,
	snd.kWaveSawtooth,
	snd.kWaveTriangle,
	snd.kWaveNoise,
	snd.kWavePOPhase,
	snd.kWavePODigital,
	snd.kWavePOVosim
}


SoundSrcType =
{
	"sampler",
	"sine",
	"square",
	"sawtooth",
	"triangle",
	"noise",
	"phase",
	"digital",
	"vosim",
	"wavetable"
}

BeatMachine = {}


function BeatMachine.CreateTrack()

	track = {}

	track.channel = nil
	track.instrument = nil
	track.synth = nil
	track.track = nil

	track.attack = 0.0
	track.decay = 0.2
	track.sustain = 0.3
	track.release = 0.5

	track.soundSource = 0
	track.trackName = ""

	track.sampleName = ""

	track.volume = 0.5
	track.panning = 0.0

	track.muted = false
	track.isChordTrack = false

	track.delayline = nil
	track.filter = nil
	track.bitCrusher = nil

	track.isDrumTrack = false

	return track

end


function BeatMachine.Create()

	ScaleManager.Create()

	BeatMachine.sequence = snd.sequence.new()

	BeatMachine.tracks = {}

	for i = 1, BM_CONST.BM_MAX_TRACK do
		BeatMachine.tracks[i] = BeatMachine.CreateTrack()
	end

	BeatMachine.beatLength = 0
	BeatMachine.BMP = 120
	BeatMachine.version = 0
	BeatMachine.beatName = ""
	BeatMachine.producer = ""

end


function BeatMachine.GetSoundSrcType(typeName)

	for i = 1, #SoundSrcType do
		
		if SoundSrcType[i] == typeName then
			return i-1
		end
	end

	return 0

end


function BeatMachine.LoadBeat(path)

	local data = json.decodeFile(path)

	print("Version: " .. data.beat.ver)
	
	print("Scale: " .. data.beat.scale.base .. " " .. data.beat.scale.type)

	ScaleManager.SetupScaleWithString(data.beat.scale.type, data.beat.scale.base)

	print("BMP: " .. data.beat.BPM)

	-- convert BPM to steps per second
	local stepsPerBeat = 4.0
	local beatsPerSecond = data.beat.BPM / 60.0
	local stepsPerSecond = stepsPerBeat * beatsPerSecond

	BeatMachine.sequence:setTempo(stepsPerSecond)

	if data.beat.tracks ~= nil then
		local count = #data.beat.tracks

		print("Track Count: " .. count)

		for i = 1, count do
			local trackData = data.beat.tracks[i]

			if trackData.mute == 0 then
				local id = trackData.id

				local track = BeatMachine.tracks[id + 1]

				track.trackName = trackData.name

				track.soundSource = BeatMachine.GetSoundSrcType(trackData.type)

				if track.soundSource == BM_CONST.BM_TYPE_SAMPLE then
					track.sampleName = trackData.sample
					local path = "samples/" .. track.sampleName
					local sampler = snd.sample.new(path)
					track.synth = snd.synth.new(sampler)
				else

					track.synth = snd.synth.new(BM_WAVEFORMS[track.soundSource])

				end

				track.synth:setVolume(trackData.vol)

				if trackData.env ~= nil then
					track.synth:setAttack(trackData.env.a)
					track.synth:setDecay(trackData.env.d)
					track.synth:setSustain(trackData.env.s)
					track.synth:setRelease(trackData.env.r)
				else
					-- use defaults instead
					--track.synth:setAttack(0.0)
					--track.synth:setDecay(0.2)
					--track.synth:setSustain(0.3)
					--track.synth:setRelease(0.5)
				end
				

				track.instrument = snd.instrument.new()
				track.instrument:addVoice(track.synth)

				-- chord track will play 3 notes at the same time
				if trackData.chord ~= nil and  trackData.chord == 1 then
					for k = 1, 2 do
						track.instrument:addVoice(track.synth:copy())
					end
					
					track.isChordTrack = true

				end

				track.channel = snd.channel.new()
				track.channel:addSource(track.instrument)

				if trackData.pan ~= nil then
					track.channel:setPan(trackData.pan)
				end

				track.track = snd.track.new()
				track.track:setInstrument(track.instrument)
				
				BeatMachine.sequence:addTrack(track.track)

				if trackData.is_drum ~= nil then
					track.isDrumTrack = trackData.is_drum == 1
				end

				if trackData.filter ~= nil then

					local filterType = snd.kFilterLowPass

					if trackData.filter.type == 1 then
						filterType = snd.kFilterHighPass
					elseif trackData.filter.type == 2 then
						filterType = snd.kFilterBandPass
					elseif trackData.filter.type == 3 then
						filterType = snd.kFilterNotch
					end

					track.filter = snd.twopolefilter.new(filterType)
					track.filter:setFrequency(trackData.filter.freq)
					track.filter:setResonance(trackData.filter.resn)
					track.filter:setMix(trackData.filter.mix)

					track.channel:addEffect(track.filter)
					
				end

				
				if trackData.delay ~= nil then

					-- Lua and C seems to have different paraments for setting up delay.
					-- may need to do some adjustment
					track.delayline = snd.delayline.new(0.01)
					track.delayline:setFeedback(trackData.delay.feedback)
					track.delayline:setMix(trackData.delay.mix)

					track.channel:addEffect(track.delayline)

				end

				if trackData.bitcrush ~= nil then

					track.bitCrusher = snd.bitcrusher.new()
					track.bitCrusher:setAmount(trackData.bitcrush.amount)
					track.bitCrusher:setMix(trackData.bitcrush.mix)

					track.channel:addEffect(track.bitCrusher)

				end

				local noteCount = #trackData.notes
				for n = 1, noteCount do
					local note = trackData.notes[n]
					-- for Lua, step seem to start from 1, same as the index of an array
					-- step starts from 0 when saved in BMF so we need to add 1 to it

					if track.isDrumTrack then
						track.track:addNote(note.step + 1, NOTES.NOTE_C, note.len, note.vel)
					else
						track.track:addNote(note.step + 1, note.pitch, note.len, note.vel)
					end
					

					if track.isChordTrack then
						-- if this is a chord track, add extra 2 notes to play
						local noteIndex = ScaleManager.noteToIndexTable[note.pitch]

						local noteIndex3 = noteIndex + 2
						if noteIndex3 > ScaleManager.maxIndex then
							noteIndex3 -= ScaleManager.currentScalePitchCount
						end

						local note3 = ScaleManager.currentNoteValueTable[noteIndex3]
						track.track:addNote(note.step + 1, note3, note.len, note.vel)

						local noteIndex5 = noteIndex + 4
						if noteIndex5 > ScaleManager.maxIndex then
							noteIndex5 -= ScaleManager.currentScalePitchCount
						end

						local note5 = ScaleManager.currentNoteValueTable[noteIndex5]
						track.track:addNote(note.step + 1, note5, note.len, note.vel)

					end
				end

			end
		end

	end

end

function BeatMachine.PlayTheBeat(loopCount)

	BeatMachine.sequence:setLoops(loopCount)
	BeatMachine.sequence:play()

end


function BeatMachine.Update()

    gfx.clear(gfx.kColorWhite)
	gfx.setColor(gfx.kColorBlack)
	
	

end