use str
use path
use platform
use re

# avoid automatic quoting by elvish
#   kubectl '--namespace=' => kubectl --namespace=
#
# filter completion candidates
# ignore '--namespace=' if '--namespace' exists.
fn put-candidate {
  use path
  var candidates = [(all)]
  for e $candidates {
    if ( eq $e "" ) {
      continue
    }

    # unquote bash string, let elvish quote
    set e = (re:replace '\\(.)' '${1}'  $e )

    # remove space at the end (which makes quotes)
    set e = (re:replace '(.*)\s+' '${1}'  $e )

    if (re:match "=$" $e ) {
      var trimmed = (re:replace '=$' '' $e)
      if (re:match "-.*=$" $e ) {
        if (not (has-value $candidates $trimmed)) {
          put (edit:complex-candidate $trimmed &code-suffix='=')
        }
      } else {
        put (edit:complex-candidate $trimmed &code-suffix='=')
      }
    } else {
      if (and (re:match "/$" $e) (path:is-dir &follow-symlink=$true $e))  {
        put (edit:complex-candidate $e &code-suffix='')
      } else {
        put (edit:complex-candidate $e &code-suffix=' ')
      }
    }
  }
}

fn new { |&bash_function="" &completion_filename="" name @cmd|
  use path
  var src_dir = (path:dir (src)[name])
  var f = {|@cmd|
    if (eq $cmd []) {
      return
    }

    if (eq $bash_function "") {
      set bash_function = _$name" "$name
    }

    if (eq $completion_filename "") {
      set completion_filename = $name
    }

    # The fix allowing to use aliases with this function
    # We could call if as 'k get ...' or 'blabla get ...'
    # It will be always ssh
    set cmd[0] = $name

    var bash_completion_script = 'source '$src_dir'/bash-completion/bash_completion 2>/dev/null;
source '$src_dir'/bash-completion/completions/$1 2>/dev/null \
|| source '$src_dir'/bash-completion/completions/$1.bash 2>/dev/null \
|| source /usr/share/bash-completion/completions/$1 2>/dev/null \
|| source /usr/share/bash-completion/completions/$1.bash 2>/dev/null \
|| source /usr/local/share/bash-completion/completions/$1 2>/dev/null \
|| source /usr/local/share/bash-completion/completions/$1.bash 2>/dev/null \
|| source /usr/local/etc/bash_completion.d/$1 2>/dev/null \
|| source /usr/local/etc/bash_completion.d/$1.bash 2>/dev/null \
|| source /usr/local/etc/bash_completion.d/$1-completion.bash 2>/dev/null \
|| source /opt/homebrew/etc/bash_completion.d/$1 2>/dev/null \
|| source /opt/homebrew/etc/bash_completion.d/$1.bash 2>/dev/null \
|| source /opt/homebrew/etc/bash_completion.d/$1-completion.bash 2>/dev/null \
|| source '$src_dir'/completions/$1 2>/dev/null \
|| source '$src_dir'/completions/$1.bash 2>/dev/null;
'

    var completions = [(
  echo $bash_completion_script'
fn=$2
shift; shift;
COMPREPLY=()
COMP_LINE="$@"
WORDS=($COMP_LINE)
COMP_WORDS=()

# simulate COMP_WORDBREAKS
# TODO: should be better way..
isBreak() {
  if [[ "$1" == "=" ]] || [[ "$1" == ">" ]] || [[ "$1" == "<" ]] || [[ "$1" == ":" ]]; then
    echo 0
  else
    echo 1
  fi
}

# echo "${WORDS[@]}" | notify-send "$(cat -)"
# dumpArray() {
#     local -n _ary=$1
#     local _idx
#     local -i _idlen=0
#     for _idx in "${!_ary[@]}"; do
#         _idlen=" ${#_idx} >_idlen ? ${#_idx} : _idlen "
#     done
#     for _idx in "${!_ary[@]}"; do
#         printf "%-*s: %s\n" "$_idlen" "$_idx" \
#             "|${_ary["$_idx"]//$''\n''/$''\n\e[''${_idlen}C: }|"
#     done
# }
# 
# dumpArray WORDS | notify-send "$(cat -)"

for e in "${WORDS[@]}"
do
  if [[ $e == \''* ]] || [[ $e == \"* ]]; then
    # quoted words 
    COMP_WORDS+=($e)
  else
    word=""
    for (( i=0; i<${#e}; i++ )); do
      ns="${e:$(( i + 1 )):1}"
      s="${e:$i:1}"
      if [[ "$ns" == "" ]]; then
        COMP_WORDS+=("${word}${s}")
      elif [ $(isBreak "$s") == $(isBreak "$ns") ]; then
        word="${word}${s}"
      else
        word="${word}${s}"
        COMP_WORDS+=(${word})
        word=""
      fi
    done
  fi
done

if [ "${COMP_LINE: -1}" = " " ]; then
  COMP_WORDS+=("")
fi

COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
COMP_POINT=${#COMP_LINE}

$fn 2>/dev/null # elvish is looking for StdErr also

for i in "${COMPREPLY[@]}"
do
  if [[ -d "${i}" && "${i}" != */ ]]; then
    echo "${i}/"
  else
    echo "${i}"
  fi
done
' | bash --norc --noprofile -s $completion_filename $bash_function $@cmd | from-lines )]

    if (eq (count $completions) (num 0)) {
        ls -1U
    } else {
        var prefix = $cmd[-1]
        if (not-eq $completions ['']) {
          if (eq $prefix '') {
            put $@completions | put-candidate
          } else {
            if (not-eq $completions []) {
              if (eq [] (each {|n| if (str:has-prefix $n $prefix) { put $n }} $completions)) {
                # no shared prefix
                # for example kubectl --namespace= will return list of namespaces
                # we should add --namespace= prefix to each completion
                put $@completions | each { |x| put $prefix$x } | put-candidate
              } else {
                put $@completions | put-candidate
              }
            }
          }
        }
    }

  }
  put $f
}
