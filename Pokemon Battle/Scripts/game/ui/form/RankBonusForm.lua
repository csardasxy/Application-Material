local _M = class("RankBonusForm", BaseForm)

local FORM_SIZE = cc.size(800, 600)
local CLASH_FORM_SIZE = cc.size(800, 630)
local LADDER_FORM_SIZE = cc.size(800, 450)

function _M.create(rank, type, param)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(rank, type, param)
    return panel
end

function _M.createClash(type, section)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:initClash(type, section)
    return panel
end

function _M:init(rank, type, param)
    local playerRank = P._playerRank
    self._type = type
    self._param = param

    _M.super.init(self, FORM_SIZE, Str(STR.BONUS_RULE), 0)
    self:initBonusList(FORM_SIZE.height - 60, type)
end

function _M:initClash(type, section)
    local title = Str(STR.BONUS_RULE)
    _M.super.init(self, LADDER_FORM_SIZE, title, 0)

    local form = self._form

    -- Top 3 bonuses
    local bgTop = lc.createSprite{_name = "img_com_bg_10", _crect = V.CRECT_COM_BG10, _size = cc.size(lc.w(form) - _M.FRAME_THICK_H - 40, 340)}
    lc.addChildToPos(form, bgTop, cc.p(lc.w(form) / 2, lc.bottom(self._titleFrame) - 16 - lc.h(bgTop) / 2))

    local gInfo, sectionName = Data._globalInfo._ladderStage        
    if section == 0 then
        sectionName = Str(STR.TOTAL_RANK)
    elseif section == #gInfo then
        sectionName = string.format(Str(STR.LEVEL_ABOVE), lc.arrayAt(gInfo, -1))
    else
        sectionName = string.format("%d%s-%d%s", gInfo[section], Str(STR.LEVEL_S), gInfo[section + 1] - 1, Str(STR.LEVEL_S))
    end

    local label = V.addDecoratedLabel(bgTop, sectionName..Str(STR.RANK)..Str(STR.BONUS), cc.p(lc.w(bgTop) / 2, lc.h(bgTop) - 40), 26)
    label:setColor(V.COLOR_TEXT_LIGHT)

    --local tip = V.createBoldRichText(Str(STR.TOTAL_RANK_TIP), {_normalClr = V.COLOR_TEXT_LIGHT, _boldClr = V.COLOR_TEXT_GREEN_DARK, _fontSize = V.FontSize.S3})
    --lc.addChildToPos(bgTop, tip, cc.p(lc.w(bgTop) / 2, lc.bottom(label) - 18))

    local list = lc.List.createV(cc.size(lc.w(bgTop) - 20, lc.h(bgTop) - 20), 10, 10)
    lc.addChildToCenter(bgTop, list)
    lc.offset(list, 3, 2)

    local bonusIds = {}
    for k, v in pairs(Data._rankBonusInfo) do
        if v._type == type then
            table.insert(bonusIds, v._bonusId)
        end
    end

    local createRewardArea = function(index)
        local area = lc.createNode(cc.size(200, 210))
                
        local medal = lc.createSprite(string.format("img_medal_%d", index))
        lc.addChildToPos(area, medal, cc.p(lc.w(area) / 2, lc.h(area) - lc.h(medal) / 2))
        
        if #bonusIds > 0 then
            local bonus, icons = Data._bonusInfo[bonusIds[index]], {}
            for i, infoId in ipairs(bonus._rid) do
                local icon = IconWidget.create({_infoId = infoId, _count = bonus._count[i], _isFragment = bonus._isFragment[i] > 0}, IconWidget.DisplayFlag.ITEM)
                icon._name:setColor(V.COLOR_TEXT_LIGHT)
                table.insert(icons, icon)
            end
            lc.addNodesToCenterH(area, icons, 16, 60)
        end

        return area
    end

    local area1, area2, area3 = createRewardArea(1), createRewardArea(2), createRewardArea(3)
    local line1, line2 = lc.createSprite("img_divide_line_5"), lc.createSprite("img_divide_line_5")
    line1:setColor(cc.c3b(170, 150, 100))
    line1:setRotation(90)
    line2:setColor(line1:getColor())
    line2:setRotation(90)
    lc.addChildToPos(bgTop, area1, cc.p(lc.w(bgTop) / 2, 30 + lc.h(area1) / 2))
    lc.addChildToPos(bgTop, line1, cc.p(lc.left(area1) - 10, lc.y(area1)))
    lc.addChildToPos(bgTop, area2, cc.p(lc.left(area1) - 20 - lc.w(area2) / 2, lc.y(area1)))
    lc.addChildToPos(bgTop, line2, cc.p(lc.right(area1) + 10, lc.y(area1)))
    lc.addChildToPos(bgTop, area3, cc.p(lc.right(area1) + 20 + lc.w(area3) / 2, lc.y(area1)))

    -- Legend avatars
    if false then
        local bgBottom = lc.createSprite{_name = "img_com_bg_10", _crect = V.CRECT_COM_BG10, _size = cc.size(lc.w(bgTop), 226)}
        lc.addChildToPos(form, bgBottom, cc.p(lc.w(form) / 2, _M.FRAME_THICK_BOTTOM + 20 + lc.h(bgBottom) / 2))

        label = V.addDecoratedLabel(bgBottom, Str(STR.FIND_CLASH_LEGEND_AVATARS), cc.p(lc.w(bgBottom) / 2, lc.h(bgBottom) - 40), 26)
        label:setColor(V.COLOR_TEXT_LIGHT)

        local avatarIds, icons = {Data.PropsId.avatar_frame_clash_4, Data.PropsId.avatar_frame_clash_3, Data.PropsId.avatar_frame_clash_2, Data.PropsId.avatar_frame_clash_1}, {}
        for _, id in ipairs(avatarIds) do
            local icon = IconWidget.create({_infoId = id}, IconWidget.DisplayFlag.ITEM)
            icon._name:setColor(V.COLOR_TEXT_LIGHT)
            table.insert(icons, icon)
        end
        lc.addNodesToCenterH(bgBottom, icons, 24, 92)
    end
end

function _M:initBonusList(top, type)
    local form = self._form
    type = type or SglMsgType_pb.PB_TYPE_RANK_TROPHY

    local bg = lc.createImageView{_name = "img_com_bg_10", _crect = V.CRECT_COM_BG10, _size = cc.size(lc.w(form) - _M.FRAME_THICK_H - 40, top - _M.FRAME_THICK_BOTTOM - 30)}
    lc.addChildToPos(form, bg, cc.p(lc.w(form) / 2, _M.FRAME_THICK_BOTTOM + 20 + lc.h(bg) / 2))

    local list = lc.List.createV(cc.size(lc.w(bg) - 30, lc.h(bg) - 30), 10, 10)
    lc.addChildToPos(bg, list, cc.p(18, 18))
    self._list = list

    local bonuses = {}
    for _, info in pairs(Data._rankBonusInfo) do
        if info._type == type then
            table.insert(bonuses, info)
        end
    end
    table.sort(bonuses, function(a, b) return a._id < b._id end)

    if self._type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_SCORE then
        table.insert(bonuses, {_type = 1706, _bonusId = 10509})
    end

    list:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(10, #bonuses))
    for i = 1, list._cacheCount do
        local item = self:setOrCreateItem(nil, bonuses[i])
        list:pushBackCustomItem(item)
    end
end

function _M:setOrCreateItem(item, info)
    local NAME_TAG = 100
    if item == nil then
        item = lc.createImageView{_name = "img_com_bg_35", _crect = V.CRECT_COM_BG35}
        item:setContentSize(lc.w(self._list), 108)

        local bar = lc.createSprite('img_bg_deco_35')
        
        lc.addChildToPos(item, bar, cc.p(lc.w(bar) / 2, lc.h(item) / 2 + 3))

        item._icons = {}

        item.update = function(info)
            local bonus = Data._bonusInfo[info._bonusId]

            bar:setColor(info._max == 1 and cc.c3b(250, 64, 0) or (info._max == 2 and cc.c3b(0, 144, 250) or (info._max == 3 and cc.c3b(166, 128, 136) or cc.c3b(255, 255, 255))))
            item:removeChildByTag(NAME_TAG)
            if info._id then
                if info._max <= 3 and info._min == info._max then
                    local medal = lc.createSprite(string.format("img_medal_%d", info._max))
                    lc.addChildToPos(item, medal, cc.p(75, lc.ch(item)), 0, NAME_TAG)
                elseif info._min == info._max then
                    local name = V.createBMFont(V.BMFont.num_48, info._min)
                    lc.addChildToPos(item, name, cc.p(75, lc.ch(item)), 0, NAME_TAG)
                else
                    local name = V.createBMFont(V.BMFont.num_48, info._min.."-"..info._max)
                    lc.addChildToPos(item, name, cc.p(75, lc.ch(item)), 0, NAME_TAG)
                end
            else
                if self._type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_SCORE then
                    local name = V.createBMFont(V.BMFont.num_48, Str(STR.NO_CHALLENGE))
                    lc.addChildToPos(item, name, cc.p(75, lc.ch(item)), 0, NAME_TAG)
                end
            end

            for _, icon in ipairs(item._icons) do
                icon:setVisible(false)
            end

            local totalNum = #bonus._rid
            for i, infoId in ipairs(bonus._rid) do
                local data = {_infoId = bonus._rid[i], _count = bonus._count[i], _level = bonus._level[i], _isFragment = bonus._isFragment[i] > 0}
                local icon = item._icons[i]
                if not icon then
                    icon = IconWidget.create(data, IconWidget.DisplayFlag.ITEM_NO_NAME)
                    icon:setScale(0.95)
                    icon:setSwallowTouches(false)
                    lc.addChildToPos(item, icon, cc.p(lc.cw(item) + lc.cw(bar) + (i - totalNum / 2 - 0.5) * 140, lc.ch(item) + 3))
                    table.insert(item._icons, icon)
                else
                    icon:resetData(data)
                    bonusItem:setVisible(true)
                end
            end
        end
    end

    item.update(info)

    return item
end

return _M