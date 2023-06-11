# Some random WAV manipulation toys.

Speed up or slow down a wav.

`dart run faster.dart test.wav out.wav`

`dart run slower.dart test.wav out.wav`

Normalize the volume of a wav.

`dart run normalize.dart test.wav out.wav`

Apply reverb to a wav.

`dart run reverb.dart test.wav out.wav`

Not sure how to describe this one...

`dart run weird.dart test.wav out.wav`

Demo to illustrate ingesting raw (headerless) audio data:

`dart raw.dart guitar.raw pcm16bit 1 44100`