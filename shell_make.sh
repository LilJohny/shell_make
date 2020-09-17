#!/usr/bin/env bash

makefile="shmakefile"
echo start
for var in "$@"
do
    echo "$var"
done
echo finish

if [ "$1" != "" ]; then
  makefile="$1"
fi

declare -A targets
declare -A recipes

current_command=""
l_target=""
while IFS= read -r line; do

  if [[ $line == *":"* ]]; then
    current_command=""
    l_target="$(cut -d':' -f 1 <<<"$line")"

    if [[ $line == *: ]]; then
      targets["$l_target"]=""
    else
      echo 23
      dep="$(cut -d':' -f 2 <<<"$line")"
      dep="$(echo "$dep" |   xargs)"
      echo $dep
      targets["$l_target"]=$dep
    fi

  else

    if ! [[ $line =~ ^(\s+)?$ ]] && ! [[ $l_target == "" ]]; then

      if ! [[ $current_command == "" ]]; then
        current_command="$current_command && $line"
      else
        current_command=$line
      fi

      recipes["$l_target"]="$current_command"

    fi
  fi
done <"$makefile"

for i in "${!recipes[@]}"; do
  echo "key  : $i"
  echo "value: ${recipes[$i]}"
done

echo recipes here
for i in "${!targets[@]}"; do
  echo "key  : $i"
  echo "value: ${targets[$i]}"
done

