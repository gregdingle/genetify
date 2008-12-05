#!/usr/bin/env python

import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ROOT, '..'))

from pygooglechart import PieChart2D
from pygooglechart import PieChart3D

import settings
import helper

def hello_world():
    chart = PieChart3D(settings.width, settings.height)
    chart.add_data([ord(a) for a in 'hW'])
    chart.set_pie_labels(['Hello', 'World'])
    chart.download('pie-hello-world.png')

def house_explosions():
    """
    Data from http://indexed.blogspot.com/2007/12/meltdown-indeed.html
    """
    chart = PieChart2D(int(settings.width * 1.7), settings.height)
    chart.add_data([10, 10, 30, 200])
    chart.set_pie_labels([
        'Budding Chemists',
        'Propane issues',
        'Meth Labs',
        'Attempts to escape morgage',
        ])
    chart.download('pie-house-explosions.png')

def main():
    hello_world()
    house_explosions()

if __name__ == '__main__':
    main()


