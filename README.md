# ICryptol Notebook (Experimental)

This project allows [Cryptol](https://github.com/GaloisInc/cryptol) to
run in an [IPython](http://ipython.org/) notebook. There is an
executable `icryptol-kernel` that uses
[Cryptol](https://github.com/GaloisInc/cryptol) as a library, and a
script `icryptol` which sets up the current IPython environment with a
Cryptol profile.

ICryptol is not currently available on Windows (#12).

# Getting ICryptol Binaries

TODO

## Getting CVC4

ICryptol currently depends on the
[CVC4 SMT solver](http://cvc4.cs.nyu.edu/) to solve constraints during
type checking, and as the default solver for the `:sat` and `:prove`
commands. You can download CVC4 binaries for a variety of platforms
from their [download page](http://cvc4.cs.nyu.edu/downloads/).

# Building ICryptol From Source

## Prerequisites

Building ICryptol requires building Cryptol, so you must first satisfy
the
[prerequisites for Cryptol](https://github.com/GaloisInc/cryptol#prerequisites).

There are a couple extra prerequisites for the notebook, though we
hope to ease them in the future.

### Cryptol sources

Add a checkout of the Cryptol repository to your cabal sandbox
sources:

```
git clone https://github.com/GaloisInc/cryptol.git deps/cryptol
cabal sandbox init
cabal sandbox add-source deps/cryptol
```

### IPython 2.4

Install IPython 2.4 (see http://ipython.org/install.html, but note
that we don't yet support IPython 3). Internally we've had the best
luck installing with `pip install --user
"ipython[notebook]<3.0.0"`. Make sure `ipython` is on your path.

Install ZeroMQ 4 with development headers (see
https://github.com/gibiansky/IHaskell#zeromq).

Once these prerequisites are in place, you can run the notebook in
place with `make notebook`, or run `icryptol` from a distribution.

## Building ICryptol

From the ICryptol source directory, run:

    make

This will build ICryptol in place. From there, there are additional targets:

- `make notebook`: run ICryptol and launch a browser session
- `make tarball`: build a tarball with a relocatable ICryptol binary and examples
- `make dist`: build a platform-specific distribution. On all
  platforms except Windows, this is currently equivalent to `make
  tarball`. On Windows, this will build an `.msi` package using
  [WiX Toolset 3.8](http://wixtoolset.org/), which must be installed
  separately.

# Checking your Installation

Run ICryptol, and in a cell type:

    :prove True

If ICryptol responds

    Q.E.D.

then ICryptol is installed correctly. If it prints something like

    *** An error occurred.
    ***  Unable to locate executable for cvc4
    ***  Executable specified: "cvc4"

then make sure you've installed [CVC4](#getting-cvc4), and that the
binary is on your `PATH`.

# Contributing

See the
[contributor's guide for Cryptol](https://github.com/GaloisInc/cryptol#contributing]

### Repository Structure

- `/examples`: ICryptol notebooks in `.ipynb` format implementing
  several interesting algorithms
- `/profile-cryptol`: The skeleton of an IPython profile for
  ICryptol. This gets lightly preprocessed to point to the
  `icryptol-kernel` executable
- `/src`: Haskell sources for the front-end `icryptol-kernel`
  executable

# Thanks!

ICryptol has been under development for a couple of years with several
people contributing to its design and implementation. Those people
include (but are not limited to) Adam Foltzer, David Christiansen,
Dylan McNamee, Aaron Tomb, Iavor Diatchki, Rogan Creswick and Benjamin
Jones. Special thanks to Andrew Gibianski whose
[IHaskell](https://github.com/gibiansky/IHaskell) project provides the
underpinning of this project.
