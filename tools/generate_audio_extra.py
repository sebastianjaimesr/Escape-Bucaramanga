"""Efectos de sonido añadidos en la versión 1.1 (aditivo: no regenera los demás).

Uso:  py tools/generate_audio_extra.py
  hormiga  arpegio brillante al encontrar una hormiga culona
  star     campanita de estrella en la pantalla de victoria
  tally    tic corto del contador de puntaje
  start    acorde de "presiona para empezar" en la pantalla de título
"""
import numpy as np

from generate_audio import SR, decay, env, freq, save, square, triangle


def main():
    notes = [76, 81, 85, 88, 93]
    s = np.concatenate([square(freq(n), 0.055, 0.25) * env(int(SR * 0.055), r=0.01) for n in notes])
    tail = triangle(freq(93), 0.25) * decay(int(SR * 0.25), 4)
    save("hormiga", np.concatenate([s, tail]) * 0.3, "sfx")

    a = triangle(freq(88), 0.35) + 0.5 * triangle(freq(95), 0.35)
    save("star", a * decay(len(a), 3) * 0.32, "sfx")

    t = square(freq(96), 0.025, 0.25)
    save("tally", t * decay(len(t), 6) * 0.12, "sfx")

    chord = sum(square(freq(n), 0.7, 0.25) for n in (60, 64, 67, 72)) / 4.0
    save("start", chord * env(len(chord), a=0.01, d=0.2, s=0.5, r=0.3) * 0.35, "sfx")
    print("Efectos extra generados.")


if __name__ == "__main__":
    main()
