local LoginScene = class("LoginScene", cc.load("mvc").ViewBase)
local loginSocket = require("network.loginSocket")
local MainScene = require("app.views.MainScene")
local TestScene = require("app.views.TestScene")
local FIRScene = require("app.views.FIRScene")
local RoomListScene = require("app.views.RoomListScene")
local crypt = skynetCrypt
local client = require("network.client")

--zGlobal.serverIp = "10.7.2.180"
--zGlobal.serverIp = "127.0.0.1"
zGlobal.serverIp = "149.28.65.61"

zGlobal.showTips = function(content)
    local curScene = cc.Director:getInstance():getRunningScene()
    local label = cc.Label:createWithTTF(content, "arial.ttf", 50)
    label:setString(content)
    curScene:addChild(label, 100)
    label:setAnchorPoint(cc.p(0.5, 0.5))
    label:setPosition(cc.p(display.width/2, display.height/2))
    label:setColor(cc.c3b(255,0,0))
    local function endFuc(node)
        label:removeFromParent(true)
    end
    label:runAction( cc.Sequence:create(cc.MoveBy:create(1.5, cc.p(0,200)) ,cc.CallFunc:create(endFuc)))
end

zGlobal.delayCallBack = function(callBack, time)
	local curScene = cc.Director:getInstance():getRunningScene()
	local node = cc.Node:create()
	curScene:addChild(node)
	local function endFuc(node)
		print("zGlobal.delayCallBack 22")
        node:removeFromParent(true)
        callBack()
    end
    print("zGlobal.delayCallBack 11")
    node:runAction( cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(endFuc)))
end

zGlobal.toLoginScene = function()
	local loginScene = LoginScene.new()
	local scene = cc.Scene:create()
	scene:addChild(loginScene)
	cc.Director:getInstance():replaceScene(scene)
end

zGlobal.token = {
    server = "sample",
    user = "hello",
    pass = "password",
}

local function encode_token(token)
	return string.format("%s@%s:%s",
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
end

function LoginScene:onConnectSuccess()

end

function LoginScene:loginSuccess()
	print(" LoginScene:loginSuccess() ")
	local mainScene = RoomListScene.new()
	local scene = cc.Scene:create()
	scene:addChild(mainScene)
	cc.Director:getInstance():replaceScene(scene)
end

function LoginScene:onLoginMessage(msg)
	local fd = nil
    if self.loginStatus == 0 then
    	self.challenge = crypt.base64decode(msg)
    	self.clientkey = crypt.randomkey()
    	print("clientkey is ", self.clientkey)
		local sendContent = crypt.base64encode(crypt.dhexchange(self.clientkey))
		print("1 sendContent is ", sendContent)
		self.loginSock:send(sendContent .. "\n")
    elseif self.loginStatus == 1 then
    	local secret = crypt.dhsecret(crypt.base64decode(msg), self.clientkey)
    	print("11 secret is ", secret)
    	print("secret is ", crypt.hexencode(secret))
    	self.secret = secret
    	local hmac = crypt.hmac64(self.challenge, secret)
		local sendContent = crypt.base64encode(hmac)
		self.loginSock:send(sendContent .. "\n")
		local token = zGlobal.token
		local etoken = crypt.desencode(secret, encode_token(token))
		local b = crypt.base64encode(etoken)
		local sendContent = crypt.base64encode(etoken)
		self.loginSock:send(sendContent .. "\n")
	elseif self.loginStatus == 2 then
		self.loginSock:close()
		local result = msg
		print(result)
		local code = tonumber(string.sub(result, 1, 3))
		assert(code == 200)
		local subid = crypt.base64decode(string.sub(result, 5))
		print("subid=",subid)

		zGlobal.sockClient = client.new()
	    zGlobal.sockClient:connect(zGlobal.serverIp, 8018)
	    zGlobal.sockClient:setLoginInfo(self.secret, subid)
	    --self.client:connect("149.28.65.61", 8787)
	    zGlobal.sockClient:setListener(self)
    end
    self.loginStatus = self.loginStatus + 1
end

function LoginScene:onCreate()
	self.loginStatus = 0

	zGlobal.token.user = "user"..math.random(100000)

	local loginSock = loginSocket.new()
    --self.client:connect("127.0.0.1", 8787)
    loginSock:connect(zGlobal.serverIp, 8001)
    loginSock:setListener(self)
    self.loginSock = loginSock

    local function update(delta)
        loginSock:deal_msgs()
        if zGlobal.sockClient then
        	zGlobal.sockClient:deal_msgs()
        end
    end
    self:scheduleUpdateWithPriorityLua(update,0)


	--[[local readline = unpack_f(self, unpack_line)

	local challenge = crypt.base64decode(readline())

	local fd = nil

	local clientkey = crypt.randomkey()
	writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
	local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

	print("sceret is ", crypt.hexencode(secret))

	local hmac = crypt.hmac64(challenge, secret)
	writeline(fd, crypt.base64encode(hmac))

	local token = {
		server = "sample",
		user = "hello",
		pass = "password",
	}

	local etoken = crypt.desencode(secret, encode_token(token))
	local b = crypt.base64encode(etoken)
	writeline(fd, crypt.base64encode(etoken))

	local result = readline()
	print(result)
	local code = tonumber(string.sub(result, 1, 3))
	assert(code == 200)
	--socket.close(fd)
	curSock:close()

	local subid = crypt.base64decode(string.sub(result, 5))

	print("login ok, subid=", subid)

	local readpackage = unpack_f(self, unpack_package)

	local text = "echo"
	local index = 1

	print("connect")
	--fd = assert(socket.connect("127.0.0.1", 8888))
	local sock = socketConnet("127.0.0.1", 8888)
	last = ""

	local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)


	send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

	print(readpackage())
	print("===>",send_request(text,0))
	-- don't recv response
	-- print("<===",recv_response(readpackage()))

	print("disconnect")
	--socket.close(fd)
	curSock:close()

	index = index + 1

	print("connect again")
	--fd = assert(socket.connect("127.0.0.1", 8888))
	local sock = socketConnet("127.0.0.1", 8888)
	last = ""

	local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

	send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

	print(readpackage())
	print("===>",send_request("fake",0))	-- request again (use last session 0, so the request message is fake)
	print("===>",send_request("again",1))	-- request again (use new session)
	print("<===",recv_response(readpackage()))
	print("<===",recv_response(readpackage()))


	print("disconnect")
	--socket.close(fd)
	curSock:close()]]
end

return LoginScene









