from pathlib import Path
import math, wave
import numpy as np

root=Path(__file__).resolve().parents[1]
out=root/'assets/audio/sfx'
out.mkdir(parents=True,exist_ok=True)
rate=22050
rng=np.random.default_rng(20261017)

def tone(freq,duration,kind='pulse',end=None,volume=.4):
    n=int(duration*rate)
    t=np.arange(n)/rate
    frequency=np.linspace(freq, freq if end is None else end,n)
    phase=np.cumsum(frequency)/rate
    if kind=='noise':
        signal=rng.uniform(-1,1,n)
        signal=np.convolve(signal,np.ones(3)/3,'same')
    elif kind=='triangle': signal=1-4*np.abs((phase%1)-.5)
    elif kind=='sine': signal=np.sin(2*np.pi*phase)
    else: signal=np.where(phase%1<.25,1.,-.35)
    envelope=np.minimum(1,t/.004)*np.minimum(1,(duration-t)/.012)*np.exp(-t/max(duration*.8,.01))
    return signal*envelope*volume

def melody(notes,beat=.08,kind='pulse'):
    return np.concatenate([tone(n,beat,kind) if n else np.zeros(int(beat*rate)) for n in notes])

def mix(a,b):
    result=np.zeros(max(len(a),len(b)))
    result[:len(a)]+=a
    result[:len(b)]+=b
    return result

sounds={
 'shot':mix(tone(560,.085,'sine',end=240,volume=.22),tone(280,.075,'triangle',end=180,volume=.07)),
 'hit':mix(tone(240,.065,end=80),tone(0,.08,'noise',volume=.35)),
 'player_hurt':melody([220,165,110],.09),
 'enemy_down':mix(tone(180,.17,end=35),tone(0,.18,'noise',volume=.3)),
 'dash':mix(tone(240,.18,'triangle',end=1000),tone(0,.15,'noise',volume=.16)),
 'dash_ready':melody([660,990],.065,'triangle'),
 'echo':np.concatenate([tone(900,.18,'triangle',end=130)[::-1],tone(130,.2,'triangle',end=1400),melody([660,880,1320],.06)]),
 'coin':melody([1047,1568],.045,'triangle'),
 'coin_bonus':melody([1047,1568,2093],.05,'triangle'),
 'item_pickup':melody([523,659,784],.065),
 'heal':melody([392,523,659,784],.09,'triangle'),
 'bomb':mix(tone(120,.7,'sine',end=28,volume=.55),tone(0,.55,'noise',volume=.55)),
 'shield':mix(tone(330,.4,'triangle',end=990,volume=.3),tone(660,.4,'sine',volume=.25)),
 'overdrive':melody([220,330,440,660,880],.07),
 'ui_click':tone(740,.045,'triangle',volume=.25),
 'purchase':melody([523,659,784,1047],.07),
 'error':melody([165,0,147],.075,'triangle'),
 'boss_alert':melody([110,165,110,0,110,220],.14),
 'stage_clear':melody([523,659,784,1047],.13,'triangle'),
 'defeat':melody([392,330,262,196],.18,'triangle'),
 'victory':melody([523,659,784,1047,784,1047,1319],.12,'triangle'),
 'frost_warning':melody([1047,0,1047,1397],.11,'triangle'),
}
def save(path,signal):
    assert np.isfinite(signal).all()
    peak=np.max(np.abs(signal))
    if peak>.85: signal=signal*.85/peak
    pcm=(np.clip(signal,-1,1)*32767).astype('<i2')
    with wave.open(str(path),'wb') as f:
        f.setparams((1,2,rate,0,'NONE','not compressed'))
        f.writeframes(pcm.tobytes())
    assert np.sqrt(np.mean(signal**2))>.005
for name,data in sounds.items(): save(out/f'{name}.wav',data)
preview=np.concatenate([np.concatenate([sounds[n],np.zeros(int(rate*.18))]) for n in ['shot','dash','dash_ready','echo','coin','coin_bonus','heal','shield','bomb','boss_alert','victory']])
save(root/'assets/audio/sfx_preview.wav',preview)
print(f'Created {len(sounds)} original PCM effects and a preview; no clipping or silent clips.')
