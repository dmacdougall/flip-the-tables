#!/usr/bin/env bash

# The following function (replace_path) is lifted directly from an SO post by the user Jonathan Leffler here:
# http://stackoverflow.com/questions/273909/how-do-i-manipulate-path-elements-in-shell-scripts
# ---------------------------------------------- BEGIN -------------------------------------------------------

# Usage:
#
# To replace a path:
#    replace_path         PATH $PATH /exact/path/to/remove /replacement/path
#
###############################################################################

# Remove or replace an element of $1
#
#   $1 name of the shell variable to set (e.g. PATH)
#   $2 a ":" delimited list to work from (e.g. $PATH)
#   $3 the precise string to be removed/replaced
#   $4 the replacement string (use "" for removal)
replace_path() {
  path=$1
  list=$2
  remove=$3
  replace=$4 # Allowed to be empty or unset
  export $path="$(echo "$list" | tr ":" "\n" | sed "s:^$remove\$:$replace:" | tr "\n" ":" | sed 's|:$||')"
}

# ---------------------------------------------- END ---------------------------------------------------------

if [[ -z "$RUBIES" ]]; then
  echo '$RUBIES must be set to use flip-the-tables.'
  return 1
fi

if [[ -n "$GEM_HOME" || -n "$GEM_PATH" ]]; then
  echo '$GEM_HOME and $GEM_PATH should not be set if you use flip-the-tables'
  return 1
fi

# Get the full list of versions
_ft_ruby_list() {
  echo $(for f in $(find "$RUBIES" -type d -d 1); do basename "$f"; done)
}

# Swap out ruby versions by replacing $RUBIES/<ruby1>/bin with $RUBIES/<ruby2>/bin
_ft_set_ruby() {
  current=$1
  pattern=$2
  ruby=$(find "$RUBIES" -type d -d 1 -name "${pattern}*" | head -1)
  if [[ -z "$ruby" ]]; then
    echo "Error: No Ruby matched $pattern."
  elif [[ "$(dirname "$current")" != "$ruby" ]]; then
    echo -e "\033[01;32mSwitching to Ruby $(basename "$ruby").\033[39m"
    replace_path PATH "$PATH" "$current" "$ruby/bin"
  fi
}

_ft_help() {
  echo 'flip-the-tables: easily switch ruby paths around.'
  echo 'Usage: ft [version|version-short|list|<ruby-version>]'
  echo 'The tab-completion should be a good hint :)'
}

ft() {
  if [[ "$#" -ne 1 ]]; then
    _ft_help
  else
    current=$(echo "$PATH" | tr ":" "\n" | grep -m 1 "^$RUBIES/.*/bin/\?\$")
    current_short=$(basename $(dirname "$current"))
    if [[ -z "$current" ]]; then
      echo 'Error: not currently using Ruby in $RUBIES.'
    else
      case "$1" in
        help) _ft_help
          ;;
        version) echo "Current Ruby: $current_short"
          ;;
        short-version) printf "$current_short"
          ;;
        list)
          for ruby in $(_ft_ruby_list); do
            if [[ "$current_short" = "$ruby" ]]; then
              echo "* $ruby"
            else
              echo "  $ruby"
            fi
          done
          ;;
        *) _ft_set_ruby "$current" "$1"
          ;;
      esac
    fi
  fi
}
