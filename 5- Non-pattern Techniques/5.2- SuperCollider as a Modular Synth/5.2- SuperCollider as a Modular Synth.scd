//load setup
("../../Setup/Setup.scd").loadRelative

//run this to smooth out transitions
p.fadeTime=5

//Using SuperCollider as a Modular synth
//snippets help with building these sets a LOT, as standard elements such as modulation signals can be called upon very quickly
//NOTE: this will get !!! L O U D !!! - there's protection from StageLimiter of course, but be aware.

//a sine wave
~sin = {SinOsc.ar([80,82],0,0.5)}
//a pulse wave
~pulse = {Pulse.ar([20,21],SinOsc.kr(0.1).range(0.01,1),0.5)}
//a new proxy multiplying sine and pulse waves
~sinpulse = {~sin.ar * ~pulse.ar}
~sinpulse.play

~sinpulse.stop

~sin.play
~sin.stop

~pulse.play
~pulse.stop

/*

A sine wave is genreated. Multichannel expansion makes it 2 sine waves, one in each ear. The left ear is playing at 80hz, and the right ear is playing at 82hz. This difference is not enough to make it a new notes, but creates a detuning effect.

A pulse wave is generated (pulse = square wave of vairable width). Multichannel expansion makes it 2 pulse waves, one in each ear. The left is is playing at 20hz, and the right ear is playing at 21hz. A sine wave at control rate is being use to modulate the widths of the pulse waves, from 0.01 to 1 at a rate of 0.1hz.

Multiplying these 2 waves together is an interesting way of combining them into one sound, instead of stacking them by adding. It becomes a complex form of modulation. Essentially FM, but it's somewhat ambiguous which is the carrier, and which is the modulator. I tend to think of the pulse wave as the modulator, because it is lower frequency and has the LFO going. The Sin wave is carrying the main pitch that's bleeding through.

*/





//feed this into a delay with its delay line modulated slightly
~delay = {CombC.ar(~sinpulse.ar,1,LFNoise1.kr(0.1).range(0.1,0.3),4)}
~delay.play

/*

Creating a new synth based on a delay Ugen. The input of the delay is our ~sinpulse signal. The delay time is modulated by a low frequency noise signal to generate random values (between 0.1 and 0.3) at control rate.

*/


//increase the pulse speed and decrease the width, play it alongside the original
~pulse2 = {Pulse.ar([40,41],SinOsc.kr(0.1).range(0.001,0.1),0.5)}
~pulse2.play;
//actually no that would sound much better just in the delay, so stop ~pulse2 from playing and add it into ~delay by using Mix.ar
(
~pulse2.stop;
~delay = {CombC.ar(Mix.ar([~sinpulse.ar,~pulse2.ar]),1,LFNoise1.kr(0.1).range(0.1,0.3),4)};
)

/*

Created a new synth based on a pulse wave. Also multichannel expasion. Also modulating the width with a sine wave at a rate of 0.1hz, but this time with a range of shorter widths. It's also an octave down from the percieved pitch of sinpulse.

We want that synth to only play inside the delay.

We use Mix.ar to smoothly mix these signals together as the input of our delay, instead of multiplying them which would cause them to modulate each other, or adding them which would increase their amplitudes too loud.

*/



//now we have some drones, some heavily gated and filtered noise would be good.
(
~noise = {RLPF.ar(WhiteNoise.ar(1),LFNoise1.kr(0.1).range(100,2000),SinOsc.kr(0.1).range(0.1,0.4),1)};
~noiseEnv = {EnvGen.ar(Env.perc(0.0001,0.1),Dust.kr(4))};
~totalNoise = {~noise.ar*~noiseEnv.ar};
~totalNoise.play;
)
//oh no. it is mono. i'm going to pan it over 2.
//In order to make a mono proxy stereo, I will have to .clear it and then evaluate a stereo version, as the number of channels is set at initialisation time.
//luckily with Pan2 I will only have to re-evaluate the ~totalNoise proxy
~totalNoise.clear;
(
~totalNoise = {Pan2.ar(~noise.ar*~noiseEnv.ar,SinOsc.kr(0.1))};
~totalNoise.play;
)

/*

Creating a new synth out of filtered noise, we decide to use a resonant low pass filter. The input signal to this filter is white noise at full volume. The frequency cutoff of the filter is being modulated by a low frequency noise generator, which is generating random values between 100 and 2000 at a rate of 0.1hz. The Q of the filter is being modulated by a control rate sine wave, oscilating between 0.1 and 0.4, also at a rate of 0.1hz.

Now, if we want to turn that noise into percussion, we can apply an envelope to it. We use an envelope generator, give it a percussive envelope, and use a Dust Ugen to trigger its gate. The density of the Dust Ugen is set to 4, meaning the gate will trigger at an average of 4 times per second, but the intervals of time between these tiggers will be random.

Since we didn't use multichannel expansion, we need to use a Pan2 Ugen to make the signal stereo. We multiply the noise by the envelope to apply it. You can almost think of it as amplitude modulation. Then we'll use a sine wave at control rate to modulate the pan position of the noise at a rate of 0.1hz.

*/




//the filtering on the noise isn't extreme enough, change it!
~noise = {RLPF.ar(WhiteNoise.ar(1),LFNoise1.kr(0.6).range(100,2000),SinOsc.kr(0.04).range(0.00001,0.2),1)};
//the noise could also do with some delay, which would sound nice if it was fed back through a pitch shifter:
//set up the delay, and play it
~noiseDelay = {CombC.ar(Mix.ar([~totalNoise.ar]),1,0.4,7,1)}
~noiseDelay.play;
//establish the pitch shifter
~pitchShift = {PitchShift.ar(~noiseDelay,0.2,TRand.kr(0.1,2,Dust.kr(0.5)))}
//play the pitch shifter, it will slow the delay speed by half
~pitchShift.play
//if we then put the results of ~pitchShift back into ~noiseDelay, then things get interesting.
//NB - this is bad practice and gets very loud before ending up in being DC bias, but i'm doing it here to prove a point.
//If you have super high end audio equipment or just don't want any DC bias then skip this step
~noiseDelay = {CombC.ar(Mix.ar([~totalNoise.ar,~pitchShift.ar]),1,0.4,7,1)}
//in order to avoid this getting totally out of control, reduce the volume of ~pitchShift inside of ~noiseDelay
~noiseDelay = {CombC.ar(Mix.ar([~totalNoise.ar,(~pitchShift.ar*0.11)]),1,0.4,7,1)}
//or modulate it to get varying amounts of feedback
~noiseDelay = {CombC.ar(Mix.ar([~totalNoise.ar,(~pitchShift.ar*LFNoise1.kr(0.01,0.2).abs)]),1,0.4,7,1)}
//modulating the delay time too will make things get a bit wild
~noiseDelay = {CombC.ar(Mix.ar([~totalNoise.ar,(~pitchShift.ar*LFNoise1.kr(0.01,0.2).abs)]),1,LFNoise1.kr(0.1).range(0.01,0.6),7,1)}
//~noiseDelay seems to be glitching a bit and throwing DC bias - add a LeakDC around it
~noiseDelay = {LeakDC.ar(CombC.ar(Mix.ar([~totalNoise.ar,(~pitchShift.ar*LFNoise1.kr(0.01,0.2).abs)]),1,LFNoise1.kr(0.1).range(0.01,0.6),7,1))}
//let's cut the original pulse/sine waves over a few seconds
~delay.stop(20)
~sinpulse.stop(20)

/*

So, what's going on here is that we put our percusive noise generator into a delay.Both are playing at the same time. We then put that delay into a pitch shifter. Now all 3 are playing at the same time. Then we mixed the pitch shifter back into the original delay, creating a feedback loop. We have to significantly attenuate the amplitude of the pitch shifter that gets mixed back in, or else the infinite feedback loop spirals the amplitude to infinity. Thanks to the stage limiter, this actually just results in silence.

We can modulate the amplitude of the pitch shifter that gets mixed back in to create varying amounts of feedback.

We can also modulate the delay time of the delay.

I guess playing with feedback may introduce DC bias. LeakDC.ar gets rid of it.

*/


//then put them inside of a DFM1 that can self-oscillate
//make sure you evaluate ~noiseDelayAdd twice before you .play it
~noiseDelayAdd = {DFM1.ar(Mix.ar([~delay.ar,~sinpulse.ar]),500,SinOsc.kr(0.1).range(0.5,2),1,0,0.03)}
//if you've evaluated the above line twice, play it
~noiseDelayAdd.play


/*

We put some drone sounds in to a DFM1 filter, and set it to low pass at 500hz.

Now we are modulating the resonance of this filter with a sine wave, because this filter can self-oscilalte at high resonances.

*/


//a lot of these sounds are quite degraded, some harsh sounds would be nice, let's have some chaos
//go to the help file for Henon2DC and copy-paste the second example but don't evaluate it (you'll need sc3-plugins for this)
/*
(
{ Henon2DN.ar(
    2200, 8800,
    LFNoise2.kr(1, 0.2, 1.2),
    LFNoise2.kr(1, 0.15, 0.15)
) * 0.2 }.play(s);
)
*/
//turn it into a node proxy and remove the .play(s) from the end
(
~henon = { Henon2DN.ar(
    2200, 8800,
    LFNoise2.kr(1, 0.2, 1.2),
    LFNoise2.kr(1, 0.15, 0.15)
) * 0.2 };
)
//make an envelope that has a long sweeping modulation on the amount of envelopes triggered
~chaosEnv = {EnvGen.ar(Env.perc(0,0.02),Dust.kr(SinOsc.kr(0.01).range(1,10)))}
//and combine in stereo
~chaos = {Pan2.ar(~henon*~chaosEnv)}
~chaos.play
//it is SUPER quiet, up the volume on ~henon
(
~henon = { Henon2DN.ar(
    2200, 8800,
    LFNoise2.kr(1, 0.2, 1.2),
    LFNoise2.kr(1, 0.15, 0.15)
) * 3.5 };
)
//add some reverb which will work in parallel
//if you want to change the parameters of any effect without re-evaluating it - set up that value as another NodeProxy
~room = {30};
~time = {3};
~verb = {GVerb.ar(~chaosEnv,~room,~time)}
~verb.play
//increase the reverb time
~time = {40};



//this needs some melody - add two melodies in stereo, slightly out of phase:
~saws = {LFSaw.ar([LFSaw.kr(0.1).range(100,1000).round(50),LFSaw.kr(0.11).range(100,1000).round(50)],0,0.3)}
~saws.play
//too harsh, needs filtering
~saws = {RLPFD.ar(LFSaw.ar([LFSaw.kr(0.1).range(100,1000).round(50),LFSaw.kr(0.101).range(100,1000).round(50)],0,0.8),1000,0.8,0.6,10)};

/*

To create a simple melody, you can modulate the frequency of an oscillator, and round the output of the modulation to a multiple. In this case, multiples of 50. This results in playing the harmonic series, using your rounding number as your fundamental frequency.

In this case, a saw wave is used, becayse it acts as a ramp, going up across it's duty cycles, and then dropping back down, right at the end, before the next duty cycle.

Multichannel expansion is used to create 2 of the same melody, one in ear each, but each playing at a different rate.

*/

//another delay would be nice
~sawDelay = {CombC.ar(~saws.ar,1,0.5,10)};
~sawDelay.play;
//some heavy decimation on the delay
~sawDelay = {Decimator.ar(CombC.ar(~saws.ar,1,0.5,10),2200,10)};
//further bit reduction
~sawDelay = {Decimator.ar(CombC.ar(~saws.ar,1,0.5,10),2200,5)};
//even further
~sawDelay = {Decimator.ar(CombC.ar(~saws.ar,1,0.5,10),2020,3)};
//plugging the ~sawDelay into the original for more noise
~noiseDelay = {LeakDC.ar(CombC.ar(Mix.ar([~sawDelay.ar,~totalNoise.ar,(~pitchShift.ar*LFNoise1.kr(0.01,0.2).abs)]),1,LFNoise1.kr(0.1).range(0.01,0.6),7,1))}
//plugging ChaosEnv into ~noiseDelay too
~noiseDelay = {LeakDC.ar(CombC.ar(Mix.ar([~chaosEnv.ar,~sawDelay.ar,~totalNoise.ar,(~pitchShift.ar*LFNoise1.kr(0.01,0.2).abs)]),1,LFNoise1.kr(0.1).range(0.01,0.6),7,1))};
//then plugging it also into a more intense ~noiseDelayAdd for more mad effects
~noiseDelayAdd = {DFM1.ar(Mix.ar([~delay.ar,~sinpulse.ar,~noiseDelay]),LFNoise1.kr(100).range(100,10000),SinOsc.kr(0.1).range(0.5,100),1,0,0.03)}
~noiseDelayAdd.play
//it doesn't appear to be playing, probablt because ~noiseDelay is SO loud. Multiply it by half
~noiseDelay = {LeakDC.ar(CombC.ar(Mix.ar([~chaosEnv.ar,~sawDelay.ar,~totalNoise.ar,(~pitchShift.ar*LFNoise1.kr(0.01,0.2).abs)]),1,LFNoise1.kr(0.1).range(0.01,0.6),7,1)) * 0.3};
//then plug ~noiseDelayAdd into ~noiseDelay and roll off the multiplication for maximum damage
~noiseDelay = {LeakDC.ar(CombC.ar(Mix.ar([~chaosEnv.ar,~sawDelay.ar,~totalNoise.ar,(~pitchShift.ar*LFNoise1.kr(0.01,0.2).abs),~noiseDelayAdd.ar]),1,LFNoise1.kr(0.1).range(0.01,0.6),7,1))};
//increase the ridiculousness of the modulation of the delaytime
~noiseDelay = {LeakDC.ar(CombC.ar(Mix.ar([~chaosEnv.ar,~sawDelay.ar,~totalNoise.ar,(~pitchShift.ar*LFNoise1.kr(0.01,0.2).abs),~noiseDelayAdd.ar]),1,LFNoise1.kr(1).range(0.001,4),7,1))};
//put another delay on top of that?
~delay2 = {CombC.ar(~noiseDelay.ar,1,0.4,30)}
~delay2.play
//then plug that back into ~noiseDelay (which by now contains most things that are playing.
~noiseDelay = {LeakDC.ar(CombC.ar(Mix.ar([~chaosEnv.ar,~sawDelay.ar,~totalNoise.ar,(~pitchShift.ar*LFNoise1.kr(0.01,0.2).abs),~noiseDelayAdd.ar,~delay2.ar]),1,LFNoise1.kr(1).range(0.001,4),7,1))};
//also modulate ~delay2, really slowly
~delay2 = {LeakDC.ar(CombC.ar(~noiseDelay.ar,1,SinOsc.kr(0.01).range(0.0001,0.2),80))}
//things broke up for me here and I have no idea why, there's multiple things feeding back through each other here.
//and you have noise music!