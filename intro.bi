'****************************************************************************
'*
'* Name: intro.bi
'*
'* Synopsis: Game introduction related routines for DOD.
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
Namespace intro
'Parchment background.
'#Include "introback.bi"

Const maxage = 80
Const FD = 1 / 60

Dim Shared pal(maxage) As UInteger = { _
&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4, _
&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4, _
&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4,&hFFF9F7D4, _
&hFFF9F7D4,&hFFF9F6B6,&hFFF8F48E,&hFFF8F364,&hFFF8F139,&hFFF9EC14,&hFFFAD51B,&hFFFCBE22, _
&hFFFDA52A,&hFFFF8C31,&hFFFA802E,&hFFF4752A,&hFFEE6A26,&hFFE95E22,&hFFE3531D,&hFFDE471A, _
&hFFD53613,&hFFCC250D,&hFFC31207,&hFFBB0100,&hFFAC0000,&hFF9D0000,&hFF8E0000,&hFF7F0000, _
&hFF700000,&hFF610000,&hFF5A0000,&hFF550000,&hFF510000,&hFF4D0000,&hFF480000,&hFF440000, _
&hFF3F0000,&hFF3B0000,&hFF370000,&hFF320000,&hFF2E0000,&hFF2A0000,&hFF250000,&hFF210000, _
&hFF1C0000,&hFF180000,&hFF130000,&hFF100000,&hFF0B0000,&hFF070000,&hFF020000,&hFF000000, _
&hFF000000,&hFF000000,&hFF000000,&hFF000000,&hFF000000,&hFF000000,&hFF000000,&hFF000000}
Dim Shared fire(0 To txcols - 1, 0 To txrows - 1) As Integer
Dim Shared coolmap(0 To txcols - 1, 0 To txrows - 1) As Integer

'This smooths the fire by averaging the values.
Function Smooth(arr() As Integer, x As Integer, y As Integer) As Integer
    Dim As Integer xx, yy, cnt, v
    
    cnt = 0
    
    v = arr(x, y)
    cnt += 1

    If x < txcols - 1 Then 
        xx = x + 1
        yy = y
        v += arr(xx, yy)
        cnt += 1
    End If

    If x > 0 Then 
        xx = x - 1
        yy = y
        v += arr(xx, yy)
        cnt += 1
    End If
                
    If y < txrows - 1 Then
        xx = x 
        yy = (y + 1)
        v += arr(x, y + 1)
        cnt += 1
    End If
    
    If y > 0 Then
        xx = x
        yy = (y - 1)
        v += arr(x, y - 1)
        cnt += 1
    End If
    
    v = v / cnt
        
    Return v
End Function

'Creates a cool map that will combined with the fire value to give a nice effect.
Sub CreateCoolMap
   Dim As Integer i, j, x, y
    
   For x = 0 To txcols - 1 
      For y = 0 To txrows - 1
          coolmap(x, y) = RandomRange(-10, 10)
      Next
   Next
    
   For j = 1 To 10
      For x = 1 To txcols - 2 
         For y = 1 To txrows - 2
            coolmap(x, y) = Smooth(coolmap(), x, y)
         Next
      Next
   Next
End Sub

'Moves each particle up on the screen, with a chance of moving side to side.
Sub MoveParticles
   Dim As Integer x, y, tage, xx
   Dim As Single r
    
   For x = 0 To txcols - 1
      For y = 1 To txrows - 1
         'Get the current age of the particle.
         tage = fire(x, y) 
         'Moves particle left (-1) or right (1) or keeps it in current column (0). 
         xx = RandomRange(-1, 1) + x
         'Wrap around the screen.
         If xx < 0 Then xx = txcols - 1
         If xx > txcols - 1 Then xx = 0
         'Set the particle age.
         tage += coolmap(xx, y - 1) + 1
         'Make sure the age is in range.         
         If tage < 0 Then tage = 0
         If tage > (maxage - 1) Then tage = maxage - 1
         fire(xx, y - 1) = tage
      Next
   Next
                    
End Sub

'Adds particles to the fire along bottom of screen.
Sub AddParticles
    Dim As Integer x
    
    For x= 0 To txcols - 1
        fire(x, txrows - 1) = RandomRange(0, 20)
    Next
    
End Sub

'Draws the fire or parchment on the screen.
Sub DrawScreen(egg As Integer) 
   Dim As Integer x, y, cage, tx, ty, wid = 68
   Dim As UInteger clr
   Dim As String st, tt
   
    
   ScreenLock
   MoveParticles
   AddParticles
   For x = 0 To txcols - 1
      For y = 0 To txrows - 1
         If fire(x, y) < maxage Then
            cage = Smooth(fire(), x, y)
            cage += 10
            If cage > maxage Then cage = maxage
            'If background color is 0, then use fire color. 
            'clr = introback(x + y * txcols)
            'Check to see if we draw the parchment.
            If clr = &hFF000000 Then clr = pal(cage)
            'Do the easter egg.
            If egg = TRUE Then
               clr = pal(cage)
            EndIf
            Draw String (x* 8, y* 8), Chr(219), clr
         End If
      Next
   Next
   'Draw the story text.
   tx = 6 * charw
   ty = 3 * charh
   st = "Dear " & pchar.CharName & ","
   DrawStringShadow tx, ty, st
   ty += (charh * 2)
   st = "My friend and ally... Dark days are upon us and the fires of evil are threatening the beloved land. "
   st &= "The evil wizard Dolhena has escaped from her prison, the magical crystal shard in the center of the "
   st &= "Amulet of Crystal Fire. How she escaped from this prison, I do not know, but it must have required "
   st &= "great magic to accomplish. She is even now gathering an army to do battle with the good folk of the "
   st &= "land and it is only a matter of time before she overruns the weak defenses of the King. Long "
   st &= "peace, though welcome, has its own dangers."
   Do
	   tt = WordWrap(st, wid)
		DrawStringShadow tx, ty, tt
		ty += charh + 2
  	Loop Until Len(tt) = 0
   ty += charh + 2
   st = "I have been searching high and low for the Amulet and have found where she has hidden it. I thank the "
   st &= "great wizard Mancietus for his foresight in making the Amulet indestructible by any means, even magic. "
   st &= "This gives us a ray of hope in this bleak time. "
  	Do
	   tt = WordWrap(st, wid)
		DrawStringShadow tx, ty, tt
		ty += charh + 2
  	Loop Until Len(tt) = 0
   ty += charh + 2
   st = "My friend, you are the greatest of the warriors, and I must ask you to lay your life on the line for "
   st &= "the fair land. The Amulet of Crystal Fire is located on the bottom floor of the Dungeon of Doom. I ask "
   st &= "you to retrieve the Amulet while I help gather our forces for the coming battle. Bring it to me so "
   st &= "that I may once again put Dolhena back into her prison where she belongs. I know I ask for all that you " 
   st &= "have, but I also know that you would gladly give it even if I had not asked."
  	Do
	   tt = WordWrap(st, wid)
		DrawStringShadow tx, ty, tt
		ty += charh + 2
  	Loop Until Len(tt) = 0
   ty += charh + 2
   st = "God speed my friend. The fate of the land rests on your sword arm."
  	Do
	   tt = WordWrap(st, wid)
		DrawStringShadow tx, ty, tt
		ty += charh + 2
  	Loop Until Len(tt) = 0
   ty += charh + 2
   st = "Your friend and ally, Sylvanus."
  	Do
	   tt = WordWrap(st, wid)
		DrawStringShadow tx, ty, tt
		ty += charh + 2
  	Loop Until Len(tt) = 0
      
   ScreenUnLock
End Sub

'Executes the game intro.
Sub DoIntro()
	Dim As Single t
   Dim As String eg
   Dim As Integer doegg = FALSE
   
   CreateCoolMap
   Do
      eg = InKey
      If eg = "f" Then
         doegg = Not doegg
         eg = ""
      EndIf
      t = Timer
      'Draws the screen.
      DrawScreen doegg
	   Do While (Timer - t) < FD 
		   Sleep 1
	   Loop
   Loop Until eg <> "" 
   ClearKeys
End Sub
   
End Namespace

        