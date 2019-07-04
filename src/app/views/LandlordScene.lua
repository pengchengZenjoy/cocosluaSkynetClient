local LandlordScene = class("LandlordScene", cc.Node)
local LuaSock = require("app.views.LuaSock")
local client = require("network.client")
local PokerLayer = require("app.views.PokerLayer")

function LandlordScene:ctor()
    self:onCreate()
end

function LandlordScene:onCreate()
    print("LandlordScene:onCreate()")
    self.curState = "READY"
    self.canPlayCard = false
    local function update(delta)
        zGlobal.sockClient:deal_msgs()
        if self.countDownTime then
            self.countDownTime = self.countDownTime - delta
            if self.countDownTime < 0 then
                self.countDownTime = 0
            end
            self.countDownLable:setString("剩余"..math.ceil(self.countDownTime).."秒")
        end
    end
    self:scheduleUpdateWithPriorityLua(update,0)
    zGlobal.sockClient:setListener(self)

    self.pokerLayer = PokerLayer.new()
    self.pokerLayer:setListener(self)
    self:addChild(self.pokerLayer)

    self:addCountDownLabel()
    self:addOtherPlayTitle()
    self:addExitBtn()
    self:addConfirmBtn()
    self:addCancelBtn()
    self:addTipLabel()
    self.btnRoot:setVisible(false)
    self.recPlayPokerList = {}
    self.recPlayPokerListUserId = nil

    local msg = {
        msgId = "GAMEREADY",
    }
    zGlobal.sockClient:send(msg)
end

function LandlordScene:setTips(text)
    zGlobal.showTips(text)
    self.tipLable:setString(text)
end

function LandlordScene:sortPoker(pokerList)
    local sortfunction = function(item1, item2)
        if item1.num == item2.num then
            return item1.type > item2.type
        else
            return item1.num > item2.num
        end
    end
    table.sort(pokerList, sortfunction)
end

function LandlordScene:removePokerList(removeList)
    local pokerList = self.pokerList
    local isInRemoveList = function(pokerInfo)
        for i=1,#removeList do
            local removeInfo = removeList[i]
            if removeInfo.num == pokerInfo.num and removeInfo.type == pokerInfo.type then
                return true
            end
        end
        return false
    end
    for i=#pokerList,1,-1 do
        local pokerInfo = pokerList[i]
        if isInRemoveList(pokerInfo) then
            table.remove(pokerList, i)
        end
    end
end

function LandlordScene:initPlayerList()
    local playList = self.playList
    self.playTitle1:setString("空玩家1")
    self.playTitle2:setString("空玩家2")
    self.otherUserId1 = nil
    self.otherUserId2 = nil
    local myIndex = nil
    local playNum = #playList
    print("initPlayerList zGlobal.token.user="..tostring(zGlobal.token.user))
    for i,info in ipairs(playList) do
        print("initPlayerList info.userId="..tostring(info.userId))
        if info.userId == zGlobal.token.user then
            myIndex = i
            break
        end
    end
    print("initPlayerList myIndex="..tostring(myIndex))
    if not myIndex then
        return
    end
    local playIndex = myIndex + 1
    if playNum >= 2 then
        if playIndex > playNum then
            playIndex = 1
        end
        self.otherUserId1 = playList[playIndex].userId
        local name = self.otherUserId1
        if self.landlordUserId and self.landlordUserId == self.otherUserId1 then
            name = name.."(地主)"
        end
        self.playTitle1:setString(name)
    end
    if playNum >= 3 then
        playIndex = playIndex + 1
        if playIndex > playNum then
            playIndex = 1
        end
        self.otherUserId2 = playList[playIndex].userId
        local name = self.otherUserId2
        if self.landlordUserId and self.landlordUserId == self.otherUserId2 then
            name = name.."(地主)"
        end
        self.playTitle2:setString(name)
    end
end

function LandlordScene:otherPlayCard(msgObj)
    local pokerList = msgObj.pokerList
    self:sortPoker(pokerList)
    local pokerNum = #pokerList
    local startPosX = 150
    local distance = 20
    local rootNode = nil
    if msgObj.userId == self.otherUserId1 then
        self.otherRoot1:removeAllChildren()
        rootNode = self.otherRoot1
        startPosX = 80
    elseif msgObj.userId == self.otherUserId2 then
        self.otherRoot2:removeAllChildren()
        rootNode = self.otherRoot2
        startPosX = display.width - 80 - distance*(pokerNum-1)
    end
    if not rootNode then
        return
    end
    for i=1, pokerNum do
        local pokerInfo = pokerList[i]
        local pokerName = PokerLayer.numNameMap[pokerInfo.num]
        if pokerInfo.num < 16 then
            pokerName = pokerName.."_of_"..PokerLayer.typeNameMap[pokerInfo.type]
        end
        pokerName = pokerName..".png"
        local poker = cc.Sprite:create("poker/"..pokerName)
        poker:setScale(0.2)
        rootNode:addChild(poker)
        poker:setPosition(startPosX+(i-1)*distance, display.height-160)
    end
end

function LandlordScene:onMessage(msgObj)
    local msgId = msgObj.msgId
    print("LandlordScene onMessage msgId=",tostring(msgId))
    if msgId == "GAMESTART" then
        self.curState = "PLAYPOKER"
        print("GAMESTART zGlobal.token.user="..zGlobal.token.user)
        print("GAMESTART msgObj.userId="..msgObj.userId)
        self.gameEnd = false
        self.landlordUserId = msgObj.userId
        self:initPlayerList()
        self:startCountDown()
        if zGlobal.token.user == msgObj.userId then
            self.canPlayCard = true
            self:setTips("你的回合")
            for i=1,#msgObj.pokerList do
                table.insert(self.pokerList, msgObj.pokerList[i])
            end
            self:sortPoker(self.pokerList)
            self.pokerLayer:showPoker(self.pokerList)
            self.confirmBtn:setTitleText("出牌")
            self.cancelBtn:setTitleText("跳过")
            self.btnRoot:setVisible(true)
        else
            self:setTips(tostring(msgObj.userId).."的回合")
            self.btnRoot:setVisible(false)
        end
    elseif msgId == "DEALPOKER" then
        self.curState = "CALLLANDLORD"
        self.pokerList = msgObj.pokerList
        self.playList = msgObj.playList
        self:initPlayerList()
        self:sortPoker(self.pokerList)
        self.pokerLayer:showPoker(self.pokerList)
        self:startCountDown()
        if zGlobal.token.user == msgObj.userId then
            self.canPlayCard = true
            self:setTips("请叫地主")
            self.confirmBtn:setTitleText("叫地主")
            self.cancelBtn:setTitleText("跳过")
            self.btnRoot:setVisible(true)
        else
            self:setTips("等待"..tostring(msgObj.userId).."叫地主")
            self.btnRoot:setVisible(false)
        end
    elseif msgId == "CALLLANDLORD" then
        print("CALLLANDLORD msgObj.userId="..msgObj.userId)
        self.curState = "CALLLANDLORD"
        self:startCountDown()
        if zGlobal.token.user == msgObj.userId then
            self.canPlayCard = true
            self:setTips("请叫地主")
            self.confirmBtn:setTitleText("叫地主")
            self.cancelBtn:setTitleText("跳过")
            self.btnRoot:setVisible(true)
        else
            self:setTips("等待"..tostring(msgObj.userId).."叫地主")
            self.btnRoot:setVisible(false)
        end
    elseif msgId == "GAMEERROR" then
        zGlobal.showTips(msgObj.errorContent)
    elseif msgId == "S_PLAYRESULT" then
        self.canPlayCard = false
        self.gameEnd = true
        self:endCountDown()
        if zGlobal.token.user == msgObj.userId then
            self:setTips("你赢了")
            self:removePokerList(msgObj.pokerList)
            self.pokerLayer:showPoker(self.pokerList)
        else
            self:otherPlayCard(msgObj)
            if self.landlordUserId ~= zGlobal.token.user and self.landlordUserId ~= msgObj.userId then
                self:setTips("你赢了")
            else
                self:setTips("你输了")
            end
        end
    elseif msgId == "PLAYPOKER" then
        local pokerList = msgObj.pokerList
        self:startCountDown()
        if zGlobal.token.user == msgObj.userId then
            print("PLAYPOKER msgObj.pokerList="..tostring(pokerList))
            if not pokerList then
                return
            else
                self:removePokerList(pokerList)
                self.pokerLayer:showPoker(self.pokerList)
            end
        else
            self:otherPlayCard(msgObj)
        end
        if pokerList then
            self.recPlayPokerList = pokerList
            self.recPlayPokerListUserId = msgObj.userId
        end
        if zGlobal.token.user == msgObj.nextUserId then
            self.canPlayCard = true
            self:setTips("我的回合")
            self.confirmBtn:setTitleText("出牌")
            self.cancelBtn:setTitleText("跳过")
            self.btnRoot:setVisible(true)
        else
            self:setTips(tostring(msgObj.nextUserId).."的回合")
            self.btnRoot:setVisible(false)
        end
    elseif msgId == "S_EXITROOM" then
        self:endCountDown()
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

function LandlordScene:startCountDown()
    self.countDownTime = 25
    self.countDownLable:setVisible(true)
end

function LandlordScene:endCountDown()
    self.countDownTime = nil
    self.countDownLable:setVisible(false)
end

function LandlordScene:addCountDownLabel()
    local label = cc.Label:createWithTTF("倒计时", "mini.TTF", 30)
    self.countDownLable = label
    label:setString("倒计时")
    label:setColor(cc.c3b(255,255,255))
    self:addChild(label, 10)
    label:setVisible(false)
    --label:setAnchorPoint(cc.p(0, 1))
    label:setPosition(display.width/2, display.height - 50)
end

function LandlordScene:addTipLabel()
    local label = cc.Label:createWithTTF("等待其他玩家", "mini.TTF", 30)
    self.tipLable = label
    label:setString("等待其他玩家")
    label:setColor(cc.c3b(255,255,255))
    self:addChild(label, 10)
    --label:setAnchorPoint(cc.p(0, 1))
    label:setPosition(display.width/2, display.height - 20)
end

function LandlordScene:addExitBtn()
    local btn = ccui.Button:create("redA3.png", "redA3.png", "redA3.png", 0)
    btn:setTitleText("退出房间")
    btn:setTitleColor(cc.c4b(0,0,0, 255))
    btn:setTitleFontSize(30)

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
        end
    end)
    self:addChild(btn, 10)
    btn:setAnchorPoint(cc.p(1, 1))
    btn:setPosition(display.width - 10, display.height - 10)
end

function LandlordScene:getSeriesNum(numListMap, num)
    local map = numListMap[num]
    if not map then
        return 0
    end
    local list = {}
    for k,v in pairs(map) do
        table.insert(list, k)
    end
    local sortfunction = function(item1, item2)
        return item1 < item2
    end
    table.sort(list, sortfunction)
    local isSeries = true
    if #list > 1 then
        local startNum = list[1]
        for i=2,#list do
            if (startNum + 1) ~= list[i] then
                isSeries = false
                break
            end
            startNum = list[i]
        end
    end
    if isSeries then
        return #list
    else
        return 0
    end
end

function LandlordScene:getModeInfo(pokerList)
    local info = {}
    local flowerMap = {}
    local numMap = {}
    local numToFlowerMap = {}
    local numListMap = {}
    local maxNum = -1
    local pokerNum = #pokerList
    for i=1,pokerNum do
        local num = pokerList[i].num
        if not flowerMap[num] then
            flowerMap[num] = 1
        else
            flowerMap[num] = flowerMap[num] + 1
        end
        if num > maxNum then
            maxNum = num
        end
    end 
    for k,num in pairs(flowerMap) do
        numToFlowerMap[num] = k
        if not numListMap[num] then
            numListMap[num] = {}
        end
        numListMap[num][k] = true
        if not numMap[num] then
            numMap[num] = 1
        else
            numMap[num] = numMap[num] + 1
        end
    end
    local numMapNum = 0
    local numMapKey = nil
    local numMapValue = nil
    for k,v in pairs(numMap) do
        numMapKey = k
        numMapValue = v
        numMapNum = numMapNum + 1
    end
    --[[print("getSeriesNum(1)="..tostring(self:getSeriesNum(numListMap,1)))
    print("getSeriesNum(2)="..tostring(self:getSeriesNum(numListMap,2)))
    print("getSeriesNum(3)="..tostring(self:getSeriesNum(numListMap,3)))
    print("getSeriesNum(4)="..tostring(self:getSeriesNum(numListMap,4)))]]
    if numMapNum == 1 then
        if numMapKey == 1 then
            if numMapValue == 1 then
                info.type = "one"
                info.num = maxNum
                return info
            end
            if maxNum <= 15 and self:getSeriesNum(numListMap,1) >= 5 then
                info.type = "oneSeries"..numMapValue
                info.num = maxNum
                return info
            end
        elseif numMapKey == 2 and (numMapValue >= 3 or numMapValue==1) and self:getSeriesNum(numListMap,2) > 0 then
            info.type = "twoSeries"..tostring(numMapValue)
            info.num = maxNum
            return info
        elseif numMapKey == 3 and self:getSeriesNum(numListMap,3) > 0 then
            info.type = "threeSeries"..tostring(numMapValue)
            info.num = maxNum
            return info
        end
    elseif numMapNum > 1 then
        local threeSeriesNum = self:getSeriesNum(numListMap,3)
        if threeSeriesNum > 0 and numMap[1] == threeSeriesNum and pokerNum == threeSeriesNum*4 then
            info.type = "threeSeries"..tostring(threeSeriesNum).."AddOne"
            info.num = maxNum
            return info
        elseif threeSeriesNum > 0 and numMap[2] == threeSeriesNum and pokerNum == threeSeriesNum*5 then
            info.type = "threeSeries"..tostring(threeSeriesNum).."AddTwo"
            info.num = maxNum
            return info
        end
    end
    if #pokerList == 2 and pokerList[1].type == 5 and pokerList[2].type == 5 then --火箭
        info.type = "killAll"
        info.num = 100
    elseif #pokerList == 4 and numMap[4] == 1 then --炸弹
        info.type = "killAll"
        info.num = pokerList[1].num
    elseif #pokerList == 8 and numMap[4] == 1 and numMap[2] == 2 then
        info.type = "fourAddFour"
        info.num = numToFlowerMap[4]
    elseif #pokerList == 6 and numMap[4] == 1 and numMap[1] == 2 then
        info.type = "fourAddTwo"
        info.num = numToFlowerMap[4]
    elseif #pokerList == 6 and numMap[4] == 1 and numMap[2] == 1 then
        info.type = "fourAddTwo"
        info.num = numToFlowerMap[4]
    elseif #pokerList == 5 and numMap[3] == 1 and numMap[2] == 1 then
        info.type = "threeAddTwo"
        info.num = numToFlowerMap[3]
    elseif #pokerList == 4 and numMap[3] == 1 and numMap[1] == 1 then
        info.type = "threeAddOne"
        info.num = numToFlowerMap[3]
    end
    if not info.type then
        info = nil
    end
    return info
end

function LandlordScene:canSendSelectList()
    local selectList = self.pokerLayer:getSelectPokerList()
    if #selectList == 0 then
        zGlobal.showTips("请先选牌")
        return false
    end
    local modeInfo = self:getModeInfo(selectList)
    if modeInfo then
        print("modeInfo.type = "..tostring(modeInfo.type))
        print("modeInfo.num = "..tostring(modeInfo.num))
    else
        zGlobal.showTips("不能这样出牌")
        return false
    end
    print("self.recPlayPokerListUserId = "..tostring(self.recPlayPokerListUserId))
    if self.recPlayPokerListUserId == nil or self.recPlayPokerListUserId == zGlobal.token.user then
        return true
    else
        local oldModeInfo = self:getModeInfo(self.recPlayPokerList)
        if oldModeInfo then
            print("oldModeInfo.type = "..tostring(oldModeInfo.type))
            print("oldModeInfo.num = "..tostring(oldModeInfo.num))
            if modeInfo.type == oldModeInfo.type then
                if modeInfo.num > oldModeInfo.num then
                    return true
                else
                    zGlobal.showTips("请出比上家大的牌")
                    return false
                end
            elseif modeInfo.type ~= oldModeInfo.type then
                if modeInfo.type == "killAll" then
                    return true
                else
                    zGlobal.showTips("请和上家出同类型的牌")
                    return false
                end
            end
        else
            return true
        end
    end
    zGlobal.showTips("不能这样出啊")
    return false
end

function LandlordScene:addOtherPlayTitle()
    local play1 = cc.Label:createWithTTF("空玩家", "mini.TTF", 20)
    self.playTitle1 = play1
    play1:setString("空玩家1")
    play1:setColor(cc.c3b(255,255,255))
    self:addChild(play1, 10)
    play1:setAnchorPoint(cc.p(0, 1))
    play1:setPosition(10, display.height - 60)

    local play2 = cc.Label:createWithTTF("空玩家", "mini.TTF", 20)
    self.playTitle2 = play2
    play2:setString("空玩家2")
    play2:setColor(cc.c3b(255,255,255))
    self:addChild(play2, 10)
    play2:setAnchorPoint(cc.p(1, 1))
    play2:setPosition(display.width - 10, display.height - 60)

    local otherRoot1 = cc.Node:create()
    self:addChild(otherRoot1, 10)
    self.otherRoot1 = otherRoot1

    local otherRoot2 = cc.Node:create()
    self:addChild(otherRoot2, 10)
    self.otherRoot2 = otherRoot2
end

function LandlordScene:addConfirmBtn()
    local btnRoot = cc.Node:create()
    self:addChild(btnRoot, 10)
    self.btnRoot = btnRoot
    local btn = ccui.Button:create("redA3.png", "redA3.png", "redA3.png", 0)
    btn:setTitleText("确认")
    btn:setTitleColor(cc.c4b(0,0,0, 255))
    btn:setTitleFontSize(40)

    --按钮的回调函数
    btn:addTouchEventListener(function(sender, eventType)
        if (0 == eventType) then
            print("touch confirmBtn self.canPlayCard="..tostring(self.canPlayCard))
            if not self.canPlayCard then
                return
            end
            if self.curState == "CALLLANDLORD" then
                local msg = {
                    msgId = "CALLLANDLORD",
                    isLandlord = true,
                }
                zGlobal.sockClient:send(msg)
            elseif self.curState == "PLAYPOKER" then
                if self:canSendSelectList() then
                    local msg = {
                        msgId = "PLAYPOKER",
                        pokerList = self.pokerLayer:getSelectPokerList(),
                    }
                    zGlobal.sockClient:send(msg)
                else
                    return
                end
                --[[local msg = {
                    msgId = "EXITROOM",
                }
                zGlobal.sockClient:send(msg)]]
            end
            self.btnRoot:setVisible(false)
        end
    end)
    self.confirmBtn = btn
    self.btnRoot:addChild(btn, 10)
    btn:setPosition(display.width/2 + 100, display.height/2+50)
end

function LandlordScene:addCancelBtn()
    local btn = ccui.Button:create("redA3.png", "redA3.png", "redA3.png", 0)
    btn:setTitleText("跳过")
    btn:setTitleColor(cc.c4b(0,0,0, 255))
    btn:setTitleFontSize(40)

    --按钮的回调函数
    btn:addTouchEventListener(function(sender, eventType)
        if (0 == eventType) then
            print("touch cancelBtn")
            if not self.canPlayCard then
                return
            end
            if self.curState == "CALLLANDLORD" then
                local msg = {
                    msgId = "CALLLANDLORD",
                    isLandlord = false,
                }
                zGlobal.sockClient:send(msg)
            else
                local msg = {
                    msgId = "PLAYPOKER",
                }
                zGlobal.sockClient:send(msg)
            end
            self.btnRoot:setVisible(false)
        end
    end)
    self.cancelBtn = btn
    self.btnRoot:addChild(btn, 10)
    btn:setPosition(display.width/2 - 100, display.height/2+50)
end

return LandlordScene
