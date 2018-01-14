local _M = class("DarkUserInfoForm", BaseForm)

local FORM_SIZE = cc.size(710, 600)
local RANK_AREA_SIZE = cc.size(570, 310)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    self._userId = userId
    self._indicator = V.showPanelActiveIndicator(self._form)
    ClientData.sendGetDarkInfo()
end

function _M:initDark(pbDark)
    local user = P

    local form = self._form

    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(form, titleBg, cc.p(lc.w(form) / 2, lc.h(form) - _M.FRAME_THICK_TOP - lc.h(titleBg) / 2))

    local title = V.createTTFStroke(Str(STR.DARK_BATTLE), V.FontSize.M2)
    lc.addChildToCenter(titleBg, title)
    
    -- user icon and server
    local userWidget = UserWidget.create(user, UserWidget.Flag.NAME_UNION, 1, false, true)
    lc.addChildToPos(form, userWidget, cc.p(_M.FRAME_THICK_LEFT + 40 + lc.w(userWidget) / 2, lc.bottom(titleBg) - 30 - lc.h(userWidget) / 2))
    userWidget._unionArea._name:setColor(V.COLOR_TEXT_ORANGE)

    -- detail info
    local area = lc.createImageView{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = RANK_AREA_SIZE}
    lc.addChildToPos(form, area, cc.p(lc.w(form) / 2, lc.bottom(userWidget) - lc.h(area) / 2 - 20))

    -- clash record
    local title = V.addDecoratedLabel(area, Str(STR.FIND_DARK_RECORD), cc.p(lc.w(area) / 2, lc.h(area) - 50), 26)
    local trophyArea = V.createIconLabelArea("img_icon_res16_s", user._playerFindDark._trophy, 160)
    lc.addChildToPos(area, trophyArea, cc.p(lc.w(area) - lc.cw(trophyArea) - 20, lc.y(title:getParent())))

    local winLabel = V.createTTF(Str(STR.BATTLE_WIN).."  "..pbDark.total_win, V.FontSize.S2, V.COLOR_TEXT_WHITE)
    winLabel:setAnchorPoint(0, 0.5)
    lc.addChildToPos(area, winLabel, cc.p(lc.left(title:getParent()) + 13, lc.bottom(title:getParent()) - 25 - lc.ch(winLabel)))

    local loseLabel = V.createTTF(Str(STR.BATTLE_LOSE).."  "..pbDark.total_lose, V.FontSize.S2, V.COLOR_TEXT_WHITE)
    loseLabel:setAnchorPoint(0, 0.5)
    lc.addChildToPos(area, loseLabel, cc.p(lc.w(area) - lc.w(loseLabel) - 40, lc.y(winLabel)))

    local line = lc.createSprite{_name = "img_divide_line_8", _crect = cc.rect(6, 1, 1, 1), _size = cc.size(lc.w(area) - 16, 5)} 
    lc.addChildToPos(area, line, cc.p(lc.cw(area), lc.ch(area)))
    line:setRotation(180)

    local win2To0Label = V.createTTF("2:0"..Str(STR.GET_WIN).."  "..pbDark.two_zero_win, V.FontSize.S2, V.COLOR_TEXT_WHITE)
    win2To0Label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(area, win2To0Label, cc.p(lc.x(winLabel), lc.ch(area) - 30 - lc.ch(win2To0Label)))

    local lose0To2Label = V.createTTF("0:2"..Str(STR.GET_LOSE).."  "..pbDark.zero_two_lose, V.FontSize.S2, V.COLOR_TEXT_WHITE)
    lose0To2Label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(area, lose0To2Label, cc.p(lc.x(loseLabel), lc.y(win2To0Label)))

    local win2To1Label = V.createTTF("2:1"..Str(STR.GET_WIN).."  "..pbDark.two_one_win, V.FontSize.S2, V.COLOR_TEXT_WHITE)
    win2To1Label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(area, win2To1Label, cc.p(lc.x(winLabel), lc.bottom(win2To0Label) - 16 - lc.ch(win2To1Label)))

    local lose1To2Label = V.createTTF("1:2"..Str(STR.GET_LOSE).."  "..pbDark.one_two_lose, V.FontSize.S2, V.COLOR_TEXT_WHITE)
    lose1To2Label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(area, lose1To2Label, cc.p(lc.x(loseLabel), lc.y(win2To1Label)))

    local win1To0Label = V.createTTF("1:0"..Str(STR.GET_WIN).."  "..pbDark.one_zero_win, V.FontSize.S2, V.COLOR_TEXT_WHITE)
    win1To0Label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(area, win1To0Label, cc.p(lc.x(winLabel), lc.bottom(win2To1Label) - 16 - lc.ch(win1To0Label)))

    local lose0To1Label = V.createTTF("0:1"..Str(STR.GET_LOSE).."  "..pbDark.zero_one_lose, V.FontSize.S2, V.COLOR_TEXT_WHITE)
    lose0To1Label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(area, lose0To1Label, cc.p(lc.x(loseLabel), lc.y(win1To0Label)))
end

function _M:createLabelValueArea(labelStr, val)
    local area = lc.createNode(cc.size(220, 46))
    area:setAnchorPoint(cc.p(0, 0.5))
    
    local label = V.createTTF(labelStr, V.FontSize.S2, V.COLOR_TEXT_LIGHT)
    lc.addChildToPos(area, label, cc.p(lc.cw(label), lc.ch(area)))

    local val = V.createTTF(val == 0 and Str(STR.VOID_SHORT) or val, V.FontSize.M1, V.COLOR_TEXT_LIGHT)
    lc.addChildToPos(area, val, cc.p(lc.right(label) + 40, lc.ch(area) - lc.ch(label) + lc.ch(val) - 2))

    return area
end

function _M:onEnter()
    _M.super.onEnter(self)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:onExit()
    _M.super.onExit(self)

    ClientData.removeMsgListener(self)
end

function _M:onMsg(msg)
    local msgType = msg.type

    if msgType == SglMsgType_pb.PB_TYPE_WORLD_DARK_DUEL_DASHBOARD then
        local pbDark = msg.Extensions[World_pb.SglWorldMsg.dark_duel_dash_board_resp]
        self:initDark(pbDark)

        if self._indicator then
            self._indicator:removeFromParent()
            self._indicator = nil
        end
        return true

    end
    
    return false
end

return _M