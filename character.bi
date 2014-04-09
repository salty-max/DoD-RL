'****************************************************************************
'*
'* Name: character.bi
'*
'* Synopsis: Character related routines for DOD.
'*
'* Description: This file contains the character generation and management
'*              routines used in the program. 
'*              
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
'Character screen background.
'#Include "charback.bi"

'Character attribute type def.
Type characterinfo
   cname As String * 40 'Name of character.
   stratt(2) As Integer 'Strength attribute (0), str bonus (1)
   staatt(2) As Integer 'Stamina attribute (0), sta bonus (1)
   dexatt(2) As Integer 'Dexterity attribute (0), dex bonus (1)
   aglatt(2) As Integer 'Agility attribute (0), sta bonus (1)
   intatt(2) As Integer 'Intelligence attribute (0), int bonus (1)
   currhp As Integer    'Current HP
   maxhp As Integer     'Max HP
   ucfsk(2) As Integer  'Unarmed combat skill (0), ucf bonus (1)
   acfsk(2) As Integer  'Armed combat skill (0), acf bonus (1)
   pcfsk(2) As Integer  'Projectile combat skill (0), pcf bonus (1)
   mcfsk(2) As Integer  'Magic combat skill (0), mcf bonus (1)
   cdfsk(2) As Integer  'Combat defense skill (0), cdf bonus (1)
   mdfsk(2) As Integer  'Magic defense skill (0), mdf bonus (1)
   currxp As Integer    'Current spendable XP amount.
   totxp As Integer     'Lifetime XP amount.0
   currgold As Integer  'Current gold amount.
   totgold As Integer   'Lifetime gold amount.
   locx As Integer      'Current x position on map.
   locy As Integer      'Current y location on map.
End Type

'Character object.
Type character
   Private:
   _cinfo As characterinfo
   Public:
   Declare Sub PrintStats ()
   Declare Function GenerateCharacter() As Integer
End Type

'Prints out the current stats for character.
Sub character.PrintStats ()
   Dim As Integer tx, ty, row = 8
   Dim As String sinfo
   
   ScreenLock
   'Draw the background.
   'DrawBackground charback()
   'Draw the title.
   sinfo = Trim(_cinfo.cname) & " Attributes and Skills" 
   ty = row * charh
   tx = (CenterX(sinfo)) * charw
   DrawStringShadow tx, ty, sinfo, fbYellow
   'Draw the attributes.
   row += 4
   ty = row * charh
   tx = 70
   sinfo = "Strength:     " & _cinfo.stratt(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Stamina:      " & _cinfo.staatt(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Dexterity:    " & _cinfo.dexatt(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Agility:      " & _cinfo.aglatt(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Intelligence: " & _cinfo.intatt(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Hit Points:   " & _cinfo.currhp
   DrawStringShadow tx, ty, sinfo
   row += 3
   ty = row * charh
   sinfo = "Unarmed Combat:    " & _cinfo.ucfsk(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Armed Combat:      " & _cinfo.acfsk(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Projectile Combat: " & _cinfo.pcfsk(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Magic Combat:      " & _cinfo.mcfsk(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Combat Defense:    " & _cinfo.cdfsk(0)
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Magic Defense:     " & _cinfo.mdfsk(0)
   DrawStringShadow tx, ty, sinfo
   row += 3
   ty = row * charh
   sinfo = "Experience: " & _cinfo.currxp
   DrawStringShadow tx, ty, sinfo
   row += 2
   ty = row * charh
   sinfo = "Gold:       " & _cinfo.currgold
   DrawStringShadow tx, ty, sinfo

   ScreenUnLock
End Sub

'Generates a new character.
Function character.GenerateCharacter() As Integer
   Dim As String chname, prompt, skey
   Dim As Integer done = FALSE, ret = TRUE, tx, ty
   
   'Set up user input prompt.
   prompt = "Press <r> to roll again, <enter> to accept, <esc> to exit to menu."
   tx = (CenterX(prompt)) * charw
   ty = (txrows - 6) * charh   
   'Get the name of the character.
   Do
      Cls
      'Using simple input here.
      Input "Enter your character's name (40 chars max):",chname
      'Validate the name here. 
      If Len(chname) > 0 And Len(chname) < 41 Then
         done = TRUE
      Else
         'Let the user know what they did wrong.
         Cls
         If Len(chname) = 0 Then
            Print "Name is required. <Press any key.>"
            Sleep
            ClearKeys
         EndIf
         If Len(chname) > 40 Then
            Print "Name is too long. 40 chars max. <Press any key.>"
            Sleep
            ClearKeys
         EndIf
      EndIf
      Sleep 10
   Loop Until done = TRUE
   done = FALSE
   'Generate the character data.
   Do
      With _cinfo
         .cname = chname
         .stratt(0) = RandomRange (1, 20)
         .staatt(0) = RandomRange (1, 20)
         .dexatt(0) = RandomRange (1, 20)
         .aglatt(0) = RandomRange (1, 20)
         .intatt(0) = RandomRange (1, 20)
         .currhp = .stratt(0) + .staatt(0) 
         .maxhp = .currhp
         .ucfsk(0) = .stratt(0) + .aglatt(0) 
         .acfsk(0) = .stratt(0) + .dexatt(0) 
         .pcfsk(0) = .dexatt(0) + .intatt(0)
         .mcfsk(0) = .intatt(0) + .staatt(0)
         .cdfsk(0) = .stratt(0) + .aglatt(0)
         .mdfsk(0) = .aglatt(0) + .intatt(0)
         .currxp = RandomRange (100, 200)
         .totxp = .currxp
         .currgold = RandomRange (50, 100)
         .totgold = .currgold
         .locx = 0
         .locy = 0
      End With
      'Print out the current character stats.
      PrintStats
      DrawStringShadow tx, ty, prompt
      'Get the user command.
      Do
         'Get the key press.
         skey = Inkey
         'Format to lower case.
         skey = LCase(skey)
         'If escape exit back to menu.
         If skey = key_esc Then
            done = TRUE
            ret = FALSE
         EndIf
         'If enter continue with game.
         If skey = key_enter Then
            done = TRUE
         EndIf
         Sleep 10
      Loop Until (skey = "r") Or (skey = key_esc) Or (skey = key_enter)
   Loop Until done = TRUE 
   Return ret
End Function

'Set up our character variable.
Dim Shared pchar As character
 