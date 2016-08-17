#!/bin/bash

pandoc --smart --toc --normalize -f markdown_github+footnotes+fenced_code_attributes+simple_tables+markdown_in_html_blocks --highlight-style=espresso --template=template.html readme.md -o index.html
