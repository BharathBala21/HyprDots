if status is-interactive
# Commands to run in interactive sessions can go here
end
fastfetch
set fish_greeting ""
set -gx EDITOR vim
starship init fish | source


function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	command yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
		builtin cd -- "$cwd"
	end
	command rm -f -- "$tmp"
end

alias yazi="sudo yazi"


# Added by Antigravity CLI installer
fish_add_path $HOME/.local/bin