local _M = class("HallArea", lc.ExtendCCNode)

local AREA_WIDTH_MAX = 800

function _M.create(w, h)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(w, h)
    area:init()

    area:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            area:onEnter()
        elseif evtName == "exit" then
            area:onExit()
        elseif evtName == "cleanup" then
            area:onCleanup()
        end
    end)

    return area
end

function _M:init()
    self:initBottomArea()

    local gap = 10

    lc.TextureCache:addImageWithMask("res/jpg/create_room.jpg")
    local createBtn = V.createShaderButton("res/jpg/create_room.jpg", function(sender) self:createRoom() end)
    createBtn:setAnchorPoint(1, 0.5)
    lc.addChildToPos(self, createBtn, cc.p(lc.cw(self) - gap, lc.ch(self) + lc.ch(self._bottomArea)))

    lc.TextureCache:addImageWithMask("res/jpg/join_room.jpg")
    local joinBtn = V.createShaderButton("res/jpg/join_room.jpg", function(sender)
        require("InputNumberForm").create(Str(STR.INPUT_ROOM_ID)..":", P._lastRoomId, function(form, text) self:onJoinRoom(form, text)
    end):show() end)
    joinBtn:setAnchorPoint(0, 0.5)
    lc.addChildToPos(self, joinBtn, cc.p(lc.cw(self) + gap, lc.y(createBtn)))

end

function _M:initBottomArea()
    local area = lc.createNode(cc.size(lc.w(self), 80))
    lc.addChildToPos(self, area, cc.p(lc.w(self) / 2, lc.h(area) / 2))
    self._bottomArea = area



    local bottomBg = V.createLineSprite("img_bottom_bg", lc.w(area))
    lc.addChildToPos(area, bottomBg, cc.p(lc.w(area) / 2, lc.h(area) / 2))

    local btnLog = V.createScale9ShaderButton("img_btn_1_s", function() require("RoomBattleReportForm").create():show() end, V.CRECT_BUTTON_S, 120)
    btnLog:addLabel(Str(STR.LOG))    
    lc.addChildToPos(area, btnLog, cc.p(lc.w(area) - 6 - lc.w(btnLog) / 2, 36))

    local btnTroop = V.createScale9ShaderButton("img_btn_2_s",
        function()
            self._ignoreSync = true
            lc.pushScene(require("HeroCenterScene").create())
        end,
    V.CRECT_BUTTON_S, 120)
    btnTroop:addLabel("0")
    lc.addChildToPos(area, btnTroop, cc.p(lc.left(btnLog) - 10 - lc.w(btnTroop) / 2, lc.y(btnLog)))
    self._btnTroop = btnTroop
end

function _M:updateTroopButton()
    if self._btnTroop then
        self._btnTroop._label:setString(string.format("%s %d", Str(STR.TROOP), P._curTroopIndex))
    end
end

function _M:onJoinRoom(form, text)
    if #text ~= 6 then
        ToastManager.push(Str(STR.MATCH_JOIN_NOT_ALLOWED))
        form:hide()
        return 
    end
    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendQueryRoom(text)
    form:hide()
end

function _M:createRoom()
    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData:sendCreateRoom()
end

function _M:onEnter()
    self:updateTroopButton()
    self._listeners = {}
end

function _M:onExit()
    for _,listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

function _M:onCleanup()
    lc.TextureCache:removeTextureForKey("res/jpg/create_room.jpg")
    lc.TextureCache:removeTextureForKey("res/jpg/join_room.jpg")
end

return _M