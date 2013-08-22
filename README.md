VirtualNode
===========

Virtual Environments for Node

VirtualNode tries to be as simple as possible.
It's shell agnostic, it works on bash, zsh, fish, etc.


Installation
============


Bash
----

Add to your ~/.bashrc this lines:

```bash
export SHELL=/bin/bash  # or the path to your bash executable
alias vn="bash /path/to/virtualnode.sh"
```

Zsh
----

Add to your ~/.zshrc this lines:

```bash
SHELL=/usr/bin/zsh  # or the path to your zsh executable
alias vn="bash /path/to/virtualnode.sh"
```

Fish
----

Add to your ~/.zshrc this lines:

```sh
set SHELL /usr/bin/fish
function vn
    bash /path/to/virtualnode.sh $argv
end
```

Usage
=====

```
vn new <name>              Create a new environment using the system global version
vn new -v <version> <name> Create a new environment with the version passed
vn workon <name>           Enter a subshell where the environment <name> is being used
vn rm <name>               Deletes virtual envirnoment for <version>
vn ls                      List all environments
vn help                    Output help information

<version> can be the string "latest" to get the latest distribution.
```


Update the prompt
=================

The prompt won't be updated, but this can be easily fixed using the $VIRTUAL_NODE variable.

Bash
----

```bash
if [ -n "$VIRTUAL_NODE" ] ; then
    export PS1="($VIRTUAL_NODE)$PS1"
fi
```

Zsh
----
To be done, contributions are welcome

Fish
----

```sh
functions -c fish_prompt fish_prompt_original

function fish_prompt
    set prompt (fish_prompt_original)
    if set -q VIRTUAL_NODE
        set prompt (set_color -b 62A white)"("(basename "$VIRTUAL_NODE")")"(set_color normal)"$prompt"
    end
    echo $prompt
end
```


Autocompletion
==============

Bash
----
To be done, contributions are welcome

Zsh
----
To be done, contributions are welcome

Fish
----
```sh
. /path/to/vn_complete.fish
```
