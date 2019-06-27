local FIRBoardLayer = class("FIRBoardLayer", cc.Layer)

function FIRBoardLayer:ctor()
	self:updateLayer()
    self:registerTouch()
end

function FIRBoardLayer:updateLayer()
	self.drawMap = {}
	self:removeAllChildren()
	local horNum = 15
	local verNum = 15
	local lineDis = 80
	self.horNum = horNum
	self.verNum = verNum
	self.lineDis = lineDis
	local bgWidth = (verNum+1)*lineDis
	local bgHeight = (horNum+1)*lineDis
    local bgLayer = cc.LayerColor:create(cc.c4b(213, 176, 146, 255), bgWidth, bgHeight)
    self:addChild(bgLayer)

    local draw = cc.DrawNode:create()
    self.drawNode = draw
    self:addChild(draw, 2)

    for i=1,verNum do
    	draw:drawSegment(cc.p(i*lineDis,lineDis), cc.p(i*lineDis,lineDis*verNum), 5, cc.c4f(0, 0, 0, 1))
    end

    for i=1,horNum do
    	draw:drawSegment(cc.p(lineDis,i*lineDis), cc.p(lineDis*horNum,i*lineDis), 5, cc.c4f(0, 0, 0, 1))
    end

    self.minPosX = display.width - bgWidth
    self.minPosX = math.min(0, self.minPosX)
    self.minPosY = display.height - bgHeight
    self.minPosY = math.min(0, self.minPosY)
end

function FIRBoardLayer:registerTouch()
	local function onTouchBegan(touch, event)
		self.isMoved = false
        local pos = touch:getLocation()
        self.touchBeginPos = pos
        self.beginNodePosX = self:getPositionX()
        self.beginNodePosY = self:getPositionY()
        return true
    end

    local function onTouchMoved(touch, event)
        local pos = touch:getLocation()
        local disX = pos.x - self.touchBeginPos.x
        local disY = pos.y - self.touchBeginPos.y
        if math.abs(disX) > 5 or math.abs(disY) > 5 then
        	self.isMoved = true
        end
        local newPosX = self.beginNodePosX + disX
        newPosX = math.min(0, newPosX)
        newPosX = math.max(newPosX, self.minPosX)
        local newPosY = self.beginNodePosY + disY
        newPosY = math.min(0, newPosY)
        newPosY = math.max(newPosY, self.minPosY)
        self:setPosition(newPosX, newPosY)
    end

    local function onTouchEnded(touch, event)
        if not self.isMoved then
        	local pos = touch:getLocation()
        	local touchPosX = pos.x - self:getPositionX()
        	local touchPosY = pos.y - self:getPositionY()
        	local nearIndexX = math.floor(touchPosX/self.lineDis + 0.5)
        	nearIndexX = math.max(1, nearIndexX)
        	nearIndexX = math.min(self.verNum, nearIndexX)
        	local nearIndexY = math.floor(touchPosY/self.lineDis + 0.5)
        	nearIndexY = math.max(1, nearIndexY)
        	nearIndexY = math.min(self.horNum, nearIndexY)
        	local targetX = nearIndexX*self.lineDis
			local targetY = nearIndexY*self.lineDis
			local distance = 30
			if math.abs(touchPosX-targetX) <= distance and math.abs(touchPosY-targetY) <= distance then
				if self.listener then
					self.listener:playChess(nearIndexX, nearIndexY)
				end
        	end
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function FIRBoardLayer:drawChess(indexX, indexY, isMy)
	if self.drawMap[indexX] and self.drawMap[indexX][indexY] then
		print("hasDrawed")
		return
	end
	if not self.drawMap[indexX] then
		self.drawMap[indexX] = {}
	end
	self.drawMap[indexX][indexY] = true
	local posX = indexX*self.lineDis
	local posY = indexY*self.lineDis
	local color = cc.c4f(1,1,1,1)
	if isMy then
		color = cc.c4f(0,0,0,1)
	end
	self.drawNode:drawSolidCircle(cc.p(posX, posY), 30, math.pi/2, 50, 1.0, 1.0, color)
	self:forcus(posX, posY)
end

function FIRBoardLayer:forcus(forcusPosX, forcusPosY)
	local curPosX = self:getPositionX()
    local curPosY = self:getPositionY()
    local forcusWorldPosX = forcusPosX + curPosX
    local forcusWorldPosY = forcusPosY + curPosY
    local targetPosX = display.width/2
    local targetPosY = display.height/2
    local newPosX = curPosX + targetPosX - forcusWorldPosX
    newPosX = math.min(0, newPosX)
    newPosX = math.max(newPosX, self.minPosX)
    local newPosY = curPosY + targetPosY - forcusWorldPosY
    newPosY = math.min(0, newPosY)
    newPosY = math.max(newPosY, self.minPosY)
    self:setPosition(newPosX, newPosY)
end

function FIRBoardLayer:setListener(value)
	self.listener = value
end

return FIRBoardLayer
