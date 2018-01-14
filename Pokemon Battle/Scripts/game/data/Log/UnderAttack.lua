local _M = class("UnderAttack")

function _M:ctor()
    self._list = {}
end

function _M:clear()
    self._list = {}
end

function _M:addBattle(resp)
    table.insert(self._list, {
        _user = require("User").create(resp.user_info),
		_troop = ClientData.pbTroopToTroop(resp.troop),
        _isRevenge = resp.is_revenge or false,
        _isRescue = resp.is_rescue or false,
		_isUnionWar = false,
        _timestamp = resp.timestamp
    })
end

function _M:removeBattle(userId)
    for i, data in ipairs(self._list) do
        if data._user._id == userId and (not data._isUnionWar) then
            table.remove(self._list, i)
            return data
        end
    end
end

function _M:addUnionBattle(resp)
	table.insert(self._list, {
        _user = require("User").create(resp.attacker),
		_troop = nil,
        _isRevenge = flase,
		_isUnionWar = true,
        _timestamp = resp.timestamp
    })
end

function _M:removeUnionBattle(userId)
    for i, data in ipairs(self._list) do
        if data._user._id == userId and data._isUnionWar then
            table.remove(self._list, i)
            return data
        end
    end
end

return _M