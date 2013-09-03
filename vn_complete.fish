set vn_name vn


function __vn_needs_command
    set cmd (commandline -opc)
    if [ (count $cmd) -eq 1 -a $cmd[1] = "$vn_name" ]
        return 0
    end
    return 1
end



function __vn_list_vn
    eval "$vn_name ls --no-version"
end

function __vn_using_command
    set cmd (commandline -opc)
	if test (count $cmd) -gt 1
	    if test $argv[1] = $cmd[2]
		    return 0
		end
	end
	return 1
end

function __vn_using_command_options
    set cmd (commandline -opc)
	if test (count $cmd) -gt 2
	    if test $argv[1] = $cmd[2]
	        if test $argv[2] = $cmd[3]
    		    return 0
            end
		end
	end
	return 1
end

#### new
complete -f -c $vn_name -n '__vn_needs_command' -a new -d 'Creates a new virtual environment'
complete -f -c $vn_name -n '__vn_using_command new' -s v -l version -d 'Version to install'
complete -f -c $vn_name -n '__vn_using_command_options new -v' -a 'latest'


#### workon
complete -f -c $vn_name -n '__vn_needs_command' -a workon -d 'Actives an existing virtual environment'
complete -f -c $vn_name -n '__vn_using_command workon' -a '(__vn_list_vn)' -d 'Node env'

#### rm
complete -f -c $vn_name -n '__vn_needs_command' -a rm -d 'Deletes a virtual environment'
complete -f -c $vn_name -n '__vn_using_command rm' -a '(__vn_list_vn)' -d 'Node env'

#### ls
complete -f -c $vn_name -n '__vn_needs_command' -a ls -d 'List all existing virtual environments'


#### setproject
complete -f -c $vn_name -n '__vn_needs_command' -a setproject -d 'Bind a virtualenv to a project'
complete -f -c $vn_name -n '__vn_using_command setproject' -a '(__vn_list_vn)' -d 'Node env'
