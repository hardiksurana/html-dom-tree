# html-dom-tree
Parses HTML tags and attributes and displays the DOM tree in level order traversal

## Execution Instructions

1. Type the following instructions in your terminal one after another
```
bison -d Yacc.y
flex Lex.l
gcc -o parser Yacc.tab.c
./parser
```

2. Now, enter some HTML code. 
3. After the input has been given, press ENTER and then press Ctrl+D
4. You can now view the level order traversed display of the DOM tree elements with their associated attributes

### Sample Input:

```
<html>
<head><title> hello world </title></head>
<body class='body'> hello </body>
</html>
```

### Sample Output:
```
------------------------------ display called ------------------------------

L0 -> html , 
L1 -> head , body (class), 
L2 -> title , 

[ii]: Parse status: SUCCESS!
```