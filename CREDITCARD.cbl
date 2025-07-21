       IDENTIFICATION DIVISION.
       PROGRAM-ID. CREDITCARD.
       AUTHOR. CREDIT-CARD-SYSTEM.
       DATE-WRITTEN. 2025-07-21.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CARD-FILE ASSIGN TO "CARDDATA.DAT"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT STATEMENT-FILE ASSIGN TO "STATEMENT.TXT"
               ORGANIZATION IS LINE SEQUENTIAL.
               
       DATA DIVISION.
       FILE SECTION.
       FD  CARD-FILE.
       01  CARD-RECORD.
           05  CR-CARD-NUMBER       PIC X(16).
           05  CR-CARDHOLDER-NAME   PIC X(30).
           05  CR-BALANCE           PIC 9(7)V99.
           05  CR-CREDIT-LIMIT      PIC 9(7)V99.
           05  CR-APR               PIC 99V99.
           
       FD  STATEMENT-FILE.
       01  STATEMENT-LINE           PIC X(80).
       
       WORKING-STORAGE SECTION.
       01  WS-CARD-DETAILS.
           05  WS-CARD-NUMBER       PIC X(16).
           05  WS-CARDHOLDER-NAME   PIC X(30).
           05  WS-BALANCE           PIC 9(7)V99.
           05  WS-CREDIT-LIMIT      PIC 9(7)V99.
           05  WS-APR               PIC 99V99.
           
       01  WS-VALIDATION-FIELDS.
           05  WS-CARD-VALID        PIC X VALUE 'N'.
           05  WS-DIGIT             PIC 9.
           05  WS-SUM               PIC 999 VALUE ZERO.
           05  WS-CHECK-DIGIT       PIC 9.
           05  WS-DOUBLE-DIGIT      PIC 99.
           05  WS-POSITION          PIC 99.
           05  WS-DIGIT-COUNT       PIC 99.
           
       01  WS-INTEREST-FIELDS.
           05  WS-MONTHLY-RATE      PIC 9V9999.
           05  WS-INTEREST-CHARGE   PIC 9(5)V99.
           05  WS-NEW-BALANCE       PIC 9(7)V99.
           
       01  WS-DISPLAY-FIELDS.
           05  WS-DISPLAY-BALANCE   PIC Z,ZZZ,ZZ9.99.
           05  WS-DISPLAY-LIMIT     PIC Z,ZZZ,ZZ9.99.
           05  WS-DISPLAY-INTEREST  PIC ZZ,ZZ9.99.
           05  WS-DISPLAY-APR       PIC Z9.99.
           
       01  WS-DATE-TIME.
           05  WS-CURRENT-DATE.
               10  WS-YEAR          PIC 9(4).
               10  WS-MONTH         PIC 99.
               10  WS-DAY           PIC 99.
           05  WS-CURRENT-TIME.
               10  WS-HOUR          PIC 99.
               10  WS-MINUTE        PIC 99.
               
       01  WS-EOF                   PIC X VALUE 'N'.
       01  WS-MENU-CHOICE           PIC 9 VALUE ZERO.
       01  WS-CONTINUE              PIC X VALUE 'Y'.
       
       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           PERFORM DISPLAY-MENU UNTIL WS-CONTINUE = 'N'
           STOP RUN.
           
       DISPLAY-MENU.
           DISPLAY " "
           DISPLAY "CREDIT CARD MANAGEMENT SYSTEM"
           DISPLAY "============================="
           DISPLAY "1. Validate Credit Card Number"
           DISPLAY "2. Calculate Interest"
           DISPLAY "3. Generate Statement"
           DISPLAY "4. Display All Cards"
           DISPLAY "5. Exit"
           DISPLAY " "
           DISPLAY "Enter your choice: " WITH NO ADVANCING
           ACCEPT WS-MENU-CHOICE
           
           EVALUATE WS-MENU-CHOICE
               WHEN 1
                   PERFORM VALIDATE-CARD-NUMBER
               WHEN 2
                   PERFORM CALCULATE-INTEREST
               WHEN 3
                   PERFORM GENERATE-STATEMENT
               WHEN 4
                   PERFORM DISPLAY-ALL-CARDS
               WHEN 5
                   MOVE 'N' TO WS-CONTINUE
               WHEN OTHER
                   DISPLAY "Invalid choice. Please try again."
           END-EVALUATE.
           
       VALIDATE-CARD-NUMBER.
           DISPLAY " "
           DISPLAY "Enter credit card number: " WITH NO ADVANCING
           ACCEPT WS-CARD-NUMBER
           
           PERFORM LUHN-ALGORITHM
           
           IF WS-CARD-VALID = 'Y'
               DISPLAY "Card number is VALID"
           ELSE
               DISPLAY "Card number is INVALID"
           END-IF.
           
       LUHN-ALGORITHM.
           MOVE 'N' TO WS-CARD-VALID
           MOVE ZERO TO WS-SUM
           MOVE ZERO TO WS-DIGIT-COUNT
           
           PERFORM VARYING WS-POSITION FROM 16 BY -1 UNTIL WS-POSITION < 1
               IF WS-CARD-NUMBER(WS-POSITION:1) IS NUMERIC
                   ADD 1 TO WS-DIGIT-COUNT
                   MOVE WS-CARD-NUMBER(WS-POSITION:1) TO WS-DIGIT
                   
                   IF FUNCTION MOD(WS-DIGIT-COUNT, 2) = 0
                       COMPUTE WS-DOUBLE-DIGIT = WS-DIGIT * 2
                       IF WS-DOUBLE-DIGIT > 9
                           COMPUTE WS-DOUBLE-DIGIT = 
                               WS-DOUBLE-DIGIT - 9
                       END-IF
                       ADD WS-DOUBLE-DIGIT TO WS-SUM
                   ELSE
                       ADD WS-DIGIT TO WS-SUM
                   END-IF
               END-IF
           END-PERFORM
           
           IF FUNCTION MOD(WS-SUM, 10) = 0 AND WS-DIGIT-COUNT = 16
               MOVE 'Y' TO WS-CARD-VALID
           END-IF.
           
       CALCULATE-INTEREST.
           DISPLAY " "
           DISPLAY "Enter card number: " WITH NO ADVANCING
           ACCEPT WS-CARD-NUMBER
           
           PERFORM READ-CARD-DATA
           
           IF WS-EOF = 'N'
               COMPUTE WS-MONTHLY-RATE = WS-APR / 100 / 12
               COMPUTE WS-INTEREST-CHARGE = 
                   WS-BALANCE * WS-MONTHLY-RATE
               COMPUTE WS-NEW-BALANCE = 
                   WS-BALANCE + WS-INTEREST-CHARGE
                   
               MOVE WS-BALANCE TO WS-DISPLAY-BALANCE
               MOVE WS-INTEREST-CHARGE TO WS-DISPLAY-INTEREST
               MOVE WS-NEW-BALANCE TO WS-DISPLAY-BALANCE
               MOVE WS-APR TO WS-DISPLAY-APR
               
               DISPLAY " "
               DISPLAY "Current Balance: $" WS-DISPLAY-BALANCE
               DISPLAY "APR: " WS-DISPLAY-APR "%"
               DISPLAY "Interest Charge: $" WS-DISPLAY-INTEREST
               DISPLAY "New Balance: $" WS-DISPLAY-BALANCE
           ELSE
               DISPLAY "Card not found in database"
           END-IF.
           
       GENERATE-STATEMENT.
           DISPLAY " "
           DISPLAY "Enter card number: " WITH NO ADVANCING
           ACCEPT WS-CARD-NUMBER
           
           PERFORM READ-CARD-DATA
           
           IF WS-EOF = 'N'
               OPEN OUTPUT STATEMENT-FILE
               
               MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE
               
               MOVE SPACES TO STATEMENT-LINE
               STRING "CREDIT CARD STATEMENT" 
                   DELIMITED BY SIZE INTO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               MOVE ALL "=" TO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               MOVE SPACES TO STATEMENT-LINE
               STRING "Statement Date: " WS-MONTH "/" WS-DAY "/" 
                   WS-YEAR DELIMITED BY SIZE INTO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               MOVE SPACES TO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               MOVE SPACES TO STATEMENT-LINE
               STRING "Card Number: " WS-CARD-NUMBER(1:4) 
                   "-****-****-" WS-CARD-NUMBER(13:4)
                   DELIMITED BY SIZE INTO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               MOVE SPACES TO STATEMENT-LINE
               STRING "Cardholder: " WS-CARDHOLDER-NAME
                   DELIMITED BY SIZE INTO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               MOVE SPACES TO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               MOVE WS-BALANCE TO WS-DISPLAY-BALANCE
               MOVE WS-CREDIT-LIMIT TO WS-DISPLAY-LIMIT
               
               MOVE SPACES TO STATEMENT-LINE
               STRING "Current Balance: $" WS-DISPLAY-BALANCE
                   DELIMITED BY SIZE INTO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               MOVE SPACES TO STATEMENT-LINE
               STRING "Credit Limit: $" WS-DISPLAY-LIMIT
                   DELIMITED BY SIZE INTO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               COMPUTE WS-MONTHLY-RATE = WS-APR / 100 / 12
               COMPUTE WS-INTEREST-CHARGE = 
                   WS-BALANCE * WS-MONTHLY-RATE
               MOVE WS-INTEREST-CHARGE TO WS-DISPLAY-INTEREST
               
               MOVE SPACES TO STATEMENT-LINE
               STRING "Interest This Period: $" WS-DISPLAY-INTEREST
                   DELIMITED BY SIZE INTO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               COMPUTE WS-NEW-BALANCE = 
                   WS-BALANCE + WS-INTEREST-CHARGE
               MOVE WS-NEW-BALANCE TO WS-DISPLAY-BALANCE
               
               MOVE SPACES TO STATEMENT-LINE
               STRING "New Balance: $" WS-DISPLAY-BALANCE
                   DELIMITED BY SIZE INTO STATEMENT-LINE
               WRITE STATEMENT-LINE
               
               CLOSE STATEMENT-FILE
               DISPLAY "Statement generated successfully!"
           ELSE
               DISPLAY "Card not found in database"
           END-IF.
           
       READ-CARD-DATA.
           MOVE 'Y' TO WS-EOF
           OPEN INPUT CARD-FILE
           
           PERFORM UNTIL WS-EOF = 'Y'
               READ CARD-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       IF CR-CARD-NUMBER = WS-CARD-NUMBER
                           MOVE CR-CARD-NUMBER TO WS-CARD-NUMBER
                           MOVE CR-CARDHOLDER-NAME TO 
                               WS-CARDHOLDER-NAME
                           MOVE CR-BALANCE TO WS-BALANCE
                           MOVE CR-CREDIT-LIMIT TO WS-CREDIT-LIMIT
                           MOVE CR-APR TO WS-APR
                           MOVE 'N' TO WS-EOF
                           EXIT PERFORM
                       END-IF
               END-READ
           END-PERFORM
           
           CLOSE CARD-FILE.
           
       DISPLAY-ALL-CARDS.
           DISPLAY " "
           DISPLAY "ALL CREDIT CARDS IN SYSTEM"
           DISPLAY "=========================="
           
           OPEN INPUT CARD-FILE
           MOVE 'N' TO WS-EOF
           
           PERFORM UNTIL WS-EOF = 'Y'
               READ CARD-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       MOVE CR-BALANCE TO WS-DISPLAY-BALANCE
                       MOVE CR-CREDIT-LIMIT TO WS-DISPLAY-LIMIT
                       
                       DISPLAY "Card: " CR-CARD-NUMBER(1:4) 
                           "-****-****-" CR-CARD-NUMBER(13:4)
                           " Name: " CR-CARDHOLDER-NAME
                           " Balance: $" WS-DISPLAY-BALANCE
               END-READ
           END-PERFORM
           
           CLOSE CARD-FILE.