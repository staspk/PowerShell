import os


#--- Absolute Paths to Project Directories ---------------------------------------------#
PROJECT_ROOT_DIRECTORY          =  os.path.dirname(os.path.abspath(__file__))
ENV                             =  os.path.join(PROJECT_ROOT_DIRECTORY, '.env', '.env')
TEMP_DIR                        =  os.path.join(PROJECT_ROOT_DIRECTORY, 'temp')