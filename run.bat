bison -d Yacc.y
flex Lex.l
gcc -o parser Yacc.tab.c
./parser