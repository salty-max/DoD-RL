'****************************************************************************'
'*
'* Name: map.bi
'*
'* Synopsis: Map related routines.
'*
'* Description: This file contains map related routines used in the program.  
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

'Min and max room dimensions.
#Define roommax 8
#Define roommin 4
#Define nroommin 20
#Define nroommax 50

'Empty cell flag.
#Define emptycell 0

'Level size
#Define mapw 100 'Map width
#Define maph 100 'Map height

'Grid cell size (width and height)
Const csize = 10

'Grid dimensions.
Const gw = mapw \ csize
Const gh = maph \ csize

'Coordinates.
Type mcoord
    x As Integer
    y As Integer
End Type

'Room dimensions.
Type rmdim
    rwidth As Integer
    rheight As Integer
    rcoord As mcoord
End Type

'Room information.
Type roomtype
    roomdim As rmdim 'Room width and height
    tl As mcoord     'Room rect
    br As mcoord
End Type

'Grid cell structure.
Type celltype
    cellcoord As mcoord 'The cell position.
    room As Integer     'Room id. This is an index into the room array
End Type

Dim Shared rooms(1 To nroommax) As roomtype     'Room array
Dim Shared grid(1 To gw, 1 To gh) As celltype   'Grid of cells.
Dim Shared as Integer numrooms                  'Number of rooms in map.

'Init the grid and room arrays.
Sub InitGrid
    Dim As Integer i, j, x, y, gx = 1, gy = 1
    
    'Clear room array.
    For i = 1 To nroommax
        rooms(i).roomdim.rwidth = 0
        rooms(i).roomdim.rheight = 0
        rooms(i).roomdim.rcoord.x = 0
        rooms(i).roomdim.rcoord.y = 0
        rooms(i).tl.x = 0
        rooms(i).tl.y = 0
        rooms(i).br.x = 0
        rooms(i).br.y = 0
    Next
    
    'How many rooms ?
    numrooms = RandomRange(nroommin, nroommax)
    
    'Build some rooms.
    For i = 1 To numrooms
        rooms(i).roomdim.rwidth = RandomRange(roommin, roommax)
        rooms(i).roomdim.rheight = RandomRange(roommin, roommax)
    Next
    
    'Clear the grid array.
    For i = 1 To gw
        For j = 1 To gh
            grid(i, j).cellcoord.x = gx
            grid(i, j).cellcoord.y = gy
            grid(i, j).Room = emptycell
            gy += csize
        Next
        
        gy = 1
        gx += csize
    Next
    
    'Add rooms to the grid.
    For i = 1 To numrooms
        'Find an empty spot in the grid
        Do
            x = RandomRange(2, gw - 1)
            y = RandomRange(2, gh - 1)
        Loop Until grid(x, y).Room = emptycell
        
        'Room center
        rooms(i).roomdim.rcoord.x = grid(x, y).cellcoord.x + (rooms(i).roomdim.rwidth \ 2)
        rooms(i).roomdim.rcoord.y = grid(x, y).cellcoord.y + (rooms(i).roomdim.rheight \ 2)
        
        'Set the room rect.
        rooms(i).tl.x = grid(x, y).cellcoord.x
        rooms(i).tl.y = grid(x, y).cellcoord.y
        rooms(i).br.x = grid(x, y).cellcoord.x + rooms(i).roomdim.rwidth + 1
        rooms(i).br.y = grid(x, y).cellcoord.y + romms(i).roomdim.rheight + 1
        
        'Save the room index.
        grid(x, y).Room = i
    Next
End Sub

'Transfer grid data to map array.
Sub DrawMapToArray
    Dim As Integer i, x, y, pr, rr, rl, ru, kr
    
    'Draw the first room to map array.
    For x = rooms(1).tl.x + 1 To rooms(i).br.x - 1
        For y = rooms(1).tl.y + 1 To rooms(i).br.y - 1
            level.lmap(x, y).terrid = tfloor
        Next
    Next
    
    'Draw the rest of the rooms to the map array and connect them.
    For i = 2 To numrooms
        For x = rooms(i).tl.x + 1 To rooms(i).br.x - 1
            For y = rooms(i).tl.y + 1 To rooms(i).br.y - 1
                level.lmap(x, y).terrid = tfloor
            Next
        Next
        
        ConnectRooms i, i - 1
    Next
End Sub

