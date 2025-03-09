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


SCALES =
{
    SCALE_CHROMATIC = 1,
    SCALE_MAJOR = 2,

    SCALE_NATURALMINOR = 3,
    SCALE_MELODICMINOR = 4,
    SCALE_HARMONICMINOR = 5,

    SCALE_DORIAN = 6,
    SCALE_MIXOLYDIAN = 7,

    SCALE_LYDIAN = 8,
    SCALE_LYDIAN_DOMINANT = 9,
    SCALE_LYDIAN_AUGMENTED = 10,
    SCALE_LYDIAN_DIMINISHED = 11,

    SCALE_PHRYGIAN = 12,

    SCALE_LOCRIAN = 13,
    SCALE_SUPER_LOCRIAN = 14,

    SCALE_PERSIAN = 15,

    SCALE_MAJOR_PENTATONIC = 16,
    SCALE_MINOR_PENTATONIC = 17,

    SCALE_IWATO = 18,

    SCALE_COUNT = 18
}

ScaleNames =
{
	"Chromatic",
	"Major",
	"Natural Minor",
	"Melodic Minor",
	"Harmonic Minor",

	"Dorian",
	"Mixolydian",
	"Lydian",
	"Lydian Dominant",
	"Lydian Augmented",
	"Lydian Diminished",

	"Phrygian",
	"Locrian",
	"Super Locrian",

	"Persian",

	"Major Pentatonic",
	"Minor Pentatonic",
	"Iwato"
}

NOTES =
{
    NOTE_C = 0,
    NOTE_C_SHARP = 1,
    NOTE_D = 2,
    NOTE_D_SHARP = 3,
    NOTE_E = 4,
    NOTE_F = 5,
    NOTE_F_SHARP = 6,
    NOTE_G = 7,
    NOTE_G_SHARP = 8,
    NOTE_A = 9,
    NOTE_A_SHARP = 10,
    NOTE_B = 11,
    NOTE_COUNT = 12,
    NOTE_C4 = 60
}

PitchNames =
{
	"C",
	"C#",
	"D",
	"D#",
	"E",
	"F",
	"F#",
	"G",
	"G#",
	"A",
	"A#",
	"B"
}

SCALE_CONSTS =
{
    SCALE_SEMITONE_COUNT = 12,

    -- C1
    SCALE_NOTE_MIN = 24,
    SCALE_NOTE_MAX = 119,

    SCALE_BUFFER_SIZE = 128,
}

ChromaticScale = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 };
MajorScale = { 0,2,4,5,7,9,11 };
NaturalMinorScale = { 0,2,3,5,7,8,10 };
MelodicMinorScale = { 0,2,3,5,7,9,11 };
HarmonicMinorScale = { 0,2,3,5,7,8,11 };

DorianMode = { 0,2,3,5,7,9,10 };
MixolydianMode = { 0,2,4,5,7,9,10 };
LydianMode = { 0,2,4,6,7,9,11 };

LydianDominant = { 0,2,4,6,7,9,10 };
LydianAugmented = { 0,2,4,6,8,9,11 };
LydianDiminished = { 0,2,3,6,7,9,11 };

PhrygianMode = { 0,1,3,5,7,8,10 };
LocrianMode = { 0,1,3,5,6,8,10 };
SuperLocrianMode = { 0,1,3,4,6,8,10 };

PersianScale = { 0,1,4,5,6,8,11 };

MajorPentatonicScale = { 0,2,4,7,9 };
MinorPentatonicScale = { 0,3,5,7,10 };
IwatoScale = { 0,1,5,6,10 };

Scales =
{
    ChromaticScale,

    MajorScale,
    NaturalMinorScale,
    MelodicMinorScale,
    HarmonicMinorScale,

    DorianMode,
    MixolydianMode,
    LydianMode,

    LydianDominant,
    LydianAugmented,
    LydianDiminished,

    PhrygianMode,
    LocrianMode,
    SuperLocrianMode,

    PersianScale,

    MajorPentatonicScale,
    MinorPentatonicScale,
    IwatoScale
}


ScalePitchCount =
{
	12,

	7,
	7,
	7,
	7,

	7,
	7,
	7,
	7,
	7,
	7,

	7,
	7,
	7,

	7,

	5,
	5,
	5
}

ScaleManager = {}


function ScaleManager.Create()

    ScaleManager.octave = {}
    ScaleManager.noteToIndexTable = {}
    ScaleManager.currentNoteValueTable = {}

    ScaleManager.currentScale = SCALES.SCALE_MAJOR
    ScaleManager.noteIndex = 1
    ScaleManager.currentScalePitchCount = 12

    ScaleManager.maxIndex = 1
    ScaleManager.defaultPitchIndex = 1

end


function ScaleManager.SetupScale(scaleIndex, firstPitch)

    for i = 1, SCALE_CONSTS.SCALE_BUFFER_SIZE do
        ScaleManager.noteToIndexTable[i] = 0
        ScaleManager.currentNoteValueTable[i] = 0
    end


    local scaleInfo = Scales[scaleIndex]
    local pitchCount = ScalePitchCount[scaleIndex]

    local currentPitchFirst = SCALE_CONSTS.SCALE_NOTE_MIN + firstPitch

    local pitchIndexInScale = 1
    while currentPitchFirst <= SCALE_CONSTS.SCALE_NOTE_MAX do
        for i = 1, pitchCount do
            local noteValue = currentPitchFirst + scaleInfo[i]
            if noteValue <= SCALE_CONSTS.SCALE_NOTE_MAX then
                ScaleManager.noteToIndexTable[noteValue] = pitchIndexInScale
                ScaleManager.currentNoteValueTable[pitchIndexInScale] = noteValue

                pitchIndexInScale = pitchIndexInScale + 1
            end
        end

        currentPitchFirst += SCALE_CONSTS.SCALE_SEMITONE_COUNT

    end

    ScaleManager.maxIndex = pitchIndexInScale - 1
    ScaleManager.defaultPitchIndex = pitchCount * 3 + 1

    ScaleManager.currentScale = scaleIndex
    ScaleManager.noteIndex = firstPitch
    ScaleManager.currentScalePitchCount = pitchCount

end



function ScaleManager.SetupScaleWithString(scaleName, baseNoteName)
    
    local scaleIndex = 1
    local baseNoteOffset = 0

    for i = 1, SCALES.SCALE_COUNT do
        if ScaleNames[i] == scaleName then
            scaleIndex = i
            break
        end
    end

    for i = 1, NOTES.NOTE_COUNT do
        
        if NOTES[i] == baseNoteName then
            baseNoteOffset = i - 1
            break
        end
    end

    ScaleManager.SetupScale(scaleIndex, baseNoteOffset)

end