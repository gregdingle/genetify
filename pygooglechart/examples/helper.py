import random

def random_data(points=50, maximum=100):
    return [random.random() * maximum for a in xrange(points)]

def random_colour(min=20, max=200):
    func = lambda: int(random.random() * (max-min) + min)
    r, g, b = func(), func(), func()
    return '%02X%02X%02X' % (r, g, b)

