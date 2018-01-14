local _M = class("ClashUserInfoForm", BaseForm)

local FORM_SIZE = cc.size(710, 600)
local RANK_AREA_SIZE = cc.size(570, 310)

function _M.create(userId, isSelf)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(userId, isSelf)
    return panel
end

function _M:init(userId, isSelf)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    self._userId = userId
    self._isSelf = isSelf
    self._indicator = V.showPanelActiveIndicator(self._form)
end

function _M:initVisit(pbVisit)
    local user = require("User").create(pbVisit.user_info)

    local grade = P._playerFindClash:getGrade(user._trophy)
    local form = self._form

    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(form, titleBg, cc.p(lc.w(form) / 2, lc.h(form) - 10 - lc.h(titleBg) / 2))

    local title = V.createTTFStroke(Str(Data._ladderInfo[grade]._nameSid)..Str(STR.FIND_CLASH_FIELD), V.FontSize.M2)
    lc.addChildToCenter(titleBg, title)
    
    -- user icon and server
    local userWidget = UserWidget.create(user, UserWidget.Flag.NAME_UNION, 1, false, true)
    lc.addChildToPos(form, userWidget, cc.p(_M.FRAME_THICK_LEFT + 40 + lc.w(userWidget) / 2, lc.bottom(titleBg) - 30 - lc.h(userWidget) / 2))
    userWidget._unionArea._name:setColor(V.COLOR_TEXT_ORANGE)
    
    if self._isSelf then
        local btnLog = V.createScale9ShaderButton("img_btn_1_s", function() require("LogForm").create(Battle_pb.PB_BATTLE_WORLD_LADDER):show() end, V.CRECT_BUTTON_S, 120)
        btnLog:addLabel(Str(STR.LOG))    
        lc.addChildToPos(form, btnLog, cc.p(lc.right(userWidget) + 176 + lc.w(btnLog) / 2, lc.y(userWidget)))
    end

    --[[
    local region = V.createTTF(ClientData.genChannelRegionName(user._regionId), V.FontSize.S2, V.COLOR_LABEL_LIGHT)
    lc.addChildToPos(form, region, cc.p(lc.w(form) - _M.FRAME_THICK_RIGHT - 40 - lc.w(region) / 2, lc.top(userWidget) - lc.h(region) / 2 - 8))
    ]]

    -- detail info
    local area = lc.createImageView{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = RANK_AREA_SIZE}
    lc.addChildToPos(form, area, cc.p(lc.w(form) / 2, lc.bottom(userWidget) - lc.h(area) / 2 - 20))

    -- clash record
    local label = V.addDecoratedLabel(area, Str(STR.FIND_CLASH_RECORD), cc.p(lc.w(area) / 2, lc.h(area) - 50), 26)

    local trophyArea = V.createIconLabelArea("img_icon_res6_s", user._trophy, 160)    
    lc.addChildToPos(area, trophyArea, cc.p(lc.w(area) - lc.cw(trophyArea) - 20, lc.y(label:getParent())))

    local rankLast = self:createLabelValueArea(Str(STR.SEASON_LAST_RANK), pbVisit.pre_rank)
    lc.addChildToPos(area, rankLast, cc.p(lc.left(label:getParent()) + 13, lc.bottom(label:getParent()) - 16 - lc.ch(rankLast)))

    local rankBest = self:createLabelValueArea(Str(STR.SEASON_BEST_RANK), pbVisit.best_rank)
    lc.addChildToPos(area, rankBest, cc.p(lc.cw(area) + 20, lc.y(rankLast)))

    -- clash legend record
    local line = lc.createSprite{_name = "img_divide_line_8", _crect = cc.rect(6, 1, 1, 1), _size = cc.size(lc.w(area) - 16, 5)} 
    lc.addChildToPos(area, line, cc.p(lc.cw(area), lc.ch(area)))
    line:setRotation(180)

    local label = V.addDecoratedLabel(area, Str(STR.FIND_CLASH_LEGEND_RECORD), cc.p(lc.cw(area), lc.ch(area) - 45), 26, 1)

    local legendTrophyArea = V.createIconLabelArea("img_icon_props_s7131", pbVisit.legend_trophy, 160)    
    lc.addChildToPos(area, legendTrophyArea, cc.p(lc.w(area) - lc.cw(legendTrophyArea) - 20, lc.y(label:getParent())))

    local rankLast = self:createLabelValueArea(Str(STR.SEASON_LAST_RANK), pbVisit.pre_legend_rank)
    lc.addChildToPos(area, rankLast, cc.p(lc.left(label:getParent()) + 13, lc.bottom(label:getParent()) - 16 - lc.ch(rankLast)))

    local rankBest = self:createLabelValueArea(Str(STR.SEASON_BEST_RANK), pbVisit.best_legend_rank)
    lc.addChildToPos(area, rankBest, cc.p(lc.cw(area) + 20, lc.y(rankLast)))
end

function _M:createLabelValueArea(labelStr, val)
    local area = lc.createNode(cc.size(220, 46))
    area:setAnchorPoint(cc.p(0, 0.5))
    
    local label = V.createTTF(labelStr, V.FontSize.S2, V.COLOR_TEXT_LIGHT)
    lc.addChildToPos(area, label, cc.p(lc.cw(label), lc.ch(area)))

    local val = V.createTTF(val == 0 and Str(STR.VOID_SHORT) or val, V.FontSize.M1, V.COLOR_TEXT_LIGHT)
    lc.addChildToPos(area, val, cc.p(lc.right(label) + 40, lc.ch(area) - lc.ch(label) + lc.ch(val) - 2))

    lc.offset(val, 0, -6)

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

function _M:onShowActionFinished()
    ClientData.sendUserVisitRegion(self._userId)
end

function _M:onMsg(msg)
    local msgType = msg.type

    if msgType == SglMsgType_pb.PB_TYPE_USER_VISIT_EX then
        local pbVisit = msg.Extensions[User_pb.SglUserMsg.user_visit_ex_resp]
        self:initVisit(pbVisit)

        if self._indicator then
            self._indicator:removeFromParent()
            self._indicator = nil
        end
        return true

    end
    
    return false
end

return _M