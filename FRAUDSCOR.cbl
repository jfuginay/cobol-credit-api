       IDENTIFICATION DIVISION.
       PROGRAM-ID. FRAUDSCOR.
       AUTHOR. ATM-FRAUD-DETECTION-SYSTEM.
       DATE-WRITTEN. 2025-07-23.
       
      *****************************************************************
      * Real-time fraud scoring for ATM transactions                 *
      * Replaces batch fraud detection with instant scoring          *
      *****************************************************************
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FRAUD-PATTERNS ASSIGN TO "FRAUDPAT.DAT"
               ORGANIZATION IS INDEXED
               ACCESS IS RANDOM
               RECORD KEY IS FP-PATTERN-ID.
               
       DATA DIVISION.
       FILE SECTION.
       FD  FRAUD-PATTERNS.
       01  FRAUD-PATTERN-RECORD.
           05  FP-PATTERN-ID        PIC X(10).
           05  FP-DESCRIPTION       PIC X(50).
           05  FP-WEIGHT           PIC 999.
           05  FP-THRESHOLD        PIC 999.
           
       WORKING-STORAGE SECTION.
       01  WS-TRANSACTION-DATA.
           05  WS-CARD-NUMBER      PIC X(16).
           05  WS-AMOUNT           PIC 9(7)V99.
           05  WS-ATM-ID           PIC X(10).
           05  WS-GEO-CODE         PIC X(20).
           05  WS-TRANS-TIME       PIC X(8).
           
       01  WS-FRAUD-SCORE.
           05  WS-TOTAL-SCORE      PIC 999 VALUE ZERO.
           05  WS-VELOCITY-SCORE   PIC 999 VALUE ZERO.
           05  WS-LOCATION-SCORE   PIC 999 VALUE ZERO.
           05  WS-AMOUNT-SCORE     PIC 999 VALUE ZERO.
           05  WS-TIME-SCORE       PIC 999 VALUE ZERO.
           
       01  WS-RISK-FACTORS.
           05  WS-HIGH-AMOUNT      PIC X VALUE 'N'.
           05  WS-UNUSUAL-LOC      PIC X VALUE 'N'.
           05  WS-VELOCITY-FLAG    PIC X VALUE 'N'.
           05  WS-ODD-HOURS        PIC X VALUE 'N'.
           
       01  WS-DECISION           PIC X(10).
       01  WS-REASON-COUNT       PIC 9 VALUE ZERO.
       01  WS-REASONS            OCCURS 5 TIMES PIC X(50).
       
       LINKAGE SECTION.
       01  LS-INPUT-PARAMS.
           05  LS-CARD-NUMBER      PIC X(16).
           05  LS-AMOUNT           PIC 9(7)V99.
           05  LS-ATM-ID           PIC X(10).
           05  LS-GEO-CODE         PIC X(20).
           
       01  LS-OUTPUT-RESULTS.
           05  LS-FRAUD-SCORE      PIC 999.
           05  LS-DECISION         PIC X(10).
           05  LS-REASON-COUNT     PIC 9.
           05  LS-REASONS          OCCURS 5 TIMES PIC X(50).
           
       PROCEDURE DIVISION USING LS-INPUT-PARAMS LS-OUTPUT-RESULTS.
       
       MAIN-PROCESS.
           PERFORM INITIALIZE-DATA
           PERFORM CHECK-AMOUNT-RISK
           PERFORM CHECK-VELOCITY-RISK
           PERFORM CHECK-LOCATION-RISK
           PERFORM CHECK-TIME-RISK
           PERFORM CALCULATE-TOTAL-SCORE
           PERFORM DETERMINE-DECISION
           PERFORM PREPARE-OUTPUT
           GOBACK.
           
       INITIALIZE-DATA.
           MOVE LS-CARD-NUMBER TO WS-CARD-NUMBER
           MOVE LS-AMOUNT TO WS-AMOUNT
           MOVE LS-ATM-ID TO WS-ATM-ID
           MOVE LS-GEO-CODE TO WS-GEO-CODE
           ACCEPT WS-TRANS-TIME FROM TIME.
           
       CHECK-AMOUNT-RISK.
           IF WS-AMOUNT > 500.00
               MOVE 'Y' TO WS-HIGH-AMOUNT
               ADD 30 TO WS-AMOUNT-SCORE
               ADD 1 TO WS-REASON-COUNT
               MOVE "High amount transaction" 
                   TO WS-REASONS(WS-REASON-COUNT)
           END-IF
           
           IF WS-AMOUNT > 1000.00
               ADD 40 TO WS-AMOUNT-SCORE
               ADD 1 TO WS-REASON-COUNT
               MOVE "Very high amount over $1000" 
                   TO WS-REASONS(WS-REASON-COUNT)
           END-IF.
           
       CHECK-VELOCITY-RISK.
      *    In production, would check against transaction history
      *    For demo, simulate velocity check
           IF WS-ATM-ID(1:3) = "ATM"
               ADD 20 TO WS-VELOCITY-SCORE
           END-IF.
           
       CHECK-LOCATION-RISK.
      *    Check if location is unusual for this card
      *    For demo, check if GEO code indicates high-risk area
           IF WS-GEO-CODE(1:4) = "RISK"
               MOVE 'Y' TO WS-UNUSUAL-LOC
               ADD 35 TO WS-LOCATION-SCORE
               ADD 1 TO WS-REASON-COUNT
               MOVE "Transaction in high-risk location" 
                   TO WS-REASONS(WS-REASON-COUNT)
           END-IF.
           
       CHECK-TIME-RISK.
      *    Check if transaction at unusual hours
           IF WS-TRANS-TIME(1:2) < "06" OR WS-TRANS-TIME(1:2) > "23"
               MOVE 'Y' TO WS-ODD-HOURS
               ADD 15 TO WS-TIME-SCORE
               ADD 1 TO WS-REASON-COUNT
               MOVE "Transaction during unusual hours" 
                   TO WS-REASONS(WS-REASON-COUNT)
           END-IF.
           
       CALCULATE-TOTAL-SCORE.
           COMPUTE WS-TOTAL-SCORE = WS-AMOUNT-SCORE + 
                                    WS-VELOCITY-SCORE +
                                    WS-LOCATION-SCORE +
                                    WS-TIME-SCORE.
                                    
           IF WS-TOTAL-SCORE > 100
               MOVE 100 TO WS-TOTAL-SCORE
           END-IF.
           
       DETERMINE-DECISION.
           EVALUATE TRUE
               WHEN WS-TOTAL-SCORE > 80
                   MOVE "DENY" TO WS-DECISION
               WHEN WS-TOTAL-SCORE > 60
                   MOVE "CHALLENGE" TO WS-DECISION
               WHEN OTHER
                   MOVE "ALLOW" TO WS-DECISION
           END-EVALUATE.
           
       PREPARE-OUTPUT.
           MOVE WS-TOTAL-SCORE TO LS-FRAUD-SCORE
           MOVE WS-DECISION TO LS-DECISION
           MOVE WS-REASON-COUNT TO LS-REASON-COUNT
           PERFORM VARYING WS-REASON-COUNT FROM 1 BY 1
               UNTIL WS-REASON-COUNT > LS-REASON-COUNT
               MOVE WS-REASONS(WS-REASON-COUNT) 
                   TO LS-REASONS(WS-REASON-COUNT)
           END-PERFORM.