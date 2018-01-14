local _M = class("BattleTestInputForm", BaseForm)

local FORM_SIZE = cc.size(720, 280)

local BTN_STR = {Str(STR.SEND), Str(STR.CHANGE), Str(STR.SEND)}

local KEY = {
    _ENTER       = 35, -- to confirm modification
    _BACKSPACE   = 7,
    _DELETE      = 23, -- to clear input content
    _0           = 76,
    _1           = 77,
    _2           = 78,
    _3           = 79,
    _4           = 80,
    _5           = 81,
    _6           = 82,
    _7           = 83,
    _8           = 84,
    _9           = 85,
    _ESC         = 6,
    _A           = 124,
    _B           = 125,
    _C           = 126,
    _D           = 127,
    _E           = 128,
    _F           = 129,
    _G           = 130,
    _H           = 131,
    _I           = 132,
    _J           = 133,
    _K           = 134,
    _L           = 135,
    _M           = 136,
    _N           = 137,
    _O           = 138,
    _P           = 139, 
    _Q           = 140,
    _R           = 141,
    _S           = 142,  
    _T           = 143,
    _U           = 144,
    _V           = 145,
    _W           = 146,
    _X           = 147,
    _Y           = 148,
    _Z           = 149,
    _SHORT_LINE   = 73,
}

function _M.create(callback, opType)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(callback, opType)
    return panel
end

function _M:init(callback, opType)
    _M.super.init(self, FORM_SIZE, "input", 0)

    self._callback = callback
    self._opType = opType
    self._hideBg = true

    local form = self._form

    -- edit box
    local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), cc.size(600, 60), Str(STR.INPUT_SHARE_TEXT))
    lc.addChildToPos(form, editor, cc.p(lc.w(form) / 2, lc.bottom(self._titleFrame) - 20 - lc.h(editor) / 2))
    self._editor = editor
    self._editor:setTouchEnabled(false)

--    local btnConfirm = V.createScale9ShaderButton("img_btn_2", function() self:confirm() end, V.CRECT_BUTTON, 120)
--    btnConfirm:addLabel(Str(STR.CONFIRM))
--    lc.addChildToPos(form, btnConfirm, cc.p(lc.right(editor) - lc.w(btnConfirm) / 2, 80))
--    self._btnConfirm = btnConfirm
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._inputContent = ""
    self._keyListener = lc.addEventListener(Data.Event.unitest, function(event) 
        self:onKeyEvent(event)
    end)
end

function _M:onExit()
    _M.super.onExit(self)

    lc.Dispatcher:removeEventListener(self._keyListener)
end

function _M:onKeyEvent(event)
    local key = tonumber(event._key)
    print ('##################', event._key, "type " , type(event._key))

    if key == KEY._ENTER then
        self:confirm()
    elseif key == KEY._DELETE then
        self._inputContent = ""
    elseif key == KEY._BACKSPACE then
        if self._inputContent ~= "" then
            self._inputContent = string.sub(self._inputContent, 1, #self._inputContent - 1)
        end
    elseif key == KEY._ESC then
        self:hide()
    else 
        self._inputContent = self._inputContent .. self:parseKey(key)
    end
    if self._opType == BattleTestData.OperationType._export then
        self._inputContent = string.lower(self._inputContent)
    end
    self._editor:setText(self._inputContent)
    print("00000000000000000000000--", self._inputContent)
end

function _M:parseKey(key)
    if key == KEY._0 then
        return "0"
    elseif key == KEY._1 then
        return "1"
    elseif key == KEY._2 then
        return "2"
    elseif key == KEY._3 then
        return "3"
    elseif key == KEY._4 then
        return "4"
    elseif key == KEY._5 then
        return "5"
    elseif key == KEY._6 then
        return "6"
    elseif key == KEY._7 then
        return "7"
    elseif key == KEY._8 then
        return "8"
    elseif key == KEY._9 then
        return "9"
    end

    if self._opType == BattleTestData.OperationType._export then
        if key == KEY._A then
            return "A"
        elseif key == KEY._B then
            return "B"
        elseif key == KEY._C then
            return "C"
        elseif key == KEY._D then
            return "D"
        elseif key == KEY._E then
            return "E"
        elseif key == KEY._F then
            return "F"
        elseif key == KEY._G then
            return "G"
        elseif key == KEY._H then
            return "H"
        elseif key == KEY._I then
            return "I"
        elseif key == KEY._J then
            return "J"
        elseif key == KEY._K then
            return "K"
        elseif key == KEY._L then
            return "L"
        elseif key == KEY._M then
            return "M"
        elseif key == KEY._N then
            return "N"
        elseif key == KEY._O then
            return "O"
        elseif key == KEY._P then
            return "P"
        elseif key == KEY._Q then
            return "Q"
        elseif key == KEY._R then
            return "R"
        elseif key == KEY._S then
            return "S"
        elseif key == KEY._T then
            return "T"
        elseif key == KEY._U then
            return "U"
        elseif key == KEY._V then
            return "V"
        elseif key == KEY._W then
            return "W"
        elseif key == KEY._X then
            return "X"
        elseif key == KEY._Y then
            return "Y"
        elseif key == KEY._Z then
            return "Z"
        elseif key == KEY._SHORT_LINE then
            return "-"
        end
    end
    return ""
end

function _M:confirm()
    local text = self._editor:getText()

    local maxLength = 5
    if self._opType == BattleTestData.OperationType._modifyHp then
        maxLength = 5
    elseif self._opType == BattleTestData.OperationType._export then
        maxLength = 12
    end

    if lc.utf8len(text) > maxLength  then
        ToastManager.push(Str(STR.MESSAGE)..string.format(Str(STR.CANNOT_MORE_THAN), maxLength))
        return

    elseif lc.utf8len(text) == 0 then
        ToastManager.push(Str(STR.INPUT_MESSAGE))
        return
    else
        if self._opType == BattleTestData.OperationType._modifyHp then
            local n = tonumber(text)
            if n == nil then
                ToastManager.push(string.format(Str(STR.INPUT_NUMBER), 400))
            else 
                if self._callback ~= nil then
                    self._callback(text)
                end
                self:hide()
            end
        elseif self._opType == BattleTestData.OperationType._export then
            
            if not string.find(text, "\\") and not string.find(text, "/") and not string.find(text, ":") then
                if self._callback ~= nil then
                    self._callback(text)
                end
                self:hide()
            else
                ToastManager.push(string.format(Str(STR.CANNOT_CONTAIN_SPECIAL_SYMBOL), "\\, /, :"))
            end
        end
    end
end

function _M:hide(isForce)
    _M.super.hide(self, isForce)
end

return _M