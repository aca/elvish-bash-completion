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
  var candidates = [(all)]

  for e $candidates {
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
      put (edit:complex-candidate $e &code-suffix=' ')
    }
  }
}

fn new { |&bash_function="" &completion_filename="" name @cmd|
  var f = {|@cmd|
    if (eq $cmd []) {
      return
    }

    if (eq $bash_function "") {
      set bash_function = _$name
    }

    if (eq $completion_filename "") {
      set completion_filename = $name
    }

    # The fix allowing to use aliases with this function
    # We could call if as 'k get ...' or 'blabla get ...'
    # It will be always ssh
    set cmd[0] = $name

    var bash_completion_script = 'source /usr/share/bash-completion/bash_completion
source /usr/share/bash-completion/completions/$1 2>/dev/null
'
    if (eq $platform:os "darwin") {
      set bash_completion_script = "source /usr/local/share/bash-completion/bash_completion
source /usr/local/share/bash-completion/completions/$1 2>/dev/null || source /usr/local/etc/bash_completion.d/$1 2>/dev/null
"
    }

    # COMP_WORDBREAKS="'@><=;|&(:
    # TODO: Do we need COMP_WORDBREAKS?
    var completions = [(
  echo $bash_completion_script'

isBreak() {
  [[ "$1" == "=" ]] || [[ "$1" == ">" ]] || [[ "$1" == "<" ]] || [[ "$1" == ":" ]]
}


fn=$2
shift; shift;
COMPREPLY=()
COMP_LINE="$@"
WORDS=($COMP_LINE)
COMP_WORDS=()

# simulate COMP_WORDBREAKS
# TODO: It might be wrong
for e in "${WORDS[@]}"
do
  if [[ $e == \''* ]]; then
    COMP_WORDS+=($e)
  elif [[ $e == \"* ]]; then
    COMP_WORDS+=($e)
  else
    word=""
    for (( i=0; i<${#e}; i++ )); do
      ns="${e:$(( i + 1 )):1}"
      s="${e:$i:1}"
      if [[ "$ns" == "" ]]; then
        COMP_WORDS+=("${word}${s}")
      elif isBreak "$s" && ! isBreak "$ns"; then
        word="${word}${s}"
        COMP_WORDS+=(${word})
        word=""
      elif isBreak "$ns" && ! isBreak "$s"; then
        word="${word}${s}"
        COMP_WORDS+=(${word})
        word=""
      else
        word="${word}${s}"
      fi
    done
  fi
done

if [ "${COMP_LINE: -1}" = " " ]; then
  COMP_WORDS+=("")
fi

COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
# declare -p COMP_WORDS >> /tmp/debug
# echo "COMP_CWORD: $COMP_CWORD" >> /tmp/debug

COMP_POINT=${#COMP_LINE}
$fn 2>/dev/null # elvish is looking for StdErr also
for i in "${COMPREPLY[@]}"
do
  # unquote bash string
  #   "<s>"
  #   "file with space"
  echo $(eval "echo $i")
done
' | bash --norc --noprofile -s $completion_filename $bash_function $@cmd | from-lines | each {|n| str:trim-space $n} )]
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
            # put $@completions | each {|x| put (edit:complex-candidate $x &code-suffix=' ')}
            put $@completions | put-candidate
          }
        }
      }
    }
  }
  put $f
}
