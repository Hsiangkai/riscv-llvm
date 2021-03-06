#!/bin/sh

COMPSUCC=0
COMPFAIL=0
RUNSUCC=0
RUNFAIL=0
rm -f comppass compfail runpass runfail
touch comppass compfail runpass runfail
mkdir -p output
rm output/*

TESTS_TO_SKIP=$(cat <<EOF
# Nested functions, unsupported in clang
20000822-1.c
20010209-1.c
20010605-1.c
20030501-1.c
20040520-1.c
20061220-1.c
20090219-1.c
920415-1.c
920428-2.c
920501-7.c
920612-2.c
920721-4.c
921017-1.c
921215-1.c
931002-1.c
comp-goto-2.c
nest-align-1.c
nest-stdar-1.c
nestfunc-1.c
nestfunc-2.c
nestfunc-3.c
nestfunc-5.c
nestfunc-6.c
nestfunc-7.c
pr22061-3.c
pr22061-4.c
pr24135.c
pr51447.c
pr71494.c

# Expects gnu89 inline behaviour
20001121-1.c
20020107-1.c
930526-1.c
961223-1.c
880608-1.c
bcp-1.c
loop-2c.c
p18298.c
restrict-1.c
unroll-1.c
va-arg-7.c
va-arg-8.c

# Variable length arrays in structs, unsupported in clang
20020412-1.c
20040308-1.c
20040423-1.c
20041218-2.c
20070919-1.c
align-nest.c
pr41935.c

# Initialization of flexible array member unsupported in clang
pr28865.c

# Runtime failure even on clang x86
20021127-1.c
20031003-1.c
alloca-1.c
bitfld-3.c
bitfld-5.c
eeprof-1.c
pr32244-1.c
pr34971.c

# Clang has no __builtin_malloc
20071018-1.c
20071120-1.c
pr36765.c
pr43008.c

# Non-void function must return a value
920302-1.c
920501-3.c
920728-1.c

# Must link with libm
980709-1.c
float-floor.c

# x86 only
990413-2.c

# Unsupported builtins, even on x86 clang
builtin-bitops-1.c
pr39228.c
pr47327.c
pr78586.c
pr79327.c
va-arg-pack-1.c

# Requires mmap
loop-2f.c
loop-2g.c

# Link error, even on x86 clang
medce-1.c

# Clang does not support 'DD' suffix on floating constant
pr80692.c

# Requires definitions of stdout/stderr
fprintf-1.c
fprintf-chk-1.c
gofast.c
vfprintf-1.c
vfprintf-chk-1.c
EOF
)

# Strip comments, empty lines, and sort TESTS_TO_SKIP
$(cut -d'#' -f1 <<EOF | sed -e '/^$/d' -e 's/[[:blank:]]*$//'| sort > skip.txt
$TESTS_TO_SKIP
EOF
)

TESTS=$(comm -23 - <<EOF skip.txt
$(ls *.c)
EOF
)

for FILE in $TESTS; do
  echo "Compiling $FILE"
  BASEFILE=$(basename $FILE .c)
  timelimit -s1 -t 4 ./rvcc.sh $FILE
  if [ -e output/$BASEFILE ]; then
    echo ":)";
    echo $BASEFILE >> comppass
    COMPSUCC=$((COMPSUCC + 1))
    
    timelimit -s1 -t 4 spike pk output/$BASEFILE
    if [ $? -eq 0 ]; then
      echo ":)";
      echo $BASEFILE >> runpass
      RUNSUCC=$((RUNSUCC + 1))
    else
      echo ":("
      echo $BASEFILE >> runfail
      RUNFAIL=$((RUNFAIL + 1))
    fi
  else
    echo ":("
    echo $BASEFILE >> compfail
    COMPFAIL=$((COMPFAIL + 1))
  fi
  printf "\n\nCompile pass:fail %d:%d\n" $COMPSUCC $COMPFAIL
  printf "Run pass:fail %d:%d\n\n\n" $RUNSUCC $RUNFAIL
done
