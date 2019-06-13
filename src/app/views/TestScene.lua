local TestScene = class("TestScene", cc.Node)
local LuaSock = require("app.views.LuaSock")
local client = require("network.client")
local crypt = skynetCrypt

local token = {
	server = "sample",
	user = "hello",
	pass = "password",
}
	
function TestScene:ctor(secret,subid)
    print("pc77 TestScene secret = "..tostring(secret))
    print("pc77 TestScene subid = "..tostring(subid))
    self.secret = secret
    self.subid = subid
    self:onCreate()
end

function TestScene:onCreate()

    local randomKey = skynetCrypt.randomkey()
    
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

    self:testSocket()
    local function update(delta)
        self.client:deal_msgs()
    end
    self:scheduleUpdateWithPriorityLua(update,0)
end

function TestScene:onConnectSuccess()
    print("pc11 onConnectSuccess token.user=",token.user)
    if self.testStatus == 0 then
		self.index = 1
	    local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(self.subid) , self.index)
		local hmac = crypt.hmac64(crypt.hashkey(handshake), self.secret)
		local msg = handshake .. ":" .. crypt.base64encode(hmac)

	    local size = #msg
	    local package = string.pack(">HA", size, msg);
		self.client:sendNoPack(package)
	else
		self.index = self.index + 1
		local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(self.subid) , self.index)
		local hmac = crypt.hmac64(crypt.hashkey(handshake), self.secret)
		local msg = handshake .. ":" .. crypt.base64encode(hmac)
		local size = #msg
    	local package = string.pack(">HA", size, msg);
		self.client:sendNoPack(package)
	end
end

function TestScene:onMessage(msg)
	print("TestScene onMessage msg=",tostring(msg))
	if self.testStatus == 0 then
    	print("===>",self:send_request("echo",0))
    	print("disconnect")
		self.client:close()
		self.client:reConnect()
    elseif self.testStatus == 1 then
    	print("22 msg=",msg)
		print("===>",self:send_request("fake",0))	-- request again (use last session 0, so the request message is fake)
		print("===>",self:send_request("again",1))	-- request again (use new session)
    elseif self.testStatus == 2 then
    	print("self.testStatus="..tostring(self.testStatus))
		print("self.testStatus=",self:recv_response(msg))
	else
		print("self.testStatus="..tostring(self.testStatus))
		print("self.testStatus=",self:recv_response(msg))
    end
    self.testStatus = self.testStatus + 1
end

function TestScene:send_request(v, session)
	--local package = string.pack(">I2", size)..v..string.pack(">I4", session)
	local size = #v + 4
    local package = string.pack(">HAI",size, v,session);
    self.client:sendNoPack(package)
	return v, session
end

function TestScene:recv_response(v)
	local size = #v - 5
	local argument = ">A"..tostring(size).."bI"
	local num, content, ok,session  = string.unpack(v, argument)
	return ok ~=0 , content, session
end

function TestScene:testSocket()
	self.testStatus = 0
    self.client = client.new()
    self.client:connect("127.0.0.1", 8888)
    self.client:setListener(self)
end

return TestScene
