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

fetch () {
  local version=$(ver "$1")
  if nave_has "$version"; then
    echo "already fetched $version" >&2
    return 0
  fi

  local src="$NAVE_SRC/$version"
  remove_dir "$src"
  ensure_dir "$src"

  local url
  local urls=(
    "http://nodejs.org/dist/v$version/node-v$version.tar.gz"
    "http://nodejs.org/dist/node-v$version.tar.gz"
    "http://nodejs.org/dist/node-$version.tar.gz"
  )
  for url in "${urls[@]}"; do
    curl -#Lf "$url" > "$src".tgz
    if [ $? -eq 0 ]; then
      $tar xzf "$src".tgz -C "$src" --strip-components=1
      if [ $? -eq 0 ]; then
        echo "fetched from $url" >&2
        return 0
      fi
    fi
  done

  rm "$src".tgz
  remove_dir "$src"
  echo "Couldn't fetch $version" >&2
  return 1
}



latest_version () {
  curl -s http://nodejs.org/dist/ \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
    | tail -n1
}

install_remote () {
    local tar=${TAR-tar}

    # Try to figure out the os and arch for binary fetching
    local uname="$(uname -a)"
    local arch=x86
    case "$uname" in
        Linux\ *) local os=linux ;;
        Darwin\ *) local os=darwin ;;
        SunOS\ *) local os=sunos ;;
    esac
    case "$uname" in
        *x86_64*) arch=x64 ;;
    esac
    local version="$1"

    if [ -z "$os" ]; then
        fail "Could not determine your OS"
    fi
    # binaries started with node 0.8.6
    case "$version" in
      0.8.[012345]) fail "Version older than 0.8.6 not supported" ;;
      0.[1234567]) fail "Version older than 0.8.6 not supported" ;;
      latest) version=$(latest_version) ;;
    esac

    local t="$version-$os-$arch"
    local url="http://nodejs.org/dist/v$version/node-v${t}.tar.gz"
    local temp=$(mktemp -d)
    local tgz="$temp/$t.tgz"
    curl -#Lf "$url" > "$tgz"
    if [ $? -ne 0 ]; then
        # binary download failed.
        rm -r "$temp"
        fail "Download failed, is version $version a valid version?."
    fi

    # unpack straight into the build target.
    $tar xzf "$tgz" -C "$VNODE_ROOT/$VIRTUAL_NODE" --strip-components 1
    if [ $? -ne 0 ]; then
        fail "Unpack failed"
    fi

    # it worked!
    rm -r "$temp"
    echo "installed from binary" >&2
    return 0

}


function vnode_new () {

    while [ $# -gt 0 ] ; do
        case "$1" in
                -v | --version) shift ; local version="$1" ; shift ;;
                -*) fail "bad option '$1'" ;;
                *)  if [ -n "$name" ]; then
                        fail "Create multiple envs at once is not allowed!!"
                    fi
                    local name="$1" ; shift ;;
         esac
    done

    export_vars $name

    local prefix="$npm_config_prefix"
    local bin="$npm_config_binroot"
    local lib="$npm_config_root"
    local mod="$prefix/lib/node_modules"


    if ! [ -d "$prefix" ]; then
        ensure_dir "$prefix"
    else
        fail "'$VIRTUAL_NODE' already exists!!!"
    fi

    if [ -n "$version" ]; then
        install_remote $version $name
    else
        ensure_dir "$bin"
        ensure_dir "$lib"
        ensure_dir "$mod"

        cp /usr/bin/node "$bin"

        cp -r /usr/lib/node_modules/npm/ "$mod"
        ln -s "$mod/npm/bin/npm-cli.js" "$bin/npm"
    fi


    vnode_workon $name
}

# Given a virtualenv directory and a project directory,
# set the virtualenv up to be associated with the
# project
function vnode_setproject {
    typeset venv="$1"
    typeset prj="$2"
    if [ -z "$venv" ] ; then
        venv="$VIRTUAL_NODE"
        if [ -z "$VIRTUAL_NODE" ] ; then
            fail "No virtual env provided!!!"
        fi
    fi

    if [ -z "$prj" ]; then
        prj="$(pwd)"
    fi
    echo "Setting project for $(basename $venv) to $prj"
    echo "$prj" > "$VNODE_ROOT/$VIRTUAL_NODE/.project"
}

function get_project_dir {
    if [ -f "$VNODE_ROOT/$VIRTUAL_NODE/.project" ]; then
        typeset project_dir="$(cat "$VNODE_ROOT/$VIRTUAL_NODE/.project")"
        if [ ! -z "$project_dir" ]; then
            echo "$project_dir"
        else
            fail "Project directory $project_dir does not exist!!!"
        fi
    else
        fail "No project set in $VIRTUAL_NODE"
    fi
    return 0
}


function export_vars () {
    if [ -z "$1" ]
      then
        echo "No virtual env name supplied"
        echo "$@"
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
    if [ ! -d "$npm_config_binroot" ]; then
        fail "$VIRTUAL_NODE doesn't exit yet, create it before!"
    fi

    export PATH="$npm_config_binroot:$PATH"

    # Use project folder if defined
    prj_dir=$(get_project_dir 2>&1)
    status=$?

    echo "Launching subshell in virtual environment. Type 'exit' or 'Ctrl+D' to return."
    if [ $status -eq 0 ]; then
        cd $prj_dir && exec "$SHELL"
    else
        exec "$SHELL"
    fi
}


function vnode_ls () {

    if [ -n "$1" ]; then
        if [ "$1" == '--no-version' ]; then
            local show_version=false
        else
            local show_version=true
        fi
    else
        local show_version=true
    fi

    for name in `ls -- "$VNODE_ROOT" | sort`; do
        if $show_version; then
            echo "$name: $($VNODE_ROOT/$name/bin/node -v 2>/dev/null)"
        else
            echo "$name"
        fi
    done
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
        new | workon | rm | ls | setproject | help)
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

new <name>               Create a new environment using the system global version
new -v <version> <name>  Create a new environment with the version passed
workon <name>            Enter a subshell where the environment <name> is being used
rm <name>                Deletes virtual envirnoment for <version>
ls                       List all environments
setproject <venv> <path> Bind an existing virtualenv to an existing project.
                         When no arguments are given, the current virtualenv and
                         current directory are assumed.
help                     Output help information

<version> can be the string "latest" to get the latest distribution.

EOF
}


main "$@"
