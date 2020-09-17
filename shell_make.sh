#!/usr/bin/env bash

generate_targets_need_run(){
  target="${1}"
  if ! [[ " ${run_targets[@]} " =~ " ${target} " ]]; then
    run_targets+=("$target")
  fi
  dependencies=${targets["$target"]}
  export IFS=" "
  for dependecy in $dependencies; do

    if ! [[ $dependecy == "" ]] && ! [[ " ${run_targets[@]} " =~ " ${dependecy} " ]]; then
      run_targets+=("$dependecy")
      generate_targets_need_run "$dependecy"
    fi
  done
}

execute_target_command(){
  target=$1
  eval "${recipes[$target]}"
}


makefile="shmakefile"
next_arg_file=0
targets=[]
run_targets=()
given_args=()

for var in "$@"
do
    if [[ $var == "-f" ]]; then
      next_arg_file=1
    elif [[ $next_arg_file == 1 ]]; then
      makefile="$var"
      next_arg_file=0
    else
      given_args+=("$var")
    fi
done


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
      dep="$(cut -d':' -f 2 <<<"$line")"
      dep="$(echo "$dep" |   xargs)"
      targets["$l_target"]=$dep
    fi

  else

    if ! [[ $line =~ ^(\s+)?$ ]] && ! [[ $l_target == "" ]]; then

      if ! [[ $current_command == "" ]]; then
        line="$(echo "$line" | xargs)"
        current_command="$current_command && $line"
      else
        line="$(echo "$line" | xargs)"
        current_command=$line
      fi

      recipes["$l_target"]="$current_command"

    fi
  fi
done <"$makefile"
if [[ "${#given_args[@]}" == 0 ]]; then
    generate_targets_need_run "${targets[0]}"
else
    for var in "${given_args[@]}"
    do
      generate_targets_need_run "$var"
    done
fi



for (( i=${#run_targets[@]}-1 ; i>=0 ; i-- )) ;
do
    target="${run_targets[i]}"
    execute_target_command "$target"
done