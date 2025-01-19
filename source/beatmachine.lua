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
ScaleManager = {}


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

	track.delayline = snd.delayline.new(128)
	track.isDelayEnabled = false
	track.delayFeedback = 0.5
	track.delayMix = 0.5

	track.filter = snd.twopolefilter.new(snd.kFilterLowPass)
	track.isFilterEnabled = false
	track.filterFreq = 20000
	track.filterResn = 0.0
	track.filterMix = 0.5
	track.filterType = snd.kFilterLowPass

	track.bitCrusher = snd.bitcrusher.new()
	track.isBitCrusherEnabled = false
	track.bitCrusherAmount = 0.5
	track.bitCrusherMix = 0.5

	return track

end


function BeatMachine.Create()

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
					track.synth:setAttack(0.0)
					track.synth:setDecay(0.2)
					track.synth:setSustain(0.3)
					track.synth:setRelease(0.5)
				end
				

				track.instrument = snd.instrument.new()
				track.instrument:addVoice(track.synth, 24, 127, 0)

				-- chord track will play 3 notes at the same time
				if trackData.chord ~= nil and  trackData.chord == 1 then
					for k = 1, 2 do
						track.instrument:addVoice(track.synth:copy(), 24, 127, 0)
					end
					
				end

				track.channel = snd.channel.new()
				track.channel:addSource(track.instrument)

				if trackData.pan ~= nil then
					track.channel:setPan(trackData.pan)
				end

				track.track = snd.track.new()
				track.track:setInstrument(track.instrument)
				
				BeatMachine.sequence:addTrack(track.track)

				local noteCount = #trackData.notes
				for n = 1, noteCount do
					local note = trackData.notes[n]
					-- for Lua, step seem to start from 1, same as the index of an array
					-- step starts from 0 when saved in BMF so we need to add 1 to it
					track.track:addNote(note.step + 1, note.pitch, note.len, note.vel)
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