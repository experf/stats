# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html
#

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys
from pathlib import Path
import re
import inspect

sys.path.insert(0, os.path.abspath(".."))

from stats.cfg import CFG


GIT_BRANCH_RE = re.compile(r"\*\ ([^\n]+)\n")


# -- Project information -----------------------------------------------------

project = "Stats"
copyright = "2021, nrser"
author = "nrser"


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "sphinx.ext.autodoc",
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates"]

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ["_static"]

import commonmark

r = repr

def docstring(app, what, name, obj, options, lines):
    lines_in = [*lines]

    # md  = inspect.cleandoc('\n'.join(lines))
    md  = '\n'.join(lines)
    ast = commonmark.Parser().parse(md)
    rst = commonmark.ReStructuredTextRenderer().render(ast)
    lines.clear()
    lines += rst.splitlines()

    try:
        file = inspect.getfile(obj)
    except:
        file = None

    try:
        module = inspect.getmodule(obj).__name__
    except:
        module = None

    name = getattr(obj, "__qualname__", None)

    if module is not None:
        if name is not None:
            name = f"{module}.{name}"
        else:
            name = module
    
    dest = CFG.stats.paths.tmp / "rst"

    if not dest.exists():
        dest.mkdir()

    if len(lines_in) > 0 and name is not None:
        path = dest / f"{name}.rst"
        # print(f"WRITE {path}")
        with path.open("w") as fp:
            print("### LINES IN ###", file=fp)
            for line in lines_in:
                print(line, file=fp)
            print("### LINES OUT ###", file=fp)
            for line in lines:
                print(line, file=fp)

def setup(app):
    app.connect('autodoc-process-docstring', docstring)

# At the bottom of conf.py
# def setup(app):
#     pkg_root = Path(__file__).parent
#     origin_url = sh.get(
#         "git",
#         "remote",
#         "get-url",
#         "origin",
#         chdir=pkg_root,
#     ).strip(".git\n")
#     branch = GIT_BRANCH_RE.search(sh.get("git", "branch", chdir=pkg_root))[1]

#     github_doc_root = f"{origin_url}/tree/{branch}/docs/"

#     app.add_config_value(
#         "recommonmark_config",
#         {
#             "url_resolver": lambda url: github_doc_root + url,
#             "auto_toc_tree_section": "Contents",
#         },
#         True,
#     )
#     app.add_transform(AutoStructify)
