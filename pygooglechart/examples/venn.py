#!/usr/bin/env python

import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ROOT, '..'))

from pygooglechart import VennChart

import settings
import helper

def ultimate_power():
    """
    Data from http://indexed.blogspot.com/2007/08/real-ultimate-power.html
    """
    chart = VennChart(settings.width, settings.height)
    chart.add_data([100, 100, 100, 20, 20, 20, 10])
    chart.set_title('Ninjas or God')
    chart.set_legend(['unseen agents', 'super powerful', 'secret plans'])
    chart.download('venn-ultimate-power.png')

def main():
    ultimate_power()

if __name__ == '__main__':
    main()


