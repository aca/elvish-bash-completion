# Bash Terraform completion
# Originally adapted from: https://gist.github.com/cornfeedhobo/8bc08747ec3add1fc5adb2edb7cd68d3
#
# Author: Jeremy Melanson
#
# Features of this update:
# - Use built-in bash routines for text processing, instead of external tools (awk, sed, grep, ...).
# - fixes the retrieval of options from the Terraform executble.
# - Optional _init_terraform_completion function, which can enable command-completion for multiple Terraform executables.
#

#--- Get options listing from Terraform command.
_terraform_completion_get_opts () {
  local CMD_EXEC="${1}"
  local TF_OPT="${2}"

  local IFS=$'\n'

  #-- "terraform -help"
  if [[ "${TF_OPT}" == "" ]]; then

    for O in $(${CMD_EXEC} -help); do
      if [[ "${O}" =~ ^\ +([^\ ]+) ]]; then
        echo "${BASH_REMATCH[1]}"

      fi
    done

  #-- "terraform -help XXXX"
  else

    for O in $(${CMD_EXEC} -help ${TF_OPT}); do
      if [[ "${O}" =~ ^\ +(-[^\ =]+=?) ]]; then
        echo -e "${BASH_REMATCH[1]}"

      fi
    done
  fi
}

#--- This function is passed to 'complete' for handling completion.
_terraform_completion () {
  local cur prev words cword opts
  _init_completion -s || return

  _get_comp_words_by_ref -n : cur prev words cword
  COMPREPLY=()

  opts=""

  if [[ ${cur} == -* ]] ; then
    compopt -o nospace

  fi

  local CMD_EXEC="${COMP_WORDS[0]}"

  if [[ ${cword} -eq 1 ]] ; then
    if [[ ${cur} == -* ]] ; then
      opts="--help --version"

    else
      opts="$(_terraform_completion_get_opts ${CMD_EXEC})"

    fi

  elif [[ ${cword} -gt 1 ]]; then

    if [[ ${cword} -eq 2 && ${prev} =~ \-\-?help ]]; then
      opts="$(_terraform_completion_get_opts ${CMD_EXEC})"

    else
      local TF_COMMAND="${words[1]}"
      opts="$(_terraform_completion_get_opts ${CMD_EXEC} ${TF_COMMAND})"

    fi
  fi

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

  return 0
}

#--- Initialize Bash Command Completion for multiple Terraform executables.
# It searches the PATH for files starting with "terraform", but does not
# contain "-" characters. This avoids adding Completion for third-party
# Terraform provider plugins that exist as a separate executable
# (terraform-provider-XXXX).
_init_terraform_completion () {
  local IFS=':'
  #-- Regex used when looking for terraform executables.
  # Looks for "terraform", or "terraform[anything else that isn't a dash]".
  # This enables Command Completion for multiple versions of Terraform,
  # if you have them.
  local TF_EXEC_PREFIX='^terrafor(m[^-]+|m)$'

  local ORIG_DIR="${PWD}"

  for P in ${PATH}; do
    if [ -d "${P}" ]; then
      cd "${P}"

    else
      continue

    fi

    for E in *; do
      if [[ "${E}" =~ ${TF_EXEC_PREFIX} ]]; then
        complete -F _terraform_completion ${E}

      fi
    done
  done

  cd "${ORIG_DIR}"
}

complete -F _terraform_completion terraform

#--- Optionally enable command completion for multiple Terraform executables.
# It currently works with executables in the PATH, that are named similar
# to "terraform_XXXX".
#
# ** If your files are named differently, then you may need to modify the REGEX
# ** in TF_EXEC_PREFIX to suit your needs.
#
# This provides a little simplicity, when working with multiple Terraform versions.
#
# Uncomment this line to enable:
_init_terraform_completion

#--- Remove the initialization function. It is only needed once.
unset -f _init_terraform_completion
