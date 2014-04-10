'****************************************************************************
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
'Size of the map.
#Define mapw 100
#Define maph 100
'Min and max room dimensions
#Define roommax 8 
#Define roommin 4
#Define nroommin 20
#Define nroommax 50 
'Empty cell flag.
#Define emptycell 0
'Viewport width and height.
#Define vw 40 
#Define vh 55 
'Grid cell size (width and height)
#Define csizeh 10
#Define csizew 10
'Grid dimensions.
Const gw = mapw \ csizew
Const gh = maph \ csizeh

'The types of terrain in the map.
Enum terrainids
   tfloor = 0  'Walkable terrain.
   twall       'Impassable terrain.
   tdooropen   'Open door.
   tdoorclosed 'Closed door.
   tstairup    'Stairs up.
   tstairdn   'Stairs down.
End Enum

'Room dimensions.
Type rmdim
	rwidth As Integer
	rheight As Integer
	rcoord As mcoord
End Type

'Room information
Type roomtype
	roomdim As rmdim  'Room width and height.
	tl As mcoord      'Room rect
	br As mcoord
	secret As Integer         
End Type

'Grid cell structure.
Type celltype
	cellcoord As mcoord 'The cell position.
	Room As Integer     'Room id. This is an index into the room array.
End Type

'Door type.
Type doortype
    locked As Integer   'TRUE if locked.
    lockdr As Integer   'Lockpick difficulty.
    dstr As Integer     'Strength of door (for bashing)
End Type

'Map info type
Type mapinfotype
	terrid As terrainids  'The terrain type.
	hasmonster As Integer 'Current cell has a monster in it.
	hasitem As Integer    'Current cell has an item in it.
	monidx As Integer     'Index into monster array.
	visible As Integer    'Character can see cell.
	seen As Integer       'Character has seen cell.
    doorinfo As doortype  'Door information.
End Type

'Dungeon level information.
Type levelinfo
   numlevel As Integer 'Current level number.
   lmap(1 To mapw, 1 To maph) As mapinfotype 'Map array.
End Type

'Dungeon level object.
Type levelobj
   Private:
   _level As levelinfo                 'The level map structure.
   _numrooms As Integer                'The number of rooms in the level.
   _mcoord As mcoord
   _rooms(1 To nroommax) As roomtype   'Room information.
   _grid(1 To gw, 1 To gh) As celltype 'Grid infromation.
   _blockingtiles As Integer Ptr       'Set of blocking tiles.
   _blocktilecnt As Integer            'Number of blocking tiles.
   Declare Function _BlockingTile(tx As Integer, ty As Integer) As Integer 'Returns true if blocking tile.
   Declare Function _LineOfSight(x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer) As Integer 'Returns true if line of sight to tile.
   Declare Function _CanSee(tx As Integer, ty As Integer) As Integer 'Can character see tile.
   Declare Sub _CalcLOS () 'Calculates line of sight with post processing to remove artifacts.
   Declare Function _GetMapSymbol(tile As terrainids) As String 'Returns the ascii symbol for terrian id.
   Declare Function _GetMapSymbolColor(tile As terrainids) As UInteger
   Declare Sub _InitGrid() 'Inits the grid.
   Declare Sub _ConnectRooms( r1 As Integer, r2 As Integer) 'Connects rooms.
   Declare Sub _AddDoorsToRoom(i As Integer) 'Adds doors to a room.
   Declare Sub _AddDoors() 'Iterates through all rooms adding doors to each room.
   Declare Sub _DrawMapToArray() 'Transfers room data to map array. 
   Public:
   Declare Constructor ()
   Declare Destructor ()
   Declare Property LevelID(lvl As Integer) 'Sets the current level.
   Declare Property LevelID() As Integer 'Returns the current level number.
   Declare Sub DrawMap () 'Draws the map on the screen.
   Declare Sub GenerateDungeonLevel() 'Generates a new dungeon level.
   Declare Sub SetTile(x As Integer, y As Integer, tileid As terrainids) 'Sets the tile at x, y of map.
   Declare Function IsBlocking(x As Integer, y As Integer) As Integer 'Returns TRUE if tile at x, y is blocking.
   Declare Function GetTileID(x As Integer, y As Integer) As terrainids 'Returns the tile id at x, y.
   Declare Function IsDoorLocked(x As Integer, y As Integer) As Integer 'Returns TRUE if a door is locked.
End Type

'Initlaizes object.
Constructor levelobj ()
   'Set the number of blocking tiles.
   _blocktilecnt = 3
   'Set up block tile list.
   _blockingtiles = Callocate(_blocktilecnt * SizeOf(Integer))
   'Add blocking tiles to list.
   _blockingtiles[0] = twall
   _blockingtiles[1] = tdoorclosed
   _blockingtiles[2] = tstairup
End Constructor

'Cleans up object.
Destructor levelobj ()
   If _blockingtiles <> NULL Then
      DeAllocate _blockingtiles
      _blockingtiles = NULL
   EndIf
End Destructor

'Sets the current level.
Property levelobj.LevelID(lvl As Integer)
   _level.numlevel = lvl
End Property

'Returns the current level number.
Property levelobj.LevelID() As Integer
   Return _level.numlevel
End Property

'Returns True if tile is blocking tile.
Function levelobj._BlockingTile(tx As Integer, ty As Integer) As Integer
   Dim ret As Integer = FALSE
   Dim tid As terrainids = _level.lmap(tx, ty).terrid
   
   'If tile contains a monster it is blocking.
   If _level.lmap(tx, ty).hasmonster = TRUE Then
      ret = TRUE
   Else
      'Make sure the pointer was initialzed.
      If _blockingtiles <> NULL Then
         'Look for the current tile in the list.
         For i As Integer = 0 To _blocktilecnt - 1
            'Found it so must be blocking.
            If _blockingtiles[i] = tid Then
               ret = TRUE
               Exit For
            EndIf
         Next
      End If
   EndIf
    Return ret
End Function

'Bresenhams line algo
Function levelobj._LineOfSight(x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer) As Integer
    Dim As Integer i, deltax, deltay, numtiles
    Dim As Integer d, dinc1, dinc2
    Dim As Integer x, xinc1, xinc2
    Dim As Integer y, yinc1, yinc2
    Dim isseen As Integer = TRUE
    
    deltax = Abs(x2 - x1)
    deltay = Abs(y2 - y1)

    If deltax >= deltay Then
        numtiles = deltax + 1
        d = (2 * deltay) - deltax
        dinc1 = deltay Shl 1
        dinc2 = (deltay - deltax) Shl 1
        xinc1 = 1
        xinc2 = 1
        yinc1 = 0
        yinc2 = 1
    Else
        numtiles = deltay + 1
        d = (2 * deltax) - deltay
        dinc1 = deltax Shl 1
        dinc2 = (deltax - deltay) Shl 1
        xinc1 = 0
        xinc2 = 1
        yinc1 = 1
        yinc2 = 1
    End If

    If x1 > x2 Then
        xinc1 = - xinc1
        xinc2 = - xinc2
    End If
    
    If y1 > y2 Then
        yinc1 = - yinc1
        yinc2 = - yinc2
    End If

    x = x1
    y = y1
    
    For i = 2 To numtiles
      If _BlockingTile(x, y) Then
        isseen = FALSE
        Exit For
      End If
      If d < 0 Then
          d = d + dinc1
          x = x + xinc1
          y = y + yinc1
      Else
          d = d + dinc2
          x = x + xinc2
          y = y + yinc2
        End If
    Next
    
    Return isseen
End Function

'Determines if player can see object.
Function levelobj._CanSee(tx As Integer, ty As Integer) As Integer
   Dim As Integer ret = FALSE, px = pchar.Locx, py = pchar.Locy
   Dim As Integer dist
        
	dist = CalcDist(pchar.Locx, tx, pchar.Locy, ty)
	If dist <= vh Then
   	ret = _LineOfSight(tx, ty, px, py)
	End If
    
   Return ret
End Function

'Caclulate los with post processing.
Sub levelobj._CalcLOS ()
	Dim As Integer i, j, x, y, w = vw / 2, h = vh / 2
	Dim As Integer x1, x2, y1, y2
	
	'Clear the vismap
	For i = 1 To mapw
   	For j = 1 To maph
   		_level.lmap(i, j).visible = FALSE
   	Next
	Next
	'Only check within viewport
	x1 = pchar.Locx - w
	If x1 < 1 Then x1 = 1
	y1 = pchar.Locy - h
	If y1 < 1 Then y1 = 1
	
	x2 = pchar.Locx + w
	If x2 > mapw - 1 Then x2 = mapw - 1
	y2 = pchar.Locy + h
	If y2 > maph - 1 Then y2 = maph - 1
	'iterate through vision area
	For i = x1 To x2
		For j = y1 To y2
	   	'Don't recalc seen tiles
	      If _level.lmap(i, j).visible = FALSE Then
	         If _CanSee(i, j) = TRUE Then
	         	_level.lmap(i, j).visible = TRUE
	         	_level.lmap(i, j).seen = TRUE
	         End If
	      End If
	  Next
	Next
	'Post process the map to remove artifacts.
	For i = x1 To x2
		For j = y1 To y2
			If (_BlockingTile(i, j) = TRUE) And (_level.lmap(i, j).visible = FALSE) Then
				x = i
				y = j - 1
				If (x > 0) And (x < mapw + 1) Then
					If (y > 0) And (y < maph + 1) Then
						If (_level.lmap(x, y).terrid = tfloor) And (_level.lmap(x, y).visible = TRUE) Then
							_level.lmap(i, j).visible = TRUE
							_level.lmap(i, j).seen = TRUE
						EndIf
					EndIf
				EndIf 
				
				x = i
				y = j + 1
				If (x > 0) And (x < mapw + 1) Then
					If (y > 0) And (y < maph + 1) Then
						If (_level.lmap(x, y).terrid = tfloor) And (_level.lmap(x, y).visible = TRUE) Then
							_level.lmap(i, j).visible = TRUE
							_level.lmap(i, j).seen = TRUE
						EndIf
					EndIf
				EndIf 

				x = i + 1
				y = j
				If (x > 0) And (x < mapw + 1) Then
					If (y > 0) And (y < maph + 1) Then
						If (_level.lmap(x, y).terrid = tfloor) And (_level.lmap(x, y).visible = TRUE) Then
							_level.lmap(i, j).visible = TRUE
							_level.lmap(i, j).seen = TRUE
						EndIf
					EndIf
				EndIf 

				x = i - 1
				y = j
				If (x > 0) And (x < mapw + 1) Then
					If (y > 0) And (y < maph + 1) Then
						If (_level.lmap(x, y).terrid = tfloor) And (_level.lmap(x, y).visible = TRUE) Then
							_level.lmap(i, j).visible = TRUE
							_level.lmap(i, j).seen = TRUE
						EndIf
					EndIf
				EndIf 

				x = i - 1
				y = j - 1
				If (x > 0) And (x < mapw + 1) Then
					If (y > 0) And (y < maph + 1) Then
						If (_level.lmap(x, y).terrid = tfloor) And (_level.lmap(x, y).visible = TRUE) Then
							_level.lmap(i, j).visible = TRUE
							_level.lmap(i, j).seen = TRUE
						EndIf
					EndIf
				EndIf 

				x = i + 1
				y = j - 1
				If (x > 0) And (x < mapw + 1) Then
					If (y > 0) And (y < maph + 1) Then
						If (_level.lmap(x, y).terrid = tfloor) And (_level.lmap(x, y).visible = TRUE) Then
							_level.lmap(i, j).visible = TRUE
							_level.lmap(i, j).seen = TRUE
						EndIf
					EndIf
				EndIf 

				x = i + 1
				y = j + 1
				If (x > 0) And (x < mapw + 1) Then
					If (y > 0) And (y < maph + 1) Then
						If (_level.lmap(x, y).terrid = tfloor) And (_level.lmap(x, y).visible = TRUE) Then
							_level.lmap(i, j).visible = TRUE
							_level.lmap(i, j).seen = TRUE
						EndIf
					EndIf
				EndIf 

				x = i - 1
				y = j + 1
				If (x > 0) And (x < mapw + 1) Then
					If (y > 0) And (y < maph + 1) Then
						If (_level.lmap(x, y).terrid = tfloor) And (_level.lmap(x, y).visible = TRUE) Then
							_level.lmap(i, j).visible = TRUE
							_level.lmap(i, j).seen = TRUE
						EndIf
					EndIf
				EndIf
				
			EndIf 
		Next
	Next
End Sub

'Return ascii symbol for tile
Function levelobj._GetMapSymbol(tile As terrainids) As String
	Dim As String ret
	
   Select Case tile
   	Case twall
   		ret = "#"
   	Case tfloor
   		ret = "."
      Case tstairup
   		ret = "<"
      Case tstairdn
   		ret = ">"
   	Case tdooropen
   		ret = "'"
   	Case tdoorclosed
   		ret = "\"
   	Case Else
            ret = "?"
   End Select
   
   Return ret
End Function

'Returns the color for object.
Function levelobj._GetMapSymbolColor(tile As terrainids) As UInteger
	Dim ret As UInteger
	
   Select Case tile
   	Case twall
   		ret = fbTan
      Case tfloor
   		ret = fbWhite
      Case tstairup
   		ret = fbYellow
      Case tstairdn
   		ret = fbYellow
   	Case tdooropen
   		ret = fbTan
   	Case tdoorclosed
   		ret = fbSienna
      Case Else
         ret = fbWhite
   End Select
   
   Return ret
End Function

'Draws the map on the screen.
Sub levelobj.DrawMap ()
   Dim As Integer i, j, w = vw, h = vh, x, y, px, py, pct
   Dim As UInteger tilecolor, bcolor
   Dim As String mtile
   Dim As terrainids tile
   
	_CalcLOS
	'Get the view coords
	i = pchar.Locx - (w / 2)
	j = pchar.Locy - (h / 2)
	If i < 1 Then i = 1
	If j < 1 Then j = 1
	If i + w > mapw Then i = mapw - w
	If j + h > mapw Then j = mapw - h
	'Draw the visible portion of the map.
	 For x = 1 To w
	     For y = 1 To h
	        'Clears current location to black.
	     		tilecolor = fbBlack 
	     		PutText acBlock, y, x, tilecolor
	     		'Print the tile.
	         If _level.lmap(i + x, j + y).visible = True Then
     			   'Get tile id
     			   tile = _level.lmap(i + x, j + y).terrid
        		   'Get the tile symbol
         	   mtile = _GetMapSymbol(tile)
         	   'Get the tile color
         	   tilecolor = _GetMapSymbolColor(tile)
		         'Print the item marker.
		         If _level.lmap(i + x, j + y).hasitem = True Then
		         	'Item info here.
		         EndIf
	            PutText mtile, y, x, tilecolor
		         'If the current location has a monster print that monster.
		         If _level.lmap(i + x, j + y).hasmonster = TRUE Then
		         	'Put monster info here.
		         EndIf
	         Else
	         	'Not in los.
	         	If _level.lmap(i + x, j + y).seen = TRUE Then
	         		If _level.lmap(i + x, j + y).hasitem = True Then
	         			PutText "?", y, x, fbSlateGrayDark
	         		Else
	            		PutText mtile, y, x, fbSlateGrayDark
	         		End If
	         	End If
	         End If
	     Next 
	 Next
   'Draw the player
	px = pchar.Locx - i
	py = pchar.Locy - j
	pct = Int((pchar.CurrHP / pchar.MaxHP) * 100) 
	If pct > 74 Then
		PutText acBlock, py, px, fbBlack
		PutText "@", py, px, fbGreen
	ElseIf (pct > 24) AndAlso (pct < 75) Then
		PutText acBlock, py, px, fbBlack
		PutText "@", py, px, fbYellow
	Else
		PutText acBlock, py, px, fbBlack
		PutText "@", py, px, fbRed
	EndIf

End Sub

'Init the grid and room arrays
Sub levelobj._InitGrid()
   Dim As Integer i, j, x, y, gx = 1, gy = 1
	
	'Clear room array.		
   For i = 1 To nroommax
   	_rooms(i).roomdim.rwidth = 0
   	_rooms(i).roomdim.rheight = 0
   	_rooms(i).roomdim.rcoord.x = 0
   	_rooms(i).roomdim.rcoord.y = 0
   	_rooms(i).tl.x = 0
   	_rooms(i).tl.y = 0
   	_rooms(i).br.x = 0
   	_rooms(i).br.y = 0
   Next 
   'How many rooms
   _numrooms = RandomRange(nroommin, nroommax)
   'Build some rooms
   For i = 1 To _numrooms
   	_rooms(i).roomdim.rwidth = RandomRange(roommin, roommax)
    	_rooms(i).roomdim.rheight = RandomRange(roommin, roommax)
   Next
    'Clear the grid array
   For i = 1 To gw 
   	For j = 1 To gh
    		_grid(i, j).cellcoord.x = gx
    		_grid(i, j).cellcoord.y = gy
     		_grid(i, j).Room = emptycell
     		gy += csizeh
   	Next
   	gy = 1
   	gx += csizew
   Next
	'Add rooms to the grid
   For i = 1 To _numrooms
   	'Find an empty spot in the grid
   	Do
   		x = RandomRange(2, gw - 1)
   		y = RandomRange(2, gh - 1)
   	Loop Until _grid(x, y).Room = emptycell
   	'Room center
   	_rooms(i).roomdim.rcoord.x = _grid(x, y).cellcoord.x + (_rooms(i).roomdim.rwidth \ 2)   
   	_rooms(i).roomdim.rcoord.y = _grid(x, y).cellcoord.y + (_rooms(i).roomdim.rheight \ 2)
		'Set the room rect
		_rooms(i).tl.x = _grid(x, y).cellcoord.x 
		_rooms(i).tl.y = _grid(x, y).cellcoord.y 
		_rooms(i).br.x = _grid(x, y).cellcoord.x + _rooms(i).roomdim.rwidth + 1
		_rooms(i).br.y = _grid(x, y).cellcoord.y + _rooms(i).roomdim.rheight + 1
   	'Save the room index
   	_grid(x, y).Room = i
   Next
End Sub 

'Connect all the rooms.
Sub levelobj._ConnectRooms( r1 As Integer, r2 As Integer)
	Dim As Integer idx, x, y
	Dim As mcoord currcell, lastcell
	Dim As Integer wflag
	
	currcell = _rooms(r1).roomdim.rcoord
	lastcell = _rooms(r2).roomdim.rcoord
		
	x = currcell.x
	If x < lastcell.x Then
		wflag = FALSE
		Do
			x += 1
			If _level.lmap(x, currcell.y).terrid = twall Then wflag = TRUE
			If (_level.lmap(x, currcell.y).terrid = tfloor) And (wflag = TRUE) Then
				Exit Sub
			EndIf
			_level.lmap(x, currcell.y).terrid = tfloor
		Loop Until x = lastcell.x
	End If
	
	If x > lastcell.x Then
		wflag = FALSE
		Do
			x -= 1
			If _level.lmap(x, currcell.y).terrid = twall Then wflag = TRUE
			If (_level.lmap(x, currcell.y).terrid = tfloor) And (wflag = TRUE) Then 
				Exit Sub
			EndIf
			_level.lmap(x, currcell.y).terrid = tfloor
		Loop Until x = lastcell.x
	EndIf
	
	y = currcell.y
	If y < lastcell.y Then
		wflag = FALSE
		Do
			y += 1
			If _level.lmap(x, y).terrid = twall Then wflag = TRUE
			If (_level.lmap(x, y).terrid = tfloor) And (wflag = TRUE) Then 
				Exit Sub
			EndIf
			_level.lmap(x, y).terrid = tfloor
		Loop Until y = lastcell.y
	EndIf
	
	If y > lastcell.y Then
		Do
			y -= 1
			If _level.lmap(x, y).terrid = twall Then wflag = TRUE
			If (_level.lmap(x, y).terrid = tfloor) And (wflag = TRUE) Then 
				Exit Sub
			EndIf
			_level.lmap(x, y).terrid = tfloor
		Loop Until y = lastcell.y
	EndIf
		 
End Sub

'Add doors to a room.
Sub levelobj._AddDoorsToRoom(i As Integer)
	Dim As Integer row, col, dd1, dd2
	
	'Iterate along top room.
	For col = _rooms(i).tl.x To _rooms(i).br.x
		dd1 = _rooms(i).tl.y
		dd2 = _rooms(i).br.y
		'If a floor space in the wall.
		If _level.lmap(col, dd1).terrid = tfloor Then
			'Add door.
			_level.lmap(col, dd1).terrid = tdoorclosed
            _level.lmap(col, dd1).doorinfo.locked = FALSE
            If _level.lmap(col, dd1).doorinfo.locked = TRUE Then
               _level.lmap(col, dd1).doorinfo.lockdr = 0
               _level.lmap(col, dd1).doorinfo.dstr = 0
            End If
		EndIf
		'Iterate along bottom of room.
		If _level.lmap(col, dd2).terrid = tfloor Then
			_level.lmap(col, dd2).terrid = tdoorclosed
            _level.lmap(col, dd2).doorinfo.locked = FALSE
            If _level.lmap(col, dd2).doorinfo.locked = TRUE Then
               _level.lmap(col, dd2).doorinfo.lockdr = 0
               _level.lmap(col, dd2).doorinfo.dstr = 0
            End If
		End If
	Next
	'Iterate along left side of room.
	For row = _rooms(i).tl.y To _rooms(i).br.y
		dd1 = _rooms(i).tl.x
		dd2 = _rooms(i).br.x
		If _level.lmap(dd1, row).terrid = tfloor Then
			_level.lmap(dd1, row).terrid = tdoorclosed
            _level.lmap(dd1, row).doorinfo.locked = FALSE
            If _level.lmap(dd1, row).doorinfo.locked = TRUE Then
               _level.lmap(dd1, row).doorinfo.lockdr = 0
               _level.lmap(dd1, row).doorinfo.dstr = 0
            End If
		End If
		'Iterate along right side of room.
		If _level.lmap(dd2, row).terrid = tfloor Then
			_level.lmap(dd2, row).terrid = tdoorclosed
            _level.lmap(dd2, row).doorinfo.locked = FALSE
            If _level.lmap(dd2, row).doorinfo.locked = TRUE Then
               _level.lmap(dd2, row).doorinfo.lockdr = 0
               _level.lmap(dd2, row).doorinfo.dstr = 0
            End If
		EndIf
	Next
	
End Sub

'Adds doors to rooms.
Sub levelobj._AddDoors()
    For i As Integer = 1 To _numrooms
        _AddDoorsToRoom i
    Next
End Sub

'Transfer grid data to map array.
Sub levelobj._DrawMapToArray()
	Dim As Integer i, x, y, pr, rr, rl, ru, kr
	
	'Draw the first room to map array
		For x = _rooms(1).tl.x + 1 To _rooms(1).br.x - 1
			For y = _rooms(1).tl.y + 1 To _rooms(1).br.y - 1
				_level.lmap(x, y).terrid = tfloor
			Next
		Next
	'Draw the rest of the rooms to the map array and connect them.
	For i = 2 To _numrooms
		For x = _rooms(i).tl.x + 1 To _rooms(i).br.x - 1
			For y = _rooms(i).tl.y + 1 To _rooms(i).br.y - 1
				_level.lmap(x, y).terrid = tfloor
			Next
		Next
		_ConnectRooms i, i - 1
	Next
	'Add doors to selected rooms.
	_AddDoors
	'Set up player location.
	x = _rooms(1).roomdim.rcoord.x + (_rooms(1).roomdim.rwidth \ 2) 
	y = _rooms(1).roomdim.rcoord.y + (_rooms(1).roomdim.rheight \ 2)
	pchar.Locx = x - 1
	pchar.Locy = y - 1
	'Set up the stairs up.
	_level.lmap(pchar.Locx, pchar.Locy).terrid = tstairup
	'Set up stairs down in last room.
	x = _rooms(_numrooms).roomdim.rcoord.x + (_rooms(_numrooms).roomdim.rwidth \ 2) 
	y = _rooms(_numrooms).roomdim.rcoord.y + (_rooms(_numrooms).roomdim.rheight \ 2)
	_level.lmap(x - 1, y - 1).terrid = tstairdn
End Sub

'Generate a new dungeon level.
Sub levelobj.GenerateDungeonLevel()
	Dim As Integer x, y

	'Clear level
	For x = 1 To mapw
		For y = 1 To maph
			'Set to wall tile
			_level.lmap(x, y).terrid = twall
			_level.lmap(x, y).visible = FALSE
			_level.lmap(x, y).seen = FALSE
			_level.lmap(x, y).hasmonster = FALSE
			_level.lmap(x, y).hasitem = FALSE
            _level.lmap(x, y).doorinfo.locked = FALSE
            _level.lmap(x, y).doorinfo.lockdr = 0
            _level.lmap(x, y).doorinfo.dstr = 0
		Next
	Next
	_InitGrid
	_DrawMapToArray
End Sub

'Sets the tile at x, y of map.
Sub levelobj.SetTile(x As Integer, y As Integer, tileid As terrainids)
    _level.lmap(x, y).terrid = tileid
End Sub

'Returns TRUE if tile at x, y is blocking.
Function levelobj.IsBlocking(x As Integer, y As Integer) As Integer
    Return _BlockingTile(x, y)
End Function

'Returns the tile id at x, y.
Function levelobj.GetTileID(x As Integer, y As Integer) As terrainids
    Return _level.lmap(x, y).terrid
End Function

'Returns TRUE if door is locked.
Function levelobj.IsDoorLocked(x As Integer, y As Integer) As Integer
    Return _level.lmap(x, y).doorinfo.locked
End Function

'Level variable.
Dim Shared level As levelobj
