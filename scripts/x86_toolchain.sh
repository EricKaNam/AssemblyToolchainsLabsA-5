#! /bin/bash

# Created by Lubos Kuzma
# Revised by Ching Hang Chung, Eric
# ISS Program, SADT, SAIT
# October 2023


if [ $# -lt 1 ]; then	#command-line arguments ($#) is less than (-lt) 1. show the menu
	echo "Usage:"
	echo ""
	echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
	echo ""
	echo "-v | --verbose                Show some information about steps performed."
	echo "-g | --gdb                    Run gdb command on executable."
	echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start."
	echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
	echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
	echo "-32| --x64                 	Compile for 32bit (x64) system."
	echo "-o | --output <filename>      Output filename."

	exit 1				#exits the program
fi

POSITIONAL_ARGS=()		#define an array to store non-flag command-line arguments
GDB=False				#set default GDB to False, ii.e. no GDB mode
OUTPUT_FILE=""			#set default OUTPUT_FILE to Null, i.e. default output name is the same as source file
VERBOSE=False			#set default Verbose to False, i.e. no detail
BITS=True				#set default BITS to True, i.e. to run in 64-bit
QEMU=False				#set default QEMU to False, not to use QEMU emulator
BREAK="_start"			#set default break point at _start
RUN=False				#set default RUN to False

while [[ $# -gt 0 ]]; do		#When argument greater tham (-gt) 0
	case $1 in
		-g|--gdb)
			GDB=True			#Sets the GDB variable to true
			shift # past argument
			;;
		-o|--output)			#variable to the value in $2
			OUTPUT_FILE="$2"
			shift # past argument
			shift # past value
			;;
		-v|--verbose)			#Sets the VERBOSE variable to true
			VERBOSE=True
			shift # past argument
			;;
		-32|--x64)				#Set the BITS variable to false 
			BITS=False
			shift # past argument
			;;
		-q|--qemu)				#Sets the VERBOSE variable to true
			QEMU=True
			shift # past argument
			;;
		-r|--run)				#Sets the RUN variable to true
			RUN=True
			shift # past argument
			;;
		-b|--break)				#Sets the BREAK variable the value in $2
			BREAK="$2"
			shift # past argument
			shift # past value
			;;
		-*|--*)
			echo "Unknown option $1"	#if it is an unknown option, program exits.
			exit 1
			;;
		*)
			POSITIONAL_ARGS+=("$1") # save positional arg
			shift # past argument
			;;
	esac	#reverse of "case", the end of case selection
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters and updates the command-line arguments
#For example, if POSITIONAL_ARGS contains the elements "file1.txt" and "file2.txt", 
#the set command will effectively set $1 to "file1.txt" and $2 to "file2.txt


if [[ ! -f $1 ]]; then		#If the first positional argument (likely the filename) does not exist as a file.
	echo "Specified file does not exist"
	exit 1
fi

if [ "$OUTPUT_FILE" == "" ]; then
	OUTPUT_FILE=${1%.*}				#if no output file name is entered, use the input file's name with the extension removed
fi

if [ "$VERBOSE" == "True" ]; then	# is set to true, it displays information about the selected options and the compilation process.
	echo "Arguments being set:"
	echo "	GDB = ${GDB}"
	echo "	RUN = ${RUN}"
	echo "	BREAK = ${BREAK}"
	echo "	QEMU = ${QEMU}"
	echo "	Input File = $1"
	echo "	Output File = $OUTPUT_FILE"
	echo "	Verbose = $VERBOSE"
	echo "	64 bit mode = $BITS" 
	echo ""

	echo "NASM started..."

fi

if [ "$BITS" == "True" ]; then
	#USE NASM assembler to generates a 64-bit ELF (Executable and Linkable Format) binary
	nasm -f elf64 $1 -o $OUTPUT_FILE.o && echo ""


elif [ "$BITS" == "False" ]; then
	#USE NASM assembler to generates a 32-bit ELF (Executable and Linkable Format) binary
	nasm -f elf $1 -o $OUTPUT_FILE.o && echo ""

fi

if [ "$VERBOSE" == "True" ]; then
	#Show the progress as Assembler finished
	echo "NASM finished"
	echo "Linking ..."
fi

if [ "$BITS" == "True" ]; then
	#ld (GNU Linker) combines a number of object and archive files,into a 64-bit ELF executable file
	ld -m elf_x86_64 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""


elif [ "$BITS" == "False" ]; then
	#ld (GNU Linker) combines a number of object and archive files,into a 32-bit ELF executable file
	ld -m elf_i386 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""

fi


if [ "$VERBOSE" == "True" ]; then
	#Finish the linking part
	echo "Linking finished"

fi

if [ "$QEMU" == "True" ]; then
	#Start the QEMU (Quick Emulator) loader
	echo "Starting QEMU ..."
	echo ""

	if [ "$BITS" == "True" ]; then
		#If both QEMU and GDB(64-bit) are selected, it is to run QEMU in 64-bit
		qemu-x86_64 $OUTPUT_FILE && echo ""

	elif [ "$BITS" == "False" ]; then
		#If only QEMU is selected, it is to run QEMU in 32-bit
		qemu-i386 $OUTPUT_FILE && echo ""

	fi

	exit 0
	
fi

if [ "$GDB" == "True" ]; then

	gdb_params=()	#This line initializes an array called gdb_params to store GDB command-line options
	gdb_params+=(-ex "b ${BREAK}")	#insert the option '-ex "b {BREAK}"' (break point) to the gdb_params

	if [ "$RUN" == "True" ]; then

		gdb_params+=(-ex "r")	#this line appends the -ex "r" option to the gdb_params 

	fi

	gdb "${gdb_params[@]}" $OUTPUT_FILE	# expands the gdb_params array into individual elements, pass the -ex options to GDB

fi
