'****************************************************************************
'*
'* Name: mmenu.bi
'*
'* Synopsis: Main menu file.
'*
'* Description: This is the main menu routines that display and return the menu
'*              selection to the main program.  
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

'Wrap this in a namespace since we only need this at the beginning
Namespace mmenu

'Background color map
'#Include "menuback.bi"

'These are the menu return values.
Enum mmenuret
    mNew
    mLoad
    mInstructions
    mQuit
End Enum

'Draws the menu to the screen
Sub DrawMenu(m() As String, midx As Integer, mx As Integer, my As Integer)
    Dim as Integer x = mx - 2   , y = my
    
    'Iterate through the menu array and draw items to the screen.
    For i As Integer = mNew To mQuit
        If midx = i Then
            Draw String (x * charw, y * charh), m(i), fbWhite
        Else
            Draw String (x * charw, y * charh), m(i), fbGray
        EndIf
        
        y += 2
    Next
End Sub

'This draws the menu and returns the selected value.
Function MainMenu() As mmenuret
    Dim As mmenuret idx = mNew
    Dim menuitems(mNew To mQuit) As String
    Dim As Integer mx, my, done = False, tx, ty
    Dim As String mkey, mtitle
    
    'Set the menu text.
    menuitems(mNew) = "New Game "
    menuitems(mLoad) = "Load Game   "
    menuitems(mInstructions) = "Instructions"
    menuitems(mQuit) = "Quit    "
    
    'Set the menu items x, y
    mx = CenterX(menuitems(3))
    my = CenterY(UBound(menuitems) * 2)
    
    ScreenLock
    
    'Draw the menu background.
    'DrawBackground menuback()
    
    'Draw the title with drop shadow.
    mtitle = "Dungeon of Doom v." & dodver
    tx = CenterX(mtitle) * charw
    ty = (10 * charh)
    Draw String (tx + 1, ty + 1), mtitle, fbBlack
    Draw String (tx, ty), mtitle, fbYellow
    
    'Draw the menu text.
    DrawMenu menuitems(), idx, mx, my
    
    ScreenUnlock
    
    Do
        'Get the current key.
        mkey = InKey
        
        'Did user press a key ?
        If mkey <> "" Then
            'If user presses escape or close button, then exit whit quit id
            If(mkey = key_esc) Or (mkey = key_close) Then
                idx = mQuit
                done = TRUE
            EndIf
            
            'User pressed up arrow.
            If mkey = key_up Then
                'Decrement the menu index.
                idx -= 1
                'Wrap around to bottom of menu.
                If idx < mNew Then idx = mQuit
                'Draw the menu.
                ScreenLock
                DrawMenu menuitems(), idx, mx, my
                ScreenUnlock
            EndIf
            
            'User pressed down arrow.
            If mkey = key_dn Then
                'Increment the menu index.
                idx += 1
                'Wrap around to top of menu.
                If idx > mQuit Then idx = mNew
                'Draw the menu.
                ScreenLock
                DrawMenu menuitems(), idx, mx, my
                ScreenUnLock
            EndIf
            
            'User pressed enter key.
            If mkey = key_enter Then
                'Exit menu
                done = TRUE
            EndIf
        EndIf
        
        Sleep 10
    Loop Until done = TRUE
    
    'Clear any keys.
    ClearKeys
    Return idx
End Function

End Namespace
        