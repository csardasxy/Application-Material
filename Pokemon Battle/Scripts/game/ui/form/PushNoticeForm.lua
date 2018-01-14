local _M = class("PushNoticeForm", BaseForm)

local FORM_SIZE = cc.size(600, 620)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.PUSH_NOTICE), bor(_M.FLAG.PAPER_BG, _M.FLAG.BASE_TITLE_BG, _M.FLAG.SCROLL_V))

    local form = self._form
    form:setTouchEnabled(false)

    local list = lc.List.createV(cc.size(lc.w(self._bg), lc.h(self._bg) - 10 - lc.h(self._titleFrame)), 20, 10)
    lc.addChildToPos(self._bg, list, cc.p(4, 12))
    self._list = list
    
    self:addItem(ClientData.ConfigKey.push_grain_noon, STR.PUSH_GRAIN_NOON)
    self:addItem(ClientData.ConfigKey.push_grain_night, STR.PUSH_GRAIN_NIGHT)
    self:addItem(ClientData.ConfigKey.push_reward_send, STR.PUSH_REWARD_SEND)    
    self:addItem(ClientData.ConfigKey.push_copy_pvp_unlock, STR.PUSH_COPY_PVP_UNLOCK)
    self:addItem(ClientData.ConfigKey.push_union_help, STR.PUSH_UNION_HELP)
    self:addItem(ClientData.ConfigKey.push_grain_full, STR.PUSH_GRAIN_FULL)
    self:addItem(ClientData.ConfigKey.push_gold_full, STR.PUSH_GOLD_FULL)
    self:addItem(ClientData.ConfigKey.push_guard_fragment, STR.PUSH_GUARD_FRAGMENT)
end

function _M:addItem(key, sid)
    local isOn = lc.UserDefault:getBoolForKey(key, true)

    local item = ccui.Widget:create()
    item._isOn = isOn

    local updateButton = function(btn, isOn)
        if isOn then
            btn._label:setString(Str(STR.ON))
            btn:loadTextureNormal("img_btn_1", ccui.TextureResType.plistType)
        else
            btn._label:setString(Str(STR.OFF))
            btn:loadTextureNormal("img_btn_2", ccui.TextureResType.plistType)
        end
    end

    local btnSwitch = V.createShaderButton("img_btn_1", function(btn)
        item._isOn = not item._isOn
        lc.UserDefault:setBoolForKey(key, item._isOn)

        if key == ClientData.ConfigKey.push_copy_pvp or key == ClientData.ConfigKey.push_union_help then
            ClientData.syncServerPush()
        end

        updateButton(btn, item._isOn)
    end)
    item:setContentSize(420, lc.h(btnSwitch))

    btnSwitch:addLabel("")
    lc.addChildToPos(item, btnSwitch, cc.p(lc.w(item) - lc.w(btnSwitch) / 2, lc.h(item) / 2))

    updateButton(btnSwitch, isOn)

    local text = V.createBoldRichText(Str(sid), V.RICHTEXT_PARAM_DARK_S1)
    lc.addChildToPos(item, text, cc.p(lc.w(text) / 2, lc.h(item) / 2))

    self._list:pushBackCustomItem(item)
    return item
end

return _M