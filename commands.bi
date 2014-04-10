/'****************************************************************************
*
* Name: commands.bi
*
* Synopsis: Command related routines.
*
* Description: This file contains the command related subroutines and functions.  
*              
*
* Copyright 2010, Richard D. Clark
*
*                          The Wide Open License (WOL)
*
* Permission to use, copy, modify, distribute and sell this software and its
* documentation for any purpose is hereby granted without fee, provided that
* the above copyright notice and this license appear in all source copies. 
* THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY OF
* ANY KIND. See http://www.dspguru.com/wol.htm for more information.
*
*****************************************************************************'/
'Opens a closed door if not locked.
Function OpenDoor (x As Integer, y As Integer) As Integer
   Dim As Integer ret = TRUE, doorlocked
   
  'Check for locked door.
   doorlocked = level.IsDoorLocked(x, y)
   If doorlocked = FALSE Then
      'Open the door.
      level.SetTile x, y, tdooropen
   Else
      'Door is locked and cannot be opened.
      ret = FALSE
   End If
   
   Return ret
End Function

'Move the character based on the compass direction.
Function MoveChar(comp As compass) As Integer
   Dim As Integer ret = FALSE, block
   Dim As vec vc = vec(pchar.Locx, pchar.Locy) 'Creates a vector object.
   Dim As terrainids tileid
   
   vc+= comp
   'Check to make sure we don't move off map.
   If (vc.vx >= 1) And (vc.vx <= mapw) Then
      If (vc.vy >= 1) And (vc.vy <= maph) Then
         'Check for blocking tile.
         block = level.IsBlocking(vc.vx, vc.vy)
         'Move character.
         If block = FALSE Then
            'Set the new character position.
            pchar.Locx = vc.vx
            pchar.Locy = vc.vy
            ret = TRUE
         Else 'Check for special tiles.
            'Get tile id.
            tileid = level.GetTileID(vc.vx, vc.vy)
            Select Case tileid
               Case tdoorclosed 'Check for closed door.
                  ret = OpenDoor(vc.vx, vc.vy)
                  'If false then print message.
                  If ret = FALSE Then
                     'print message here.
                  Else
                     'Set the new character position.
                     pchar.Locx = vc.vx
                     pchar.Locy = vc.vy
                     ret = TRUE
                  EndIf
               Case tstairup 'Enable move onto up stairs.
                  'Set the new character position.
                  pchar.Locx = vc.vx
                  pchar.Locy = vc.vy
                  ret = TRUE
            End Select
         EndIf
      EndIf
   EndIf
   
   Return ret
End Function

