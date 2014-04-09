'****************************************************************************
'*
'* Name: utils.bi
'*
'* Synopsis: Utility routines for DOD.
'*
'* Description: This file contains misc utility routines used in the program.  
'*
'* Copyright 2014, Maxime Blanc
'*
'*                          The Wide Open License (WOL)
'*
'* Permission to use, copy, modify, distribute and sell this software and its
'* documentation for any purpose is hereby granted without fee, provided that
'* the above copyright notice and this license appear in all source copies. 
'* THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY OF
'* ANY KIND. See http://www.dspguru.com/wol.htm for more information.
'*
'*****************************************************************************'/
' Clears key board buffer.
Sub ClearKeys
    Do: Sleep 1: Loop While Inkey<> ""
End Sub

' Draws a background image using passed color map
Sub DrawBackground(cmap() As UInteger)
    'Iterate through the array, drawing the block character in the array color.
    For x As Integer = 0 To txcols - 1
        For y As Integer = 0 To txrows - 1
            'Get the color our of the array using the formula.
            Dim clr As UInteger = cmap(x + y * txcols)
            
            'Use draw string as it is faster 
            'and we don't need to worry about locate statements.
            Draw String (x * charw, y * charh), acBlock, clr
        Next
    Next
End Sub

'Returns a random number within range.
Function RandomRange(lowerbound As Integer, upperbound As Integer) As Integer
    Return Int((upperbound - lowerbound + 1) * Rnd + lowerbound)
End Function

'Draw a string with drop shadow
Sub DrawStringShadow(x As Integer, y As Integer, txt As String, fcolor As UInteger = fbWhite)
    Draw String(x + 1, y + 1), txt, fbBlack
    Draw String(x, y), txt, fcolor
End Sub