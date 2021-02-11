Command Line Interface (CLI) For Stats App
==============================================================================

A little domain-specific Python 3 package for tooling, providing a `stats`
executable and exposing functionality via a collection of sub-commands.

> 📢 At the time-of-writing (2021-02-11), all operations act against the _local_
> development environment -- but that may be simply because that's all there is
> at the moment. So, this may change in the future.

Implemented using Python's built-in [argparse][] module, with pretty-printing
handled by Will McGugan's exceptional [rich][] package, and with miraculous 
"it just works" Bash completion provided by Andrey Kislyuk's [argcomplete][].

[argparse]:     https://docs.python.org/3/library/argparse.html
[rich]:         https://github.com/willmcgugan/rich
[argcomplete]:  https://github.com/kislyuk/argcomplete

Setup
------------------------------------------------------------------------------

Handled on Mac by `//dev/bin/setup` script, which would be the place to start if
you're doing anything new or different.

Installs the dependencies and links the package in a Python 3 `virtualenv`,
leveraging [pyenv][] and it's friend [pyenv-virtualenv][].

[pyenv]:            https://github.com/pyenv/pyenv
[pyenv-virtualenv]: https://github.com/pyenv/pyenv-virtualenv

Bash Completion
------------------------------------------------------------------------------

Run in the terminal in question:

    eval "$(register-python-argcomplete stats)"

or (from the repo root):

    source ./cli/share/bash-completion.sh

which does the same thing.

> 📢 You need to do this in _each_ and _every_ terminal you want completion
> active in, at least until we figure out some auto-magic method of loading it.
