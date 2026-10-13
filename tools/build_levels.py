"""Construye los mapas de los 7 niveles en data/levels/*.json.

Uso:  py tools/build_levels.py

Leyenda del mapa (una celda = 16x16 px):
  .  vacío            #  suelo sólido          =  plataforma de un sentido
  B  caja sólida      ^  vidrios (daño)        o  bocadillo (coleccionable)
  p  pista            h  corazón (vida)        P  inicio del jugador
  C  punto de control X  meta / salida         F  amigo del nivel
  d  dron vigía       g  perro bravo           M  plataforma móvil horizontal
  V  plataforma móvil vertical                 |  barrera intermitente
  c  carro estacionado L  farola               S  señal de tránsito
  T  árbol/palmera    b  banca                 w  vitrina de tienda
  K  CAI              k  patrulla estacionada  t  caneca
  f  matera           !  letrero de ayuda (usa la lista "hints")
  n  cono (daño)
Restricciones de diseño (física del jugador): subir <= 3 celdas, hueco <= 4
caminando y <= 6 corriendo.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
H = 20
G = 16  # fila superior del suelo por defecto


class Map:
    def __init__(self):
        self.cols = []
        self.x = 0
        self.top = G

    def _col(self, x):
        while len(self.cols) <= x:
            self.cols.append(["."] * H)
        return self.cols[x]

    def set(self, x, y, ch):
        if 0 <= y < H:
            self._col(x)[y] = ch

    def ground(self, n, top=None, fill="#"):
        if top is not None:
            self.top = top
        start = self.x
        for i in range(n):
            col = self._col(self.x + i)
            for y in range(self.top, H):
                col[y] = fill
        self.x += n
        return start

    def pit(self, n):
        start = self.x
        for i in range(n):
            self._col(self.x + i)
        self.x += n
        return start

    def on(self, x, ch, dy=0, top=None):
        """Coloca algo de pie sobre el suelo de la columna x."""
        t = self.surface(x) if top is None else top
        self.set(x, t - 1 + dy, ch)

    def surface(self, x):
        col = self._col(x)
        for y in range(H):
            if col[y] in "#B":
                return y
        return H

    def row(self, x0, n, y, ch):
        for i in range(n):
            self.set(x0 + i, y, ch)

    def coins_arc(self, x0, n, y):
        for i in range(n):
            lift = 1 if 0 < i < n - 1 else 0
            self.set(x0 + i, y - lift, "o")

    def rows(self):
        w = len(self.cols)
        return ["".join(self.cols[x][y] for x in range(w)) for y in range(H)]


def level_1():
    m = Map()
    s = m.ground(16)
    m.on(s + 2, "P"); m.on(s + 1, "L"); m.on(s + 5, "!"); m.on(s + 11, "L"); m.on(s + 13, "S")
    m.coins_arc(s + 8, 4, G - 2)
    s = m.ground(14)
    m.on(s + 1, "!"); m.set(s + 4, G - 1, "B"); m.coins_arc(s + 3, 3, G - 4)
    m.on(s + 11, "t")
    m.pit(3)
    s = m.ground(14)
    m.on(s + 5, "c"); m.coins_arc(s + 4, 3, G - 4); m.on(s + 10, "L"); m.on(s + 1, "!")
    s = m.ground(8, top=14)
    m.on(s + 2, "!"); m.on(s + 5, "T")
    m.pit(4)
    s = m.ground(14, top=14)
    m.on(s + 3, "C"); m.on(s + 7, "L"); m.coins_arc(s + 8, 4, 11)
    s = m.ground(14, top=16)
    m.on(s + 1, "!"); m.on(s + 5, "^"); m.on(s + 6, "^"); m.coins_arc(s + 4, 4, G - 4)
    m.row(s + 9, 4, 12, "="); m.coins_arc(s + 9, 4, 11); m.on(s + 12, "c")
    s = m.ground(16)
    m.on(s + 1, "!"); m.on(s + 9, "g"); m.on(s + 4, "L"); m.on(s + 14, "S")
    m.row(s + 6, 4, 12, "="); m.set(s + 7, 11, "h")
    m.pit(2)
    s = m.ground(10, top=15)
    m.on(s + 4, "C"); m.on(s + 7, "c")
    m.pit(7)
    m.set(m.x - 4, 13, "M"); m.set(m.x - 4, 11, "o")
    s = m.ground(12, top=15)
    m.on(s + 1, "!"); m.on(s + 4, "n"); m.on(s + 8, "L"); m.coins_arc(s + 3, 3, 11)
    s = m.ground(6, top=13)
    m.coins_arc(s + 1, 4, 11)
    s = m.ground(18, top=15)
    m.on(s + 2, "c"); m.on(s + 6, "^"); m.on(s + 10, "g"); m.on(s + 15, "X"); m.on(s + 13, "L"); m.on(s + 17, "S")
    m.ground(6)
    return m.rows()


def level_2():
    m = Map()
    s = m.ground(14)
    m.on(s + 2, "P"); m.on(s + 5, "w"); m.on(s + 10, "w"); m.on(s + 1, "!")
    m.row(s + 8, 5, 12, "="); m.coins_arc(s + 8, 5, 11)
    s = m.ground(16)
    m.on(s + 3, "c"); m.on(s + 8, "L"); m.on(s + 12, "w")
    m.row(s + 6, 4, 11, "="); m.row(s + 11, 4, 9, "="); m.coins_arc(s + 11, 4, 8); m.set(s + 13, 8, "o")
    m.on(s + 6, "^"); m.on(s + 7, "^")
    m.pit(4)
    m.row(m.x - 4, 4, 13, "="); m.set(m.x - 3, 12, "o"); m.set(m.x - 2, 12, "o")
    s = m.ground(16, top=15)
    m.on(s + 3, "C"); m.on(s + 6, "w"); m.on(s + 11, "w"); m.on(s + 9, "g")
    m.row(s + 2, 5, 11, "="); m.row(s + 9, 5, 8, "="); m.coins_arc(s + 9, 5, 7)
    s = m.ground(4, top=13)
    s = m.ground(4, top=11)
    m.coins_arc(s, 4, 9)
    m.pit(4)
    s = m.ground(8, top=11)
    m.on(s + 2, "T"); m.on(s + 6, "t"); m.coins_arc(s + 2, 4, 8)
    s = m.ground(4, top=13)
    s = m.ground(16, top=15)
    m.on(s + 1, "!"); m.on(s + 4, "w"); m.on(s + 10, "c"); m.on(s + 14, "L")
    m.row(s + 2, 4, 11, "="); m.row(s + 7, 4, 9, "="); m.row(s + 12, 4, 7, "=")
    m.coins_arc(s + 12, 4, 6); m.set(s + 13, 5, "h")
    m.on(s + 6, "n")
    m.pit(6)
    m.set(m.x - 3, 12, "M")
    s = m.ground(14, top=15)
    m.on(s + 2, "C"); m.on(s + 6, "w"); m.on(s + 9, "^"); m.on(s + 10, "^"); m.on(s + 12, "w")
    m.coins_arc(s + 8, 4, 11)
    s = m.ground(3, top=14)
    s = m.ground(3, top=13)
    s = m.ground(12, top=12)
    m.on(s + 2, "g"); m.on(s + 6, "T"); m.coins_arc(s + 1, 5, 9); m.on(s + 9, "L")
    m.row(s + 4, 6, 8, "="); m.coins_arc(s + 4, 6, 7)
    m.pit(3)
    s = m.ground(10, top=14)
    m.on(s + 3, "c"); m.on(s + 7, "w")
    s = m.ground(20, top=15)
    m.on(s + 2, "w"); m.on(s + 5, "^"); m.on(s + 9, "g"); m.on(s + 12, "w")
    m.row(s + 3, 5, 11, "="); m.coins_arc(s + 3, 5, 10); m.on(s + 17, "X"); m.on(s + 15, "L")
    m.ground(6, top=15)
    return m.rows()


def level_3():
    m = Map()
    s = m.ground(14, top=15)
    m.on(s + 2, "P"); m.on(s + 6, "!"); m.on(s + 10, "L"); m.on(s + 12, "k")
    s = m.ground(18, top=15)
    m.on(s + 6, "K"); m.on(s + 1, "!"); m.on(s + 13, "L"); m.on(s + 16, "S")
    m.row(s + 2, 4, 11, "="); m.set(s + 3, 10, "p")
    s = m.ground(10, top=15)
    m.on(s + 3, "|"); m.on(s + 7, "|"); m.coins_arc(s + 4, 3, 13)
    s = m.ground(4, top=13)
    s = m.ground(4, top=11)
    m.set(s + 2, 7, "d")
    m.pit(4)
    s = m.ground(10, top=11)
    m.on(s + 3, "C"); m.coins_arc(s + 5, 4, 8)
    s = m.ground(6, top=14)
    m.on(s + 2, "^"); m.on(s + 3, "^")
    s = m.ground(14, top=15)
    m.on(s + 2, "k"); m.on(s + 8, "g"); m.on(s + 12, "L")
    m.row(s + 4, 3, 11, "="); m.row(s + 9, 3, 9, "="); m.set(s + 10, 8, "p")
    m.set(s + 6, 6, "d")
    s = m.ground(8, top=15)
    m.on(s + 2, "|"); m.on(s + 5, "|"); m.coins_arc(s + 2, 4, 12)
    m.pit(6)
    m.set(m.x - 3, 13, "V"); m.set(m.x - 3, 9, "o")
    s = m.ground(12, top=13)
    m.on(s + 2, "C"); m.on(s + 5, "c"); m.on(s + 9, "n"); m.set(s + 7, 8, "d")
    s = m.ground(4, top=11)
    s = m.ground(5, top=9)
    m.set(s + 2, 7, "h")
    m.pit(3)
    s = m.ground(6, top=10)
    m.row(s, 6, 5, "="); m.set(s + 3, 4, "p")
    s = m.ground(4, top=13)
    s = m.ground(18, top=15)
    m.on(s + 2, "|"); m.on(s + 5, "^"); m.on(s + 8, "|"); m.on(s + 11, "g"); m.on(s + 15, "X"); m.on(s + 13, "k")
    m.coins_arc(s + 3, 4, 12); m.set(s + 9, 10, "d")
    m.ground(6, top=15)
    return m.rows()


def level_4():
    m = Map()
    s = m.ground(16, top=15, fill="#")
    m.on(s + 2, "P"); m.on(s + 5, "T"); m.on(s + 9, "b"); m.on(s + 12, "T"); m.on(s + 7, "!")
    m.coins_arc(s + 8, 5, 12)
    s = m.ground(6, top=14)
    m.on(s + 3, "L")
    m.pit(5)
    m.set(m.x - 3, 13, "V")
    s = m.ground(12, top=12)
    m.on(s + 2, "T"); m.on(s + 6, "b"); m.coins_arc(s + 4, 5, 9); m.on(s + 10, "f")
    s = m.ground(8, top=14)
    m.on(s + 2, "T"); m.row(s + 3, 4, 10, "="); m.coins_arc(s + 3, 4, 9)
    s = m.ground(22, top=15)
    m.on(s + 3, "L"); m.on(s + 6, "b"); m.on(s + 10, "F"); m.on(s + 8, "C"); m.on(s + 14, "T"); m.on(s + 18, "L")
    m.on(s + 16, "!")
    s = m.ground(12, top=15)
    m.on(s + 3, "g")
    m.pit(4)
    s = m.ground(10, top=13)
    m.on(s + 3, "T"); m.coins_arc(s + 2, 5, 10)
    m.pit(6)
    m.set(m.x - 3, 11, "M"); m.set(m.x - 3, 9, "o")
    s = m.ground(12, top=12)
    m.on(s + 3, "C"); m.on(s + 6, "b"); m.on(s + 9, "T"); m.set(s + 5, 7, "d")
    s = m.ground(4, top=14)
    s = m.ground(16, top=15)
    m.on(s + 2, "T"); m.on(s + 5, "^"); m.on(s + 8, "g"); m.on(s + 13, "X"); m.on(s + 11, "L")
    m.coins_arc(s + 4, 3, 12)
    m.ground(6, top=15)
    return m.rows()


def level_5():
    m = Map()
    s = m.ground(12, top=15)
    m.on(s + 2, "P"); m.on(s + 5, "f"); m.on(s + 8, "L"); m.on(s + 10, "f"); m.on(s + 6, "!")
    # escaleras del barrio
    for k in range(4):
        s = m.ground(2, top=14 - k)
        m.set(s, 13 - k - 1, "o")
    s = m.ground(10, top=11)
    m.on(s + 3, "w"); m.on(s + 7, "f"); m.coins_arc(s + 2, 5, 8)
    m.pit(4)
    s = m.ground(8, top=11)
    m.on(s + 2, "g"); m.on(s + 6, "L")
    for k in range(3):
        s = m.ground(2, top=12 + k)
    s = m.ground(16, top=15)
    m.on(s + 2, "C"); m.on(s + 5, "c"); m.on(s + 9, "b"); m.on(s + 12, "w")
    m.set(s + 8, 8, "B"); m.set(s + 9, 8, "B"); m.row(s + 10, 3, 9, "=")
    m.coins_arc(s + 8, 5, 6)
    m.row(s + 13, 3, 12, "="); m.set(s + 14, 11, "h")
    s = m.ground(4, top=13)
    m.on(s + 1, "f")
    s = m.ground(4, top=11)
    m.on(s + 2, "n")
    m.pit(5)
    m.set(m.x - 3, 10, "M")
    s = m.ground(24, top=12)
    m.on(s + 3, "L"); m.on(s + 6, "b"); m.on(s + 9, "F"); m.on(s + 7, "C"); m.on(s + 12, "w"); m.on(s + 16, "f")
    m.on(s + 19, "g"); m.coins_arc(s + 13, 5, 9)
    for k in range(3):
        s = m.ground(2, top=13 + k)
        m.set(s, 11 + k, "o")
    s = m.ground(10, top=15)
    m.on(s + 2, "^"); m.on(s + 3, "^"); m.on(s + 7, "c"); m.coins_arc(s + 1, 4, 12)
    m.pit(3)
    s = m.ground(6, top=13)
    m.on(s + 2, "f"); m.set(s + 3, 9, "d")
    s = m.ground(4, top=10)
    m.coins_arc(s, 4, 7)
    m.pit(4)
    s = m.ground(8, top=12)
    m.on(s + 2, "C"); m.on(s + 5, "L")
    for k in range(3):
        s = m.ground(2, top=13 + k)
    s = m.ground(18, top=15)
    m.on(s + 2, "w"); m.on(s + 6, "g"); m.on(s + 9, "^"); m.on(s + 14, "X"); m.on(s + 12, "L"); m.on(s + 16, "f")
    m.coins_arc(s + 7, 5, 11); m.row(s + 3, 4, 11, "="); m.coins_arc(s + 3, 4, 10)
    m.ground(6, top=15)
    return m.rows()


def level_6():
    m = Map()
    s = m.ground(16, top=13)
    m.on(s + 2, "P"); m.on(s + 6, "!"); m.on(s + 10, "L"); m.on(s + 13, "S")
    m.pit(5)
    m.set(m.x - 3, 10, "o")
    s = m.ground(10, top=13)
    m.on(s + 4, "L"); m.on(s + 7, "c")
    m.pit(6)
    m.set(m.x - 4, 12, "M")
    s = m.ground(12, top=12)
    m.on(s + 2, "C"); m.on(s + 6, "^"); m.on(s + 7, "^"); m.coins_arc(s + 5, 4, 8); m.on(s + 10, "L")
    m.set(s + 9, 7, "d")
    m.pit(5)
    s = m.ground(4, top=11)
    m.coins_arc(s, 4, 8)
    m.pit(5)
    s = m.ground(14, top=12)
    m.on(s + 3, "c"); m.on(s + 8, "g"); m.on(s + 12, "L"); m.row(s + 5, 4, 8, "="); m.coins_arc(s + 5, 4, 7)
    m.pit(7)
    m.set(m.x - 5, 11, "M"); m.set(m.x - 2, 9, "V")
    s = m.ground(12, top=12)
    m.on(s + 2, "C"); m.on(s + 6, "n"); m.on(s + 9, "L"); m.set(s + 5, 7, "d")
    s = m.ground(4, top=11)
    m.pit(6)
    m.set(m.x - 3, 8, "o")
    s = m.ground(20, top=11)
    m.on(s + 3, "L"); m.on(s + 6, "C"); m.on(s + 10, "F"); m.on(s + 14, "L"); m.on(s + 17, "S")
    m.coins_arc(s + 12, 4, 7)
    s = m.ground(9, top=13)
    m.on(s + 2, "^")
    m.pit(5)
    s = m.ground(10, top=12)
    m.on(s + 2, "g"); m.on(s + 6, "c"); m.set(s + 4, 7, "d"); m.set(s + 8, 6, "h")
    m.pit(6)
    m.set(m.x - 3, 10, "M")
    s = m.ground(18, top=13)
    m.on(s + 3, "L"); m.on(s + 6, "^"); m.on(s + 13, "X"); m.on(s + 11, "L"); m.coins_arc(s + 5, 4, 9)
    m.ground(6, top=13)
    return m.rows()


def level_7():
    m = Map()
    s = m.ground(14, top=15)
    m.on(s + 2, "P"); m.on(s + 6, "L"); m.on(s + 9, "!"); m.on(s + 12, "w")
    s = m.ground(12, top=15)
    m.on(s + 3, "c"); m.on(s + 8, "^"); m.coins_arc(s + 6, 4, 11); m.row(s + 2, 4, 11, "=")
    m.pit(5)
    m.set(m.x - 3, 12, "M")
    s = m.ground(12, top=13)
    m.on(s + 2, "C"); m.on(s + 5, "g"); m.on(s + 9, "L"); m.set(s + 6, 8, "d")
    s = m.ground(4, top=11)
    s = m.ground(5, top=9)
    m.pit(4)
    s = m.ground(10, top=10)
    m.on(s + 3, "T"); m.coins_arc(s + 2, 5, 7); m.set(s + 7, 6, "h")
    for k in range(3):
        s = m.ground(2, top=11 + k * 2)
    s = m.ground(14, top=15)
    m.on(s + 2, "C"); m.on(s + 5, "|"); m.on(s + 9, "|"); m.on(s + 12, "w"); m.coins_arc(s + 5, 5, 12)
    m.pit(6)
    m.set(m.x - 4, 12, "M"); m.set(m.x - 2, 10, "o")
    s = m.ground(10, top=14)
    m.on(s + 2, "g"); m.on(s + 6, "^"); m.on(s + 7, "^"); m.set(s + 4, 9, "d")
    s = m.ground(30, top=15)
    m.on(s + 2, "C"); m.on(s + 6, "L"); m.on(s + 10, "T"); m.on(s + 13, "b"); m.on(s + 16, "k")
    m.on(s + 20, "L"); m.on(s + 24, "X"); m.on(s + 27, "T"); m.coins_arc(s + 3, 5, 12)
    m.ground(6, top=15)
    return m.rows()


LEVELS = [
    dict(id="level_01", title="Nivel 1: Calles nocturnas", subtitle="Una confusión con la mochila negra",
         theme="calles", music="chase", rain=False, build=level_1,
         chase=dict(mode="delay", delay=6.0, speed=52.0, accel=0.35, max_speed=78.0),
         mission=[dict(type="reach_exit", text="Escapa de la persecución y llega a la meta")],
         intro="intro_level_01", outro=None, friend=None,
         hints=["Muévete con A/D o las flechas", "Salta con ESPACIO, W o flecha arriba",
                "Súbete a los carros para saltar más alto", "Mantén SHIFT para correr: los huecos grandes lo necesitan",
                "Los vidrios rotos y los conos hacen daño", "Los perros bravos no se pisan: ¡sáltalos!",
                "Las plataformas móviles te llevan sobre los huecos"]),
    dict(id="level_02", title="Nivel 2: Sector comercial", subtitle="Luces y vitrinas de Cabecera",
         theme="comercial", music="chase", rain=True, build=level_2,
         chase=dict(mode="delay", delay=4.0, speed=58.0, accel=0.4, max_speed=84.0),
         mission=[dict(type="collect", count=18, text="Recoge 18 bocadillos para invitar a tus amigos"),
                  dict(type="reach_exit", text="Llega a la meta")],
         intro="intro_level_02", outro=None, friend=None,
         hints=["Los toldos son rutas alternativas con más bocadillos", "Sigue la ruta alta para esquivar a los perros"]),
    dict(id="level_03", title="Nivel 3: El CAI", subtitle="Aclarar el malentendido",
         theme="cai", music="chase", rain=False, build=level_3,
         chase=dict(mode="delay", delay=5.0, speed=62.0, accel=0.45, max_speed=88.0),
         mission=[dict(type="pistas", count=3, text="Encuentra 3 pistas sobre el verdadero ladrón"),
                  dict(type="reach_exit", text="Llega a la meta con las pistas")],
         intro="intro_level_03", outro=None, friend=None,
         hints=["El CAI está cerrado: busca pistas para demostrar tu inocencia",
                "Las barreras se abren y se cierran: espera tu momento. Salta sobre los drones para desactivarlos"]),
    dict(id="level_04", title="Nivel 4: El parque", subtitle="Primer reencuentro",
         theme="parque", music="park", rain=False, build=level_4,
         chase=dict(mode="after_friend", delay=1.5, speed=64.0, accel=0.45, max_speed=90.0),
         mission=[dict(type="friend", text="Encuentra a tu amigo en el parque"),
                  dict(type="reach_exit", text="Salgan juntos del parque")],
         intro="intro_level_04", outro=None,
         friend=dict(id="gorra", dialogue="friend_gorra"),
         hints=["Acércate a tu amigo y presiona E para hablar", "¡La patrulla volvió! Corre hacia la salida"]),
    dict(id="level_05", title="Nivel 5: El barrio", subtitle="Escaleras, tiendas y vecinos",
         theme="barrio", music="chase", rain=True, build=level_5,
         chase=dict(mode="delay", delay=5.0, speed=68.0, accel=0.5, max_speed=94.0),
         mission=[dict(type="friend", text="Encuentra a tu amigo en la tienda del barrio"),
                  dict(type="collect", count=14, text="Recoge 14 bocadillos"),
                  dict(type="reach_exit", text="Llega a la meta")],
         intro="intro_level_05", outro=None,
         friend=dict(id="rulos", dialogue="friend_rulos"),
         hints=["Habla con los amigos con E: se unen al grupo"]),
    dict(id="level_06", title="Nivel 6: El viaducto", subtitle="La persecución más exigente",
         theme="viaducto", music="viaduct", rain=False, build=level_6,
         chase=dict(mode="delay", delay=3.0, speed=78.0, accel=0.6, max_speed=104.0),
         mission=[dict(type="friend", text="Rescata a tu amigo atrapado en el viaducto"),
                  dict(type="reach_exit", text="Cruza el viaducto")],
         intro="intro_level_06", outro=None,
         friend=dict(id="gafas", dialogue="friend_gafas"),
         hints=["¡Corre (SHIFT) y salta! Los huecos del viaducto son largos"]),
    dict(id="level_07", title="Nivel 7: Encuentro final", subtitle="Todos juntos hasta el mirador",
         theme="final", music="finale", rain=False, build=level_7,
         chase=dict(mode="delay", delay=3.0, speed=74.0, accel=0.5, max_speed=98.0),
         mission=[dict(type="reach_exit", text="Llega al mirador con tus amigos")],
         intro="intro_level_07", outro="ending", friend=None,
         hints=["Último esfuerzo: el mirador está al final de la calle"]),
]


def validate(lid, rows):
    w = len(rows[0])
    assert all(len(r) == w for r in rows), lid
    flat = "".join(rows)
    for ch in "PX":
        assert flat.count(ch) == 1, (lid, ch, flat.count(ch))
    # Huecos: ninguno mayor a 7 celdas
    gap = 0
    for x in range(w):
        if all(rows[y][x] not in "#B" for y in range(H)):
            gap += 1
            assert gap <= 7, (lid, "hueco demasiado ancho en x=%d" % x)
        else:
            gap = 0
    return w


def main():
    out_dir = os.path.join(ROOT, "data", "levels")
    os.makedirs(out_dir, exist_ok=True)
    index = []
    for lv in LEVELS:
        rows = lv["build"]()
        w = validate(lv["id"], rows)
        hints_needed = "".join(rows).count("!")
        assert hints_needed <= len(lv["hints"]), (lv["id"], hints_needed, len(lv["hints"]))
        data = {k: v for k, v in lv.items() if k != "build"}
        data["tile_size"] = 16
        data["width"] = w
        data["height"] = H
        data["map"] = rows
        with open(os.path.join(out_dir, lv["id"] + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
        index.append(dict(id=lv["id"], title=lv["title"], scene="res://scenes/levels/%s.tscn" % lv["id"]))
        print(lv["id"], "ancho", w, "bocadillos", "".join(rows).count("o"), "pistas", "".join(rows).count("p"))
    with open(os.path.join(out_dir, "levels.json"), "w", encoding="utf-8") as f:
        json.dump(dict(levels=index), f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
