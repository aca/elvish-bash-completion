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
/usr/local/share/bash-completion/completions/$1 2>/dev/null
/usr/local/share/bash-completion/bash_completion/$1 2>/dev/null
"
    }

    # TODO: Do we need COMP_WORDBREAKS?
    var completions = [(
  echo $bash_completion_script'
fn=$2
shift; shift;
COMP_CWORD=$1
shift
COMPREPLY=()
COMP_WORDBREAKS=''"''"''"''><=;|&(:'' 
COMP_LINE="$@"
COMP_WORDS=($COMP_LINE)

if [ "${COMP_LINE: -1}" = " " ]; then
  COMP_WORDS+=("")
fi

COMP_POINT=${#COMP_LINE}
$fn 2>/dev/null # elvish is looking for StdErr also
printf ''%s\n'' "${COMPREPLY[@]}"
' | bash --norc --noprofile -s $completion_filename $bash_function (- (count $cmd) 1) $@cmd | from-lines | each {|n| str:trim-space $n} )]
    var prefix = $cmd[-1]
    if (eq $completions ['']) {
    # no match
    } else {
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
