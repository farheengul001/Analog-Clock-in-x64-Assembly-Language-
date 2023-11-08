;---------------------------------------------------------------------------------------------------------------------
;					Microprocessor Systems
;
;					Assignment # 1
;
;				     GRAPHICAL ANALOG CLOCK
;---------------------------------------------------------------------------------------------------------------------
;		NAME				REGISTRATION NUMBER		CLASS: BEE 11-B
;		
;		Ch. Muhammad Shaheer Yasir	286021
;		
;		Muhammad Hamza			290951
;
;		Shehroze Amir			283937
;
;		Farheen Gul			290352
;----------------------------------------------------------------------------------------------------------------------
;
;TOOLS USED : TASM,	DOSBOX
;
;INTERRUPTS USED:	INT 10H			FOR GRAPHICS
;			INT 21H			FOR WRITING CHARACTERS
;			INT 16H			FOR KEYBOARD STROKES
;			INT 15H			FOR GIVING TIME DELAY
;
;-----------------------------------------------------------------------------------------------------------------------
;PROCEDURES:		MAIN 
;			KEYBOARDINTERRUPT
;			POSITION
;			COS
;			SIN
;			MODAMINUSB			; |A-B|
;			PRINTPIXEL
;			CLOCKSTRUCTURE
;			HOURLINE1
;			HOURLINE2
;			MINUTELINE
;			CLOCKDIAL
;			PRINTPOINT
;			PRINTPOINT2
;			TIME
;			FINDTHETA1
;			PLACESECONDHAND
;			FINDTHETA2
;			PLACEMINUTEHAND
;			FINDTHETA3
;			PLACEHOURHAND
;			CLRSCR
;			SETSCREENBACKGROUND
;-------------------------------------------------------------------------------------------------------------------------
;							BEGINNING OF PROGRAM
;-------------------------------------------------------------------------------------------------------------------------

.MODEL SMALL			
.STACK 100H			


;--------------------------------------------------------------------------------------------------------------------------
;						ALL VARIABLES WILL BE DEFINED HERE
.data

	SIN_X		DW		?

	SIN_XX		DW		?

	S		DB		?

	X		DW		?

	Y		DW		?

	X_CENTER	DW		300

	Y_CENTER	DW		250

	RADIUS		DW		200

	SAVEMODE	DB		?

	SI2		DB		?

	MIN		DB		?

	SEC		DB		?

	HOUR		DB		?

	THETA1		DW		?

	THETA2		DW		?

	THETA3		DW		?

	i		DW		1

	COLOR		=		0100B
	
	COLOR_SELECTION_PORT   =        3C9H
	
	VIDEO_PALLETE_PORT    =         3C8H

	PALLETE_INDEX_BACKGROUND   =    0
;						END OF DATA SEGMENT
;-----------------------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------------------
;						START OF CODE SEGMENT
.code
;------------------------------------------------------------------------------------------------------------------------------------
;	MAIN:			MAIN PROCEDURE OF THE PROGRAM
;	RECEIVES:		NOTHING
;	RETURNS			NOTHING
;	REQUIRES		NOTHING
;-------------------------------------------------------------------------------------------------------------------------------------
MAIN PROC
;						INTITIALIZING DS AS HEAP MEMORY TO ACCESS
	MOV AX,@DATA
	MOV DS,AX

;						SAVING THE CURRENT VIDEO MODE
	MOV AH,0FH
	INT 10H
	MOV SAVEMODE,AL

;						SWITCHING TO A GRAPHICS MODE 640 X 480 PIXELS WITH 2 COLORS
	MOV AH,0
	MOV AL,11H
	INT 10H		

;						STARING MAINLOOP WHICH WILL RUN INIFINETLY UNTIL ESC KEY IS PRESSED
	MAINLOOP:

;						SETTING CENTER POINT OF THE CLOCK AND THEN CALLING PROCEDURES SEQUENTIALLY TO DRAW THE CLOCK
		MOV DX,X_CENTER
		MOV CX,Y_CENTER

		CALL PRINTPOINT2
		
		CALL CLOCKSTRUCTURE

		CALL CLOCKDIAL

		CALL TIME

		CALL FINDTHETA1

		CALL PLACESECONDHAND

		CALL FINDTHETA2

		CALL PLACEMINUTEHAND

		CALL FINDTHETA3

		CALL PLACEHOURHAND

		CALL SETSCREENBACKGROUND

		MOV CX,0FH
		MOV DX,4240H
		MOV AH,86H
		INT 15H

		CALL CLRSCR

		CALL KEYBOARDINTERRUPT

	LOOP MAINLOOP

;						WAITING FOR KEYBOARD STROKE
	MOV AH,0
	INT 16H

;						SWTTCHING BACK TO NORMAL MODE
	MOV AH,0
	MOV AL,SAVEMODE
	INT 10H

;						QUIT LABEL WILL TERMINATE THE PROGRAM
	QUIT:
		MOV AH,4CH
		INT 21H
MAIN ENDP
;						END OF MAIN PROCEDURE
;-----------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------
;	KEYBOARDINTERRUPT:		IT WILL WAIT FOR ESC KEY. IF NO KEY OR ANY OTHER KEY IS PRESSED, IT WON'T AFFECT THE PROGRAM. WHEN ESC KEY IS PRESSED IT WILL QUIT THE PROGRAM
;	RECEIVES:			NOTHING
;	RETURNS:			JUMP TO QUIT LABEL IF ESC KEY IS PRESSED
;	REQUIRES:			SHOULD BE PLACED IN AN INFINITE LOOP
;------------------------------------------------------------------------------------------------------------------------

KEYBOARDINTERRUPT PROC

	PUSH AX

;					LOOP L1 WILL RUN IF A KEY IS PRESSED
	L1:
;					CHECKING FOR A KEYSTROKE
		MOV AH,11H
		INT 16H
;					IF NO KEY IS PRESSED, RETURN TO MAIN PROC
		JZ NOKEY
		MOV AH,10H
		INT 16H
;					COMPARING KEY PRESSED WITH 1 (ESC KEY)
		CMP AH,1
;					IF ESC KEY IS PRESSED, QUIT THE PROGRAM
		JE QUIT
		JMP L1

	NOKEY:
		OR AL,1
	POP AX
	RET

KEYBOARDINTERRUPT ENDP
;					END OF KEYBOARD INTERRUPT
;----------------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------------------------
;	POSITION:			IT WILL CALCULATE X AND Y COORDINATES BASED ON THETA, RADIUS, X AND Y CENTERS
;	RECEIVES:			DX: X_CENTER, CX:Y_CENTER, BX: RADIUS, AX: ANGLE
;	RETURNS:			X: X-COORDINATE,	Y: Y-COORDINATE			
;	REQUIRES:			DX,CX,BX AND AX SHOULD BE SET WITH APPROPRIATE VALUES
;-----------------------------------------------------------------------------------------------------------------------------

POSITION PROC

	PUSH DX
	PUSH AX
	PUSH CX
;					CALCULATING SIN OF ANGLE
	CALL SIN
;					CALCULATING Y COORDINATE USING FORUMULA	 Y = R SIN (THETA)
	MOV DX,0
	MOV CX,BX
	MUL CX
	MOV CX,10000
	DIV CX
	POP CX
;					IF ANGLE IS BETWEEN 0 AND 180, IT WILL ADD CENTERS TO X COORDINATE
;					IF ANGLE IS BETWEEN 180 AND 360, IT WILL SUBTRACT CENTERS FROM X COORDINATE
;					SI2 IS 1 WHEN ANGLE IS IN LOWER HALF AND 0 WHEN ANGLE IS IN UPPER HALF
	CMP SI2,1
	JE P1

	ADD AX,CX
	JMP P2
	
	P1:
		SUB CX,AX
		MOV AX,CX
	P2:
		MOV Y,AX
		POP AX
;					CALCULATING COS OF ANGLE AND DOING THE SAME PROCEDURE AS EXPLAINED ABOVE

	CALL COS
	
	MOV DX,0
	MOV CX,BX
;					X = R COS (THETA)
	MUL CX
	MOV CX,10000
	DIV CX

	CMP SI2,1
	JE P3

	ADD AX,X_CENTER
	JMP P4

	P3:
		MOV CX,X_CENTER
		SUB CX,AX
		MOV AX,CX

	P4:
		MOV X,AX
		POP DX
	RET
POSITION ENDP					
;					END OF POSITION PROCEDURE
;------------------------------------------------------------------------------------------------------------------------------------

;------------------------------------------------------------------------------------------------------------------------------------
;	COS:				CALCULATE COSINE OF THE ANGLE
;	RECEIVES:			AX: ANGLE 
;	RETURNS:			AX: COS (ANGLE) * 10000
;	REQUIRES:			ANGLE TO BE SET IN AX
;-------------------------------------------------------------------------------------------------------------------------------------

COS PROC
;					COSINE OF ANY ANGLE IS SAME AS SINE OF (ANGLE + 90). WE WILL USE THIS TECHNIQUE TO COMPUTE COSINE.
	ADD AX,90
	CALL SIN
	RET

COS ENDP	
;					END OF COS PROCEDURE
;-------------------------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------------------
;	SIN:				CALCULATE SIN OF THE ANGLE
;	RECEIVES:			AX: ANGLE
;	RETURNS:			AX: SIN (ANGLE) * 10000
;	REQUIRES:			ANGLE TO BE SET IN AX
;-------------------------------------------------------------------------------------------------------------------------------------

SIN PROC

PUSH CX
PUSH DX
PUSH BX

;					TO COMPUTE SIN OF ANY ANGLE, WE HAVE USED A MATHEMATICAL TECHNIQUE. WE SAW THIS TECHNIQUE ON INTERNET AND USED
;					IT AS IT IS.

SINSTART:
	
	CMP AX,90
	JA ANGLEABOVE90

ANGLE_0_TO_90:
;					IF THE ANGLE IS IN UPPER HALF PLANE I.E ANGLE FROM 0 TO 180 WE WILL SET SI2 AS 0
	MOV SI2,0
	JMP CALCULATE

ANGLEABOVE90:

	CMP AX,180
	JBE ANGLE_91_TO_180
	JMP ANGLEABOVE180

ANGLE_91_TO_180:
;					IF THE ANGLE IS BETWEEN 91 TO 180, WE WILL SUBTRACT IT FROM 180 AND THEN CALCULATE IT.
	MOV CX,180
	SUB CX,AX
	MOV AX,CX
	MOV SI2,0
	JMP CALCULATE

ANGLEABOVE180:

	CMP AX,270
	JBE ANGLE_181_TO_270
	JMP ANGLE_271_TO_360

ANGLE_181_TO_270:
;					IF THE ANGLE IS BETWEEN 181 TO 270, WE WIL SUBTRACT 180 FROM IT. WE WILL SET SI2 TO 1 IF THE ANGLE IS IN LOWER HALF PLANE.
	SUB AX,180
	MOV SI2,1
	JMP CALCULATE

ANGLE_271_TO_360:
	
	CMP AX,359
	JA ANGLEABOVE359
	MOV CX,360
	SUB CX,AX
	MOV AX,CX
	MOV SI2,1
	JMP CALCULATE

ANGLEABOVE359:
;					USING THE PROPERTY OF SIN THAT THEY ARE PERIODIC WITH TIME PERIOD 2 * PI. THUS ANGLE ABOVE 360 WILL BE SAME.
	SUB AX,360
	JMP SINSTART

CALCULATE:
	
;					HERE WE HAVE CALCULATED THE SIN OF ANY ANGLE
	MOV CX,175
	XOR DX,DX
;					SIN_X = ANGLE * 175
	MUL CX
	MOV SIN_X,AX
;					SIN_XX= (SIN_X * SIN_X)/10000
	XOR DX,DX
	MOV CX,AX
	MUL CX
	MOV CX,10000
	DIV CX
	MOV SIN_XX,AX

	XOR DX,DX
	MOV CX,120
	DIV CX

	MOV BX,1677
	CALL MODAMINUSB
	
	MOV CX,SIN_XX
	XOR DX,DX
	MUL CX
	MOV CX,10000
	DIV CX

	MOV CX,10000
	MOV DL,0
	CMP DL,S
	JE C1

	SUB CX,AX
	MOV AX,CX
	JMP C2

	C1:
		ADD AX,CX

	C2:
		MOV CX,SIN_X
		XOR DX,DX
		MUL CX
		MOV CX,10000
		DIV CX

	POP BX
	POP DX
	POP CX

	MOV S,0
	RET

SIN ENDP
;						END OF SIN PROCEDURE
;--------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------
;	MODAMINUSB:				CALCULATE DIFFERENCE BETWEEN A AND B |A - B|
;	RECEIVES:				AX, BX
;	RETURNS:				|AX - BX|
;	REQUIRES:				NOTHING
;---------------------------------------------------------------------------------------------------------------

MODAMINUSB PROC
;						COMPUTE A - B IF A IS GREATER ELSE COMPUTE B - A
	CMP AX,BX
	JAE AMINUSB
	
	XOR S,1
	XCHG AX,BX

	AMINUSB:
		SUB AX,BX
	RET

MODAMINUSB ENDP
;						END OF MODAMINUSB PROCEDURE
;-----------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------
;	PRINTPIXEL:				PRINT ONE PIXEL AT GIVEN COORDINATES
;	RECEIVES:				DX: Y-COORDINATE, CX:X-COORDINATE
;	RETURNS:				NOTHING
;	REQUIRES:				NOTHING
;------------------------------------------------------------------------------------------------------------------

PRINTPIXEL PROC
;						PRINTING A PIXEL OF COLOR WHITE ON VIDEOPAGE 0
	MOV AH,0CH
	MOV AL,1
	MOV BH,0
	INT 10H
	RET
PRINTPIXEL ENDP
;						END OF PRINTPIXEL PROCEDURE
;-------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------
;	CLOCKSTRUCTURE:				DRAWS THE OUTER STRUCTURE OF THE CLOCK
;	RECEIVES:				NOTHING
;	RETURNS:				NOTHING
;	REQUIRES:				PROGRAM SHOULD BE SET IN GRAPHICS MODE
;-------------------------------------------------------------------------------------------------------------------

CLOCKSTRUCTURE PROC
;						DRAWING MINUTE LINES AND HOUR LINES
	CALL HOURLINE1
	CALL HOURLINE2
	CALL MINUTELINE
;						CREATING A LOOP 360 TIMES WHICH INCREMENT THE ANGLE AND PRINT PIXEL
	MOV CX,360
	MOV AX,0

	STRUCT:
		PUSH CX
		MOV BX,RADIUS
		MOV CX,Y_CENTER
		MOV DX,X_CENTER
		
		PUSH AX
		CALL POSITION
		MOV CX,X
		MOV DX,Y
		CALL PRINTPIXEL
		POP AX

		INC AX
		POP CX
	LOOP STRUCT
	RET
		
CLOCKSTRUCTURE ENDP
;						END OF CLOCKSTRUCTURE PROCEDURE
;------------------------------------------------------------------------------------------------------------------------

;------------------------------------------------------------------------------------------------------------------------
;	HOURLINE1:				PRINTS HOUR LINES 
;	RECEIVES:				NOTHING
;	RETURNS:				NOTHING
;	REQUIRES:				NOTHING
;------------------------------------------------------------------------------------------------------------------------

HOURLINE1 PROC
;						IT LOOP 12 TIMES TO CREATE EACH HOURLINE ON CLOCK
	MOV CX,12
	MOV AX,0
	MOV BX,RADIUS
	
	HL1:
		PUSH CX
		PUSH BX
		MOV CX,10
;						THIS LOOP WILL CREATE THE LINE
		HL2:
			PUSH CX
			MOV CX,Y_CENTER
			MOV DX,X_CENTER
			PUSH AX
			CALL POSITION
			MOV CX,X
			MOV DX,Y
			CALL PRINTPIXEL
			POP AX
			POP CX
			SUB BX,1
		LOOP HL2
		ADD AX,30
		POP BX
		POP CX
	LOOP HL1
	RET
	
HOURLINE1 ENDP
;						END OF HOURLINE1 PROC
;------------------------------------------------------------------------------------------------------------------------

;------------------------------------------------------------------------------------------------------------------------
;	HOURLINE2:				PRINTS HOUR LINES WHICH ARE POWER OF 90 DEGREES
;	RECEIVES:				NOTHING
;	RETURNS:				NOTHING
;	REQUIRES:				NOTHING
;------------------------------------------------------------------------------------------------------------------------

HOURLINE2 PROC
;						IT LOOP 4 TIMES TO CREATE 90 DEGREE HOURLINE LARGER ON CLOCK
	MOV CX,4
	MOV AX,0
	MOV BX,RADIUS
	
	HHL1:
		PUSH CX
		PUSH BX
		MOV CX,20
;						THIS LOOP WILL CREATE THE LINE
		HHL2:
			PUSH CX
			MOV CX,Y_CENTER
			MOV DX,X_CENTER
			PUSH AX
			CALL POSITION
			MOV CX,X
			MOV DX,Y
			CALL PRINTPIXEL
			POP AX
			POP CX
			SUB BX,1
		LOOP HHL2
		ADD AX,90
		POP BX
		POP CX
	LOOP HHL1
	RET
	
HOURLINE2 ENDP
;						END OF HOURLINE2 PROC
;------------------------------------------------------------------------------------------------------------------------

;------------------------------------------------------------------------------------------------------------------------
;	MINUTELINE:				PRINTS MINUTE LINES 
;	RECEIVES:				NOTHING
;	RETURNS:				NOTHING
;	REQUIRES:				NOTHING
;------------------------------------------------------------------------------------------------------------------------

MINUTELINE PROC
;						IT WILL LOOP 60 TIMES TO CREATE EACH MINUTE LINE ON CLOCK
	MOV CX,60
	MOV AX,0
	MOV BX,RADIUS
	
	ML1:
		PUSH CX
		PUSH BX
		MOV CX,5
;						THIS LOOP WILL CREATE THE LINE
		ML2:
			PUSH CX
			MOV CX,Y_CENTER
			MOV DX,X_CENTER
			PUSH AX
			CALL POSITION
			MOV CX,X
			MOV DX,Y
			CALL PRINTPIXEL
			POP AX
			POP CX
			SUB BX,1
		LOOP ML2
		ADD AX,6
		POP BX
		POP CX
	LOOP ML1
	RET
	
MINUTELINE ENDP
;						END OF MINUTELINE PROC
;-------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------
;	CLOCKDIAL:				IT WILL DRAW DIAL OF THE CLOCK
;	RECIEVES:				NOTHING
;	RETURNS:				NOTHING
;	REQUIRES:				CLOCKSTRUCTURE SHOULD BE CALLED FIRST
;-------------------------------------------------------------------------------------------------------------

CLOCKDIAL PROC
;						PRINTING 12
	MOV DH,5
	MOV DL,36
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'1'
	INT 21H

	MOV DH,5
	MOV DL,37
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'2'
	INT 21H

;						PRINTING 1
	MOV DH,6
	MOV DL,46
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'1'
	INT 21H

;						PRINTING 2
	MOV DH,10
	MOV DL,55
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'2'
	INT 21H

;						PRINTING 3
	MOV DH,15
	MOV DL,58
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'3'
	INT 21H

;						PRINTING 4
	MOV DH,20
	MOV DL,55
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'4'
	INT 21H

;						PRINTING 5
	MOV DH,24
	MOV DL,47
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'5'
	INT 21H

;						PRINTING 6
	MOV DH,25
	MOV DL,37
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'6'
	INT 21H

;						PRINTING 7
	MOV DH,24
	MOV DL,28
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'7'
	INT 21H

;						PRINTING 8
	MOV DH,20
	MOV DL,19
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'8'
	INT 21H

;						PRINTING 9
	MOV DH,15
	MOV DL,16
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'9'
	INT 21H

;						PRINTING 10
	MOV DH,10
	MOV DL,18
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'1'
	INT 21H

	MOV DH,10
	MOV DL,19
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'0'
	INT 21H

;						PRINTING 11
	MOV DH,6
	MOV DL,25
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'1'
	INT 21H

	MOV DH,6
	MOV DL,26
;						IT WILL POSITION THE CURSOR
	MOV AH,02H
	MOV BH,0
	INT 10H
	
	MOV AH,2
	MOV DL,'1'
	INT 21H

	RET
CLOCKDIAL ENDP
;						END OF CLOCKDIAL PROCEDURE
;-----------------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------------
;	PRINTPOINT:				IT WILL PRINT CONSECUTIVE PIXELS TO MAKE A PIXEL DARK
;	RECIEVES:				CX: X-COORDINATE,	DX: Y-COORDINATE
;	RETURNS:				NOTHING
;	REQUIRES:				PROGRAM SHOULD BE IN GRAPHICS MODE
;-----------------------------------------------------------------------------------------------------------------------------

PRINTPOINT PROC

	PUSH CX
	PUSH DX
	CALL PRINTPIXEL
	
	INC CX
	CALL PRINTPIXEL
	
	SUB CX,2
	CALL PRINTPIXEL

	ADD CX,1
	DEC DX
	CALL PRINTPIXEL
	
	ADD DX,2
	CALL PRINTPIXEL

	POP DX
	POP CX

	RET

PRINTPOINT ENDP
;						END OF PRINTPOINT PROCEDURE
;----------------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------------------------
;	PRINTPOINT2:				IT IS ACTUALLY FOR THE MIDDLE POINT OF CLOCK. IT WILL MAKE MUCH THICKER AND DARKER PIXEL
;	RECIEVES:				NOTHING
;	RETURNS:				NOTHING
;	REQUIRES:				PROGRAM SHOULD BE IN GRAPHICS MODE
;----------------------------------------------------------------------------------------------------------------------------

PRINTPOINT2 PROC

;						USING LOOPS TO CREATE SMALL CIRCLES, THEN INCREASING RADIUS AND LOOPING IT TO MAKE 5 CIRCLES UNTIL THE RADIUS REACHES 6.
	PUSH i
	MOV CX,5
	
	STRUCT3:
		PUSH CX
		MOV CX,360
		MOV AX,0
		
		STRUCT2:
			PUSH CX
			MOV BX,i
			MOV CX,Y_CENTER
			MOV DX,X_CENTER
			PUSH AX
			CALL POSITION
			MOV CX,X
			MOV DX,Y
			CALL PRINTPIXEL
			POP AX
			INC AX
			POP CX
		LOOP STRUCT2
		
		INC i
		POP CX
	LOOP STRUCT3

	POP i
	RET

PRINTPOINT2 ENDP
;  						END OF PRINTPOINT2 PROCEDURE
;-------------------------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------------------------
;	TIME:					CALCULATE SYSTEM TIME
;	RECEIVES:				NOTHING
;	RETURNS:				HOUR: CURRENT HOUR, MIN: CURRENT MINUTE, SEC: CURRENT SECOND
;	REQUIRES:				NOTHING
;---------------------------------------------------------------------------------------------------------------------------------

TIME PROC
;						IT WILL RETURN SYSTEM TIME IN FORMAT CH:CL:DH
	MOV AH,2CH
	INT 21H

	MOV MIN,CL
	MOV SEC,DH
;						IF HOUR IS IN PM THEN ABOVE PROCEDURE WILL RETURN VALUES GREATER THAN 12
;						IT WILL CONVERT THEM BACK TO 1-12 FORMAT
	CMP CH,12
	JA ABOVE12
	JMP BELOW12

	ABOVE12:
		SUB CH,12
		MOV HOUR,CH
		JMP RET4
	
	BELOW12:
		MOV HOUR,CH

	RET4:
		RET

TIME ENDP
;						END OF TIME PROCEDURE
;----------------------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------------------------------
;	FINDTHETA1:				IT WILL CALCULATE ANGLE SECOND HAND IS MAKING WITH POSITIVE X-AXIS (ANGLE WILL BE CLOCKWISE)
;	RECEIVES:				CURRENT SECONDS STORED IN SEC
;	RETURNS:				THETA1
;	REQUIRES:				TIME PROC SHOULD BE CALLED BEFORE CALLING THIS PROCEDURE
;-----------------------------------------------------------------------------------------------------------------------------------

FINDTHETA1 PROC
;						THE LOGIC WHICH IS USED HERE IS THIS: 		IF SEC >= 15, THEN THETA1 = (SEC - 15)*6
;												IF SEC < 15, THEN THETA1 = 270 + (SEC * 6)
	CMP SEC,15
	JB BELOW15S
	JMP ABOVE15S

	BELOW15S:
		MOV THETA1,270
		CMP SEC,60
		JE S60
		JMP NOT60S

		S60:
			JMP RET1
		
		NOT60S:
			MOV AL,SEC
			MOV BL,6
			MUL BL
			ADD THETA1,AX
			JMP RET1
			
	ABOVE15S:
		MOV BL,SEC
		SUB BL,15
		MOV AL,6
		MUL BL
		MOV THETA1,AX
	RET1:
		RET

FINDTHETA1 ENDP
;						END OF FINDTHETA1 PROCEDURE
;-------------------------------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------------------------
;	PLACESECONDHAND:			IT WILL PRINT SECOND HAND ON CLOCK
;	RECEIVES:				THETA1
;	RETURNS:				NOTHING
;	REQUIRES:				FINDTHETA1 SHOULD BE CALLED BEFORE CALLING THIS PROCEDURE
;-------------------------------------------------------------------------------------------------------------------------------------------

PLACESECONDHAND PROC
;						FIRST WE WILL FIND X AND Y COORDINATES WITH THE HELP OF POSTION PROCEDURE AND THEN WE WILL LOOP TO MAKE A LINE FROM THAT POINT TO CENTER
	MOV AX,THETA1
	MOV BX,RADIUS
	SUB BX,50
	MOV CX,BX
	
	S1:
		PUSH CX	
		MOV BX,CX
		MOV CX,Y_CENTER
		MOV DX,X_CENTER
		PUSH AX
		CALL POSITION
		MOV CX,X
		MOV DX,Y
		CALL PRINTPIXEL
		POP AX
		POP CX
	LOOP S1
	RET
	
PLACESECONDHAND ENDP
;						END OF PLACESECONDHAND PROCEDURE
;--------------------------------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------------------------------
;	FINDTHETA2:				IT WILL CALCULATE ANGLE MINUTE HAND IS MAKING WITH POSITIVE X-AXIS (ANGLE WILL BE CLOCKWISE)
;	RECEIVES:				CURRENT MINUTES STORED IN MIN
;	RETURNS:				THETA2
;	REQUIRES:				TIME PROC SHOULD BE CALLED BEFORE CALLING THIS PROCEDURE
;-----------------------------------------------------------------------------------------------------------------------------------

FINDTHETA2 PROC
;						THE LOGIC WHICH IS USED HERE IS THIS: 		IF MIN  >= 15, THEN THETA2 = (MIN - 15)*6
;												IF MIN < 15, THEN THETA2 = 270 + (MIN * 6)
	CMP MIN,15
	JB BELOW15M
	JMP ABOVE15M

	BELOW15M:
		MOV THETA2,270
		CMP MIN,60
		JE M60
		JMP NOT60M

		M60:
			JMP RET2
		
		NOT60M:
			MOV AL,MIN
			MOV BL,6
			MUL BL
			ADD THETA2,AX
			JMP RET2
			
	ABOVE15M:
		MOV BL,MIN
		SUB BL,15
		MOV AL,6
		MUL BL
		MOV THETA2,AX
	RET2:
		RET

FINDTHETA2 ENDP
;						END OF FINDTHETA2 PROCEDURE
;-------------------------------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------------------------
;	PLACEMINUTEHAND:			IT WILL PRINT MINUTE HAND ON CLOCK
;	RECEIVES:				THETA2
;	RETURNS:				NOTHING
;	REQUIRES:				FINDTHETA2 SHOULD BE CALLED BEFORE CALLING THIS PROCEDURE
;-------------------------------------------------------------------------------------------------------------------------------------------

PLACEMINUTEHAND PROC
;						FIRST WE WILL FIND X AND Y COORDINATES WITH THE HELP OF POSTION PROCEDURE AND THEN WE WILL LOOP TO MAKE A LINE FROM THAT POINT TO ORIGIN
	MOV AX,THETA2
	MOV BX,RADIUS
	SUB BX,50
	MOV CX,BX
	
	M1:
		PUSH CX	
		MOV BX,CX
		MOV CX,Y_CENTER
		MOV DX,X_CENTER
		PUSH AX
		CALL POSITION
		MOV CX,X
		MOV DX,Y
		CALL PRINTPOINT
		POP AX
		POP CX
	LOOP M1
	RET
	
PLACEMINUTEHAND ENDP
;						END OF PLACEMINUTEHAND PROCEDURE
;--------------------------------------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------------------------------------
;	FINDTHETA3:				IT WILL FIND THE ANGLE HOUR HAND MAKES WITH POSITIVE X-AXIS (ANGLE WILL BE CLOCKWISE).
;	REQUIRES:				CURRENT HOURS STORED IN HOUR AND CURRENT MINUTES STORED IN MIN
;	RETURNS:				THETA3
;	REQUIRES:				TIME PROCEDURE SHOULD BE CALL BEFORE CALLING THIS PROCEDURE
;--------------------------------------------------------------------------------------------------------------------------------------------

FINDTHETA3 PROC
;						LOGIC OF THIS PROCEDURE IS AS FOLLOWS:		IF HOUR >= 3 THEN THETA3 = (HOUR - 3) * 30
;												IF HOUR < 3 THEN THETA3 = 270 + (HOUR * 30)
;						THEN WE WILL COMPARE CURRENT MIN AND ADD ANGLE ACCORDING TO IT. LOGIC WILL BE AS FOLLOWS:
;						THETA3 = THETA3 + 6 * (MIN / 12)                DIVISION WILL BE INTEGER BASED
	CMP HOUR,3
	JB BELOW3
	JMP ABOVE3

	BELOW3:
		MOV THETA3,270
		MOV AL,HOUR
		MOV BL,30
		MUL BL
		ADD THETA3,AX
		MOV AL,MIN
		XOR AH,AH
		MOV BL,12
		DIV BL
		XOR AH,AH
		MOV BL,6
		MUL BL
		ADD THETA3,AX
		JMP RET3
	
	ABOVE3:
		MOV AL,HOUR
		SUB AL,3
		MOV BL,30
		MUL BL
		MOV THETA3,AX
		MOV AL,MIN
		XOR AH,AH
		MOV BL,12
		DIV BL
		XOR AH,AH
		MOV BL,6
		MUL BL
		ADD THETA3,AX
	
	RET3:
		RET

FINDTHETA3 ENDP
;						END OF FINDTHETA3 PROCEDURE
;--------------------------------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------------------------
;	PLACEHOURHAND:				IT WILL PRINT HOUR HAND ON CLOCK
;	RECEIVES:				THETA3
;	RETURNS:				NOTHING
;	REQUIRES:				FINDTHETA3 SHOULD BE CALLED BEFORE CALLING THIS PROCEDURE
;-------------------------------------------------------------------------------------------------------------------------------------------

PLACEHOURHAND PROC
;						FIRST WE WILL FIND X AND Y COORDINATES WITH THE HELP OF POSTION PROCEDURE AND THEN WE WILL LOOP TO MAKE A LINE FROM THAT POINT TO ORIGIN
	MOV AX,THETA3
	MOV BX,RADIUS
	SUB BX,100
	MOV CX,BX
	
	H1:
		PUSH CX	
		MOV BX,CX
		MOV CX,Y_CENTER
		MOV DX,X_CENTER
		PUSH AX
		CALL POSITION
		MOV CX,X
		MOV DX,Y
		CALL PRINTPOINT
		POP AX
		POP CX
	LOOP H1
	RET
	
PLACEHOURHAND ENDP
;						END OF PLACEHOURHAND PROCEDURE
;--------------------------------------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------------------------------------
;	CLRSCR:					IT WILL CLEAR THE SCREEN
;	RECEIVES:				NOTHING
;	RETURNS:				NOTHING
;	REQUIRES:				NOTHING
;-----------------------------------------------------------------------------------------------------------------------------------------

CLRSCR PROC
;						TO CLEAR SCREEN WE HAVE TO MOVE 0600H IN AX. DL AND DH DENOTES THE UPPER AND LOWER LIMIT WHICH ARE 4040H. THE COLOR IS SET TO 0 IN BH.
	MOV AX,0600H
	MOV CX,0
	MOV DX,4040H
	MOV BH,0
	INT 10H
	MOV AH,2
	MOV BH,0
	MOV DX,0
	INT 10H
	RET

CLRSCR ENDP
;						END OF CLRSCR PROCEDURE
;----------------------------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------------------------------------
;	SETSCREENBACKGROUND:			SET THE SCREEN BACKGROUND COLOR TO DARK BLUE
;	RECEIVES:				VIDEO_PALLETE_PORT, COLOR_SELECTION_PORT AND PALLETE_INDEX_BACKGROUND
;	RETURNS:				NOTHING
;	REQUIRES:				NOTHING
;-----------------------------------------------------------------------------------------------------------------------------------------

SETSCREENBACKGROUND PROC

;						SET COLOR INDEX FOR RGB VALUE
	MOV DX, VIDEO_PALLETE_PORT
	MOV AL, PALLETE_INDEX_BACKGROUND
;						OUT TRANSFERS PALLETE_INDEX_BACKGROUND = 0 FROM .DATA TO DX
	OUT DX,AL
	MOV DX, COLOR_SELECTION_PORT
;						RED
	MOV AL,0
	OUT DX,AL
;						GREEN
	MOV AL,0
	OUT DX,AL
;						BLUE (INTENSITY 15/63)
	MOV AL,15
	OUT DX,AL
	RET
	
SETSCREENBACKGROUND ENDP
END MAIN
;						END OF PROGRAM
;-----------------------------------------------------------------------------------------------------------------------------------------