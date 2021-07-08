Stats
==============================================================================

Our nascent statistics system.

Notation
------------------------------------------------------------------------------

In paths the [@](https://unicodelookup.com/#@/1) ("at" character) means "the
repository root" (the directory this file lives in).

Developing
------------------------------------------------------------------------------

There is a shell script at [@/dev/bin/setup](dev/bin/setup) that is _supposed_
to do this, but you know how that goes. Never work save from at the time you fix
them.

But, the procession _should_ look something like (from repo root):

1.  `asdf install`
    
    > 📢 There's an issue with `asdf` / kerl / Erlang on macOS Big Sur (`11.4`)
    > — `autoconf` needs to be at _exactly_ version `2.69`, because Erlang
    > and/or macOS are developed by very immature people.
    > 
    > What to do:
    > 
    >     brew tap nrser/versions
    >     brew install --no-binaries nrser/versions/autoconf@2.69
    >     PATH="$(brew --prefix autoconf@2.69)/bin:$PATH" asdf install erlang [VERSION]
    > 
    > **_You'll want to replace `[VERSION]` with the string in 
    
2.  `./dev/bin/setup`
2.  

...

Building Releases
------------------------------------------------------------------------------

See [@/rel/README.md](rel/README.md])

Deploying
------------------------------------------------------------------------------

See [@/deploy/README.md](deploy/README.md)
