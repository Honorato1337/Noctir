from pathlib import Path
import numpy as np
import wave
RATE=44100
SECONDS=2.4
OUT=Path(__file__).resolve().parents[1]/'assets/audio/sfx'
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(20261018)
t=np.arange(round(RATE*SECONDS))/RATE
noise=rng.normal(size=len(t))
def filtered(signal,width):return np.convolve(signal,np.ones(width)/width,'same')
def save(name,signal):
    signal=np.tanh(signal)
    signal-=signal.mean()
    signal*=.72/max(np.max(np.abs(signal)),.001)
    fade=np.minimum(1,t/.015)*np.minimum(1,(SECONDS-t)/.10)
    left=signal*fade
    right=(.94*signal+.06*np.roll(signal,37))*fade
    pcm=(np.column_stack((left,right))*32767).astype('<i2')
    with wave.open(str(OUT/name),'wb') as w:
        w.setparams((2,2,RATE,0,'NONE','not compressed'))
        w.writeframes(pcm.tobytes())
    print(name,SECONDS,'seconds, peak',round(np.max(np.abs(pcm))/32767,3))
# Combustion engine: ignition chatter, cylinder harmonics and two gear shifts.
rpm=38+62*np.clip(t/SECONDS,0,1)
rpm-=15*np.exp(-((t-.85)/.08)**2)+18*np.exp(-((t-1.55)/.09)**2)
phase=2*np.pi*np.cumsum(rpm)/RATE
engine=sum(np.sin(phase*h+.13*h)/h for h in range(1,9))
ignition=np.sin(2*np.pi*23*t)*(t<.22)*np.exp(-t*8)
chassis=filtered(noise,31)*.8+np.sin(2*np.pi*18*t)*.08
rover=.50*engine*(.70+.15*np.sin(phase*.5))+.18*chassis+.40*ignition
save('rover_engine.wav',rover)
# Rocket: short ignition, pressure rise, broad exhaust and deep chamber rumble.
thrust=np.clip((t-.22)/.55,0,1)
low=filtered(noise,181)*6
hiss=filtered(noise,4)
chamber=np.sin(2*np.pi*(44*t+12*t*t))+.4*np.sin(2*np.pi*83*t)
ignition_noise=filtered(noise,9)*np.exp(-((t-.25)/.095)**2)*2.4
rocket=(.52*low+.20*hiss+.20*chamber)*(.12+.88*thrust)+ignition_noise
save('rocket_engine.wav',rocket)
