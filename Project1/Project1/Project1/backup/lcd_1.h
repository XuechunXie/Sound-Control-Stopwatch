//*****************************************************************************
//*****************************************************************************
//  FILENAME:  LCD_1.h
//  Version: 1.5, Updated on 2009/10/23 at 10:13:12
//  Generated by PSoC Designer 5.0.1127.0
//
//  DESCRIPTION:  LCD User Module C Language interface file.
//-----------------------------------------------------------------------------
//      Copyright (c) Cypress Semiconductor 2009. All Rights Reserved.
//*****************************************************************************
//*****************************************************************************


#include <m8c.h>

#define LCD_1_BARGRAPH_ENABLE 1

/* Create pragmas to support proper argument and return value passing */
#pragma fastcall16  LCD_1_Start
#pragma fastcall16  LCD_1_Init
#pragma fastcall16  LCD_1_Control
#pragma fastcall16  LCD_1_WriteData
#pragma fastcall16  LCD_1_PrString
#pragma fastcall16  LCD_1_PrCString
#pragma fastcall16  LCD_1_PrHexByte
#pragma fastcall16  LCD_1_PrHexInt
#pragma fastcall16  LCD_1_Position
#pragma fastcall16  LCD_1_Delay50uTimes
#pragma fastcall16  LCD_1_Delay50u

#if ( LCD_1_BARGRAPH_ENABLE )
#pragma fastcall16  LCD_1_InitBG
#pragma fastcall16  LCD_1_DrawBG
#pragma fastcall16  LCD_1_InitVBG
#pragma fastcall16  LCD_1_DrawVBG
#endif

//-------------------------------------------------
// Prototypes of the LCD_1 API.
//-------------------------------------------------

extern void  LCD_1_Start(void);
extern void  LCD_1_Init(void);
extern void  LCD_1_Control(BYTE bData);
extern void  LCD_1_WriteData(BYTE bData);
extern void  LCD_1_PrString(char * sRamString);
extern void  LCD_1_PrCString(const char * sRomString);
extern void  LCD_1_Position(BYTE bRow, BYTE bCol);
extern void  LCD_1_PrHexByte(BYTE bValue);
extern void  LCD_1_PrHexInt(INT iValue);

extern void  LCD_1_Delay50uTimes(BYTE bTimes);
extern void  LCD_1_Delay50u(void);

// Do not use, will be removed in future version.
extern void  LCD_1_Write_Data(BYTE bData);
#pragma fastcall16 LCD_1_Write_Data
//


#if ( LCD_1_BARGRAPH_ENABLE )
extern void  LCD_1_InitBG(BYTE bBGType);
extern void  LCD_1_InitVBG(void);
extern void  LCD_1_DrawVBG(BYTE bRow, BYTE bCol, BYTE bHeight, BYTE bPixelRowEnd);
extern void  LCD_1_DrawBG(BYTE bRow, BYTE bCol, BYTE bLen, BYTE bPixelColEnd);


#define LCD_1_SOLID_BG                      0x00
#define LCD_1_LINE_BG                       0x01


#endif

//-------------------------------------------------
// Defines for LCD_1 API's.
//-------------------------------------------------
#define LCD_1_DISP_ON                       0x0C
#define LCD_1_DISP_OFF                      0x08
#define LCD_1_DISP_BLANK                    0x0A
#define LCD_1_DISP_CLEAR_HOME               0x01
#define LCD_1_CURSOR_ON                     0x0E
#define LCD_1_CURSOR_OFF                    0x0C
#define LCD_1_CURSOR_WINK                   0x0D
#define LCD_1_CURSOR_BLINK                  0x0F
#define LCD_1_CURSOR_SH_LEFT                0x10
#define LCD_1_CURSOR_SH_RIGHT               0x14
#define LCD_1_CURSOR_HOME                   0x02
#define LCD_1_CURSOR_LEFT                   0x04
#define LCD_1_CURSOR_RIGHT                  0x06

#define LCD_1_PORT_MASK                     0x7F
//------------------------------------------------------
//  Register Address Constants for  LCD_1
//------------------------------------------------------

#define LCD_1_Port                        PRT0DR
#define LCD_1_PortMode0                   PRT0DM0
#define LCD_1_PortMode1                   PRT0DM1

// end of file LCD_1.h
