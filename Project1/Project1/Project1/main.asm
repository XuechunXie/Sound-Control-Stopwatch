;-----------------------------------------------------------------------------
; Assembly main line
;-----------------------------------------------------------------------------

include "m8c.inc"       ; part specific constants and macros
include "memory.inc"    ; Constants & macros for SMM/LMM and Compiler
include "PSoCAPI.inc"   ; PSoC API definitions for all User Modules


export _main
export _COUNTING_INCREMENT
export _inc_press_interuptNo

BUTTON_MSK: EQU 80h ;use port2 pin7 as the input of button press, 80h=10000000
CRT_STATE: EQU 80h   ;current State                                                                                            
PRESS_INTERUPTNO: EQU B5h
LED_MSK: EQU 01h
;use to store x times stopwatch result
SET_HOUR: EQU 81h  
SET_MINUTE:	EQU 8Ah
SET_SEC: EQU 93h	
SET_MS:	EQU 9Ch
MS_COUNT: EQU A5h
;used to store the min,max,sum of x stopwatch results
TEMP_MIN_HOUR: EQU A6h 
TEMP_MIN_MINUTE: EQU A7h
TEMP_MIN_SEC: EQU A8h
TEMP_MAX_HOUR: EQU A9h
TEMP_MAX_MINUTE: EQU AAh
TEMP_MAX_SEC: EQU ABh
TEMP_SUM_HOUR: EQU ACh
TEMP_SUM_MINUTE: EQU ADh
TEMP_SUM_SEC: EQU AEh
TIMING_TIMES: EQU AFh
;division parameters
remainder:	EQU B0h
dividend: EQU B1h
divisor:	EQU B2h
temp:	EQU B3h
lcount: EQU B4h



.LITERAL
Longest:
	DS "Longest Time:"
	DB 00h
Avg:
	DS "Average Time:"
	DB 00h				 			; String should always be null terminated							
Shortest:
	DS "Shortest Time:"
	DB 00h 							
IDLE:
	DS "Idle"
	DB 00h 								
SENSE_MODE:
	DS "Sensitivity Mode"
	DB 00h 
ACCRUARY_MODE:
	DS "Accuracy Mode"
	DB 00h 
MEASURE_MODE:
	DS "Measurement Mode"
	DB 00h 
MEMORY_MODE:
	DS "Memory Mode"
	DB 00h 

DIGITS: DS "0123456789:."

.ENDLITERAL


;-----------------------------------------------
;  Main Function
;-----------------------------------------------
_main:	
	mov [CRT_STATE],3    				;initialize CRT_STATE to be idle
	or  F,01h   						;Enable globle interrupt
	call Counter8_1_EnableInt			;enable Counter Interupt
	call Counter8_2_EnableInt
	call LCD_Start						;start LCD
	call LCD_Init						;initialize LCD
	call _LED_1_Start					;start the LEDs, which are used to indicate the CRT_STATE
	call _LED_2_Start
	call _LED_3_Start	
	mov [TIMING_TIMES],00h				;initialize the stopwatch using time to be 0
	_BACK:	
	call _button_press
	and  F,F9h   						;initalize C , Z flag to 0 
	cmp [PRESS_INTERUPTNO],15			;if press>3s, jmp to FSM1
	;call _LCD_Display_PressNo			;display how many counters are used, use for debug
	jnc FSM1
	
	FSM1:
	cmp [CRT_STATE],0	
	call _LCD_Display_Idle 				;display mode
	call _LED_Display
	jz  STATE0
	cmp [CRT_STATE],1
	call _LCD_Display_Sensitity    		;display mode
	call _LED_Display
	jz  STATE1
	cmp [CRT_STATE],2
	call _LCD_Display_Accuracy   		;display mode
	call _LED_Display
	jz  STATE2
	cmp [CRT_STATE],3
	call _LCD_Display_Measurement        ;display mode
	call _LED_Display	
	jz  STATE3
	cmp [CRT_STATE],4
	call _LCD_Display_Memory    			;display mode
	call _LED_Display
	jz  STATE4	
	
	STATE0:                      ;idle	
	mov [CRT_STATE],1   				;change the current state to next
	jmp _BACK

	STATE1: 					;SensitityMode
	;add codes here
	mov [CRT_STATE],2             		;change the current state to next
	jmp _BACK
	
	STATE2:							     ;AccuracyMode
	;add codes here
	mov [CRT_STATE],3   				;change the current state to next
	jmp _BACK

	STATE3:									;MeasurementMode
	call _button_press
	and  F,F9h   						;initalize C and Z flag to 0
	cmp [PRESS_INTERUPTNO],0			;if no press, Z flag set 
	jz 	_is_Sound_Mode
	cmp [PRESS_INTERUPTNO],15 			;if press<3s, jmp to FSM1
	jnc _start_stopwatch
	mov [CRT_STATE],4
	jmp _BACK
_is_Sound_Mode:
	;if also not sound mode ,jmp STATE3_END
	;if it is sound mode, start stopwatch
	jmp	_start_stopwatch
_start_stopwatch:
	inc [TIMING_TIMES]					;counting how many stopwatch are used
	;mov [MS_COUNT],00h
	call Counter8_2_Start
	call CHECK_ShortPress
	jc 	_stop_stopwatch
	
_COUNTING_INCREMENT:
	inc [MS_COUNT]
	inc [SET_MS]						;if MS=100MS,;SET_MS=
	and  F,FDh   						;initalize Z flag to 0
	cmp [SET_MS],11						;CMP MS,11
	jz	SECOND_COUNT
 SECOND_COUNT:
	inc [SET_SEC]						;if MS==11,Set_SEC=Set_SEC+1,set_ms=1
	mov [SET_MS],1
	and  F,FDh   						;initalize Z flag to 0
	cmp [SET_SEC],61					;check if second>60 sec
	jz	MINUTE_COUNT
 MINUTE_COUNT:	
 	inc	[SET_MINUTE]
	mov [SET_SEC],1
	and  F,FDh 
	cmp	[SET_MINUTE],61					
	jz	HOUR_COUNT
 HOUR_COUNT:
 	inc [SET_HOUR]						
	mov	[SET_MINUTE],1
	ret

	
CHECK_ShortPress:
	jmp _button_press
	and  F,F9h   						;initalize C and Z flag to 0
	cmp [PRESS_INTERUPTNO],0			;if no press, Z flag set 
	jnz _compare_X 	
	_compare_X:
	cmp [PRESS_INTERUPTNO],15 			;if press<3s, jmp to FSM1
	reti

	
_stop_stopwatch:
	call Counter8_2_Stop
	and  F,FDh   						;initalize Z flag to 0
	cmp [TIMING_TIMES],1
	jz	_initalize_temp
	jnz _compare_temp
_BACK_STOP:
	mov A,SET_MS
	inc A
	mov A,SET_SEC
	inc A
	mov A,SET_MINUTE
	inc A
	mov A,SET_HOUR
	inc A						;increase the address of them to store the next coming result of stopwatch
	jmp _LCD_Display_Time
	;counter for y Sec to stay
	and  F,F9h   						;initalize C and Z flag to 0
	call CHECK_ShortPress
	jc 	_start_stopwatch
	jnc _BACK
	
	
_initalize_temp:
	mov	A,[SET_HOUR]
	mov	[TEMP_MIN_HOUR],A
	mov [TEMP_MAX_HOUR],A
	mov [TEMP_SUM_HOUR],A
	mov A,[SET_MINUTE]
	mov [TEMP_MIN_MINUTE],A
	mov [TEMP_MAX_MINUTE],A	
	mov [TEMP_SUM_MINUTE],A
	mov A,[SET_SEC]
	mov [TEMP_MIN_SEC],A	
	mov [TEMP_MAX_SEC],A
	mov [TEMP_SUM_SEC],A
_compare_temp:
	and	F,F9h   						;initalize C and Z flag to 0
	mov	A,[SET_HOUR]
	cmp A,[TEMP_MIN_HOUR]
	jc	_update_minAndSum						;if current hour<min_hour,update min 
	mov A,[SET_MINUTE]
	cmp A,[TEMP_MIN_MINUTE]
	jc	_update_minAndSum
	mov A,[SET_SEC]
	cmp A,[TEMP_MIN_SEC]
	jc	_update_minAndSum
	//if current_time>min_time, continue compare current_time vs. max_time
	and	F,F9h   						;initalize C and Z flag to 0
	mov	A,[SET_HOUR]
	cmp A,[TEMP_MAX_HOUR]				
	jnc _update_minAndSum						;if current hour>min_hour,update min
	mov A,[SET_MINUTE]
	cmp A,[TEMP_MIN_MINUTE]
	jnc _update_minAndSum
	mov A,[SET_SEC]
	cmp A,[TEMP_MIN_SEC]
	jnc _update_minAndSum
	//if min_time<current_time<max_time,just update sum
	jmp _update_sum
_update_minAndSum:
	mov	A,[SET_HOUR]	
	mov	[TEMP_MIN_HOUR],A
	add [TEMP_SUM_HOUR],A
	mov A,[SET_MINUTE]	
	mov [TEMP_MIN_MINUTE],A
	add [TEMP_SUM_MINUTE],A
	mov A,[SET_SEC]	
	mov [TEMP_MIN_SEC],A
	add [TEMP_SUM_SEC],A
	jmp _BACK_STOP
	
_update_maxAndSum:
	mov	A,[SET_HOUR]	
	mov	[TEMP_MAX_HOUR],A
	add [TEMP_SUM_HOUR],A
	mov A,[SET_MINUTE]	
	mov [TEMP_MAX_MINUTE],A
	add [TEMP_SUM_MINUTE],A 
	mov A,[SET_SEC]	
	mov [TEMP_MAX_SEC],A
	add [TEMP_SUM_SEC],A
	jmp	_BACK_STOP
_update_sum:
	mov	A,[SET_HOUR]      
	add [TEMP_SUM_HOUR],A
	mov A,[SET_MINUTE]
	add [TEMP_SUM_MINUTE],A
	mov A,[SET_SEC]
	add [TEMP_SUM_SEC],A
	jmp	_BACK_STOP

	
STATE3_END:	
	mov [CRT_STATE],4   				;change the current state to next
	JMP _BACK

STATE4:									;MemoryMode
	mov [CRT_STATE],1					;change the current state to next state
	jmp CHECK_ShortPress
	jnc	FSM1							;if long press button, jump back to next state
	
	//calculate Avg based on SUM
	mov A, [TEMP_SUM_HOUR]
	mov [dividend],A
	mov [divisor],09h
	jmp div8
	mov A,[dividend]
	mov [TEMP_SUM_HOUR],A				;restore the result(Avg) back to TEMP_SUM
	mov A, [TEMP_SUM_MINUTE]			
	mov [dividend],A
	mov [divisor],09h
	jmp div8
	mov A,[dividend]
	mov [TEMP_SUM_MINUTE],A				;restore Avg_min to temp_sum_min
	mov A, [TEMP_SUM_SEC]
	mov [dividend],A
	mov [divisor],09h
	jmp div8
	mov A,[dividend]
	mov [TEMP_SUM_SEC],A				;restor Avg_sec to temp_sum_sec
	_start_memory_display:
	;short button press->display Avg time
	jmp CHECK_ShortPress
	jc	_LCD_Display_Average 
	jnc FSM1
	mov A,00h   						;load Row
	mov X,01h   						;load column
	call LCD_Position
	mov A,10
	call LCD_WriteData	
	;short button press->display Longest time
	jmp CHECK_ShortPress
	jc	_LCD_Display_Longest
	jnc FSM1
	mov A,00h   						;load Row
	mov X,01h   						;load column
	call LCD_Position
	mov A,10
	call LCD_WriteData	
	;short button pressd->display Shortest time
	jmp CHECK_ShortPress
	jc _LCD_Display_Shortest
	jnc	FSM1
	mov A,00h   						;load Row
	mov X,01h   						;load column
	call LCD_Position
	mov A,10
	call LCD_WriteData	
	;short button pressd->display Shortest time
	jmp CHECK_ShortPress
	jc	_start_memory_display
	jnc	FSM1	

div8:
	mov [remainder],00h 				;initialize remainder to 0
	and F,fbh 							;clear carry bit in flags
	mov [lcount],8 				;set loop counter to 8
d8u_1:
	rlc [dividend] 					;shift MSB of dividend to LSB of remainder
	rlc [remainder] 					; continued
	mov [temp],[remainder] 			;store remainder
	mov a,[remainder] 				;subtract divisor from remainder
	sub a,[divisor] 					;continued
	mov [remainder],a 				;continued
	jnc d8u_2 							;jump if result was positive
	mov [remainder],[temp] 			;restore remainder
	and [dividend],feh 				;clear LSB of dividend
	jmp chkLcount8 						;jump to loop counter decrement
d8u_2:
	or [dividend],01h 				;set dividend LSB to 1
chkLcount8:
	dec [lcount] 						;decrement loop counter
	jnz d8u_1 							;repeat steps if loop counter not zero
;division complete

_button_press:
	mov [PRESS_INTERUPTNO],00h
	mov A,REG[PRT2DR]  					;get the input button press for port2
	and A,BUTTON_MSK     				;get pin7 value, button_msk=10000000
	jz	_button_press					;if pin7=1,start to count, counter perio=250
	call _start_counter
	and  F,F9h   						;initalize C and Z flag to 0
	wait_release:
	mov A,REG[PRT2DR]
	and A,BUTTON_MSK 					;check if press has been losen, that is pin=0
	jnz wait_release
	call _stop_counter					;if the pin=0, stop counting
	ret

_inc_press_interuptNo:
	INC [PRESS_INTERUPTNO]  			;INC interuptNO
	ret
_stop_counter:
	call Counter8_1_Stop
	ret
_start_counter:
	call Counter8_1_Start
	ret


_LCD_Display_Longest:     //used to display Avg,Longest,Shortest time
	mov A,00h   						;load Row
	mov X,00h   						;load column
	call LCD_Position
	mov A,>Longest  					;Load MSB part of pointer
	mov X,<Longest  					;load LSB part of pointer
	call LCD_PrCString    				;display string at current LCD Cursion position
	
_LCD_Display_Shortest:     //used to display Avg,Longest,Shortest time
	mov A,00h   						;load Row
	mov X,00h   						;load column
	call LCD_Position
	mov A,>Shortest  					;Load MSB part of pointer
	mov X,<Shortest  					;load LSB part of pointer
	call LCD_PrCString    				;display string at current LCD Cursion position
	
_LCD_Display_Average:     //used to display Avg,Longest,Shortest time
	mov A,01h   						;load Row
	mov X,06h   						;load column
	call LCD_Position
	mov A,>Avg  						;Load MSB part of pointer
	mov X,<Avg 							;load LSB part of pointer
	call LCD_PrCString    				;display string at current LCD Cursion position
	ret
	
_LCD_Display_Idle:     //used to display Avg,Longest,Shortest time
	mov A,01h   						;load Row
	mov X,00h   						;load column
	call LCD_Position
	mov A,>IDLE  						;Load MSB part of pointer
	mov X,<IDLE  						;load LSB part of pointer
	call LCD_PrCString    				;display string at current LCD Cursion position	
	ret
	
_LCD_Display_Sensitity:     //used to display Avg,Longest,Shortest time
	mov A,00h   						;load Row
	mov X,00h   						;load column
	call LCD_Position
	mov A,>SENSE_MODE  						;Load MSB part of pointer
	mov X,<SENSE_MODE 						;load LSB part of pointer
	call LCD_PrCString    				;display string at current LCD Cursion position
	ret
	
_LCD_Display_Accuracy:     //used to display Avg,Longest,Shortest time
	mov A,00h   						;load Row
	mov X,00h   						;load column
	call LCD_Position
	mov A,>ACCRUARY_MODE  						;Load MSB part of pointer
	mov X,<ACCRUARY_MODE  						;load LSB part of pointer
	call LCD_PrCString    				;display string at current LCD Cursion position
	ret
	
_LCD_Display_Measurement:     //used to display Avg,Longest,Shortest time
	mov A,00h   						;load Row
	mov X,00h   						;load column
	call LCD_Position
	mov A,>MEASURE_MODE  						;Load MSB part of pointer
	mov X,<MEASURE_MODE  						;load LSB part of pointer
	call LCD_PrCString    				;display string at current LCD Cursion position
	ret
	
_LCD_Display_Memory:     //used to display Avg,Longest,Shortest time
	mov A,00h   						;load Row
	mov X,00h   						;load column
	call LCD_Position
	mov A,>MEMORY_MODE  						;Load MSB part of pointer
	mov X,<MEMORY_MODE  						;load LSB part of pointer
	call LCD_PrCString    				;display string at current LCD Cursion position	
	ret
	

_LCD_Display_Time:
	mov A,00h   						;load Row
	mov X,00h   						;load column
	call LCD_Position
	mov A,[SET_HOUR]
	index DIGITS
	call LCD_PrHexByte
	
	mov A,00h   						;load Row
	mov X,02h   						;load column
	call LCD_Position
	mov A,10
	index DIGITS
	call LCD_PrHexByte
	
	mov A,00h   						;load Row
	mov X,03h   						;load column
	call LCD_Position
	mov A,[SET_MINUTE]
	index DIGITS
	call LCD_PrHexByte	
	
	mov A,00h   						;load Row
	mov X,05h   						;load column
	call LCD_Position
	mov A,10
	index DIGITS
	call LCD_PrHexByte
	
	mov A,00h   						;load Row
	mov X,06h   						;load column
	call LCD_Position
	mov A,[SET_SEC]
	index DIGITS
	call LCD_PrHexByte	
	
	mov A,00h   						;load Row
	mov X,08h   						;load column
	call LCD_Position
	mov A,11
	index DIGITS
	call LCD_PrHexByte
	ret

_LCD_Display_PressNo:
	mov A,00h   						;load Row
	mov X,00h   						;load column
	call LCD_Position
	mov A,[PRESS_INTERUPTNO]
	call LCD_PrHexByte
	ret
	
_LED_Display:
	mov A,[CRT_STATE]
	mov [temp],A
	and A,LED_MSK
	call _LED_1_Switch
	mov A,[temp]
	rlc A
	mov [temp],A
	and A,LED_MSK
	call _LED_2_Switch
	mov A,[temp]
	rlc A
	and A,LED_MSK
	call _LED_3_Switch
	ret
	

.terminate:
    jmp .terminate
	
