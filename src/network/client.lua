local Socket = require "socket"
local Packer = require "network.packer"

local M = {}

M.__index = M

function M.new(...)
    local o = {}
	setmetatable(o, M)
	M.init(o, ...)
	return o
end

function M:init()
	self.last = ""
	self.pack_list = {}
	self.head = nil
	self.callback_tbl = {}
	self:registerProto()
end

function M:registerProto()
	local pbList = {"C2SMsg.pb","S2CMsg.pb"}
	for i=1,#pbList do
		local pbFilePath = cc.FileUtils:getInstance():fullPathForFilename(pbList[i])
		print("registerProto pbFilePath", pbFilePath)
	    local buffer = read_protobuf_file_c(pbFilePath)
	    protobuf.register(buffer)
	end
end

function M:connect_is_success( ... )
    local for_write = {};
    table.insert(for_write,self.sock);
    local ready_forwrite;
    _,ready_forwrite,errorStr = socket.select(nil,for_write,1);
    if #ready_forwrite > 0 then
    	self.isConnectSuccess = true
    	if self.listener then
			self.listener:onConnectSuccess()
		end
        return true;
    end
    
    return false;
end

function M:connect(ip, port)
    self.ip = ip
    self.port = port
	self:_createSock()
end

function M:_createSock()
	local sock
    local isipv6_only = false
    local addrinfo, err = Socket.dns.getaddrinfo(self.ip)
    for i,v in ipairs(addrinfo) do
	   	if v.family == "inet6" then 
	   		isipv6_only = true; 
	   		break 
	   	end
   	end
   	if isipv6_only then 
   		sock = socket.tcp6()
   		print("connect tcp6")
   	else
   		sock = socket.tcp()
   		print("connect tcp")
   	end
   	sock:settimeout(0)
	local n,e = sock:connect(self.ip, self.port)
	print("connect e=", e)
	self.sock = sock
end

function M:reConnect()
	self.isConnectSuccess = false
	self:_createSock()
end

function M:keepConnect()
	--local n,e = self.sock:connect(self.ip, self.port)
	--print("keepConnect e=", e)
end

function M:send(msg)
    local packet = Packer.pack(msg)
    self.sock:send(packet)
end

function M:sendNoPack(msg)
    self.sock:send(msg)
end

function M:deal_msgs()
	if not self.isConnectSuccess then
		if not self:connect_is_success() then
			self:keepConnect()
		end
		return
	end
	self:recv()
	self:split_pack()
	while self:dispatch_one() do
	
	end
end

function M:recv()
	local reads, writes = socket.select({self.sock}, {}, 0)
	if #reads == 0 then
		--print("no reads")
		return
	end

	-- 读包头,两字节长度
	if #self.last < 2 then
		local r, s = self.sock:receive(2 - #self.last)
		if s == "closed" then
			self:on_close()
			return
		end
			
		if not r then
			return
		end
		
		self.last = self.last .. r
		if #self.last < 2 then
			return
		end
	end
	
	local len = self.last:byte(1) * 256 + self.last:byte(2)
	
	local r, s = self.sock:receive(len + 2 - #self.last)
	if s == "closed" then
		self:on_close()
		return
	end
	
	if not r then
		return
	end
	
	self.last = self.last .. r
	if #self.last < 2 then
		return
	end
		
    if not r then
		print("socket empty", s)
        return
    end

    print("recv data", #r)
end

function M:split_pack()
	local last = self.last
    local len
    repeat
        if #last < 2 then
            break
        end
        len = last:byte(1) * 256 + last:byte(2)
        if #last < len + 2 then
            break
        end
        table.insert(self.pack_list, last:sub(3, 2 + len))
        last = last:sub(3 + len) or ""
    until(false)
	self.last = last
end

function M:dispatch_one()
	if not next(self.pack_list) then
		return
	end
	local data = table.remove(self.pack_list, 1)
	if self.listener then
		self.listener:onMessage(data)
	end
	--[[print("split pack",#data)
	local msgId, msgObj = Packer.unpack(data)
	local callback = self.callback_tbl[msgId]
	if callback then
		callback.callback(callback.obj, params)
	end
	if self.listener then
		self.listener:onMessage(msgObj)
	end]]
	return
end

function M:register(name, obj, callback)
	self.callback_tbl[name] = {obj = obj, callback = callback}
end

function M:unregister(name)
	self.callback_tbl[name] = nil
end

function M:setListener(value)
	self.listener = value
end

function M:close()
	self.sock:close()
end

function M:on_close()
	self:close()
end

return M