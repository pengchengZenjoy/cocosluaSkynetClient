
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local LuaSock = require("app.views.LuaSock")
local client = require("network.client")

function MainScene:onCreate()
    -- add background image
    --[[display.newSprite("HelloWorld.png")
        :move(display.center)
        :addTo(self)]]

    local randomKey = skynet.randomkey()
    print("pc77 randomKey = "..tostring(randomKey))
    print(_VERSION)

    local btn = ccui.Button:create("edit_bg_big.png", "edit_bg_big.png", "edit_bg_big.png", 0)
    btn:setTitleText("发送")
    btn:setTitleColor(cc.c4b(0,0,0, 255))
    btn:setTitleFontSize(40)
    btn:setPosition(display.cx + 200, display.cy + 130)
    btn:addTo(self)
    self.sendBtn = btn

    --按钮的回调函数
    btn:addTouchEventListener(function(sender, eventType)
        if (0 == eventType)  then
            print("pressed")
            --self.sock:send()
            local text = self.editBox:getText()
            if not text or #text <1 then
                return
            end
            print("send text =",text)
            self.editBox:setText("")
            local msg = {
                msgId = "CHAT",
                chatInfo = {
                    chatContent = text
                }
            }
            self.client:send(msg)
        elseif (1 == eventType)  then
            print("move")
        elseif  (2== eventType) then
            print("up")
        elseif  (3== eventType) then
            print("cancel")
        end
    end)

    self:createEditBox()
    self:testSocket()
    self:createScrollView()
    local function update(delta)
        self.client:deal_msgs()
    end
    self:scheduleUpdateWithPriorityLua(update,0)
end

function MainScene:onConnectSuccess()
    print("pc11 onConnectSuccess")
    local msg = {
        msgId = "GETCHATLIST",
    }
    self.client:send(msg)
end

function MainScene:testSocket()
    self.client = client.new()
    --self.client:connect("127.0.0.1", 8787)
    self.client:connect("149.28.65.61", 8787)
    self.client:setListener(self)
    --[[sock = LuaSock.new()
    sock:connect()
    self.sock = sock]]
end

function MainScene:onMessage(msgObj)
    local msgId = msgObj.msgId
    if msgId == "CHATLIST" then
        self.curChatList = msgObj.chatList
        self:updateScrollView()
    elseif msgId == "CHAT" then
        if not self.curChatList then
            self.curChatList = {}
        end
        table.insert(self.curChatList, msgObj.chatList[1])
        self:updateScrollView()
    end
    local chatList = msgObj.chatList
    for i=1,#chatList do
        print("recv index=", i)
        print("recv chatContent=", chatList[i].chatContent)
    end
end

function MainScene:createEditBox()
    self.editBox = ccui.EditBox:create(cc.size(359,63), "shuru.png")  --输入框尺寸，背景图片
    self.editBox:setPosition(cc.p(display.cx + 200, display.cy + 200))
    --self.editBox:anch(cc.p(0.5,0.5))
    self.editBox:setFontSize(26)
    self.editBox:setFontColor(cc.c3b(0,0,0))
    self.editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE ) --输入键盘返回类型，done，send，go等
    self.editBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE) --输入模型，如整数类型，URL，电话号码等，会检测是否符合

    self.editBox:registerScriptEditBoxHandler(function(eventname,sender) self:editboxHandle(eventname,sender) end) --输入框的事件，主要有光标移进去，光标移出来，以及输入内容改变等
    self:addChild(self.editBox)
    --self.editBox:setHACenter() --输入的内容锚点为中心，与anch不同，anch是用来确定控件位置的，而这里是确定输入内容向什么方向展开(。。。说不清了。。自己测试一下)

    -- add HelloWorld label
    --[[self.inputLable = cc.Label:createWithSystemFont("输入点什么", "Arial", 22)
    self.inputLable:setColor(cc.c3b(0,0,0))
    self.inputLable:setPosition(display.cx, display.cy + 200)
    self:addChild(self.inputLable, 3)]]
end

function MainScene:editboxHandle(strEventName,pSender)
    local edit = pSender
    local strFmt 
    if strEventName == "began" then
        strFmt = string.format("editBox %p DidBegin !", edit)
        print(strFmt)
        --self.inputLable.setString(edit:getText())
    elseif strEventName == "ended" then
        strFmt = string.format("editBox %p DidEnd !", edit)
        print(strFmt)
        --self.inputLable.setString(edit:getText())
    elseif strEventName == "return" then
        strFmt = string.format("editBox %p was returned !",edit)
        print(strFmt)
        --self.inputLable.setString(edit:getText())
    elseif strEventName == "changed" then
        strFmt = string.format("editBox %p TextChanged, text: %s ", edit, edit:getText())
        print(strFmt)
        --self.inputLable.setString(edit:getText())
    end
end

function MainScene:createScrollView()
    local scrollview=ccui.ScrollView:create() 
    scrollview:setTouchEnabled(true) 
    scrollview:setBounceEnabled(true)
    scrollview:setDirection(ccui.ScrollViewDir.vertical)
    scrollview:setContentSize(cc.size(display.width/2,display.height))
    scrollview:setPosition(cc.p(0,0))
    self.scrollview = scrollview
    self:addChild(scrollview)
end

function MainScene:updateScrollView()
    local scrollview = self.scrollview
    scrollview:removeAllChildren()
    local topHeight = 10
    local bottomHeight = 10
    local chatList = self.curChatList
    local chatNum = #chatList
    local onChatHeight = 40
    local innerHeight = topHeight + onChatHeight*chatNum + bottomHeight
    if innerHeight < display.height then
        innerHeight = display.height
    end
    scrollview:setInnerContainerSize(cc.size(display.width/2,innerHeight))
    for i =1,chatNum do
        local chatInfo = chatList[i]
        local chatLb = cc.Label:createWithSystemFont(chatInfo.chatContent, "Arial", 22)
        scrollview:addChild(chatLb)
        chatLb:setAnchorPoint(cc.p(0.0, 1))
        chatLb:setPosition(100, innerHeight - topHeight - onChatHeight*(i-1))
    end
end

function MainScene:testPbc()
	local pbFilePath = cc.FileUtils:getInstance():fullPathForFilename("MsgProtocol.pb")
    release_print("PB file path: "..pbFilePath)
    
    local buffer = read_protobuf_file_c(pbFilePath)
    protobuf.register(buffer) --注:protobuf 是因为在protobuf.lua里面使用module(protobuf)来修改全局名字
    
    local stringbuffer = protobuf.encode("Person",      
        {      
            name = "Alice",      
            id = 12345,      
            phone = {      
                {      
                    number = "87654321"      
                },      
            }      
        })           
    
    
    local slen = string.len(stringbuffer)
    release_print("slen = "..slen)
    
    local temp = ""
    for i=1, slen do
        temp = temp .. string.format("0xX, ", string.byte(stringbuffer, i))
    end
    release_print(temp)
    local result = protobuf.decode("Person", stringbuffer)
    release_print("result name: "..result.name)
    release_print("result name: "..result.id)
end

return MainScene
