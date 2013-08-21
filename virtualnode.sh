#!/bin/bash


function ensure_dir () {
    if ! [ -d "$1" ]; then
        mkdir -p -- "$1" || fail "couldn't create $1"
    fi
}

fail () {
  echo "$@" >&2
  exit 1
}

function vnode_new () {


    export_vars "$@"

    local prefix="$npm_config_prefix"
    local bin="$npm_config_binroot"
    local lib="$npm_config_root"
    local mod="$prefix/lib/node_modules"

    ensure_dir "$bin"
    ensure_dir "$lib"
    ensure_dir "$mod"

    #if [ -f /usr/bin/nodejs ]; then
    #    cp /usr/bin/nodejs "$bin"
    #fi
    #if [ -f /usr/bin/node ]; then
    cp /usr/bin/node "$bin"
    #fi

    cp -r /usr/lib/node_modules/npm/ "$mod"
    ln -s "$mod/npm/bin/npm-cli.js" "$bin/npm"


    vnode_workon $@
}

function export_vars () {
    if [ -z "$1" ]
      then
        echo "No virtual env name supplied"
        exit 1
    fi

    export VIRTUAL_NODE="$1"

    local prefix="$VNODE_ROOT/$VIRTUAL_NODE"
    local bin="$prefix/bin"
    local lib="$prefix/lib/node"
    local mod="$prefix/lib/node_modules"

    export npm_config_binroot="$bin"
    export npm_config_root="$lib"
    export npm_config_prefix="$prefix"
    export NODE_PATH="$lib"


}


function vnode_workon () {

    export_vars "$@"

    export PATH="$bin:$PATH"
    exec "$SHELL"
}




function vnode_ls () {
    #local result=""

    while read name; do
            #result+="$name: $($VNODE_ROOT/$name/bin/node -v 2>/dev/null)|"
            echo "$name: $($VNODE_ROOT/$name/bin/node -v 2>/dev/null)"
        done < <( ls -- "$VNODE_ROOT" | sort )
    #echo "$result" | column -t -s "|"
}

function vnode_rm () {
    if [ -z "$1" ]
      then
        echo "No virtual env name supplied"
        exit 1
    fi

    local folder="$VNODE_ROOT/$1"

    if ! [ -d "$folder" ]; then
        fail "virtual env '$1' doesn't exist"
    fi

    rm -rf "$folder" && echo "$1 successfully deleted"

}

function main() {
    if ! [ -d "$VNODE_ROOT" ]; then
        export VNODE_ROOT="$HOME/.vnode"
        ensure_dir "$VNODE_ROOT"
    fi


    local cmd="$1"
    shift
    case $cmd in
        new | workon | rm | ls)
            cmd="vnode_$cmd"
            ;;
        * )
            cmd="vnode_help"
            ;;
    esac
    $cmd "$@"
    local ret=$?
    if [ $ret -eq 0 ]; then
        exit 0
    else
        echo "failed with code=$ret" >&2
        exit $ret
    fi
}


function vnode_help () {
  cat <<EOF

Usage: vn <cmd>

Commands:

install <version>    Install the version passed (ex: 0.1.103)
use <version>        Enter a subshell where <version> is being used
use <ver> <program>  Enter a subshell, and run "<program>", then exit
use <name> <ver>     Create a named env, using the specified version.
                     If the name already exists, but the version differs,
                     then it will update the link.
usemain <version>    Install in /usr/local/bin (ie, use as your main nodejs)
clean <version>      Delete the source code for <version>
uninstall <version>  Delete the install for <version>
ls                   List versions currently installed
ls-remote            List remote node versions
ls-all               List remote and local node versions
latest               Show the most recent dist version
help                 Output help information

<version> can be the string "latest" to get the latest distribution.
<version> can be the string "stable" to get the latest stable version.

EOF
}


main "$@"
