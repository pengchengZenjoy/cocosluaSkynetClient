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
end

function M:connect_is_success( ... )
    local for_write = {};
    table.insert(for_write,self.sock);
    local ready_forwrite;
    _,ready_forwrite,errorStr = socket.select(nil,for_write,1);
    print("pc88 errorStr="..tostring(errorStr))
    if #ready_forwrite > 0 then
    	print("pc88 self.isConnectSuccess=")
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
	local n,e = sock:connect(ip, port)
	print("connect e=", e)
	self.sock = sock
end

function M:send(msg)
   self.sock:send(msg)
end

function M:deal_msgs()
	if not self.isConnectSuccess then
		self:connect_is_success()
		return
	end
	self:recv()
end

function M:recv()
	if self.isClose then
		return
	end
	local reads, writes = socket.select({self.sock}, {}, 0)
	if #reads == 0 then
		return
	end


	local r, s = self.sock:receive("*l")
	print("recv s=", tostring(s))
	if s == "closed" then
		zGlobal.showTips("server not open")
		self:close()
		return
	end
		
	if not r then
		return
	end

    print("recv data", #r)
    if self.listener then
		self.listener:onLoginMessage(r)
	end
end

function M:setListener(value)
	self.listener = value
end

function M:close()
	--self.isClose = true
	self.sock:close()
end

return M
