"""
PyGoogleChart - A complete Python wrapper for the Google Chart API

http://pygooglechart.slowchop.com/

Copyright 2007 Gerald Kaszuba

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""

import os
import urllib
import urllib2
import math
import random
import re

# Helper variables and functions
# -----------------------------------------------------------------------------

__version__ = '0.1.2'

reo_colour = re.compile('^([A-Fa-f0-9]{2,2}){3,4}$')


def _check_colour(colour):
    if not reo_colour.match(colour):
        raise InvalidParametersException('Colours need to be in ' \
            'RRGGBB or RRGGBBAA format. One of your colours has %s' % \
            colour)

# Exception Classes
# -----------------------------------------------------------------------------


class PyGoogleChartException(Exception):
    pass


class DataOutOfRangeException(PyGoogleChartException):
    pass


class UnknownDataTypeException(PyGoogleChartException):
    pass


class NoDataGivenException(PyGoogleChartException):
    pass


class InvalidParametersException(PyGoogleChartException):
    pass


class BadContentTypeException(PyGoogleChartException):
    pass


# Data Classes
# -----------------------------------------------------------------------------


class Data(object):

    def __init__(self, data):
        assert(type(self) != Data)  # This is an abstract class
        self.data = data


class SimpleData(Data):
    enc_map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

    def __repr__(self):
        encoded_data = []
        for data in self.data:
            sub_data = []
            for value in data:
                if value is None:
                    sub_data.append('_')
                elif value >= 0 and value <= SimpleData.max_value:
                    sub_data.append(SimpleData.enc_map[value])
                else:
                    raise DataOutOfRangeException()
            encoded_data.append(''.join(sub_data))
        return 'chd=s:' + ','.join(encoded_data)

    @staticmethod
    def max_value():
        return 61


class TextData(Data):

    def __repr__(self):
        encoded_data = []
        for data in self.data:
            sub_data = []
            for value in data:
                if value is None:
                    sub_data.append(-1)
                elif value >= 0 and value <= TextData.max_value:
                    sub_data.append(str(float(value)))
                else:
                    raise DataOutOfRangeException()
            encoded_data.append(','.join(sub_data))
        return 'chd=t:' + '|'.join(encoded_data)

    @staticmethod
    def max_value():
        return 100


class ExtendedData(Data):
    enc_map = \
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-.'

    def __repr__(self):
        encoded_data = []
        enc_size = len(ExtendedData.enc_map)
        for data in self.data:
            sub_data = []
            for value in data:
                if value is None:
                    sub_data.append('__')
                elif value >= 0 and value <= ExtendedData.max_value:
                    first, second = divmod(int(value), enc_size)
                    sub_data.append('%s%s' % (
                        ExtendedData.enc_map[first],
                        ExtendedData.enc_map[second]))
                else:
                    raise DataOutOfRangeException( \
                        'Item #%i "%s" is out of range' % (data.index(value), \
                        value))
            encoded_data.append(''.join(sub_data))
        return 'chd=e:' + ','.join(encoded_data)

    @staticmethod
    def max_value():
        return 4095

# Axis Classes
# -----------------------------------------------------------------------------


class Axis(object):
    BOTTOM = 'x'
    TOP = 't'
    LEFT = 'y'
    RIGHT = 'r'
    TYPES = (BOTTOM, TOP, LEFT, RIGHT)

    def __init__(self, axis_index, axis_type, **kw):
        assert(axis_type in Axis.TYPES)
        self.has_style = False
        self.axis_index = axis_index
        self.axis_type = axis_type
        self.positions = None

    def set_index(self, axis_index):
        self.axis_index = axis_index

    def set_positions(self, positions):
        self.positions = positions

    def set_style(self, colour, font_size=None, alignment=None):
        _check_colour(colour)
        self.colour = colour
        self.font_size = font_size
        self.alignment = alignment
        self.has_style = True

    def style_to_url(self):
        bits = []
        bits.append(str(self.axis_index))
        bits.append(self.colour)
        if self.font_size is not None:
            bits.append(str(self.font_size))
            if self.alignment is not None:
                bits.append(str(self.alignment))
        return ','.join(bits)

    def positions_to_url(self):
        bits = []
        bits.append(str(self.axis_index))
        bits += [str(a) for a in self.positions]
        return ','.join(bits)


class LabelAxis(Axis):

    def __init__(self, axis_index, axis_type, values, **kwargs):
        Axis.__init__(self, axis_index, axis_type, **kwargs)
        self.values = [str(a) for a in values]

    def __repr__(self):
        return '%i:|%s' % (self.axis_index, '|'.join(self.values))


class RangeAxis(Axis):

    def __init__(self, axis_index, axis_type, low, high, **kwargs):
        Axis.__init__(self, axis_index, axis_type, **kwargs)
        self.low = low
        self.high = high

    def __repr__(self):
        return '%i,%s,%s' % (self.axis_index, self.low, self.high)

# Chart Classes
# -----------------------------------------------------------------------------


class Chart(object):
    """Abstract class for all chart types.

    width are height specify the dimensions of the image. title sets the title
    of the chart. legend requires a list that corresponds to datasets.
    """

    BASE_URL = 'http://chart.apis.google.com/chart?'
    BACKGROUND = 'bg'
    CHART = 'c'
    SOLID = 's'
    LINEAR_GRADIENT = 'lg'
    LINEAR_STRIPES = 'ls'

    def __init__(self, width, height, title=None, legend=None, colours=None):
        assert(type(self) != Chart)  # This is an abstract class
        assert(isinstance(width, int))
        assert(isinstance(height, int))
        self.width = width
        self.height = height
        self.data = []
        self.set_title(title)
        self.set_legend(legend)
        self.set_colours(colours)
        self.fill_types = {
            Chart.BACKGROUND: None,
            Chart.CHART: None,
        }
        self.fill_area = {
            Chart.BACKGROUND: None,
            Chart.CHART: None,
        }
#        self.axis = {
#            Axis.TOP: None,
#            Axis.BOTTOM: None,
#            Axis.LEFT: None,
#            Axis.RIGHT: None,
#        }
        self.axis = []
        self.markers = []

    # URL generation
    # -------------------------------------------------------------------------

    def get_url(self):
        url_bits = self.get_url_bits()
        return self.BASE_URL + '&'.join(url_bits)

    def get_url_bits(self):
        url_bits = []
        # required arguments
        url_bits.append(self.type_to_url())
        url_bits.append('chs=%ix%i' % (self.width, self.height))
        url_bits.append(self.data_to_url())
        # optional arguments
        if self.title:
            url_bits.append('chtt=%s' % self.title)
        if self.legend:
            url_bits.append('chdl=%s' % '|'.join(self.legend))
        if self.colours:
            url_bits.append('chco=%s' % ','.join(self.colours))
        ret = self.fill_to_url()
        if ret:
            url_bits.append(ret)
        ret = self.axis_to_url()
        if ret:
            url_bits.append(ret)
        if self.markers:
            url_bits.append(self.markers_to_url())
        return url_bits

    # Downloading
    # -------------------------------------------------------------------------

    def download(self, file_name):
        opener = urllib2.urlopen(self.get_url())

        if opener.headers['content-type'] != 'image/png':
            raise BadContentTypeException('Server responded with a ' \
                'content-type of %s' % opener.headers['content-type'])

        open(file_name, 'wb').write(urllib.urlopen(self.get_url()).read())

    # Simple settings
    # -------------------------------------------------------------------------

    def set_title(self, title):
        if title:
            self.title = urllib.quote(title)
        else:
            self.title = None

    def set_legend(self, legend):
        # legend needs to be a list, tuple or None
        assert(isinstance(legend, list) or isinstance(legend, tuple) or
            legend is None)
        if legend:
            self.legend = [urllib.quote(a) for a in legend]
        else:
            self.legend = None

    # Chart colours
    # -------------------------------------------------------------------------

    def set_colours(self, colours):
        # colours needs to be a list, tuple or None
        assert(isinstance(colours, list) or isinstance(colours, tuple) or
            colours is None)
        # make sure the colours are in the right format
        if colours:
            for col in colours:
                _check_colour(col)
        self.colours = colours

    # Background/Chart colours
    # -------------------------------------------------------------------------

    def fill_solid(self, area, colour):
        assert(area in (Chart.BACKGROUND, Chart.CHART))
        _check_colour(colour)
        self.fill_area[area] = colour
        self.fill_types[area] = Chart.SOLID

    def _check_fill_linear(self, angle, *args):
        assert(isinstance(args, list) or isinstance(args, tuple))
        assert(angle >= 0 and angle <= 90)
        assert(len(args) % 2 == 0)
        args = list(args)  # args is probably a tuple and we need to mutate
        for a in xrange(len(args) / 2):
            col = args[a * 2]
            offset = args[a * 2 + 1]
            _check_colour(col)
            assert(offset >= 0 and offset <= 1)
            args[a * 2 + 1] = str(args[a * 2 + 1])
        return args

    def fill_linear_gradient(self, area, angle, *args):
        assert(area in (Chart.BACKGROUND, Chart.CHART))
        args = self._check_fill_linear(angle, *args)
        self.fill_types[area] = Chart.LINEAR_GRADIENT
        self.fill_area[area] = ','.join([str(angle)] + args)

    def fill_linear_stripes(self, area, angle, *args):
        assert(area in (Chart.BACKGROUND, Chart.CHART))
        args = self._check_fill_linear(angle, *args)
        self.fill_types[area] = Chart.LINEAR_STRIPES
        self.fill_area[area] = ','.join([str(angle)] + args)

    def fill_to_url(self):
        areas = []
        for area in (Chart.BACKGROUND, Chart.CHART):
            if self.fill_types[area]:
                areas.append('%s,%s,%s' % (area, self.fill_types[area], \
                    self.fill_area[area]))
        if areas:
            return 'chf=' + '|'.join(areas)

    # Data
    # -------------------------------------------------------------------------

    def data_class_detection(self, data):
        """
        Detects and returns the data type required based on the range of the
        data given. The data given must be lists of numbers within a list.
        """
        assert(isinstance(data, list) or isinstance(data, tuple))
        max_value = None
        for a in data:
            assert(isinstance(a, list) or isinstance(a, tuple))
            if max_value is None or max(a) > max_value:
                max_value = max(a)
        # don't use SimpleData because no support for floats
        # for data_class in (SimpleData, TextData, ExtendedData):
        for data_class in (TextData, ExtendedData):
            if max_value <= data_class.max_value():
                return data_class
        raise DataOutOfRangeException()

    def add_data(self, data):
        self.data.append(data)
        return len(self.data) - 1  # return the "index" of the data set

    def data_to_url(self, data_class=None):
        if not data_class:
            data_class = self.data_class_detection(self.data)
        if not issubclass(data_class, Data):
            raise UnknownDataTypeException()
        return repr(data_class(self.data))

    # Axis Labels
    # -------------------------------------------------------------------------

    def set_axis_labels(self, axis_type, values):
        assert(axis_type in Axis.TYPES)
        values = [ urllib.quote(a) for a in values ]
        axis_index = len(self.axis)
        axis = LabelAxis(axis_index, axis_type, values)
        self.axis.append(axis)
        return axis_index

    def set_axis_range(self, axis_type, low, high):
        assert(axis_type in Axis.TYPES)
        axis_index = len(self.axis)
        axis = RangeAxis(axis_index, axis_type, low, high)
        self.axis.append(axis)
        return axis_index

    def set_axis_positions(self, axis_index, positions):
        try:
            self.axis[axis_index].set_positions(positions)
        except IndexError:
            raise InvalidParametersException('Axis index %i has not been ' \
                'created' % axis)

    def set_axis_style(self, axis_index, colour, font_size=None, \
            alignment=None):
        try:
            self.axis[axis_index].set_style(colour, font_size, alignment)
        except IndexError:
            raise InvalidParametersException('Axis index %i has not been ' \
                'created' % axis)

    def axis_to_url(self):
        available_axis = []
        label_axis = []
        range_axis = []
        positions = []
        styles = []
        index = -1
        for axis in self.axis:
            available_axis.append(axis.axis_type)
            if isinstance(axis, RangeAxis):
                range_axis.append(repr(axis))
            if isinstance(axis, LabelAxis):
                label_axis.append(repr(axis))
            if axis.positions:
                positions.append(axis.positions_to_url())
            if axis.has_style:
                styles.append(axis.style_to_url())
        if not available_axis:
            return
        url_bits = []
        url_bits.append('chxt=%s' % ','.join(available_axis))
        if label_axis:
            url_bits.append('chxl=%s' % '|'.join(label_axis))
        if range_axis:
            url_bits.append('chxr=%s' % '|'.join(range_axis))
        if positions:
            url_bits.append('chxp=%s' % '|'.join(positions))
        if styles:
            url_bits.append('chxs=%s' % '|'.join(styles))
        return '&'.join(url_bits)

    # Markers, Ranges and Fill area (chm)
    # -------------------------------------------------------------------------

    def markers_to_url(self):
        return 'chm=%s' % '|'.join([','.join(a) for a in self.markers])

    def add_marker(self, index, point, marker_type, colour, size):
        self.markers.append((marker_type, colour, str(index), str(point), \
            str(size)))

    def add_horizontal_range(self, colour, start, stop):
        self.markers.append(('r', colour, '1', str(start), str(stop)))

    def add_vertical_range(self, colour, start, stop):
        self.markers.append(('R', colour, '1', str(start), str(stop)))

    def add_fill_range(self, colour, index_start, index_end):
        self.markers.append(('b', colour, str(index_start), str(index_end), \
            '1'))

    def add_fill_simple(self, colour):
        self.markers.append(('B', colour, '1', '1', '1'))


class ScatterChart(Chart):

    def __init__(self, *args, **kwargs):
        Chart.__init__(self, *args, **kwargs)

    def type_to_url(self):
        return 'cht=s'


class LineChart(Chart):

    def __init__(self, *args, **kwargs):
        assert(type(self) != LineChart)  # This is an abstract class
        Chart.__init__(self, *args, **kwargs)
        self.line_styles = {}
        self.grid = None

    def set_line_style(self, index, thickness=1, line_segment=None, \
            blank_segment=None):
        value = []
        value.append(str(thickness))
        if line_segment:
            value.append(str(line_segment))
            value.append(str(blank_segment))
        self.line_styles[index] = value

    def set_grid(self, x_step, y_step, line_segment=1, \
            blank_segment=0):
        self.grid = '%s,%s,%s,%s' % (x_step, y_step, line_segment, \
            blank_segment)

    def get_url_bits(self):
        url_bits = Chart.get_url_bits(self)
        if self.line_styles:
            style = []
            # for index, values in self.line_style.items():
            for index in xrange(max(self.line_styles) + 1):
                if index in self.line_styles:
                    values = self.line_styles[index]
                else:
                    values = ('1', )
                style.append(','.join(values))
            url_bits.append('chls=%s' % '|'.join(style))
        if self.grid:
            url_bits.append('chg=%s' % self.grid)
        return url_bits


class SimpleLineChart(LineChart):

    def type_to_url(self):
        return 'cht=lc'


class XYLineChart(LineChart):

    def type_to_url(self):
        return 'cht=lxy'


class BarChart(Chart):

    def __init__(self, *args, **kwargs):
        assert(type(self) != BarChart)  # This is an abstract class
        Chart.__init__(self, *args, **kwargs)
        self.bar_width = None

    def set_bar_width(self, bar_width):
        self.bar_width = bar_width

    def get_url_bits(self):
        url_bits = Chart.get_url_bits(self)
        url_bits.append('chbh=%i' % self.bar_width)
        return url_bits


class StackedHorizontalBarChart(BarChart):

    def type_to_url(self):
        return 'cht=bhs'


class StackedVerticalBarChart(BarChart):

    def type_to_url(self):
        return 'cht=bvs'


class GroupedBarChart(BarChart):

    def __init__(self, *args, **kwargs):
        assert(type(self) != GroupedBarChart)  # This is an abstract class
        BarChart.__init__(self, *args, **kwargs)
        self.bar_spacing = None

    def set_bar_spacing(self, spacing):
        self.bar_spacing = spacing

    def get_url_bits(self):
        # Skip 'BarChart.get_url_bits' and call Chart directly so the parent
        # doesn't add "chbh" before we do.
        url_bits = Chart.get_url_bits(self)
        if self.bar_spacing is not None:
            if self.bar_width is None:
                raise InvalidParametersException('Bar width is required to ' \
                    'be set when setting spacing')
            url_bits.append('chbh=%i,%i' % (self.bar_width, self.bar_spacing))
        else:
            url_bits.append('chbh=%i' % self.bar_width)
        return url_bits


class GroupedHorizontalBarChart(GroupedBarChart):

    def type_to_url(self):
        return 'cht=bhg'


class GroupedVerticalBarChart(GroupedBarChart):

    def type_to_url(self):
        return 'cht=bvg'


class PieChart(Chart):

    def __init__(self, *args, **kwargs):
        assert(type(self) != PieChart)  # This is an abstract class
        Chart.__init__(self, *args, **kwargs)
        self.pie_labels = []

    def set_pie_labels(self, labels):
        self.pie_labels = [urllib.quote(a) for a in labels]

    def get_url_bits(self):
        url_bits = Chart.get_url_bits(self)
        if self.pie_labels:
            url_bits.append('chl=%s' % '|'.join(self.pie_labels))
        return url_bits


class PieChart2D(PieChart):

    def type_to_url(self):
        return 'cht=p'


class PieChart3D(PieChart):

    def type_to_url(self):
        return 'cht=p3'


class VennChart(Chart):

    def type_to_url(self):
        return 'cht=v'


def test():
    chart = GroupedVerticalBarChart(320, 200)
    chart = PieChart2D(320, 200)
    chart = ScatterChart(320, 200)
    chart = SimpleLineChart(320, 200)
    sine_data = [math.sin(float(a) / 10) * 2000 + 2000 for a in xrange(100)]
    random_data = [a * random.random() * 30 for a in xrange(40)]
    random_data2 = [random.random() * 4000 for a in xrange(10)]
#    chart.set_bar_width(50)
#    chart.set_bar_spacing(0)
    chart.add_data(sine_data)
    chart.add_data(random_data)
    chart.add_data(random_data2)
#    chart.set_line_style(1, thickness=2)
#    chart.set_line_style(2, line_segment=10, blank_segment=5)
#    chart.set_title('heloooo')
#    chart.set_legend(('sine wave', 'random * x'))
#    chart.set_colours(('ee2000', 'DDDDAA', 'fF03f2'))
#    chart.fill_solid(Chart.BACKGROUND, '123456')
#    chart.fill_linear_gradient(Chart.CHART, 20, '004070', 1, '300040', 0,
#        'aabbcc00', 0.5)
#    chart.fill_linear_stripes(Chart.CHART, 20, '204070', .2, '300040', .2,
#        'aabbcc00', 0.2)
    axis_left_index = chart.set_axis_range(Axis.LEFT, 0, 10)
    axis_left_index = chart.set_axis_range(Axis.LEFT, 0, 10)
    axis_left_index = chart.set_axis_range(Axis.LEFT, 0, 10)
    axis_right_index = chart.set_axis_range(Axis.RIGHT, 5, 30)
    axis_bottom_index = chart.set_axis_labels(Axis.BOTTOM, [1, 25, 95])
    chart.set_axis_positions(axis_bottom_index, [1, 25, 95])
    chart.set_axis_style(axis_bottom_index, '003050', 15)

#    chart.set_pie_labels(('apples', 'oranges', 'bananas'))

#    chart.set_grid(10, 10)

#    for a in xrange(0, 100, 10):
#        chart.add_marker(1, a, 'a', 'AACA20', 10)

    chart.add_horizontal_range('00A020', .2, .5)
    chart.add_vertical_range('00c030', .2, .4)

    chart.add_fill_simple('303030A0')

    chart.download('test.png')

    url = chart.get_url()
    print url
    if 0:
        data = urllib.urlopen(chart.get_url()).read()
        open('meh.png', 'wb').write(data)
        os.system('start meh.png')


if __name__ == '__main__':
    test()
