#!/usr/bin/env python
# coding: utf-8

import os
import requests
import json
import sys
import os.path
import re

# 替换文件内容
def replace(file, new_content):
    content = read_file(file)
    content = re.sub(r"\s*s.version\s*=.*",
                     "\n  s.version          = '%s'" % (new_content), content)
    rewrite_file(file, content)
    
# 读取文件内容
def read_file(file):
    with open(file, encoding='UTF-8') as f:
        read_all = f.read()
        f.close()
    return read_all
    
# 写内容到文件
def rewrite_file(file, data):
    with open(file, 'w', encoding='UTF-8') as f:
        f.write(data)
        f.close()

if __name__ == '__main__':
    print ('参数列表:', str(sys.argv))
    replace(sys.argv[1], sys.argv[2])
