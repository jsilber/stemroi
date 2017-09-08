# Configures the Flask side of mod_wsgi for use with Apache 2.x.

import sys

sys.path.insert(0, '/var/www/stemroi')

from stemroi import app as application

