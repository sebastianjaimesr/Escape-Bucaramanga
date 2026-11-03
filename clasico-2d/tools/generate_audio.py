"""Genera música y efectos de sonido chiptune originales (WAV 16 bits, mono).

Uso:  py tools/generate_audio.py
Todo el audio es sintetizado aquí y se distribuye con el juego bajo CC0.
"""
import os
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
SR = 22050
rng = np.random.default_rng(1234)


def save(name, data, folder):
    data = np.clip(data, -1.0, 1.0)
    pcm = (data * 32000).astype(np.int16)
    p = os.path.join(OUT, folder, name + ".wav")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with wave.open(p, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def freq(note):
    return 440.0 * 2 ** ((note - 69) / 12.0)


def square(f, dur, duty=0.5):
    t = t_axis(dur)
    if np.isscalar(f):
        ph = (t * f) % 1.0
    else:
        ph = np.cumsum(f) / SR % 1.0
    return np.where(ph < duty, 1.0, -1.0)


def triangle(f, dur):
    t = t_axis(dur)
    ph = (t * f) % 1.0
    return 4 * np.abs(ph - 0.5) - 1


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def env(n, a=0.005, d=0.1, s=0.6, r=0.05, dur=None):
    total = n / SR
    out = np.ones(n) * s
    ai = int(a * SR)
    di = int(d * SR)
    ri = int(r * SR)
    if ai:
        out[:ai] = np.linspace(0, 1, ai)
    if di:
        out[ai:ai + di] = np.linspace(1, s, len(out[ai:ai + di]))
    if ri:
        out[-ri:] *= np.linspace(1, 0, ri)
    return out


def decay(n, k=8.0):
    return np.exp(-np.linspace(0, k, n))


# ---------------------------------------------------------------------------
# Efectos
# ---------------------------------------------------------------------------

def sfx():
    d = 0.18
    f = np.linspace(330, 880, int(SR * d))
    save("jump", square(f, d, 0.25) * decay(len(f), 3) * 0.35, "sfx")

    d = 0.08
    save("land", noise(d) * decay(int(SR * d), 6) * 0.3, "sfx")

    a = square(freq(84), 0.06, 0.5)
    b = square(freq(91), 0.12, 0.5)
    s = np.concatenate([a, b])
    save("collect", s * decay(len(s), 3) * 0.3, "sfx")

    d = 0.35
    f = np.linspace(500, 120, int(SR * d))
    s = square(f, d, 0.5) * 0.6 + noise(d) * 0.4
    save("hurt", s * decay(len(s), 4) * 0.35, "sfx")

    d = 0.15
    f = np.linspace(200, 60, int(SR * d))
    s = square(f, d, 0.5) * 0.7 + noise(d) * 0.3
    save("stomp", s * decay(len(s), 5) * 0.4, "sfx")

    notes = [72, 76, 79, 84]
    s = np.concatenate([square(freq(n), 0.07, 0.25) for n in notes])
    save("checkpoint", s * decay(len(s), 2) * 0.3, "sfx")

    s = square(freq(88), 0.03, 0.5)
    save("blip", s * decay(len(s), 4) * 0.18, "sfx")

    s = square(freq(76), 0.04, 0.5)
    save("ui_move", s * decay(len(s), 5) * 0.2, "sfx")
    s = np.concatenate([square(freq(79), 0.05), square(freq(86), 0.08)])
    save("ui_select", s * decay(len(s), 4) * 0.25, "sfx")

    # Sirena ficticia (bucle de 2 s)
    d = 2.0
    t = t_axis(d)
    f = 700 + 250 * np.sin(2 * np.pi * 1.0 * t)
    s = square(f, d, 0.5) * 0.5 + np.sin(np.cumsum(2 * np.pi * f) / SR) * 0.5
    save("siren", s * 0.18, "sfx")

    notes = [67, 72, 76, 79, 84, 79, 84]
    durs = [0.1, 0.1, 0.1, 0.1, 0.25, 0.1, 0.45]
    s = np.concatenate([square(freq(n), dd, 0.25) * env(int(SR * dd), r=0.03) for n, dd in zip(notes, durs)])
    save("win", s * 0.3, "sfx")

    notes = [72, 67, 64, 60]
    s = np.concatenate([square(freq(n), 0.22, 0.5) * env(int(SR * 0.22), r=0.05) for n in notes])
    save("lose", s * 0.3, "sfx")

    notes = [79, 83, 86, 91]
    s = np.concatenate([triangle(freq(n), 0.06) for n in notes])
    save("pista", s * decay(len(s), 2) * 0.4, "sfx")

    notes = [72, 76, 79, 76, 79, 84]
    s = np.concatenate([square(freq(n), 0.09, 0.125) * env(int(SR * 0.09), r=0.02) for n in notes])
    save("friend", s * 0.3, "sfx")

    d = 0.3
    f = np.linspace(200, 900, int(SR * d))
    s = square(f, d, 0.5)
    save("exit", s * decay(len(s), 2) * 0.25, "sfx")

    d = 0.25
    f = np.linspace(150, 600, int(SR * d))
    s = triangle(150, d) * 0 + square(f, d, 0.5)
    save("bounce", s * decay(len(s), 4) * 0.3, "sfx")

    save("alert", np.concatenate([square(freq(81), 0.1), np.zeros(int(SR * 0.05)), square(freq(81), 0.1)]) * 0.25, "sfx")


# ---------------------------------------------------------------------------
# Música
# ---------------------------------------------------------------------------

def render_track(bpm, bars, chords, melody, bass_style="eighth", drums=True, lead_duty=0.25, swing=0.0,
                 pad=True, volume=0.8):
    beat = 60.0 / bpm
    bar_len = beat * 4
    total = int(SR * bar_len * bars)
    out = np.zeros(total)

    def put(sig, start):
        i = int(start * SR)
        j = min(total, i + len(sig))
        out[i:j] += sig[: j - i]

    for b in range(bars):
        root, quality = chords[b % len(chords)]
        third = 3 if quality == "m" else 4
        tones = [root, root + third, root + 7]
        t0 = b * bar_len
        # Bajo
        steps = 8 if bass_style == "eighth" else 4
        for k in range(steps):
            n = root - 24 + (12 if (bass_style == "eighth" and k % 2) else 0)
            dur = bar_len / steps
            put(triangle(freq(n), dur * 0.95) * 0.35 * env(int(SR * dur * 0.95), r=0.02), t0 + k * dur)
        # Arpegio / colchón
        if pad:
            for k in range(8):
                n = tones[k % 3] + 12
                dur = bar_len / 8
                put(square(freq(n), dur * 0.8, 0.125) * 0.06 * decay(int(SR * dur * 0.8), 3), t0 + k * dur)
        # Batería
        if drums:
            for k in range(8):
                dur = bar_len / 8
                tt = t0 + k * dur
                if k in (0, 4):
                    kick = np.sin(2 * np.pi * np.cumsum(np.linspace(120, 40, int(SR * 0.12))) / SR)
                    put(kick * decay(len(kick), 5) * 0.5, tt)
                if k in (2, 6):
                    sn = noise(0.12)
                    put(sn * decay(len(sn), 6) * 0.22, tt)
                hh = noise(0.03)
                put(hh * decay(len(hh), 8) * 0.07, tt + (swing * dur if k % 2 else 0))
    # Melodía: lista de (nota o None, duración en corcheas)
    t = 0.0
    eighth = beat / 2
    total_len = bar_len * bars
    while t < total_len - 1e-6:
        for n, l in melody:
            if t >= total_len - 1e-6:
                break
            dur = l * eighth
            if n is not None:
                sig = square(freq(n), dur * 0.9, lead_duty) * env(int(SR * dur * 0.9), a=0.01, d=0.08, s=0.7, r=0.04)
                vib = 1.0
                put(sig * 0.13 * vib, t)
            t += dur
    out *= volume
    peak = np.max(np.abs(out))
    if peak > 0.95:
        out *= 0.95 / peak
    return out


def music():
    # Persecución nocturna (tensa, menor)
    chords = [(57, "m"), (53, ""), (55, ""), (52, "")]  # Am F G E
    mel = [(69, 2), (72, 1), (74, 1), (76, 2), (74, 1), (72, 1), (77, 2), (76, 2), (74, 2), (72, 2),
           (74, 2), (71, 1), (72, 1), (74, 2), (76, 2), (68, 2), (71, 2), (76, 4),
           (81, 2), (79, 1), (77, 1), (76, 2), (72, 2), (77, 1), (76, 1), (74, 2), (72, 4),
           (74, 2), (76, 1), (79, 1), (76, 2), (74, 2), (71, 2), (68, 2), (64, 4)]
    save("chase", render_track(150, 16, chords, mel, swing=0.1), "music")

    # Menú (misterioso, nocturno)
    chords = [(50, "m"), (46, ""), (48, ""), (45, "m")]  # Dm Bb C Am
    mel = [(74, 3), (72, 1), (69, 4), (None, 2), (70, 2), (72, 2), (74, 2), (77, 4), (76, 2), (74, 2),
           (72, 6), (None, 2), (69, 3), (70, 1), (72, 4), (74, 2), (72, 2), (69, 8)]
    save("menu", render_track(96, 16, chords, mel, drums=True, lead_duty=0.5, volume=0.7), "music")

    # Parque (tranquilo, mayor)
    chords = [(60, ""), (57, "m"), (53, ""), (55, "")]  # C Am F G
    mel = [(76, 2), (79, 2), (81, 2), (79, 2), (76, 4), (72, 4), (74, 2), (76, 2), (77, 2), (76, 2),
           (74, 8), (72, 2), (74, 2), (76, 2), (79, 2), (81, 4), (79, 4), (77, 2), (76, 2), (74, 2), (71, 2), (72, 8)]
    save("park", render_track(92, 16, chords, mel, bass_style="quarter", drums=False, lead_duty=0.5, volume=0.75), "music")

    # Viaducto (rápida, intensa)
    chords = [(52, "m"), (48, ""), (50, ""), (47, "")]  # Em C D B
    mel = [(76, 1), (79, 1), (83, 2), (81, 1), (79, 1), (78, 2), (76, 2), (74, 2), (76, 4),
           (71, 1), (74, 1), (78, 2), (76, 1), (74, 1), (75, 2), (71, 2), (75, 2), (78, 4)]
    save("viaduct", render_track(168, 16, chords, mel, swing=0.0), "music")

    # Final (triunfal)
    chords = [(55, ""), (52, "m"), (48, ""), (50, "")]  # G Em C D
    mel = [(79, 2), (83, 2), (86, 4), (84, 2), (83, 2), (81, 4), (79, 2), (81, 2), (83, 2), (84, 2),
           (86, 8), (88, 2), (86, 2), (84, 2), (83, 2), (81, 4), (79, 4), (81, 2), (83, 2), (78, 4), (79, 8)]
    save("finale", render_track(120, 16, chords, mel, lead_duty=0.25), "music")


if __name__ == "__main__":
    sfx()
    music()
    print("Audio generado en", OUT)
