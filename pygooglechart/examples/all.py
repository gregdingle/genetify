from glob import glob

examples = glob('*.py')
notexamples = ['settings.py', 'helper.py', 'all.py']

for example in examples:
    if example in notexamples:
        continue
    module = example[:-3]
    print module
    __import__(module).main()

