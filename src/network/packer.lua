-- 网络消息封包解包
local Utils = require "utils"
local msg_define = require "network.msg_define"

local M = {}

-- 包格式
-- 两字节包长
-- 两字节协议号
-- 两字符字符串长度
-- 字符串内容
function M.pack(msgObj)
	--[[local proto_id = msg_define.name_2_id(proto_name)
    local params_str = Utils.table_2_str(msg)
	print("msg content:", params_str)
	local len = 2 + 2 + #params_str
	local data = Utils.int16_2_bytes(len) .. Utils.int16_2_bytes(proto_id) .. Utils.int16_2_bytes(#params_str) .. params_str]]

    local pb_body = protobuf.encode("c2s.C2SMsg", msgObj)

    --[[local pb_body = protobuf.encode("s2c.S2CMsg",
    {
        msgId = "CHAT",
        chatList = {
	        {
	        	chatContent = "s2c chat list content"
	    	}
    	}
    })
    print("pb_body=",pb_body)
    print("#pb_body=",#pb_body)
    local result = protobuf.decode("s2c.S2CMsg", pb_body)
    print("result.msgId=",result.msgId)
    print("result.chatList[1].chatContent=",result.chatList[1].chatContent)]]
	local msg_len = 2 + #pb_body
    local data = string.pack(">HP",msg_len, pb_body);
    return data	
end

function M.unpack(data)
	print("数据包长",#data)
	local result = protobuf.decode("s2c.S2CMsg", data)
    return result.msgId, result
end

return M
