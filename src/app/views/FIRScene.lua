local FIRScene = class("FIRScene", cc.Node)
local LuaSock = require("app.views.LuaSock")
local client = require("network.client")
local FIRBoardLayer = require("app.views.FIRBoardLayer")

function FIRScene:ctor()
    self:onCreate()
end

function FIRScene:onCreate()
    print("FIRScene:onCreate()")
    self.canPlayChess = false
    local function update(delta)
        zGlobal.sockClient:deal_msgs()
    end
    self:scheduleUpdateWithPriorityLua(update,0)
    zGlobal.sockClient:setListener(self)
    local msg = {
        msgId = "GAMEREADY",
    }
    zGlobal.sockClient:send(msg)

    self.boardLayer = FIRBoardLayer.new()
    self.boardLayer:setListener(self)
    self:addChild(self.boardLayer)
    self:addExitBtn()
    self:addTipLabel()
end

function FIRScene:playChess(nearIndexX, nearIndexY)
    if self.canPlayChess then
        local msg = {
            msgId = "PLAYCHESS",
            chessIndexX = nearIndexX,
            chessIndexY = nearIndexY,
        }
        zGlobal.sockClient:send(msg)
        self.canPlayChess = false
    else
        if self.gameEnd then
            zGlobal.showTips("game end")
        else
            zGlobal.showTips("please wait")
        end
    end
end

function FIRScene:onMessage(msgObj)
    local msgId = msgObj.msgId
    print("FIRScene onMessage msgId=",tostring(msgId))
    if msgId == "S_G_MOVE" then
        print("S_G_MOVE zGlobal.token.user="..zGlobal.token.user)
        print("S_G_MOVE msgObj.userId="..msgObj.userId)
        self.gameEnd = false
        self.boardLayer:updateLayer()
        if zGlobal.token.user == msgObj.userId then
            self.canPlayChess = true
            zGlobal.showTips("it is you turn")
            self.tipLable:setString("my turn")
        else
            zGlobal.showTips("please wait")
            self.tipLable:setString("other turn")
        end
    elseif msgId == "S_PLAYCHESS" then
        print("S_PLAYCHESS msgObj.userId="..msgObj.userId)
        print("S_PLAYCHESS msgObj.chessIndexX="..msgObj.chessIndexX)
        print("S_PLAYCHESS msgObj.chessIndexY="..msgObj.chessIndexY)
        if zGlobal.token.user == msgObj.userId then
            zGlobal.showTips("other turn")
            self.tipLable:setString("other turn")
            self.boardLayer:drawChess(msgObj.chessIndexX, msgObj.chessIndexY, true)
        else
            self.canPlayChess = true
            zGlobal.showTips("my turn")
            self.tipLable:setString("my turn")
            self.boardLayer:drawChess(msgObj.chessIndexX, msgObj.chessIndexY, false)
        end
    elseif msgId == "S_PLAYRESULT" then
        self.canPlayChess = false
        self.gameEnd = true
        if zGlobal.token.user == msgObj.userId then
            zGlobal.showTips("you win")
            self.tipLable:setString("you win")
            self.boardLayer:drawChess(msgObj.chessIndexX, msgObj.chessIndexY, true)
        else
            zGlobal.showTips("you lose")
            self.tipLable:setString("you lose")
            self.boardLayer:drawChess(msgObj.chessIndexX, msgObj.chessIndexY, false)
        end
    elseif msgId == "S_EXITROOM" then
        if zGlobal.token.user == msgObj.userId then
            local RoomListScene = require("app.views.RoomListScene")
            local roomScene = RoomListScene.new()
            local scene = cc.Scene:create()
            scene:addChild(roomScene)
            cc.Director:getInstance():replaceScene(scene)
        else
            zGlobal.showTips("other play exit room")
            self.boardLayer:updateLayer()
            self.tipLable:setString("wait other")
        end
    end
end

function FIRScene:addTipLabel()
    local label = cc.Label:createWithTTF("wait other", "arial.ttf", 50)
    self.tipLable = label
    label:setString("wait other")
    label:setColor(cc.c3b(0,0,0))
    self:addChild(label, 10)
    label:setAnchorPoint(cc.p(0, 1))
    label:setPosition(10, display.height - 10)
end

function FIRScene:addExitBtn()
    local btn = ccui.Button:create("edit_bg_big.png", "edit_bg_big.png", "edit_bg_big.png", 0)
    btn:setTitleText("退出房间")
    btn:setTitleColor(cc.c4b(0,0,0, 255))
    btn:setTitleFontSize(40)

    --按钮的回调函数
    btn:addTouchEventListener(function(sender, eventType)
        if (0 == eventType) then
            print("touch exitBtn")
            if self.isSendExitRoom then
                return
            end
            self.isSendExitRoom = true
            local msg = {
                msgId = "EXITROOM",
            }
            zGlobal.sockClient:send(msg)
        elseif (1 == eventType)  then
            --print("move")
        elseif  (2== eventType) then
            --print("up")
        elseif  (3== eventType) then
            --print("cancel")
        end
    end)
    self:addChild(btn, 10)
    btn:setAnchorPoint(cc.p(1, 1))
    btn:setPosition(display.width - 10, display.height - 10)
end

return FIRScene
