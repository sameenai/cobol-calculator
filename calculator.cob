       IDENTIFICATION DIVISION.
       PROGRAM-ID. CALCULATOR.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-INPUT           PIC X(80).
       01 WS-LEFT-STR        PIC X(20).
       01 WS-RIGHT-STR       PIC X(20).
       01 WS-OPERATOR        PIC X(1).
       01 WS-LEFT            PIC S9(10)V9(4) VALUE 0.
       01 WS-RIGHT           PIC S9(10)V9(4) VALUE 0.
       01 WS-RESULT          PIC S9(10)V9(4) VALUE 0.
       01 WS-DISPLAY-RESULT  PIC -(10)9.9(4).
       01 WS-INT-RESULT      PIC -(10)9.
       01 WS-FRAC            PIC 9(4).
       01 WS-IDX             PIC 999 VALUE 0.
       01 WS-LEN             PIC 99 VALUE 0.
       01 WS-PARSE-STATE     PIC 9 VALUE 0.
       01 WS-CHAR            PIC X(1).
       01 WS-POWER-COUNT     PIC S9(10) VALUE 0.
       01 WS-POWER-IDX       PIC 999 VALUE 0.
       01 WS-POWER-RESULT    PIC S9(10)V9(4) VALUE 1.
       01 WS-POWER-BASE      PIC S9(10)V9(4) VALUE 0.
       01 WS-ERROR-FLAG      PIC 9 VALUE 0.
       01 WS-CONTINUE        PIC X(1) VALUE 'Y'.
       01 WS-BATCH-MODE      PIC 9 VALUE 0.
       01 WS-ARGS            PIC X(80).

       PROCEDURE DIVISION.
       MAIN-PROGRAM.
           ACCEPT WS-ARGS FROM COMMAND-LINE

           IF WS-ARGS NOT = SPACES
               MOVE WS-ARGS TO WS-INPUT
               MOVE 1 TO WS-BATCH-MODE
               PERFORM PARSE-INPUT
               IF WS-ERROR-FLAG = 0
                   PERFORM DO-CALCULATION
                   IF WS-ERROR-FLAG = 0
                       PERFORM DISPLAY-RESULT
                   END-IF
               END-IF
               STOP RUN
           END-IF

           DISPLAY "COBOL Calculator"
           DISPLAY "Format: <number> <op> <number>"
           DISPLAY "Operators: + - * / ^ %"
           DISPLAY "Type QUIT to exit"
           DISPLAY " "

           PERFORM UNTIL WS-CONTINUE = 'N'
               DISPLAY "> " WITH NO ADVANCING
               ACCEPT WS-INPUT
               IF FUNCTION UPPER-CASE(WS-INPUT(1:4)) = "QUIT"
                   MOVE 'N' TO WS-CONTINUE
               ELSE
                   PERFORM PARSE-INPUT
                   IF WS-ERROR-FLAG = 0
                       PERFORM DO-CALCULATION
                       IF WS-ERROR-FLAG = 0
                           PERFORM DISPLAY-RESULT
                       END-IF
                   END-IF
               END-IF
           END-PERFORM

           STOP RUN.

       PARSE-INPUT.
           MOVE 0 TO WS-ERROR-FLAG
           MOVE 0 TO WS-PARSE-STATE
           MOVE SPACES TO WS-LEFT-STR
           MOVE SPACES TO WS-RIGHT-STR
           MOVE SPACES TO WS-OPERATOR
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-INPUT))
               TO WS-LEN

           IF WS-LEN = 0
               DISPLAY "Error: empty input"
               MOVE 1 TO WS-ERROR-FLAG
           ELSE
               PERFORM PARSE-LOOP
           END-IF.

       PARSE-LOOP.
           MOVE 1 TO WS-IDX
           MOVE 0 TO WS-PARSE-STATE
           INITIALIZE WS-LEFT-STR
           INITIALIZE WS-RIGHT-STR

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-LEN
               MOVE WS-INPUT(WS-IDX:1) TO WS-CHAR
               EVALUATE WS-PARSE-STATE
                   WHEN 0
                       IF WS-CHAR = SPACE
                           IF WS-LEFT-STR NOT = SPACES
                               MOVE 1 TO WS-PARSE-STATE
                           END-IF
                       ELSE
                           STRING FUNCTION TRIM(WS-LEFT-STR)
                               WS-CHAR DELIMITED SIZE
                               INTO WS-LEFT-STR
                           END-STRING
                       END-IF
                   WHEN 1
                       IF WS-CHAR NOT = SPACE
                           MOVE WS-CHAR TO WS-OPERATOR
                           MOVE 2 TO WS-PARSE-STATE
                       END-IF
                   WHEN 2
                       IF WS-CHAR = SPACE
                           IF WS-OPERATOR NOT = SPACES
                               MOVE 3 TO WS-PARSE-STATE
                           END-IF
                       ELSE
                           MOVE WS-CHAR TO WS-OPERATOR
                       END-IF
                   WHEN 3
                       IF WS-CHAR NOT = SPACE
                           STRING FUNCTION TRIM(WS-RIGHT-STR)
                               WS-CHAR DELIMITED SIZE
                               INTO WS-RIGHT-STR
                           END-STRING
                       END-IF
               END-EVALUATE
           END-PERFORM

           IF WS-LEFT-STR = SPACES OR WS-OPERATOR = SPACES
               OR WS-RIGHT-STR = SPACES
               DISPLAY "Error: expected format <number> <op> <number>"
               MOVE 1 TO WS-ERROR-FLAG
           ELSE
               COMPUTE WS-LEFT =
                   FUNCTION NUMVAL(FUNCTION TRIM(WS-LEFT-STR))
               COMPUTE WS-RIGHT =
                   FUNCTION NUMVAL(FUNCTION TRIM(WS-RIGHT-STR))
           END-IF.

       DO-CALCULATION.
           MOVE 0 TO WS-ERROR-FLAG
           EVALUATE WS-OPERATOR
               WHEN '+'
                   COMPUTE WS-RESULT = WS-LEFT + WS-RIGHT
               WHEN '-'
                   COMPUTE WS-RESULT = WS-LEFT - WS-RIGHT
               WHEN '*'
                   COMPUTE WS-RESULT = WS-LEFT * WS-RIGHT
               WHEN '/'
                   IF WS-RIGHT = 0
                       DISPLAY "Error: division by zero"
                       MOVE 1 TO WS-ERROR-FLAG
                   ELSE
                       COMPUTE WS-RESULT = WS-LEFT / WS-RIGHT
                   END-IF
               WHEN '^'
                   PERFORM POWER-CALC
               WHEN '%'
                   IF WS-RIGHT = 0
                       DISPLAY "Error: modulo by zero"
                       MOVE 1 TO WS-ERROR-FLAG
                   ELSE
                       COMPUTE WS-RESULT =
                           FUNCTION MOD(WS-LEFT, WS-RIGHT)
                   END-IF
               WHEN OTHER
                   DISPLAY "Error: unknown operator " WS-OPERATOR
                   MOVE 1 TO WS-ERROR-FLAG
           END-EVALUATE.

       POWER-CALC.
           MOVE 1 TO WS-POWER-RESULT
           MOVE WS-LEFT TO WS-POWER-BASE
           MOVE WS-RIGHT TO WS-POWER-COUNT
           IF WS-POWER-COUNT = 0
               MOVE 1 TO WS-RESULT
           ELSE
               PERFORM VARYING WS-POWER-IDX FROM 1 BY 1
                   UNTIL WS-POWER-IDX > WS-POWER-COUNT
                   COMPUTE WS-POWER-RESULT =
                       WS-POWER-RESULT * WS-POWER-BASE
               END-PERFORM
               MOVE WS-POWER-RESULT TO WS-RESULT
           END-IF.

       DISPLAY-RESULT.
           MOVE WS-RESULT TO WS-DISPLAY-RESULT
           COMPUTE WS-FRAC =
               FUNCTION MOD(
                   FUNCTION ABS(WS-RESULT) * 10000, 10000)
           IF WS-FRAC = 0
               MOVE WS-RESULT TO WS-INT-RESULT
               DISPLAY FUNCTION TRIM(WS-INT-RESULT)
           ELSE
               DISPLAY FUNCTION TRIM(WS-DISPLAY-RESULT)
           END-IF.
