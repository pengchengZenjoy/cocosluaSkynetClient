local PokerLayer = class("PokerLayer", cc.Layer)

local numNameMap = {[3]="3",[4]="4",[5]="5",[6]="6",[7]="7",[8]="8",[9]="9",[10]="10",[11]="jack",
[12]="queen",[13]="king",[14]="ace",[15]="2",[16]="black_joker",[17]="red_joker"}
PokerLayer.numNameMap = numNameMap
local typeNameMap = {[1]="spades",[2]="hearts",[3]="clubs",[4]="diamonds"}
PokerLayer.typeNameMap = typeNameMap

function PokerLayer:ctor()
    self:registerTouch()
end

function PokerLayer:showPoker(pokerList)
    self:removeAllChildren()
	local pokerNum = #pokerList
    self.pokerList = pokerList
    print("PokerLayer:showPoker() pokerNum="..tostring(pokerNum))
    local startPosX = 150
    local distance = 50
    self.selectPosY = 220
    self.unSelectPosY = 150
    self.pokerScale = 0.3
    self.pokerSpriteList = {}
    self.selectMap = {}
    for i=1, pokerNum do
        local pokerInfo = pokerList[i]
        local pokerName = numNameMap[pokerInfo.num]
        if pokerInfo.num < 16 then
            pokerName = pokerName.."_of_"..typeNameMap[pokerInfo.type]
        end
        pokerName = pokerName..".png"
        --print("PokerLayer:showPoker() pokerName="..tostring(pokerName))
        local poker = cc.Sprite:create("poker/"..pokerName)
        poker:setScale(self.pokerScale)
        self:addChild(poker)
        poker:setPosition(startPosX+(i-1)*distance, self.unSelectPosY)
        table.insert(self.pokerSpriteList, poker)
    end
end

function PokerLayer:registerTouch()
	local function onTouchBegan(touch, event)
        if not self.pokerSpriteList then
            return
        end
        local pos = touch:getLocation()
		local pokerNum = #self.pokerSpriteList
        for i=pokerNum,1,-1 do
            local poker = self.pokerSpriteList[i]
            local pokerPosX = poker:getPositionX()
            local pokerPosY = poker:getPositionY()
            local hPokerWidth = poker:getContentSize().width*self.pokerScale/2
            local hPokerHeight = poker:getContentSize().height*self.pokerScale/2
            if pos.x >= (pokerPosX-hPokerWidth) and pos.x <= (pokerPosX+hPokerWidth) and pos.y >= (pokerPosY-hPokerHeight) and pos.y <= (pokerPosY+hPokerHeight) then
                print("PokerLayer registerTouch index="..i)
                if self.selectMap[i] then
                    self.selectMap[i] = nil
                    poker:setPositionY(self.unSelectPosY)
                else
                    self.selectMap[i] = true
                    poker:setPositionY(self.selectPosY)
                end
                break
            end
        end
        return true
    end

    local function onTouchMoved(touch, event)
        
    end

    local function onTouchEnded(touch, event)
        
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function PokerLayer:getSelectPokerList()
    local selectList = {}
    for k,v in pairs(self.selectMap) do
        table.insert(selectList, self.pokerList[k])
    end
    return selectList
end

function PokerLayer:setListener(value)
	self.listener = value
end

return PokerLayer
