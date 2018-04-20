%{
#include <stdio.h>
#include "lex.yy.c"
int yyerror(char *);
%}

%token START_TAG END_EMPTY_TAG END_TAG
%token ATTRIBUTE COMMENT CDATA REFERENCE XML_DECL PROC_INSTR
%token SYNTAX_ERROR

%%

document:
        prolog element misc
        ;

prolog:
        XML_DECL misc
        | misc
        ;

misc:
        COMMENT
        | PROC_INSTR
        |
        ;

element:
        START_TAG attList elementRemainder
        ;

attList:
        attList ATTRIBUTE
        | ATTRIBUTE
        | /* empty */
        ;

elementRemainder:
        END_EMPTY_TAG
        | '>' contentList END_TAG
        ;

content:
        element
        | COMMENT
        | CDATA
        | REFERENCE
        | PROC_INSTR
        ;

contentList:
        contentList content
        | content
        |
        ;
    

%%

int main(int argc, char **argv) {
   tree_init();
   yyparse();
   tree_finish();
}

int yywrap(void) {
  display();
  return 1;
}

int yyerror(char *s) {
   setParseError(1);
   printf("\nline %d: %s at %s\n", yylineno, s, yytext); 
}
