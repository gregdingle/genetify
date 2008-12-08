#!/usr/bin/env python

import cgitb; cgitb.enable()
import cgi, MySQLdb, os, itertools, math

import pygooglechart

from pprint import pprint as _pprint

CHART_FONT_SIZE = 11
CHART_WIDTH = 220
CHART_HEIGHT_FACTOR = 40

def pprint(data):
    print 'Content-type: text/html\n'
    _pprint(data)

def main():
    if not os.environ.get('SERVER_NAME'):
        # test data for non-CGI mode
        domain='genetify.com'
        page='/genetify/'
        gene='mygene'
        chart='strip'
        return_mode ='text'
    else:
        request = cgi.FieldStorage()
        domain = request.getfirst('domain')
        assert(domain)
        page = request.getfirst('page')
        assert(page)
        gene = request.getfirst('gene')
        assert(gene)
        chart = request.getfirst('chart')
        assert(chart)
        return_mode = request.getfirst('return') #optional

    # TODO: make class of custom charts
    if chart == 'bar':
        data = fetch_data(get_sql(domain, page, gene, 'bar'))
        chart = GenetifyBarChart(data, title='Average reward', x_key='avg_reward')
        URL = chart.get_url()
    elif chart == 'prob':
        data = fetch_data(get_sql(domain, page, gene, 'prob'))
        chart = GenetifyBarChart(data, title='Optimized probability', x_key='variant_weight', color='FF77FF')
        URL = chart.get_url()
    elif chart == 'share':
        data = fetch_data(get_sql(domain, page, gene, 'prob'))
        chart = GenetifyBarChart(data, title='Share of total reward', x_key='variant_share', color='FF7777')
        URL = chart.get_url()
    elif chart == 'strip':
        # TODO: refactor strip
        URL = generate_strip_chart(fetch_data(get_sql(domain, page, gene, 'strip')))

    if return_mode == 'html':
        print 'Content-type: text/html\n'
        print wrap_html(URL)
    if return_mode == 'text':
        print 'Content-type: text/plain\n'
        print URL
    else:
        print 'Location: %s \n' % URL

def wrap_html(img_src):
    return '<img src="%s">' % img_src

def scale(l, new_max=100):
    return [float(i) * new_max / max(l) for i in l]

def unique(seq, keepstr=True):
    seen = []
    return [c for c in seq if not (c in seen or seen.append(c))]

# TODO: refactor this function into class init functions
def get_sql(domain, page, gene, chart_type='bar'):
    if chart_type == 'bar':
        # TODO: create better query that doesn't use slow view
        sql = '''SELECT gene_name, variant_name, gene_variant, AVG(reward) AS avg_reward
            FROM variant_reward
            WHERE domain_name = "%s" AND page_name = "%s" AND gene_name = "%s"
            GROUP BY variant_id
            ORDER BY variant_name = '__original__', variant_name DESC
            ''' % (domain, page, gene)

    elif chart_type == 'prob':
        sql = '''SELECT * FROM result WHERE domain_name = "%s" AND page_name = "%s" AND gene_name = "%s"
            ORDER BY variant_name = '__original__', variant_name DESC
            ''' % (domain, page, gene)


    elif chart_type == 'strip':
        # TODO: create better query that doesn't use slow view
        sql = '''SELECT gene_name, variant_name, gene_variant, reward, COUNT(reward) AS count_reward
            FROM variant_reward
            WHERE domain_name = "%s" AND page_name = "%s" AND gene_name = "%s"
            GROUP BY variant_id, reward
            ORDER BY variant_name = '__original__', variant_name DESC
            ''' % (domain, page, gene)

    return sql

def fetch_data(sql):
    cursor = conn.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute(sql)
    rows = cursor.fetchall()
    assert(len(rows) != 0)

    return rows

class GenetifyBarChart(pygooglechart.GroupedHorizontalBarChart):

    def __init__(self, data, title, x_key, color=None):
        # TODO: goal name is buggy... need seperate query for goals
        # goals = set([row['goal_name'] for row in data if row['goal_name'] != None])
        # title = 'Average effects of "%s" on "%s"' % (gene, ', '.join(goals))
        pygooglechart.GroupedHorizontalBarChart.__init__(self, CHART_WIDTH, 0, title=title)

        # # TODO: this seems to determine total height of chart!
        self.set_bar_width(CHART_HEIGHT_FACTOR - CHART_HEIGHT_FACTOR/4)
        if color:
            self.set_colours([color])

        self.add_x_axis([row[x_key] for row in data])
        self.add_y_axis([row['variant_name'] for row in data])

    def add_x_axis(self, x_values):
        # TODO: why reversed? ... is this bar chart specific?
        x_values.reverse()

        # TODO: better to use max of all rewards?
        assert(max(x_values) != 0)
        full_length = max(x_values) * 1.1
        self.set_axis_range('x', 0, full_length)
        self.set_axis_style(0, '000000', CHART_FONT_SIZE)
        # TODO: why is scaling necessary?
        rel_x_values = [float(i) * 100 / full_length for i in x_values]
        self.add_data(rel_x_values)

    def add_y_axis(self, variant_names):
        # scale height to number of variants
        self.height = len(variant_names) * CHART_HEIGHT_FACTOR + CHART_HEIGHT_FACTOR
        self.set_axis_labels('y', variant_names)
        self.set_axis_style(1, '000000', CHART_FONT_SIZE)


def generate_strip_chart(data):

    def init_chart():
        title = 'Distribution of rewards'
        return pygooglechart.ScatterChart(CHART_WIDTH, 0, title=title)

    def add_x_axis(reward_values):
        assert(max(reward_values) != 0)
        # TODO: add margin?
        chart.set_axis_range('x', 0, max(reward_values))
        chart.set_axis_style(0, '000000', CHART_FONT_SIZE)
        chart.add_data(scale(reward_values))

    def add_y_axis(variants):
        variant_names = unique(variants)

        # scale height to number of variants
        chart.height = len(variant_names) * CHART_HEIGHT_FACTOR + CHART_HEIGHT_FACTOR

        # axis as space filler
        chart.set_axis_labels('y', ['....' for i in variant_names])
        chart.set_axis_style(1, 'FFFFFF') # hide dots

        # real axis
        chart.set_axis_labels('y', variant_names)
        chart.set_axis_style(2, '000000', CHART_FONT_SIZE)

        step = float(100) / (len(variant_names))
        positions = range(step/2, 100, step)
        chart.set_axis_positions(1, positions)
        chart.set_axis_positions(2, positions)

        variant_name_positions = dict(zip(variant_names, positions))
        data_positions = [variant_name_positions[name] for name in variants]
        # TODO: limit of data points?
        chart.add_data(data_positions)

    def add_freq_axis(reward_freq):
        # TODO: best transform?
        transformed = [math.pow(i, 0.5) for i in reward_freq]
        chart.add_data(scale(transformed))
        chart.add_marker(1, 1, 'o', '7777FF', CHART_HEIGHT_FACTOR * 3/5)

    chart = init_chart()

    add_x_axis([row['reward'] for row in data])
    add_y_axis([row['variant_name'] for row in data])
    add_freq_axis([row['count_reward'] for row in data])

    return chart.get_url()

if __name__ == '__main__':
    # cgi.test()
    if 'genetify.com' not in os.environ.get('SERVER_NAME', ''):
        conn = MySQLdb.connect('localhost', 'gregdingle', '', 'genetify')
    else:
        # TODO: use read-only user
        conn = MySQLdb.connect('localhost', 'genetify_user', '', 'genetify_app')
    main()
