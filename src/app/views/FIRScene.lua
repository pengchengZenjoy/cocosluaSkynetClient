local FIRScene = class("FIRScene", cc.Node)
local LuaSock = require("app.views.LuaSock")
local client = require("network.client")
local crypt = skynetCrypt

local token = {
    server = "sample",
    user = "hello",
    pass = "password",
}

function FIRScene:ctor(secret,subid)
    print("pc77 FIRScene secret11 = "..tostring(secret))
    self.secret = secret
    self.subid = subid
    -- MainScene.super.ctor(self)
    self:onCreate()
end

function FIRScene:onCreate()
    -- add background image
    --[[display.newSprite("HelloWorld.png")
        :move(display.center)
        :addTo(self)]]
    local randomKey = skynetCrypt.randomkey()
    
    print("pc77 randomKey = "..tostring(randomKey))
    print(_VERSION)

    self:testSocket()
    self:createScrollView()
    local function update(delta)
        self.client:deal_msgs()
    end
    self:scheduleUpdateWithPriorityLua(update,0)
end

function FIRScene:onConnectSuccess()
    print("pc11 onConnectSuccess")
    self.index = 1
    local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(self.subid) , self.index)
    local hmac = crypt.hmac64(crypt.hashkey(handshake), self.secret)
    local msg = handshake .. ":" .. crypt.base64encode(hmac)

    local size = #msg
    local package = string.pack(">HA", size, msg);
    self.client:sendNoPack(package)
end

function FIRScene:testSocket()
    self.client = client.new()
    self.client:connect("127.0.0.1", 8888)
    --self.client:connect("149.28.65.61", 8787)
    self.client:setListener(self)
    --[[sock = LuaSock.new()
    sock:connect()
    self.sock = sock]]
end

function FIRScene:onMessage(msgObj)
    local msgId = msgObj.msgId
    print("MainScene onMessage msgId=",tostring(msgId))
    if msgId == "CONNECTINFO" then
        local msg = {
            msgId = "GETROOMLIST",
        }
        self.client:send(msg)
    elseif msgId == "ROOMLIST" then
        local roomList = msgObj.roomList
        for i,v in ipairs(roomList) do
            print("recv index=", i)
            print("recv roomId=", v)
        end
        self:updateScrollView()
    end
end

function FIRScene:createScrollView()
    local scrollview =ccui.ScrollView:create() 
    scrollview:setTouchEnabled(true) 
    scrollview:setBounceEnabled(true)
    scrollview:setDirection(ccui.ScrollViewDir.vertical)
    scrollview:setContentSize(cc.size(display.width/2,display.height))
    scrollview:setPosition(cc.p(0,0))
    self.scrollview = scrollview
    self:addChild(scrollview)
end

function FIRScene:updateScrollView()
    local scrollview = self.scrollview
    scrollview:removeAllChildren()
    local topHeight = 20
    local bottomHeight = 20
    local roomList = self.roomList
    local roomNum = 10 --#roomList
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
                print("pressed i="..i)
            elseif (1 == eventType)  then
                print("move")
            elseif  (2== eventType) then
                print("up")
            elseif  (3== eventType) then
                print("cancel")
            end
        end)
        scrollview:addChild(btn)
        btn:setAnchorPoint(cc.p(0.0, 1))
        btn:setPosition(100, innerHeight - topHeight - oneItemHeight*(i-1))
    end
end

return FIRScene
