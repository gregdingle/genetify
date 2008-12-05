#!/usr/bin/env python

import os
import sys
import math
import random

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ROOT, '..'))

from pygooglechart import SimpleLineChart
from pygooglechart import Axis

import settings
import helper

def cat_proximity():
    """Cat proximity graph from http://xkcd.com/231/"""
    chart = SimpleLineChart(int(settings.width * 1.5), settings.height)
    chart.set_legend(['INTELLIGENCE', 'INSANITY OF STATEMENTS'])

    # intelligence
    data_index = chart.add_data([100. / y for y in xrange(1, 15)])

    # insanity of statements
    chart.add_data([100. - 100 / y for y in xrange(1, 15)])

    # line colours
    chart.set_colours(['208020', '202080'])

    # "Near" and "Far" labels, they are placed automatically at either ends.
    near_far_axis_index = chart.set_axis_labels(Axis.BOTTOM, ['FAR', 'NEAR'])

    # "Human Proximity to cat" label. Aligned to the center.
    index = chart.set_axis_labels(Axis.BOTTOM, ['HUMAN PROXIMITY TO CAT'])
    chart.set_axis_style(index, '202020', font_size=10, alignment=0)
    chart.set_axis_positions(index, [50])

    chart.download('label-cat-proximity.png')

def many_labels():
    chart = SimpleLineChart(settings.width, settings.height)

    for a in xrange(3):
        for axis_type in (Axis.LEFT, Axis.RIGHT, Axis.BOTTOM):
            index = chart.set_axis_range(axis_type, 0, random.random() * 100)
            chart.set_axis_style(index, colour=helper.random_colour(), \
                font_size=random.random() * 10 + 5)

    chart.add_data(helper.random_data())
    chart.download('label-many.png')

def main():
    cat_proximity()
    many_labels()

if __name__ == '__main__':
    main()

