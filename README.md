leycec/dotfiles
===========

**Welcome to [leycec](https://github.com/leycec)'s dotfile suite.**

## Installation
<a name="installation"></a>

Dotfiles are a gritty business. Hand me my CLI shovel.

### vcsh (Recommended)

These dotfiles are preferably installed via [`vcsh`](https://github.com/RichiH/vcsh), a Git-centric Bourne shell script for portable management and publication of dotfiles. `vcsh` cleverly leverages [Git internals](http://git-scm.com/book/en/v2/Git-Internals-Environment-Variables) rather than littering your filesystem with a battery of fragile symbolic links. <sup>You _know_ this to be a good thing.</sup>

* **Install `vcsh`.** Specifically, under:
  * **Gentoo**-based Linux distros (e.g., **Calculate**):

            $ sudo emerge vcsh

  * **Debian**-based Linux distros (e.g., **Ubuntu**):

            $ sudo apt-get install vcsh

  * Platforms providing no `vcsh` package (e.g., **Cygwin**):

            $ git clone https://github.com/RichiH/vcsh && cd vcsh && sudo make install

* **Move aside any existing dotfiles.** Renaming an existing `~/.gitconfig` file to `~/.gitconfig.d/user.conf` ensures that _your_ Git dotfile will be sourced by _our_ Git dotfile on each invocation of Git.

        $ mkdir ~/.gitconfig.d && mv ~/.gitconfig ~/.gitconfig.d/user.conf

* **Install this suite of dotfiles.**

        $ vcsh clone https://github.com/leycec/dotfiles.git

* (_Optional_) For fellow Github developers:
  * **Enter the cloned repository.**

            $ vcsh enter dotfiles

  * **Track the `github` branch**, storing front-facing GitHub documentation (including the current file).

            $ git fetch

  * **Install a Git `post-commit` hook**, synchronizing the `master` and `github` branches on every commit to the former. 

            $ ln -s $HOME/.githooks/github-post-commit $GIT_DIR/hooks/post-commit

  * **Leave the cloned repository.**

            $ exit

* (_Optional_) **Install our [Vim dotfiles](https://github.com/leycec/vimrc).** Vim is the spicy entrails of command-line life. For additional danger, why not `leycec/vimrc`?

You're done. Praise be to the open-source [Christmas Krampus](https://imgur.com/MpVkPJ5).

## License

All dotfiles are [liberally licensed](https://github.com/leycec/dotfiles/blob/github/LICENSE) under the [University of Illinois/NCSA Open Source License](https://en.wikipedia.org/wiki/University_of_Illinois/NCSA_Open_Source_License),
a hospitably lax license for the whole POSIX-compatible family.
