#!/usr/bin/env python3

import os
for f in os.listdir("."):
    r = f.replace(" ","")
    if( r != f):
        os.rename(f,r)
