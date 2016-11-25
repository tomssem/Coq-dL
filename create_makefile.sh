#!/bin/bash

if [ -e "coquelicot-2.1.1" ]
then
    echo "coquelicot-2.1.1 already exists"
else
    echo "extractint coquelicot-2.1.1 directory"
    tar -xvzf coquelicot-2.1.1.tar.gz
fi

function get_deps () {
    grep "^Require" $1.v \
    | sed 's/Require Import \(.*\)\..*$/\1/' \
    | sed 's/Require Export \(.*\)\..*$/\1/' \
    | sed 's/Require \(.*\)\..*$/\1/'
}

containsElement () {
    local e
    for e in "${@:2}"; do
	[[ "$e" == "$1" ]] && return 0;
    done
    return 1
}

declare -A aa
declare -a remfiles
declare -a allfiles
#declare -a temp

remfiles=("all")
allfiles=("all")

echo "`date`" > debug

while true
do
    #printf '%s\n' "==+== ${remfiles[@]} ==+=="
    if [[ ${#remfiles[@]} -eq 0 ]]
    then
	echo "++++++ no more files" >> debug
	break
    else
	file=${remfiles[0]}
	remfiles=("${remfiles[@]:1}")
	#printf '%s\n' "++=++ ${remfiles[@]} ++=++"
	echo "===============================" >> debug
	echo "++++++ file: ${file}" >> debug

	temp=`get_deps $file`
	deps=()
	for f in $temp
	do
	    if [ -e "${f}.v" ]
	    then deps+=("$f")
	    else
		if [ -e "syntax/${f}.v" ]
		then deps+=("syntax/$f")
		else
		    if [ -e "semantics/${f}.v" ]
		    then deps+=("semantics/$f")
		    else
			if [ -e "substitution/${f}.v" ]
			then deps+=("substitution/$f")
			else
			    if [ -e "axioms/${f}.v" ]
			    then deps+=("axioms/$f")
			    else
				if [ -e "checker/${f}.v" ]
				then deps+=("checker/$f")
				else
				    if [ -e "examples/${f}.v" ]
				    then deps+=("examples/$f")
				    else
					if [ -e "coq-tools/${f}.v" ]
					then deps+=("coq-tools/$f")
					else
					    if [ -e "coquelicot-2.1.1/theories/${f}.v" ]
					    then deps+=("coquelicot-2.1.1/theories/$f")
					    else echo "${f} doesn't exist" >> debug
					    fi
					fi
				    fi
				fi
			    fi
			fi
		    fi
		fi
	    fi	    
	done
	#printf '%s\n' "++=++ ${deps[@]} ++=++"
	#deps=("${temp[@]}")

	aa[$file]=${deps[@]}
   
	for i in "${deps[@]}"
	do
	    #echo "checking $i"
	    containsElement "$i" "${allfiles[@]}"
	    n=$?
	    if [[ $n -eq 1 ]]
	    then
		echo "++ new dependency: ${i}" >> debug
		remfiles=("${remfiles[@]}" "$i")
		allfiles=("${allfiles[@]}" "$i")
	    else echo "++ not new dependency: ${i}" >> debug
	    fi
	done
    fi
done

echo "# Makefile generated by create_makefile.sh" > Makefile
echo "" >> Makefile
echo "default : all.vo" >> Makefile

echo "" >> Makefile
echo "clean :" >> Makefile
echo "	rm -f syntax/.*.aux       syntax/*.glob       syntax/*.vo"       >> Makefile
echo "	rm -f semantics/.*.aux    semantics/*.glob    semantics/*.vo"    >> Makefile
echo "	rm -f substitution/.*.aux substitution/*.glob substitution/*.vo" >> Makefile
echo "	rm -f axioms/.*.aux       axioms/*.glob       axioms/*.vo"       >> Makefile
echo "	rm -f checker/.*.aux      checker/*.glob      checker/*.vo"      >> Makefile
echo "	rm -f examples/.*.aux     examples/*.glob     examples/*.vo"     >> Makefile

for i in "${!aa[@]}"
do
    #echo "-------------------"
    #echo "++ ${i}"

    echo "" >> Makefile
    echo -n "${i}.vo : ${i}.v" >> Makefile

    if [[ ${#aa[$i]} -eq 0 ]]
    then
	echo "${i} doesn't have dependencies"
    else
	#echo "${aa[$i]}"
	IFS=' ' read -a vals <<< "${aa[$i]}"
	for f in "${vals[@]}"
	do
	    #echo "---- ${f}"
	    echo -n " ${f}.vo" >> Makefile
	done
    fi

    echo "" >> Makefile
    echo "	coqc -R coq-tools util -R coquelicot-2.1.1 coquelicot -R syntax syntax -R semantics semantics -R substitution substitution -R axioms axioms -R checker checker -R examples examples ${i}.v" >> Makefile
done
