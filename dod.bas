'****************************************************************************
'*
'* Name : dod.bas
'*
'* Synopsis : Dungeon of Doom
'*
'* Description : Main program file
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
'*****************************************************************************'
#Include "title.bi"
#Include "defs.bi"
#Include "utils.bi"
#Include "mmenu.bi"
#Include "character.bi"
#Include "intro.bi"
#Include "map.bi"
#Include "vec.bi"
#Include "commands.bi"

'Displays the game title screen.
Sub DisplayTitle
    Dim As String txt
    Dim as Integer tx, ty
    
    'Set up the copyright notice.
    txt = "Copyright (C) 2014, by Maxime Blanc"
    tx = CenterX(txt)
    ty = txrows - 2
    
    'Lock the screen while we update it.
    ScreenLock
    
    'Draw the background.
    DrawBackground title()
    
    'Draw the copyright notice.
    Draw String (tx * charw, ty * charh), txt, fbYellow
    
    ScreenUnLock
    Sleep
    
    'Clear the key buffer.
    ClearKeys
End Sub

'Draw the main game screen.
Sub DrawMainScreen()
    ScreenLock
    Cls
    level.DrawMap
    ScreenUnlock
End Sub

'Using 640x480 32bit screen with 80x60 text.
ScreenRes 640, 480, 32
Width charw, charh
WindowTitle "Dungeon of Doom"
Randomize Timer

'Draw the title screen
'DisplayTitle

'Get the menu selection
Dim mm As mmenu.mmenuret

'Loop until the user selects New, Load or Quit.
Do
    'Draw the main menu.
    mm = mmenu.MainMenu
    'Process the menu selection.
    If mm = mmenu.mNew Then
        'Generate the character.
        Var ret = pchar.GenerateCharacter
        'Do not exit menu when user pressed ESC.
        If ret = FALSE Then
            'Set this so we loop.
            mm = mmenu.mInstructions
        Else
            'Do the intro.
            intro.DoIntro
        EndIf
    ElseIf mm = mmenu.mLoad Then
        'Load the save game.
    ElseIf mm = mmenu.mInstructions Then
        'Print the instructions.
    EndIf
Loop Until mm <> mmenu.mInstructions

'Main game loop.
If mm <> mmenu.mQuit Then
    'Build the first level of dungeon.
    level.GenerateDungeonLevel
    
    'Display the main screen.
    DrawMainScreen
    
    'Get key input until user exists.
    Do
        ckey = InKey
        If ckey <> "" Then
            'Get direction key from numpad or arrows.
            'Check for up arrow or 8
            If(ckey = key_up) OrElse (ckey = "8") Then
                mret = MoveChar(north)
                If mret = TRUE Then DrawMainScreen
            EndIf
            
            'Check for 9
            If ckey = "9" Then
                mret = MoveChar(neast)
                If mret = TRUE Then DrawMainScreen
            EndIf
            
            'Check for right arrow or 6.
            If (ckey = key_rt) OrElse (ckey = "6") Then
                mret = MoveChar(east)
                If mret = TRUE Then DrawMainScreen
            EndIf
            
            'Check for 3
            If ckey = "3" Then
                mret = MoveChar(seast)
                If mret = TRUE Then DrawMainScreen
            EndIf
            
            'Check for down arrow or 2.
            If (ckey = key_dn) OrElse (ckey = "2") Then
                mret = MoveChar(south)
                If mret = TRUE Then DrawMainScreen
            EndIf
            
            'Check for 1
            If ckey = "1" Then
                mret = MoveChar(swest)
                If mret = TRUE Then DrawMainScreen
            EndIf
            
            'Check for left arrow or 4.
            If (ckey = key_lt) OrElse (ckey = "4") Then
                mret = MoveChar(west)
                If mret = TRUE Then DrawMainScreen
            EndIf
            
            'Check for 7
            If ckey = "7" Then
                mret = MoveChar(nwest)
                If mret = TRUE Then DrawMainScreen
            EndIf
            
            'Check for down stairs.
            If ckey = ">" Then
                'Check to make sure on down stairs.
                If level.GetTileID(pchar.Locx, pchar.Locy) = tstairdn Then
                    'Build a new level.
                    level.GenerateDungeonLevel
                    
                    'Draw screen.
                    DrawMainScreen
                End If
            EndIf
        End If
        
        Sleep 1
    Loop Until ckey = key_esc
EndIf

Sleep
    