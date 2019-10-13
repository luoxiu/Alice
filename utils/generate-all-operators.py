#!/usr/bin/env python3

import os

path = "./Sources/Async/Operators"

for file in os.listdir(path):
    if not file.endswith(".gyb"):
        continue

    fromPath = os.path.join(path, file)
    toPath = fromPath.replace('.gyb', '.swift')

    script = "./utils/gyb.py {fromPath} -o {toPath} --line-directive ''".format(fromPath=fromPath, toPath=toPath)
    os.system(script)
