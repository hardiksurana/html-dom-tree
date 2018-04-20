%{
#include "htmlFunc.c"
#include "Yacc.tab.h"
%}

%option stack yylineno
%x startElement
%s endElement
%x attribute
%x xmlDecl
%x processingInstruction

Ws              ([ \t\r\n]+)
Letter          [A-Za-z]
Digit           [0-9]
NameChar        {Letter}|{Digit}|[-._:]
Name            ({Letter}|[_:]){NameChar}* 
TagList1        "a"|"abbr"|"acronym"|"address"|"b"|"base"|"big"|"blockquote"|"body"|"br"|"button"|"caption"|"cite"|"code"|"dd"
TagList2        "dfn"|"div"|"dl"|"dt"|"em"|"fieldset"|"form"|"h1"|"h2"|"h3"|"h4"|"h5"|"h6"|"head"|"hr"|"html"|"i"|"img"|"input"
TagList3        "kbd"|"label"|"legend"|"li"|"link"|"meta"|"noscript"|"object"|"ol"|"optgroup"|"option"|"p"|"param"|"pre"|"q"
TagList4        "samp"|"script"|"select"|"small"|"span"|"strong"|"style"|"sub"|"sup"|"table"|"td"|"textarea"|"th"|"title"|"tr"
TagList5        "tt"|"ul"|"var"
StarTag         ({TagList1}|{TagList2}|{TagList3}|{TagList4}|{TagList5})
AttList1        "abbr"|"accept-charset"|"accept"|"accesskey"|"action"|"align"|"alink"|"alt"|"archive"|"axis"|"background"|"bgcolor"|"border"
AttList2        "cellpadding"|"cellspacing"|"char"|"charoff"|"charset"|"checked"|"cite"|"class"|"classid"|"clear"|"code"|"codebase"|"codetype"
AttList3        "color"|"cols"|"colspan"|"compact"|"content"|"coords"|"data"|"datetime"|"declare"|"defer"|"dir"|"disabled"|"enctype"|"face"|"for"
AttList4        "frame"|"frameborder"|"headers"|"height"|"href"|"hreflang"|"hspace"|"http-equiv"|"id"|"ismap"|"label"|"lang"|"language"|"link"
AttList5        "longdesc"|"marginheight"|"marginwidth"|"maxlength"|"media"|"method"|"multiple"|"name"|"nohref"|"noresize"|"noshade"|"nowrap"
AttList6        "object"|"onblur"|"onchange"|"onclick"|"ondblclick"|"onfocus"|"onkeydown"|"onkeypress"|"onkeyup"|"onload"|"onmousedown"|"onmousemove"
AttList7        "onmouseout"|"onmouseover"|"onmouseup"|"onreset"|"onselect"|"onsubmit"|"onunload"|"profile"|"prompt"|"readonly"|"rel"|"rev"|"rows"
AttList8        "rowspan"|"rules"|"scheme"|"scope"|"scrolling"|"selected"|"shape"|"size"|"span"|"src"|"standby"|"start"|"style"|"summary"|"tabindex"
AttList9        "target"|"text"|"title"|"type"|"usemap"|"valign"|"value"|"valuetype"|"version"|"vlink"|"vspace"|"width"
StarAtt         {AttList1}|{AttList2}|{AttList3}|{AttList4}|{AttList5}|{AttList6}|{AttList7}|{AttList8}|{AttList9}|"xml"{Name}|"data-"{Name}
Comment         "<!--"[^-]*[-]{2,}([^->][^-]*[-]{2,})*">"
CData           "<![CDATA["[^\]]*[\]]{2,}([^\]>][^\]]*[\]]{2,})*">"
CharData        [^<&]*
AttValue        (\"[^<&"]*\")|("'"[^<&']*"'")
CharRef         "&#"[0-9]+";"|"&#x"[0-9a-fA-F]+";"
EntityRef       "&"{Name}";"
Char            [\t\n\r\x20-\xFF]
VersionNum      "1.0"
VersionInfo     {Ws}"version"{Ws}?"="{Ws}?("'"{VersionNum}"'"|\"{VersionNum}\")
EncName         [A-Za-z]([A-Za-z0-9._]|"-")*
EncodingDecl    {Ws}"encoding"{Ws}?"="{Ws}?(\"{EncName}\"|"'"{EncName}"'")
SDDecl          {Ws}"standalone"{Ws}?"="{Ws}?(("'"("yes"|"no")"'")|(\"("yes"|"no")\"))
XMLDecl         "<?"[xX][mM][lL]{VersionInfo}{EncodingDecl}?{SDDecl}?{Ws}?"?>"
TextDecl        "<?"[xX][mM][lL]{VersionInfo}{EncodingDecl}?{Ws}?"?>"
UnknownDecl     "<?"{Name}[^?]*[?]+([^?>][^?]*[?]+)*">"
PI              "<?"{Name}({Ws}[^?]*)?[?]+([^?>][^?]*[?]+)*">"

%%

"<"{StarTag}    {
                    yy_push_state(startElement);
                    removeFirstChar(yytext);
                    tree_add_child(yytext);
                    return START_TAG;
                }
        
"<"{Name}       {
                    yy_pop_state();
                    removeFirstChar(yytext);
                    printf("\n[!!]: unknown tag: '<%s>' on line: %d \n", yytext, yylineno);
                    setParseError(1);
                    return SYNTAX_ERROR;
                }        

<attribute>{

  {StarAtt}{Ws}?[=] {
                         yyless(yyleng - 1); /* put back the equals sign */
                         // printf("[ok]: + %s\n", yytext);
                         tree_add_attribute(yytext);
                    }
  {Name}{Ws}?[=]    {
                         yyless(yyleng - 1); /* put back the equals sign */
                         printf("[ii]: unknown attribute: '%s' on line: %d \n", yytext, yylineno);
                         setParseError(1);
                    }
  [=]{Ws}?          ;   /* ignore */
  {AttValue}        {
                         yy_pop_state();
                    }
}


<startElement>{
{Name}{Ws}?[=]{Ws}?["']     {
                                yy_push_state(attribute);
                                yyless(0);  /* put back the entire lexeme */
                            }

"/>"            {
                    yy_pop_state();
                    pop();
                    return END_EMPTY_TAG;
                }

[>]             {
                    yy_pop_state();
                    yy_push_state(endElement);
                    return *yytext;
                }
                
[ \t\n]         ; /* ignore whitespace */

}

<endElement>{
"</"{StarTag}">"    {
                        yy_pop_state();
                        pop();
                        return END_TAG;
                    }

"</"{Name}">"   {
                    yy_pop_state();
                    pop();
                    printf("[!!]: unknown tag: '%s' on line: %d \n", yytext, yylineno);
                    setParseError(1);
                    return SYNTAX_ERROR;
                }
}


{UnknownDecl}   {
                    if (yyleng >= 5 && strncmp((char*)(yytext + 2), "xml", 3) == 0)
                    {
                        if (yyleng == 5 || (isspace(yytext[5]) || yytext[5] == '?'))
                            yy_push_state(xmlDecl);
                        else
                            yy_push_state(processingInstruction);
                    }
                    else
                        yy_push_state(processingInstruction);
                    yyless(0);
                }


<xmlDecl>{
{XMLDecl}       {
                    yy_pop_state();
                    return XML_DECL;
                }
{UnknownDecl}   {
                    yy_pop_state();
                    printf("[!!]: invalid XMLDECL: %s\n", yytext);
                    setParseError(1);
                    return SYNTAX_ERROR;
                }
}

<processingInstruction>{
{PI}            {
                    yy_pop_state();
                    return PROC_INSTR;
                }
}


{Comment}       {
                    return COMMENT;
                }

{CData}         {
                    return CDATA;
                }

{CharRef}       {
                    return REFERENCE;
                }

{EntityRef}     {
                    return REFERENCE;
                }

[\n\r]          ; /* ignore */
.               ; /* ignore */
%%