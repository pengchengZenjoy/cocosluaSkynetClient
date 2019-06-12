local LuaSock = class("LuaSock")

function LuaSock:connect()
    local socket = require("socket") -- require('luasocket.socket'); 
    self.m_ip = "127.0.0.1"
    self.m_port = "8888"
    self.m_sock = socket.tcp(); 
    self.m_sock:settimeout(0);  --非阻塞
    self.m_sock:setoption("tcp-nodelay", true) --去掉优化 不用处理粘包
    self.m_sock:connect(self.m_ip, self.m_port); 
    
    --定时检测是否可写以判断socket的状态
    self.check_ = function()
        print("pc77 connect check")
        if self:connect_is_success() then
            print("pc77 connect success")
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.schedulerID)
        end
    end
    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(self.check_, 1, false)
end

function LuaSock:connect_is_success( ... )
    local for_write = {};
    table.insert(for_write,self.m_sock);
    local ready_forwrite;
    _,ready_forwrite,_ = socket.select(nil,for_write,0);
    if #ready_forwrite > 0 then
        return true;
    end
    return false;
end


function LuaSock:receive() 
    local recvt, sendt, status = socket.select({self.m_sock}, nil, 1)
    print("input", #recvt, sendt, status)
    if #recvt <= 0 then
        return;
    end

    local buffer,err = self.m_sock:receive(2);
    if buffer then 
        --读取二进制数据流
        local first, sencond = string.byte(buffer,1,2);
        local len=first*256+sencond;--通过位计算长度
        print("收到数据长度=",len)
        local buffer,err = self.m_sock:receive(len); 
        
        --unpack 使用pbc decode
        local  pb_len,pb_body = string.unpack(buffer, ">HP"); 
        local msg_head = protobuf.decode("PbHead.MsgHead", pb_head) 
        local msg_body = protobuf.decode(msg_head.msgname, pb_body)
        print("t:"..t..":"..string.char(t))
    
    end
end

function LuaSock:send()  
    --拼装头
    --[[local msg_head={msgtype = 1, msgname = msg_name, msgret = 0};
    local pb_head = protobuf.encode("PbHead.MsgHead", msg_head)
    local pb_body = protobuf.encode(msg_name, msg_body);
    --计算长度
    local pb_head_len=#pb_head;
    local pb_body_len=#pb_body;
    local pb_len=2+pb_head_len+2+pb_body_len+1; 

    local data=string.pack(">HPPb",pb_len, pb_head, pb_body, string.byte('t'));

    --数据发送
    local _len ,_error = self.m_sock:send(data);
    if _len ~= nil and _len == #data then 
        --表示发送成功 
    end]]

    local pbFilePath = cc.FileUtils:getInstance():fullPathForFilename("Person.pb")
    release_print("PB file path: "..pbFilePath)
    
    local buffer = read_protobuf_file_c(pbFilePath)
    protobuf.register(buffer)

    local pb_body = protobuf.encode("cs.Person",
    {
        name = "linsh",
        id = 1,
    })

    pb_body = "Hello MyGame"
    local pb_len = 2 + #pb_body
    local data = string.pack(">HP",pb_len, pb_body);

    local _len ,_error = self.m_sock:send(data);
    if _len ~= nil and _len == #data then 
        --表示发送成功 
    end
    --local data = protobuf.decode("cs.Person",stringbuffer)
    --print("数据编码：name="..data.name..",id="..data.id)
end

return LuaSock