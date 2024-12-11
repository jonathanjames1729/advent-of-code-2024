import os.path

NOTEBOOK_DIR = os.path.dirname(__file__)
ROOT_DIR = os.path.dirname(NOTEBOOK_DIR)
DATA_DIR = os.path.join(ROOT_DIR, 'data')
TEST_DATA_DIR = os.path.join(ROOT_DIR, 'test_data')

def load_data(name, test=False):    
    data_dir = TEST_DATA_DIR if test else DATA_DIR

    with open(os.path.join(data_dir, name)) as f:
        for line in f:
            yield line.strip()
