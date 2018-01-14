local _M = class("IconWidget", lc.ExtendUIWidget)

_M.SIZE = 92

_M.DisplayFlag = {
    --EVOLUTION       = 0x0001,           -- _evolution: evolution level
    LEVEL           = 0x0002,           -- _level: object level
    COUNT           = 0x0004,           -- _count: object count
    --TROOP_COUNT     = 0x0008,           -- _troopCount: object level
    NAME            = 0x0010,           -- _name: object name
    COUNT_RANGE     = 0x0020            -- _param: {_min, _max}
}

_M.DisplayFlag.ITEM = bor(_M.DisplayFlag.COUNT, _M.DisplayFlag.NAME)
_M.DisplayFlag.ITEM_RANGE = bor(_M.DisplayFlag.COUNT_RANGE, _M.DisplayFlag.NAME)
_M.DisplayFlag.ITEM_NO_NAME = bor(_M.DisplayFlag.COUNT)
_M.DisplayFlag.CARD_TROOP = bor(_M.DisplayFlag.LEVEL, _M.DisplayFlag.COUNT)

local CardInfoPanel = require("CardInfoPanel")

--- Create icon by data which contains all information for displaying
-- data = {_infoId, _count|_num, troopCount}
function _M.create(input, flag)
    local widget = lc.Pool.get("IconWidget")
    
    local data = widget._data
    data._infoId = input._infoId
    data._count = input._count or input._num
    data._param = input._param
    data._showOwnCount = input._showOwnCount
    
    data._cardList = input._cardList
    data._index = input._index
    data._title = input._title

    widget:resetIcon()
    widget:setData(data, flag)
    return widget
end

function _M.createByBonus(bonusInfo, i, flag)
    local widget = lc.Pool.get("IconWidget")
    
    local data = widget._data
    data._infoId = bonusInfo._rid[i]
    data._count = bonusInfo._count[i]
    data._param = bonusInfo._param

    widget:resetIcon()
    widget:setData(data, flag)
    return widget
end

function _M.createByInfoId(infoId, count, flag)
    local widget = lc.Pool.get("IconWidget")
    
    local data = widget._data
    data._infoId = infoId
    data._count = count
    
    widget:resetIcon()
    widget:setData(data, flag or _M.DisplayFlag.CARD_TROOP)
    return widget
end

--- Reset the icon to the specified data
function _M:resetData(input)
    local data = self._data
    data._infoId = input._infoId
    data._count = input._count or input._num
    data._param = input._param

    self:setData(data, self._flag)
end

function _M:init()
    self:setCascadeOpacityEnabled(true)

    self._data = {}
    self._nameColor = V.COLOR_TEXT_DARK

    local frame = cc.ShaderSprite:createWithFramename("card_icon_quality_00")
    frame:setCascadeOpacityEnabled(true)
    self:addProtectedChild(frame)
    self._frame = frame
    
    local img = cc.ShaderSprite:createWithFramename("img_blank")
    lc.addChildToCenter(frame, img, -1)
    self._img = img
    
    lc.addChildToCenter(frame, lc.createSprite("img_card_ico_bg"), -2)
    
    --[[
    local levelBg = lc.createSprite('card_icon_level_01')
    lc.addChildToPos(frame, levelBg, cc.p(12, 90))
    self._levelBg = levelBg
    ]]

    local countBg = lc.createSprite('icon_mask')
    countBg:setCascadeOpacityEnabled(true)
    lc.addChildToPos(frame, countBg, cc.p(lc.w(frame) / 2, lc.h(countBg) / 2 + 10), -1)

    local count = V.createBMFont(V.BMFont.huali_20, "")
    count:setScale(0.8)
    count:setAnchorPoint(1.0, 0.5)
    lc.addChildToPos(countBg, count, cc.p(lc.w(countBg), lc.h(countBg) / 2))
    countBg._count = count
    self._countBg = countBg

    local name = cc.Label:createWithTTF("", V.TTF_FONT, V.FontSize.M1)
    name:setScale(0.6)
    self:addProtectedChild(name)
    self._name = name

    self.setGray = function(self, isGray)
        if isGray then
            self._frame:setEffect(V.SHADER_DISABLE)
            self._img:setEffect(V.SHADER_DISABLE)
        else
            self._frame:setEffect(self._frame._shader)
            self._img:setEffect(self._img._shader)
        end
    end

    self:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

    -- Override setEnabled() methods
    local superSetEnabled = self.setEnabled
    self.setEnabled = function(self, isEnabled)
        self:setGray(not isEnabled)
        self:setTouchEnabled(isEnabled)
        superSetEnabled(self, isEnabled)
    end
end

function _M:resetIcon()
    -- Restore fields
    self:setAnchorPoint(0.5, 0.5)
    self:setPosition(0, 0)
    self:setRotation(0)
    self:setScale(1)
    self:setOpacity(255)
    self:setVisible(true)
    self:setCameraMask(ClientData.CAMERA_2D_FLAG)

    self._nameColor = V.COLOR_TEXT_DARK

    self._callback = nil

    self:removeAllChildren()

    -- Restore touch callback
    self:setEnabled(true)
    local touchEventListener = function(sender, touchType, touch)
        if touchType == ccui.TouchEventType.began then
            local longPressTimer = 0.3
            self._longPressTime = 0
            self._isLongPressing = nil

            self._longPressID = lc.Scheduler:scheduleScriptFunc(function(dt)  
                if not self._isLongPressing then
                    self._longPressTime = self._longPressTime + dt
                    if self._longPressTime >= longPressTimer then
                        self._isLongPressing = true
                        
                        local panel = require("TopMostPanel").DescPanel.createByInfoId(self._data._infoId, false)
                        if panel then
                            local hw, hh = lc.w(panel) / 2, lc.h(panel) / 2

                            local gPos = cc.pAdd(lc.convertPos(cc.p(lc.w(self) / 2, lc.h(self)), self), cc.p(0, hh + 6))
                            if gPos.x - hw < 0 then
                                gPos.x = hw
                            elseif gPos.x + hw > V.SCR_W then
                                gPos.x = V.SCR_W - hw
                            end

                            if gPos.y + hh > V.SCR_H then
                                gPos.y = V.SCR_H - hh
                            elseif gPos.y - hh < 0 then
                                gPos.y = hh
                            end

                            panel:setPosition(gPos)
                            panel:show()
                        end
                    end
                end
            end, lc.absTime(0.1), false)

        elseif touchType == ccui.TouchEventType.moved then
            if cc.pGetDistance(touch:getLocation(), touch:getStartLocation()) > lc.Gesture.BUDGE_LIMIT then
                self:cancelLongPress()
                if self._isLongPressing then
                    BasePanel.hideTopMost()
                end
            end

        elseif touchType == ccui.TouchEventType.ended or touchType == ccui.TouchEventType.canceled then
            self:cancelLongPress()
            if self._isLongPressing then
                BasePanel.hideTopMost()
                return
            end

            if touchType == ccui.TouchEventType.ended then
                if self._callback then
                    self._callback(self)

                else
                    local data = self._data

                    local scene, panel = lc._runningScene
                    if data._infoId > 0 then
                        if GuideManager.isGuideEnabled() then
                            GuideManager.pauseGuide()
                        end

                        local type = Data.getType(data._infoId)
                        if type == Data.CardType.res or type == Data.CardType.exp or type == Data.CardType.props or type == Data.CardType.common_fragment then
                            panel = require("DescForm").create(data)
                            panel:show()
                        else
                            local cardInfoPanel = CardInfoPanel.create(data._infoId)
                            if data._cardList ~= nil then
                                cardInfoPanel:setCardList(data._cardList, data._index, data._title)
                                cardInfoPanel:setCardCount(data._count)
                            end
                            cardInfoPanel:show()
                        end

                        if panel and scene._sceneId == ClientData.SceneId.battle then
                            panel:setLocalZOrder(BattleScene.ZOrder.form + 1)
                        end
                    end
                end
            end

        end
    end
    self:addTouchEventListener(touchEventListener)
end

function _M:setData(data, flag)
    local frame, img, name = self._frame, self._img, self._name
    img:removeAllChildren()

    flag = flag or _M.DisplayFlag.ITEM
    self._flag = flag

    local count = data._count
    if Data.getType(data._infoId) == Data.CardType.props then
        if data._infoId >= Data.PropsId.special then
            count = nil
        end
    end

    if count and count >= 0 and band(flag, _M.DisplayFlag.COUNT) ~= 0 then
        self._countBg:setVisible(true)
        self._countBg._count:setVisible(true)
        self._countBg._count:setColor(lc.Color3B.white)
        self._countBg._count:setString(ClientData.formatNum(count, 9999))

    elseif data._param and band(flag, _M.DisplayFlag.COUNT_RANGE) ~= 0 then
        self._countBg:setVisible(true)
        self._countBg._count:setVisible(true)
        self._countBg._count:setColor(lc.Color3B.white)
        self._countBg._count:setString(string.format("%s-%s", ClientData.formatNum(data._param._min, 9999), ClientData.formatNum(data._param._max, 9999)))

    else
        self._countBg:setVisible(false)
        self._countBg._count:setVisible(false)
    end

    if band(flag, _M.DisplayFlag.NAME) ~= 0 then
        local str = ClientData.getNameByInfoId(data._infoId)
        name:setVisible(true)
        name:setString(str)
        name:setColor(self._nameColor)
        --name:setTTFConfig{fontFilePath = V.TTF_FONT, fontSize = (lc.utf8len(str) > 4 and V.FontSize.S3 or V.FontSize.S2)}

        self:setContentSize(lc.w(frame), lc.h(frame) + 24)
        name:setPosition(lc.sw(self) / 2, lc.sh(name) / 2)
        frame:setPosition(lc.w(self) / 2, lc.h(self) - lc.h(frame) / 2)
    else
        name:setVisible(false)
        self:setContentSize(lc.w(frame), lc.h(frame))
        frame:setPosition(lc.w(self) / 2, lc.h(self) / 2)
    end

    if self._decArea then
        self._decArea:removeFromParent()
        self._decArea = nil
    end

    img:removeAllChildren()
	img:setScale(1)

    if data._infoId == 0 then
        self:setSpriteDisplay(frame, "card_icon_quality_00")
        self:setSpriteDisplay(img, "card_ico_0")
    else
        local info, type = Data.getInfo(data._infoId)
        if type == Data.ResType.fragment then
            info = Data.getInfo(P._playerCard:convert2CardId(data._infoId))
        end

        if info == nil and type ~= Data.CardType.nature and type ~= Data.CardType.category and type ~= Data.CardType.keyword then
            data._infoId = 10001
            info, type = Data.getInfo(data._infoId)
        end

        if type == Data.CardType.res then       
            self:setSpriteDisplay(frame, "card_icon_quality_00")
            self:setSpriteDisplay(img, string.format("res_ico_%d", data._infoId))
        elseif type == Data.CardType.nature or type == Data.CardType.category or type == Data.CardType.keyword then
            self:setSpriteDisplay(frame, "card_icon_quality_01", V.SHADER_TYPES[Data.CardType.monster])
            self:setSpriteDisplay(img, string.format("card_ico_%d", data._infoId))
        elseif type == Data.CardType.other then
            if data._infoId <= 60010 then
                --[[
                local shaderIndex
                if data._infoId <= 60005 then
                    shaderIndex = data._infoId - 60000
                elseif data._infoId == 60006 then
                    shaderIndex = Data.CardQuality.UR
                end

                self:setSpriteDisplay(frame, "card_icon_quality_00", V.SHADER_COLORS[shaderIndex])
                self:setSpriteDisplay(img, "card_icon_unknow")
                ]]
                self:setSpriteDisplay(frame, "card_icon_quality_00")
                self:setSpriteDisplay(img, "card_icon_unknow")
            else
                self:setSpriteDisplay(frame, "card_icon_quality_00")
                self:setSpriteDisplay(img, "card_icon_unknow")
            end
        else
            if type == Data.CardType.props then
                if Data.isAvatarFrame(data._infoId) then
                    local id = P._propBag:validPropId(data._infoId)

                    -- avatar frame
                    self:setSpriteDisplay(img, ClientData.getAvatarFrameName(id))
                    img:setScale(0.7)
                    self:setSpriteDisplay(frame, "card_icon_quality_00")

                    local _, extra = V.getPropExtra(data._infoId, img)
                    if extra then
                        img:addChild(extra)
                    end

                elseif Data.isCardBack(data._infoId) then
                    -- card back
                    self:setSpriteDisplay(img, V.getCardBackName(data._infoId))
                    img:setScale(0.12)
                    self:setSpriteDisplay(frame, "card_icon_quality_00")

                elseif info._type == Data.PropsType.artifact then
                    self:setSpriteDisplay(frame, "card_icon_empty")
                    self:setSpriteDisplay(img, ClientData.getPropIconName(data._infoId, true))

                else
                    local quality = info._quality
                    local cardType = info._cardType
                    if cardType > 0 then
                        self:setSpriteDisplay(frame, "card_icon_quality_00", V.SHADER_TYPES[cardType])
                      else
                        self:setSpriteDisplay(frame, "card_icon_quality_00")
                    end
                
                    self:setSpriteDisplay(img, ClientData.getPropIconName(data._infoId, true))
                end                                                       
            else
                local cardId = P._playerCard:convert2CardId(data._infoId)
                local shader = V.getCardShader(cardId)
                self:setSpriteDisplay(frame, "card_icon_quality_0"..info._quality, shader)
                self:setSpriteDisplay(img, V.getCardIconName(cardId))
                if type == Data.ResType.fragment then
                    local fragmentIcon = lc.createSprite("img_icon_fragment")
                    lc.addChildToPos(self, fragmentIcon, cc.p(14, lc.h(frame) + 10))
                end
            end
        end

        if count and count < 0 then
            self:setGray(true)
        end
    end
end

function _M:setNameColor(color)
    self._nameColor = color
    self._name:setColor(self._nameColor)
end

function _M:setSpriteDisplay(sprite, frameName, shader)
    if frameName then
        sprite:setSpriteFrame(frameName)
    end

    --sprite:setEffect(shader)
    --sprite._shader = shader
end

function _M:cancelLongPress()
    if self._longPressID then
        lc.Scheduler:unscheduleScriptEntry(self._longPressID)
        self._longPressID = nil
    end
end

function _M:checkHighlight()
    if self:needHighlight() then
        local light1 = lc.createSprite('img_light_3')
        light1:setColor(lc.Color3B.yellow)
        light1:setScale(1.5)
        lc.addChildToCenter(self, light1, -2)
        lc.offset(light1, 0, 12)

        local light2 = lc.createSprite('img_light_2')
        light2:setColor(light1:getColor())
        light2:setScale(3.0)
        light2:runAction(lc.rep(lc.rotateBy(4, 360)))
        lc.addChildToPos(self, light2, cc.p(light1:getPosition()), -1)
        self._light1 = light1
        self._light2 = light2
    end 
end

function _M:needHighlight()
    if self._data == nil or self._data._infoId == nil or self._data._count == nil then return false end
    local infoId, count = self._data._infoId, self._data._count
    local type = Data.getType(infoId)
    if type >= Data.CardType.monster and type <= Data.CardType.trap then return true end
    if infoId == Data.PropsId.rare_package_ticket or infoId == Data.PropsId.character_package_ticket or infoId == Data.PropsId.times_package_ticket then return count >= 5
    elseif infoId == Data.PropsId.millennium_block then return true
    end
    return false
end

function _M:onEnter()
    if band(self._flag, _M.DisplayFlag.LEVEL) ~= 0 then
        self._listener = lc.addEventListener(Data.Event.card_dirty, function(event) 
            if event._infoId == self._data._infoId then
                self:setData(self._data, self._flag)
            end
        end)
    end
end

function _M:onExit()
    if self._listener then
        lc.Dispatcher:removeEventListener(self._listener)
    end
end

function _M:onCleanup()
    lc.Pool.free(self)
end

IconWidget = _M
IconWidgetFlag = IconWidget.DisplayFlag

--- Pool related functions
-- The user should not call call these functions directly

function _M.poolCreate()
    local widget = _M.new(lc.EXTEND_WIDGET)
    widget:retain()
    widget:init()
    return widget
end

function _M:poolGet()
    if self:getParent() then
        self:removeFromParent(false)
    end
end

function _M:poolClear()
    self:release()
end

local POOL_SIZE = 100
lc.Pool.new("IconWidget", POOL_SIZE)

function _M.releaseToPool(item)
-- needs fix
   --item:removeFromParent()
    item._isBusy = false
end

return _M