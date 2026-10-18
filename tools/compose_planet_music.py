"""Three original looping compositions; NumPy synthesizer, no sampled recordings."""
from pathlib import Path
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio/music'
OUT.mkdir(parents=True, exist_ok=True)
RATE = 22050
RNG = np.random.default_rng(7419)


def voice(midi, seconds, instrument):
    t = np.arange(int((seconds + .28) * RATE)) / RATE
    f = 440 * 2 ** ((midi - 69) / 12)
    phase = 2 * np.pi * f * t
    if instrument == 'pluck':
        y = sum(np.sin(phase * h) * np.exp(-t * (3 + h * 1.5)) / h for h in range(1, 7))
        env = np.minimum(t / .004, 1) * np.exp(-t * 1.9)
    elif instrument == 'piano':
        y = sum(np.sin(phase * h * (1 + h * .00015)) * np.exp(-t * (1.2 + h * .7)) / h ** 1.8 for h in range(1, 6))
        env = np.minimum(t / .006, 1) * np.exp(-t * 1.3)
    elif instrument == 'strings':
        vibrato = .012 * np.sin(2 * np.pi * 4.8 * t)
        y = sum(np.sin(phase * h + vibrato * h) / h ** 2 for h in range(1, 6))
        env = np.minimum(t / .12, 1) * np.minimum(np.maximum((seconds + .22 - t) / .3, 0), 1)
    elif instrument == 'pad':
        y = (np.sin(phase) + .4 * np.sin(phase * 1.002) + .22 * np.sin(phase * 2)) / 1.6
        env = np.minimum(t / .35, 1) * np.minimum(np.maximum((seconds + .25 - t) / .55, 0), 1)
    elif instrument == 'bass':
        y = np.sin(phase) + .18 * np.sin(phase * 2)
        env = np.minimum(t / .012, 1) * np.exp(-t * 2.3)
    else:
        y = np.sin(phase + .16 * np.sin(phase * 2)) + .16 * np.sin(phase * 3)
        env = np.minimum(t / .035, 1) * np.minimum(np.maximum((seconds + .18 - t) / .22, 0), 1)
    return y * env


def compose(name, bpm, beats, chords, melody, kind):
    beat = 60 / bpm
    bars = 16 if name == "mars" else 32
    samples = round(bars * beats * beat * RATE)
    audio = np.zeros((samples, 2), dtype=np.float64)

    def note(midi, when, length, gain, instrument, pan=0):
        data = voice(midi, length * beat, instrument) * gain
        start = round(when * beat * RATE)
        indices = (start + np.arange(len(data))) % samples
        audio[indices, 0] += data * np.sqrt((1 - pan) / 2)
        audio[indices, 1] += data * np.sqrt((1 + pan) / 2)

    for bar in range(bars):
        root, third, fifth = chords[bar % len(chords)]
        chord = [root, third, fifth]
        at = bar * beats
        for pitch in chord:
            note(pitch, at, beats * .96, .052, 'pad', -.45 if pitch == root else .45)
        # Bass, arpeggiation and countervoice share the composed harmony.
        for b in range(beats):
            note(root - 12 if b % 2 == 0 else fifth - 12, at + b, .8, .16, 'bass')
        if name == 'mars':
            pattern = [0, 1, 2, 1, 0, 2, 1, 2]
            for i in range(8):
                note(chord[pattern[i]] + 12, at + i * .5, .48, .16, 'pluck', -.35)
            # A separate descending/inverted response gives contrapuntal movement.
            for i, step in enumerate([2, 1, 0, 1]):
                note(chord[step] + (12 if bar % 2 else 0), at + i + .25, .65, .11, 'pluck', .4)
        elif name == 'neptune':
            # Bright Classical-period phrasing over an electronic Alberti bass.
            for i, degree in enumerate([0, 2, 1, 2, 0, 2, 1, 2]):
                note(chord[degree] + 12, at + i * .5, .45, .13, 'piano', -.3)
            for b in [0, 2]:
                for pitch in chord:
                    note(pitch + 24, at + b, .35, .035, 'pluck', .5)
        else:
            # Double-time broken chords push Jupiter beyond Neptune's tempo.
            for i in range(12):
                degree = [0, 2, 1, 2, 1, 2][i % 6]
                note(chord[degree] + (0 if i == 0 else 12), at + i * .25, .42, .11, 'piano', -.4)
        phrase = melody[bar % len(melody)]
        for offset, pitch, duration in phrase:
            # The second period answers the first one an octave above in places.
            octave = 12 if bar >= 8 and bar % 4 == 2 else 0
            note(pitch + octave, at + offset, duration, .19, kind, .16)
        # Quiet electronic pulse; the melody remains in front of the percussion.
        for b in range(beats):
            t = np.arange(int(.15 * RATE)) / RATE
            kick = np.sin(2 * np.pi * (48 * t + 3 * (1 - np.exp(-t * 35)))) * np.exp(-t * 32) * .11
            idx = (round((at + b) * beat * RATE) + np.arange(len(t))) % samples
            audio[idx] += kick[:, None]
            hat = RNG.normal(0, .018, len(t)) * np.exp(-t * 90)
            hat = np.concatenate(([0], np.diff(hat)))
            audio[(idx + round(beat * .5 * RATE)) % samples] += hat[:, None]
    # Circular stereo delay/reverb: tails wrap into the start instead of silence.
    dry = audio.copy()
    for delay, gain in [(beat * .75, .20), (beat * 1.5, .12), (.037, .08), (.083, .06)]:
        audio += np.roll(dry[:, ::-1], round(delay * RATE), axis=0) * gain
    audio -= np.mean(audio, axis=0)
    audio = np.tanh(audio * 1.15)
    audio *= .78 / np.max(np.abs(audio))
    # Very short seam crossfade removes discontinuity without a silent boundary.
    seam = 128
    bridge = (audio[-1] + audio[0]) / 2
    ramp = np.linspace(0, 1, seam)[:, None]
    audio[:seam] = bridge * (1 - ramp) + audio[:seam] * ramp
    audio[-seam:] = audio[-seam:] * (1 - ramp) + bridge * ramp
    save(OUT / f'{name}.wav', audio)
    blocks = [np.sqrt(np.mean(block ** 2)) for block in np.array_split(audio, int(samples / RATE * 4))]
    assert min(blocks) > .015, (name, 'silent passage')
    assert np.max(np.abs(audio[-1] - audio[0])) < .0001
    print(f'{name}: {samples/RATE:.2f}s, peak={np.max(np.abs(audio)):.3f}, quietest quarter-second={min(blocks):.3f}')
    return audio, {'file': f'{name}.wav', 'bpm': bpm, 'meter': '4/4' if beats == 4 else ('3/4' if name == 'neptune' else '6/8'), 'bars': bars, 'seconds': samples / RATE, 'original': True}


def save(path, data):
    with wave.open(str(path), 'wb') as target:
        target.setparams((2, 2, RATE, 0, 'NONE', 'not compressed'))
        target.writeframes((np.clip(data, -1, 1) * 32767).astype('<i2').tobytes())


if __name__ == '__main__':
    # Explicitly authored melodies and harmonic periods, all original.
    specifications = [
        ('mars', 112, 4, [(50,53,57),(55,58,62),(48,52,55),(57,61,64),(58,62,65),(55,58,62),(57,61,64),(50,53,57)], [
            [(0,74,.5),(.5,77,.5),(1,76,.5),(1.5,74,.5),(2,73,.5),(2.5,69,.5),(3,72,.5),(3.5,73,.5)],
            [(0,74,1),(1,70,.5),(1.5,69,.5),(2,67,.5),(2.5,69,.5),(3,70,1)],
            [(0,72,.5),(.5,76,.5),(1,79,1),(2,77,.5),(2.5,76,.5),(3,74,.5),(3.5,72,.5)],
            [(0,73,1),(1,76,1),(2,69,1),(3,73,1)],
            [(0,77,.5),(.5,74,.5),(1,70,1),(2,74,.5),(2.5,77,.5),(3,81,1)],
            [(0,79,1),(1,77,.5),(1.5,74,.5),(2,70,1),(3,74,1)],
            [(0,76,.5),(.5,73,.5),(1,69,.5),(1.5,73,.5),(2,76,.5),(2.5,79,.5),(3,77,.5),(3.5,73,.5)],
            [(0,74,2),(2,69,1),(3,65,1)]], 'pluck'),
        ('neptune', 160, 4, [(50,54,57),(55,59,62),(57,61,64),(50,54,57),(59,62,66),(55,59,62),(57,61,64),(50,54,57)], [
            [(0,78,.5),(.5,81,.5),(1,86,1),(2,85,.5),(2.5,83,.5),(3,81,1)],
            [(0,79,.5),(.5,83,.5),(1,86,.5),(1.5,83,.5),(2,81,.5),(2.5,79,.5),(3,78,.5),(3.5,76,.5)],
            [(0,76,.5),(.5,78,.5),(1,80,.5),(1.5,81,.5),(2,85,1),(3,83,.5),(3.5,81,.5)],
            [(0,78,1),(1,74,.5),(1.5,78,.5),(2,81,1),(3,86,1)],
            [(0,83,.5),(.5,86,.5),(1,90,1),(2,88,.5),(2.5,86,.5),(3,85,1)],
            [(0,86,.5),(.5,83,.5),(1,79,.5),(1.5,83,.5),(2,86,.5),(2.5,88,.25),(2.75,86,.25),(3,83,1)],
            [(0,85,.5),(.5,83,.5),(1,81,.5),(1.5,80,.5),(2,81,.5),(2.5,85,.5),(3,88,1)],
            [(0,86,1),(1,81,.5),(1.5,78,.5),(2,74,1.5),(3.5,81,.5)]], 'piano'),
        ('jupiter', 192, 3, [(48,51,55),(56,60,63),(53,56,60),(55,59,62),(51,55,58),(56,60,63),(55,59,62),(48,51,55)], [
            [(0,79,1),(1,75,.5),(1.5,74,.5),(2,72,1)], [(0,75,1.5),(1.5,79,.5),(2,80,1)],
            [(0,84,1),(1,80,.5),(1.5,79,.5),(2,77,1)], [(0,79,1.5),(1.5,77,.25),(1.75,75,.25),(2,74,1)],
            [(0,79,1),(1,82,.5),(1.5,79,.5),(2,75,1)], [(0,80,1.5),(1.5,79,.5),(2,75,1)],
            [(0,74,.5),(.5,75,.5),(1,77,.5),(1.5,74,.5),(2,71,1)], [(0,72,3)]], 'lead')]
    tracks, metadata = [], []
    for args in specifications:
        track, meta = compose(*args)
        tracks.append(track)
        metadata.append(meta)
    preview = []
    for track in tracks:
        excerpt = track[:RATE * 12].copy()
        excerpt[:RATE // 4] *= np.linspace(0, 1, RATE // 4)[:, None]
        excerpt[-RATE // 2:] *= np.linspace(1, 0, RATE // 2)[:, None]
        preview.extend([excerpt, np.zeros((RATE // 2, 2))])
    save(OUT / 'preview.wav', np.concatenate(preview))
    (OUT / 'compositions.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
