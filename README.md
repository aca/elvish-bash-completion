# elvish-bash-completion

Generalized version of [ezh/elvish-bash-completion](https://github.com/ezh/elvish-bash-completion) with some improvements.
Provides single function `bash-completer:new`, you can convert any bash completion to elvish.

It includes submodules for bash completions and also tries to find completion in your host searching through
```
/usr/share/bash-completion/completions/
/usr/local/share/bash-completion/completions/
/usr/local/etc/bash_completion.d/
```

## Options
- `bash_function`: Normally completion bash function is named as "_command command", this option is for commands that doesn't follow this convention.
- `completion_filename`: Some completion file is named to `fd.bash` instead of `fd` (on MacOS)

## Install
```
epm:install github.com/aca/elvish-bash-completion
use github.com/aca/elvish-bash-completion/bash-completer
```

## Usage
```
set edit:completion:arg-completer[ssh] = (bash-completer:new "ssh")
set edit:completion:arg-completer[scp] = (bash-completer:new "scp")
set edit:completion:arg-completer[curl] = (bash-completer:new "curl")
set edit:completion:arg-completer[man] = (bash-completer:new "man")
set edit:completion:arg-completer[killall] = (bash-completer:new "killall")
set edit:completion:arg-completer[aria2c] = (bash-completer:new "aria2c")
set edit:completion:arg-completer[ip] = (bash-completer:new "ip")
set edit:completion:arg-completer[journalctl] = (bash-completer:new "journalctl")
set edit:completion:arg-completer[tcpdump] = (bash-completer:new "tcpdump")
set edit:completion:arg-completer[iptables] = (bash-completer:new "iptables")
set edit:completion:arg-completer[tmux] = (bash-completer:new "tmux")
set edit:completion:arg-completer[fd] = (bash-completer:new "fd")
set edit:completion:arg-completer[rg] = (bash-completer:new "rg")
set edit:completion:arg-completer[pueue] = (bash-completer:new "pueue")

# for some commands, we need to pass bash_function
set edit:completion:arg-completer[gh] = (bash-completer:new "gh" &bash_function="__start_gh")
set edit:completion:arg-completer[pkill] = (bash-completer:new "pkill" &bash_function="pgrep")
set edit:completion:arg-completer[git] = (bash-completer:new "git" &bash_function="__git_wrap__git_main")
set edit:completion:arg-completer[umount] = (bash-completer:new "umount" &bash_function="_umount_module")
set edit:completion:arg-completer[systemctl] = (bash-completer:new "systemctl" &bash_function="_systemctl systemctl")
set edit:completion:arg-completer[virsh] = (bash-completer:new "virsh" &bash_function="_virsh_complete virsh")

# builtin completions
set edit:completion:arg-completer[which] = (bash-completer:new "which"  &bash_function="_complete type" &completion_filename="complete")

# alias
set edit:completion:arg-completer[kubectl] = (bash-completer:new "kubectl" &bash_function="__start_kubectl")
set edit:completion:arg-completer[k] = $edit:completion:arg-completer[kubectl]

# specify completion filename for completions with different name
# set edit:completion:arg-completer[rg] = (bash-completer:new "rg" &completion_filename="custom_rg_completion")
```
