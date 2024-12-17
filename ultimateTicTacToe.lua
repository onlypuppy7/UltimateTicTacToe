platform.apilevel = '2.2'
-- (c) onlypuppy7/chalex0 2023
--This code has been indented in places where it may not look necessary, this is in order to be able to collapse entire code categories in IDEs such as VSCode. Indents do not affect syntax in Lua :>

--------------------------
--------FUNCTIONS---------
--------------------------

    function timer2rainbow(gc, hue, speed, lightness)
        local saturation=0.7
        local chroma = (1 - math.abs(2 * lightness - 1)) * saturation
        local h = ((hue*speed)%360)/60
        local x =(1 - math.abs(h % 2 - 1)) * chroma
        local r, g, b = 0, 0, 0
        if h < 1 then     r,g,b=chroma,x,0
        elseif h < 2 then r,g,b=x,chroma,0
        elseif h < 3 then r,g,b=0,chroma,x
        elseif h < 4 then r,g,b=0,x,chroma
        elseif h < 5 then r,g,b=x,0,chroma
        else r,g,b=chroma,0,x
        end
        local m = lightness - chroma/2
        setColorRGB(gc,255-0.2*((r+m)*255),255-0.2*((g+m)*255),255-0.2*((b+m)*255))
    end

    function setColorRGB(gc,r,g,b)
        local function limit(n) return math.max(0,math.min(255,n+(brightness*(255-n)))) end
        gc:setColorRGB(limit(r*(1-darkness)),limit(g*(1-darkness)),limit(b*(1-darkness)))
    end

    function drawString(gc,text,x,y,align)
        if align=="center" or align=="centre" then
            align=-gc:getStringWidth(text)/2
        elseif align=="right" then
            align=-gc:getStringWidth(text)
        else
            align=0
        end
        gc:drawString(text,x+align,y,"top")
    end

--------------------------
----------BOARD-----------
--------------------------

    function resetBoard()
        boards={}
        for i=1,9 do
            boards[i]={
                {{0,0},{0,0},{0,0}},{{0,0},{0,0},{0,0}},{{0,0},{0,0},{0,0}} --board 1, each table is a row, then each table in that is a cell in that row left to right, then the table for the cell is {1/2 for O/X, 1/2 for player 1/2}
            }
        end
        selectedBoard=1 currentPlayer=2 darkness=0
        nextTurn() moves=0 paused=false
    end

    function getCell(x,y)
        return boards[selectedBoard][y][x]
    end

    function place(x,y)
        if getCell(x,y)[1]~=0 then return false end
        if playerTypes[currentPlayer]~="Human" or confirmMove then
            boards[selectedBoard][y][x]={currentPlayer,currentPlayer}
            nextTurn()
        else
            confirmMove={x,y}
    end end

    function nextTurn()
        currentPlayer=3-currentPlayer confirmMove=nil moves=moves+1
        boards[selectedBoard].state=checkState(boards[selectedBoard])
        if boards[selectedBoard].state[1]~="Ongoing" then
            darkness=0.75 paused=true
    end end

--------------------------
--------ANALYSING---------
--------------------------

    function checkState(board)
        for i=1,3 do
            if board[i][1][1]~=0 and board[i][1][1]==board[i][2][1] and board[i][2][1]==board[i][3][1] then
                return {"Won",board[i][1][1],{0.02,(i/3)-1/6},{0.98,(i/3)-1/6}} --rows
        end end
        for i=1,3 do
            if board[1][i][1]~=0 and board[1][i][1]==board[2][i][1] and board[2][i][1]==board[3][i][1] then
                return {"Won",board[1][i][1],{(i/3)-1/6,0.02},{(i/3)-1/6,0.98}} --columns
        end end
        if board[1][1][1]~=0 and board[1][1][1]==board[2][2][1] and board[2][2][1]==board[3][3][1] then
            return {"Won",board[1][1][1],{0.02,0.02},{0.98,0.98}} --diagonal top left to bottom right
        end
        if board[1][3][1]~=0 and board[1][3][1]==board[2][2][1] and board[2][2][1]==board[3][1][1] then
            return {"Won",board[1][3][1],{0.98,0.02},{0.02,0.98}} --diagonal bottom left to top right
        end
        for i=1,3 do --check for draw
            for j=1,3 do
                if board[i][j][1]==0 then
                    return {"Ongoing"} --not a draw
        end end end
        return {"Drawn"}
    end

    function calculateBestMove(boardID,maxDepth)
        local function minimax(board,depth,isMaximizingPlayer)
            local state=checkState(board)
            if state[1]=="Won" then
                if state[2]==1 then       return -10+depth,nil
                else                      return  10-depth,nil end
            elseif state[1]=="Drawn" then return   0      ,nil end
            if depth==maxDepth       then return   0      ,nil end
            local bestScore, bestMove
            if isMaximizingPlayer then
                bestScore=-math.huge
                for i=1,3 do
                    for j=1,3 do
                        if board[j][i][1]==0 then
                            board[j][i][1]=2
                            local score=minimax(board,depth+1,false)
                            board[j][i][1]=0
                            if score>bestScore then
                                bestScore=score
                                bestMove={i,j}
                end end end end
            else
                bestScore=math.huge
                for i=1,3 do
                    for j =1,3 do
                        if board[j][i][1]==0 then
                            board[j][i][1]=1
                            local score=minimax(board,depth+1,true)
                            board[j][i][1]=0
                            if score<bestScore then
                                bestScore=score
                                bestMove={i,j}
            end end end end end
            return bestScore,bestMove
        end
        local _,bestMove=minimax(boards[boardID],0,true)
        return bestMove
    end

--------------------------
---------DRAWING----------
--------------------------

    function drawBackground(gc)
        setColorRGB(gc,255,255,255)
        gc:fillRect(0,0,318,212)
        local blink=math.abs((framesPassed%40)-20)
        setColorRGB(gc,219+blink,218+blink,219+blink)
        local offset=framesPassed%53
        for j=-53,212,53 do
            if background==1 then timer2rainbow(gc,framesPassed-0.003*(53+j),7,0.5+0.0008*(53+j)) end
            for i=-53,318,53 do
                gc:fillRect(i+offset,j+offset,26,26)
                gc:fillRect(i+offset+27,j+offset+27,26,26)
            end
        end
    end

    function drawSideWindow(gc)
        local windowLength=3
        local function drawWindow(height,TYPE)
            setColorRGB(gc,0,0,0)
            gc:fillRect(2,windowLength,97,height+4)
            setColorRGB(gc,240,240,170)
            gc:fillRect(4,2+windowLength,93,height)
            if TYPE=="player" then
                setColorRGB(gc,unpack(playerColour[currentPlayer]))
                gc:setFont("serif","bi",10)
                drawString(gc,"Turn: Player "..currentPlayer,51,windowLength,"centre")
            elseif TYPE=="mode" then
                setColorRGB(gc,0,0,0)
                gc:setFont("sansserif","r",10)
                drawString(gc,currentGameType,51,windowLength,"centre")
            elseif TYPE=="vs" then
                setColorRGB(gc,0,0,0)
                gc:setFont("serif","r",9)
                local function f(n) n=playerTypes[n] return string.sub(n,#n-2,#n)=="CPU" and "CPU" or n end
                drawString(gc,f(1).." vs. "..f(2),51,1+windowLength,"centre")
            elseif TYPE=="confirm" then
                setColorRGB(gc,0,0,0)
                gc:setFont("serif","b",9)
                drawString(gc,"Confirm move?",51,windowLength,"centre")
            end
            windowLength=windowLength+height+6
        end
        drawWindow(16,"mode")
        drawWindow(16,"player")
        drawWindow(16,"vs")
        -- drawWindow(16,"tabreminder")
        if confirmMove then drawWindow(16,"confirm") end
    end
    
    function drawBoard(gc,boardID,x,y,size) --xy are centre coordinates
        local board=boards[boardID]
        local thicknesses={"thin","medium","thick","extra-thick"}
        local function getPenThickness()
            if     size<=50  then return 1
            elseif size<=100 then return 2
            else                  return 3
            end
        end
        gc:setPen(thicknesses[getPenThickness()],"smooth")
        setColorRGB(gc,0,0,0)
        x,y=x-size/2,y-size/2 --convert to top left coordinates
        for i=1,2 do
            gc:drawLine(x+i*size/3,y,x+i*size/3,y+size)
            gc:drawLine(x,y+i*size/3,x+size,y+i*size/3)
        end
        for i=1,3 do
            for j=1,3 do
                local showConfirm="smooth"
                if confirmMove and confirmMove[1]==j and confirmMove[2]==i then showConfirm="dotted" end
                if board[i][j][1]~=0 or showConfirm=="dotted" then
                    setColorRGB(gc,unpack(playerColour[showConfirm=="dotted" and currentPlayer or board[i][j][2]]))
                    gc:setPen(thicknesses[getPenThickness()],showConfirm)
                    local noughtCross=(showConfirm=="dotted") and currentPlayer or board[i][j][1]
                    if noughtCross==noughtsCrosses then --draw cross
                        gc:drawLine(x+(j-1)*size/3+size/3.5, y+(i-1)*size/3+size/3.5, x+j*size/3-size/3.5, y+i*size/3-size/3.5)
                        gc:drawLine(x+j*size/3-size/3.5, y+(i-1)*size/3+size/3.5, x+(j-1)*size/3+size/3.5, y+i*size/3-size/3.5)
                    elseif noughtCross==3-noughtsCrosses then --draw nought
                        gc:drawArc((x+(j-1)*size/3)+size/24,(y+(i-1)*size/3)+size/24,size/4,size/4,0,360)
                    end
                end
            end
        end
        if board.state[1]=="Won" then
            setColorRGB(gc,unpack(playerColour[board.state[2]]))
            gc:setPen(thicknesses[getPenThickness()+1],"smooth")
            gc:drawLine(x+board.state[3][1]*size,y+board.state[3][2]*size,x+board.state[4][1]*size,y+board.state[4][2]*size)
        end
    end

    function drawMenu(gc)
        setColorRGB(gc,0,0,0)
        if currentMode[2]=="startup" then
            gc:setFont("serif","b",19)
            drawString(gc,"ULTIMATE",math.min(8*framesPassed-100,318/2),212/2-40,"centre")
            drawString(gc,"TIC-TAC-TOE",math.max(418-8*framesPassed,318/2),212/2-10,"centre")
            if framesPassed>=55 then started=true
                if framesPassed<75 then brightness=brightness-0.1 end
                if (framesPassed%20)>5 then
                    setColorRGB(gc,0,0,0)
                    gc:setFont("sansserif","i",10)
                    drawString(gc,"Press any key to continue",318/2,212/2+40,"centre")
                end
            elseif framesPassed>=35 then brightness=brightness+0.1 end
        elseif currentMode[2]=="home" then
            gc:setFont("sansserif","b",13)
            drawString(gc,"Select Your Options",318/2,10,"centre")
            gc:setFont("sansserif","r",15)
            drawString(gc,"1:",40,45,"right")
            drawString(gc,currentGameType,318/2,45,"centre")
            gc:drawLine(60,80,318-60,80)
            drawString(gc,"2:",40,80,"right")
            drawString(gc,playerTypes[1],318/2,80,"centre")
            drawString(gc,"vs.",318/2,100,"centre")
            drawString(gc,"3:",40,120,"right")
            drawString(gc,playerTypes[2],318/2,120,"centre")
            gc:setFont("sansserif","i",8)
            drawString(gc,"Press [tab] for settings",318/2,150,"centre")
            if (framesPassed%20)>5 then
                gc:setFont("sansserif","r",10)
                drawString(gc,"Play [enter]",318/2,212/2+70,"centre")
            end
        elseif currentMode[2]=="setmode" then
            gc:setFont("sansserif","b",13)
            drawString(gc,"Select Game Type",318/2,10,"centre")
        elseif string.sub(currentMode[2],1,9)=="setplayer" then
            gc:setFont("sansserif","b",13)
            drawString(gc,"Select Player "..string.sub(currentMode[2],10,10).." Type",318/2,10,"centre")
            gc:setFont("sansserif","r",15)
            drawString(gc,"1:",40,45,"right")
            drawString(gc,"Human",318/2,45,"centre")
            gc:drawLine(60,80,318-60,80)
            drawString(gc,"2:",40,80,"right")
            drawString(gc,"Easy CPU",318/2,80,"centre")
            drawString(gc,"3:",40,100,"right")
            drawString(gc,"Medium CPU",318/2,100,"centre")
            drawString(gc,"4:",40,120,"right")
            drawString(gc,"Hard CPU",318/2,120,"centre")
        elseif currentMode[2]=="settings" then
            gc:setFont("sansserif","b",13)
            drawString(gc,"Choose Settings",318/2,10,"centre")
            gc:setFont("sansserif","r",15)
            drawString(gc,"1:",40,45,"right")
            drawString(gc,"Change Background",318/2,45,"centre")
            drawString(gc,"2:",40,65,"right")
            drawString(gc,noughtsCrosses==1 and "Crosses/Noughts" or "Noughts/Crosses",318/2,65,"centre")
            drawString(gc,"3:",40,85,"right")
            setColorRGB(gc,unpack(playerColour[1]))
            drawString(gc,"Player 1",(318/2)-5,85,"right")
            setColorRGB(gc,unpack(playerColour[2]))
            drawString(gc,"Player 2",(318/2)+5,85,"left")
            setColorRGB(gc,0,0,0)
        end
    end

    function drawMisc(gc)
        if paused then
            darkness=0.75
            gc:setFont("serif","b",18)
            gc:setColorRGB(255,255,255)
            local status=boards[selectedBoard].state
            if status[1]=="Ongoing" then
                drawString(gc,"PAUSED",(318/2),75,"centre")
            elseif status[1]=="Won" then
                drawString(gc,"PLAYER "..status[2].." WINS!",(318/2),75,"centre")
            elseif status[1]=="Drawn" then
                drawString(gc,"DRAW",(318/2),75,"centre")
            end
            gc:setFont("sansserif","i",10)
            if status[1]=="Ongoing" then
                drawString(gc,"[esc]",(318/2)-29,115,"right")
                drawString(gc,"Return to game",(318/2)-15,115,"left")
            end
            drawString(gc,"[tab]",(318/2)-30,130,"right")
            drawString(gc,"Reset board",(318/2)-15,130,"left")
            drawString(gc,"[enter]",(318/2)-31,145,"right")
            drawString(gc,"Exit",(318/2)-15,145,"left")
        end
    end

--------------------------
-------EVENTS+LOOPS-------
--------------------------

    function on.paint(gc)
        framesPassed=framesPassed+2
        if currentMode[1]=="playing" then
            drawBackground(gc)
            drawBoard(gc,1,318/2+50,212/2,200)
            drawSideWindow(gc)
            drawMisc(gc)
            gameLogic()
        elseif currentMode[1]=="menu" then
            if started then drawBackground(gc) end
            drawMenu(gc)
        end
    end

    function gameLogic()
        if playerTypes[currentPlayer]~="Human" and boards[selectedBoard].state[1]=="Ongoing" and framesPassed%12==0 then
            local difficulty=playerTypes[currentPlayer]=="Medium CPU" and 2 or nil
            if moves<=1 or playerTypes[currentPlayer]=="Easy CPU" then
                local x,y=math.random(1,3),math.random(1,3)
                while getCell(x,y)[1]~=0 do
                    x,y=math.random(1,3),math.random(1,3)
                end
                place(x,y)
            else
                place(unpack(calculateBestMove(selectedBoard,difficulty)))
            end
        end
    end

    function on.charIn(char)
        if started then
            if currentMode[1]=="menu" then
                if currentMode[2]=="startup" then
                    currentMode={"menu","home"} brightness=0
                elseif currentMode[2]=="home" then
                    if     char=="1" then currentMode={"menu","setmode"} --could optimise but why
                    elseif char=="2" then currentMode={"menu","setplayer1"}
                    elseif char=="3" then currentMode={"menu","setplayer2"}
                    elseif char=="tab" then currentMode={"menu","settings"}
                    elseif char=="enter" then currentMode={"playing"} resetBoard()
                    elseif char=="escape" then currentMode={"menu","startup"}
                        framesPassed=0 started=nil
                    end
                elseif currentMode[2]=="setmode" then
                    if char=="escape" then currentMode={"menu","home"}
                    end
                elseif string.sub(currentMode[2],1,9)=="setplayer" then
                    local player=tonumber(string.sub(currentMode[2],10,10))
                    if char=="escape" then currentMode={"menu","home"}
                    elseif char=="1" then playerTypes[player]="Human" currentMode={"menu","home"}
                    elseif char=="2" then playerTypes[player]="Easy CPU" currentMode={"menu","home"}
                    elseif char=="3" then playerTypes[player]="Medium CPU" currentMode={"menu","home"}
                    elseif char=="4" then playerTypes[player]="Hard CPU" currentMode={"menu","home"}
                    end
                elseif string.sub(currentMode[2],1,9)=="settings" then
                    if char=="escape" then currentMode={"menu","home"}
                    elseif char=="1" then background=3-background
                    elseif char=="2" then noughtsCrosses=3-noughtsCrosses
                    elseif char=="3" then currentColour=(currentColour%#colours)+1 playerColour=colours[currentColour]
                    end
                end
            elseif currentMode[1]=="playing" then
                if paused then
                    if char=="enter" then currentMode={"menu","home"} paused=false darkness=0
                    elseif char=="escape" and boards[selectedBoard].state[1]=="Ongoing" then paused=false darkness=0
                    elseif char=="tab" then resetBoard()
                    end
                elseif char=="enter" then
                    if confirmMove then
                        place(unpack(confirmMove))
                        confirmMove=nil
                    end
                elseif char=="escape" then
                    if confirmMove then confirmMove=nil
                    else paused=true darkness=0.75 end
                else
                    if (not confirmMove) and (not paused) and playerTypes[currentPlayer]=="Human" then
                        if     char=="1" then place(1,3) --could optimise but why
                        elseif char=="2" then place(2,3)
                        elseif char=="3" then place(3,3)
                        elseif char=="4" then place(1,2)
                        elseif char=="5" then place(2,2)
                        elseif char=="6" then place(3,2)
                        elseif char=="7" then place(1,1)
                        elseif char=="8" then place(2,1)
                        elseif char=="9" then place(3,1)
                        end
                    end
                end
            end
        end
    end

    function on.enterKey() on.charIn("enter") end
    function on.tabKey() on.charIn("tab") end
    function on.escapeKey() on.charIn("escape") end

    function on.timer() platform.window:invalidate() end

--------------------------
----------STARTUP--------
--------------------------

    timer.start(0.1) 
    framesPassed=0 darkness=0 brightness=0 background=1 moves=0 resetBoard()
    currentColour=1 colours={{{0,0,255},{255,0,0}},{{255,0,0},{0,0,255}},{{0,255,255},{255,255,0}},{{255,0,255},{0,255,0}}}
    playerColour=colours[currentColour]
    playerTypes={"Human","Hard CPU"}
    currentGameType="Classic"
    currentMode={"menu","startup"}
    noughtsCrosses=1