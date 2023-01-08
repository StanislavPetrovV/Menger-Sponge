import random
import pygame as pg

WIN_SIZE = 1000
vec = pg.math.Vector2


class Carpet:
    def __init__(self, app):
        self.screen = app.screen
        self.attractors = [vec(0.0, 0.0), vec(0.0, 1.0), vec(1.0, 1.0), vec(1.0, 0.0),
                           vec(0.0, 0.5), vec(0.5, 1.0), vec(1.0, 0.5), vec(0.5, 0.0)]
        self.index = 0
        self.point = vec(random.random())
        self.colors = ['red', 'green', 'blue', 'orange', 'yellow', 'cyan', 'magenta', 'purple']

    def update(self):
        self.index = random.randrange(len(self.attractors))
        attractor = self.attractors[self.index]
        self.point = (self.point + 2 * attractor) / 3

    def draw(self):
        point = self.point * WIN_SIZE
        self.screen.set_at((int(point.x), int(point.y)), self.colors[self.index])


class App:
    def __init__(self):
        self.screen = pg.display.set_mode([WIN_SIZE] * 2)
        self.clock = pg.time.Clock()
        self.carpet = Carpet(self)

    def update(self):
        self.carpet.update()
        self.clock.tick(0)

    def draw(self):
        self.carpet.draw()
        pg.display.flip()

    def check_events(self):
        [exit() for e in pg.event.get() if e.type == pg.QUIT]

    def run(self):
        while True:
            self.check_events()
            self.update()
            self.draw()


if __name__ == '__main__':
    App().run()