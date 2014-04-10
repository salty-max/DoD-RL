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

'Splits text InS at sLen and returns clipped string.
Function WordWrap(InS As String, sLen As Integer) As String
    Dim As Integer i = sLen, sl
    Dim As Integer BackFlag = FALSE
    Dim As String sret, ch
    
    'Make sure we have something to with here.
    sl = Len(InS)
    If sl <= sLen Then
        sret = InS
        InS = ""
    Else
        'Find the break point in the string, backtracking
        'to find a space to break the line at if not at a space.
        Do
            'Break is at space, so done.
            ch = Mid(InS, i, 1)
            If ch = Chr(32) Then
                Exit Do
            EndIf
            
            'If not backtracking, start backtrack.
            If BackFlag = FALSE Then
                If i + 1 <= sl Then
                    i += 1
                EndIf
                BackFlag = TRUE
            Else
                i -= 1
            EndIf
        Loop Until i = 0 or ch = Chr(32) 'Backtrack to space.
        
        'Make sure we still have something to work with.
        If i > 0 Then
            'Return clipped string.
            sret = Mid(InS, 1, i)
            
            'Modify the input string: string less clipped.
            InS = Mid(InS, i + 1)
        Else
            sret = ""
        EndIf
    EndIf
    
    Return sret
End Function

'Returns fast distance calculation between two points.
Function CalcDist(x1 As Integer, x2 As Integer, y1 As Integer, y2 As Integer) As Integer
    Dim As Integer xdiff, ydiff
    Dim dist As Integer
    
    xdiff = Abs(x1 - x2)
    ydiff = Abs(y1 - y2)
    dist = (xdiff + ydiff + imax(xdiff, ydiff)) Shr 1
    Return dist
End Function

'Writes text at specified row and column.
Sub PutText(txt As String, row As Integer, col As Integer, fcolor as UInteger = fbWhite)
    Dim As Integer x, y
    
    x = (col - 1) * charw
    y = (row - 1) * charh
    Draw String (x, y), txt, fcolor
End Sub
