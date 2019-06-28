local RoomListScene = class("RoomListScene", cc.Node)
local LuaSock = require("app.views.LuaSock")
local FIRScene = require("app.views.FIRScene")
local crypt = skynetCrypt

function RoomListScene:ctor()
    self:onCreate()
end

function RoomListScene:onCreate()
    -- add background image
    --[[display.newSprite("HelloWorld.png")
        :move(display.center)
        :addTo(self)]]
    local randomKey = skynetCrypt.randomkey()

    self:createScrollView()
    local function update(delta)
        zGlobal.sockClient:deal_msgs()
    end
    self:scheduleUpdateWithPriorityLua(update,0)
    zGlobal.sockClient:setListener(self)

    local msg = {
        msgId = "GETROOMLIST",
    }
    zGlobal.sockClient:send(msg)
    print("roomListScene:onCreate()")
end

function RoomListScene:onMessage(msgObj)
    local msgId = msgObj.msgId
    print("RoomListScene onMessage msgId=",tostring(msgId))
    if msgId == "ROOMLIST" then
        local roomList = msgObj.roomList
        for i,v in ipairs(roomList) do
            print("recv index=", i)
            print("recv roomId=", v)
        end
        self.roomList = roomList
        self:updateScrollView()
    elseif msgId == "ENTERROOMSUCCESS" then
        local firScene = FIRScene.new()
        local scene = cc.Scene:create()
        scene:addChild(firScene)
        cc.Director:getInstance():replaceScene(scene)
    elseif msgId == "ENTERROOMFAIL" then
        zGlobal.showTips("player full")
        self.isSendMsg = false
    end
end

function RoomListScene:createScrollView()
    local scrollview =ccui.ScrollView:create() 
    scrollview:setTouchEnabled(true) 
    scrollview:setBounceEnabled(true)
    scrollview:setDirection(ccui.ScrollViewDir.vertical)
    scrollview:setContentSize(cc.size(display.width/2,display.height))
    scrollview:setPosition(cc.p(0,0))
    self.scrollview = scrollview
    self:addChild(scrollview)
end

function RoomListScene:updateScrollView()
    local scrollview = self.scrollview
    scrollview:removeAllChildren()
    local topHeight = 20
    local bottomHeight = 20
    local roomList = self.roomList
    local roomNum = #roomList
    local oneItemHeight = 60
    local innerHeight = topHeight + oneItemHeight*roomNum + bottomHeight
    if innerHeight < display.height then
        innerHeight = display.height
    end
    scrollview:setInnerContainerSize(cc.size(display.width/2,innerHeight))
    for i =1,roomNum do
        local btn = ccui.Button:create("edit_bg_big.png", "edit_bg_big.png", "edit_bg_big.png", 0)
        btn:setTitleText("房间"..i)
        btn:setTitleColor(cc.c4b(0,0,0, 255))
        btn:setTitleFontSize(40)

        --按钮的回调函数
        btn:addTouchEventListener(function(sender, eventType)
            if (0 == eventType)  then
                if self.isSendMsg then
                    return
                end
                print("pressed roomId="..roomList[i])
                local msg = {
                    msgId = "ENTERROOM",
                    roomId = roomList[i]
                }
                zGlobal.sockClient:send(msg)
                self.isSendMsg = true
            elseif (1 == eventType)  then
                --print("move")
            elseif  (2== eventType) then
                --print("up")
            elseif  (3== eventType) then
                --print("cancel")
            end
        end)
        scrollview:addChild(btn)
        btn:setAnchorPoint(cc.p(0.0, 1))
        btn:setPosition(100, innerHeight - topHeight - oneItemHeight*(i-1))
    end
end

return RoomListScene
