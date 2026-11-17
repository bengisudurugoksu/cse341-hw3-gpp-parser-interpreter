%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Simple symbol table for storing identifiers and their values
struct symbol {
    char *name;
    float value;
};

struct symbol symbol_table[100];  // Symbol table array
int symbol_count = 0;

// Example debug for symbol lookup
float get_identifier_value(char *name) {
    printf("Looking up variable: %s\n", name);
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            printf("Found variable: %s with value: %f\n", name, symbol_table[i].value);
            return symbol_table[i].value;
        }
    }
    printf("Warning: Variable %s not found.\n", name);
    return 0.0;
}



// Function to add or update a variable in the symbol table
void add_variable(char *name, float value) {
    printf("Adding variable: %s with value: %f\n", name, value);

    if (symbol_count >= 100) {
        fprintf(stderr, "Symbol table is full! Cannot add more variables.\n");
        exit(1);
    }

    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            printf("Updating variable: %s with new value: %f\n", name, value);
            symbol_table[i].value = value;
            return;
        }
    }

    // Allocate memory for variable name
    symbol_table[symbol_count].name = strdup(name);
    if (symbol_table[symbol_count].name == NULL) {
        fprintf(stderr, "Memory allocation failed for variable %s\n", name);
        exit(1);
    }
    symbol_table[symbol_count].value = value;
    symbol_count++; 
}

void load_file(char *filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        fprintf(stderr, "Error: Could not open file %s\n", filename);
        exit(1);  // Handle the error
    }

    char line[1024];
    while (fgets(line, sizeof(line), file)) {
        // Trim newline and extra spaces from the line
        line[strcspn(line, "\n")] = '\0';  // Remove newline character

        // Strip out the outer parentheses, if any
        if (line[0] == '(' && line[strlen(line) - 1] == ')') {
            // Remove the parentheses by shifting the string
            memmove(line, line + 1, strlen(line) - 1);
            line[strlen(line) - 1] = '\0';
        }

        // Remove extra spaces around the string
        char *trimmed_line = line;
        while (*trimmed_line == ' ' || *trimmed_line == '\t') {
            trimmed_line++;
        }

        if (strncmp(trimmed_line, "print", 5) == 0) {
            // Example: (print 3.2)
            float value;
            if (sscanf(trimmed_line, "print %f", &value) == 1) {
                printf("%f\n", value);  // Print the value
            } else {
                fprintf(stderr, "Error: Invalid print syntax in line: %s\n", trimmed_line);
            }
        }
        else if (strncmp(trimmed_line, "defvar", 6) == 0) {
            // Example: (defvar x 3.2)
            char var_name[100];
            float value;
            if (sscanf(trimmed_line, "defvar %s %f", var_name, &value) == 2) {
                add_variable(var_name, value);  // Add the variable to the symbol table
            } else {
                fprintf(stderr, "Error: Invalid defvar syntax in line: %s\n", trimmed_line);
            }
        }
        else if (strncmp(trimmed_line, "set", 3) == 0) {
            // Example: (set x 5.0)
            char var_name[100];
            float value;
            if (sscanf(trimmed_line, "set %s %f", var_name, &value) == 2) {
                // Ensure the variable is defined
                if (get_identifier_value(var_name) == 0.0) {
                    fprintf(stderr, "Error: Variable %s is not defined.\n", var_name);
                } else {
                    add_variable(var_name, value);  // Update the variable
                }
            } else {
                fprintf(stderr, "Error: Invalid set syntax in line: %s\n", trimmed_line);
            }
        }
        else {
            fprintf(stderr, "Error: Unknown command in line: %s\n", trimmed_line);
        }
    }

    fclose(file);
}


void execute_exit() {
    printf("Exiting program.\n");
    exit(0);
}
// Error handling function for Bison
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
%}

%union {
    char *str;   // For string tokens (like IDENTIFIER)
    int valuei;  // For integer values (like counts)
    float valuef; // For floating point values (like VALUEF)
}

%token <valuef> VALUEF KW_DEFFUN KW_IF KW_LESS KW_EQUAL KW_WHILE KW_FOR KW_LOAD
%token <str> IDENTIFIER
%token OP_PLUS OP_MINUS OP_MULT OP_DIV OP_OP OP_CP OP_COMMA KW_EXIT KW_PRINT KW_DEFVAR KW_SET

%type <valuef> IDLIST EXPB // Now IDLIST returns an integer count
%type <valuef> expr list values explist expi expd
%left KW_LESS
%left KW_WHILE // 'while' en yüksek önceliğe sahip olmalı
%left KW_IF
%right OP_OP OP_CP
%left OP_PLUS OP_MINUS 
%left OP_MULT OP_DIV 
%left KW_DEFVAR KW_SET KW_PRINT KW_DEFFUN KW_LOAD KW_EXIT 

%%

start:
    input
    ;

input:
    | input expr  
    | input explist 
    | input expi
    | input expd
    ;

expr:
    OP_OP OP_PLUS expr explist OP_CP { $$ = $3 + $4; }
  | OP_OP OP_MINUS expr explist OP_CP { $$ = $3 - $4; }
  | OP_OP OP_MULT expr explist OP_CP { $$ = $3 * $4; }
  | OP_OP OP_DIV expr explist OP_CP { $$ = $3 / $4; }
  | VALUEF { $$ = $1; }
  | list { $$ = $1; }
  | IDENTIFIER { $$ = get_identifier_value($1); }
  ;

values:
    values OP_COMMA VALUEF { $$ = $3; } 
    | VALUEF  
    ;

list:
    OP_OP values OP_CP { $$ = $2; }
    | OP_OP OP_CP { $$ = 0.0; }
    ;

explist:
    | expr { $$ = $1; } 
    | OP_OP explist expr OP_CP { $$ = $3; }  
    | expi { $$ = $1; } 
    | OP_OP explist expi OP_CP { $$ = $3; }  
    | expd { $$ = $1; } 
    | OP_OP explist expd OP_CP { $$ = $3; }  
  ;

IDLIST:
    IDENTIFIER { $$ = 1.0; } 
    | IDLIST OP_COMMA IDENTIFIER { $$ = 1.0 + $1; }  
  ;

IDLISTSORT:
    OP_OP IDLIST OP_CP
    ;

EXPB:
    OP_OP KW_LESS expr expr OP_CP { $$ = $3 < $4 ? 1.0 : 0.0; }  
    | OP_OP KW_EQUAL expr expr OP_CP { $$ = $3 == $4 ? 1.0 : 0.0; } 
;

expi:
   OP_OP KW_IF EXPB explist explist OP_CP { $$ = 0.0; }
    | OP_OP KW_WHILE EXPB explist OP_CP {}
  | OP_OP KW_DEFFUN IDENTIFIER IDLISTSORT explist OP_CP { $$ = 0.0; }
  | OP_OP IDENTIFIER explist OP_CP { $$ = 0.0; }
  | OP_OP KW_IF EXPB explist OP_CP { $$ = $3; }
  | OP_OP KW_FOR OP_OP IDENTIFIER EXPB expd OP_CP explist OP_CP { $$ = 0.0; } 
  | OP_OP KW_LOAD IDENTIFIER  OP_CP {load_file($3); $$ = 0.0;  }
  | OP_OP KW_EXIT OP_CP { execute_exit(); } 
  ;

expd:
   OP_OP KW_DEFVAR IDENTIFIER expr OP_CP { 
       // Handle variable definition
       add_variable($3, $4);  // $2 is the variable name, $4 is the expression (value)
       $$ = $4;
   }
  | OP_OP KW_SET IDENTIFIER expr OP_CP { 
        // Handle variable assignment
        // Check if the variable is already defined before setting
        if (get_identifier_value($3) == 0.0) {
            fprintf(stderr, "Error: Variable %s is not defined yet.\n", $3);
            exit(1);  // Or handle the error gracefully
        }
        add_variable($3, $4);  // $3 is the variable name, $4 is the expression value
        $$ = $4;
    }
  | OP_OP KW_PRINT expr OP_CP { printf("%f\n", $3); $$ = 0.0; } 
  ;


%%

int main() {
    printf("Starting interpreter...\n");
    if (yyparse() != 0) {
        fprintf(stderr, "Parsing failed.\n");
        return 1;  // If parsing fails, return error
    }
    printf("Parsing completed successfully.\n");
    return 0;
}

//flex gpp_lexer.l, bison -o parser.c -d gpp_interpreter.y ,g++ -o gpp_interpreter parser.c lex.yy.c -lfl, ./gpp_interpreter