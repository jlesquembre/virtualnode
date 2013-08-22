set vn_name vn


function needs_command
    set cmd (commandline -opc)
    if [ (count $cmd) -eq 1 -a $cmd[1] = "$vn_name" ]
        return 0
    end
    return 1
end



function list_vn
    eval "$vn_name ls --no-version"
end

function using_command
    set cmd (commandline -opc)
	if test (count $cmd) -gt 1
	    if test $argv[1] = $cmd[2]
		    return 0
		end
	end
	return 1
end


#### new
complete -x -c $vn_name -n 'needs_command' -a new -d 'Creates a new virtual environment'

#### workon
complete -x -c $vn_name -n 'needs_command' -a workon -d 'Actives an existing virtual environment'
complete -x -c $vn_name -n 'using_command workon' -a '(list_vn)' -d 'Node env'

#### rm
complete -x -c $vn_name -n 'needs_command' -a rm -d 'Deletes a virtual environment'
complete -x -c $vn_name -n 'using_command rm' -a '(list_vn)' -d 'Node env'

#### ls
complete -x -c $vn_name -n 'needs_command' -a ls -d 'List all existing virtual environments'
