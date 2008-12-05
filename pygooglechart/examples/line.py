#!/usr/bin/env python

import os
import sys
import math

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ROOT, '..'))

from pygooglechart import SimpleLineChart
from pygooglechart import XYLineChart

import settings
import helper

def simple_random():
    chart = SimpleLineChart(settings.width, settings.height)
    chart.add_data(helper.random_data())
    # chart.download('line-simple-random.png')
    print chart.get_url()

def xy_random():
    chart = XYLineChart(settings.width, settings.height)
    chart.add_data(helper.random_data())
    chart.add_data(helper.random_data())
    chart.download('line-xy-random.png')

def xy_rect():
    chart = XYLineChart(settings.width, settings.height)
    chart.add_data([10, 90, 90, 10, 10])
    chart.add_data([10, 10, 90, 90, 10])
    chart.download('line-xy-rect.png')

def xy_circle():
    chart = XYLineChart(settings.width, settings.height)
    steps = 40
    xradius = 25
    yradius = 45
    xmid = 50
    ymid = 50
    xlist = []
    ylist = []
    for angle in xrange(0, steps + 1):
        angle = float(angle) / steps * math.pi * 2
        xlist.append(math.cos(angle) * xradius + xmid)
        ylist.append(math.sin(angle) * yradius + ymid)
    chart.add_data(xlist)
    chart.add_data(ylist)
    chart.download('line-xy-circle.png')

def main():
    simple_random()
    # xy_random()
    # xy_rect()
    # xy_circle()

if __name__ == '__main__':
    main()

