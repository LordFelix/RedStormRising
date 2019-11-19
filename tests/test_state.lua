local lu = require("tests.luaunit")
require("tests.dcs_stub")
local queryDcs = require("queryDcs")
local state = require("state")

TestState = {}

function TestState:setUp()
    -- reset state
    state.currentState = state.defaultState
end

function TestState:testRemoveGroupAndUnitIds()
    local groupData = {
        [1] = {
            ["visible"] = false,
            ["name"] = "groupName",
            ["groupId"] = 1001,
            ["units"] = {
                [1] = {
                    ["x"] = 1,
                    ["y"] = 2,
                    ["name"] = "unitName",
                    ["unitId"] = 1002,
                }
            },
        }
    }

    state.removeGroupAndUnitIds(groupData)
    lu.assertEquals(groupData, {
        [1] = {
            ["visible"] = false,
            ["name"] = "groupName",
            ["units"] = {
                [1] = {
                    ["x"] = 1,
                    ["y"] = 2,
                    ["name"] = "unitName",
                }
            },
        }
    })
end

function TestState:testReadStateFromDisk()
    local _state = state.readStateFromDisk([[tests\test_state.json]])
    lu.assertEquals(_state.ctld.nextGroupId, 188)
    lu.assertEquals(_state.ctld.nextUnitId, 848)
end

function TestState:testWriteStateToDisk()
    -- we're going to write the default state here
    local expectedState = state.defaultState
    local filename = os.tmpname()
    state.writeStateToDisk(filename)
    local actualState = state.readStateFromDisk(filename)
    lu.assertEquals(actualState, expectedState)
    os.remove(filename)
end

function TestState:testCopyToCtld()
    state.currentState.ctld.nextGroupId = 11
    state.currentState.ctld.nextUnitId = 22
    state.copyToCtld()
    lu.assertEquals(ctld.nextGroupId, 11)
    lu.assertEquals(ctld.nextUnitId, 22)
end

function TestState:testCopyFomCtld()
    ctld.nextGroupId = 111
    ctld.nextUnitId = 222
    state.copyFromCtld()
    lu.assertEquals(ctld.nextGroupId, 111)
    lu.assertEquals(ctld.nextUnitId, 222)
end

function TestState:testUpdateBaseOwnership()
    state.currentState.baseOwnership = nil
    state.updateBaseOwnership()
    lu.assertEquals(state.currentState.baseOwnership, {
        airbases = { blue = {}, neutral = {}, red = {} },
        farps = { blue = {}, neutral = {}, red = {} } })
end

function TestState:testSetCurrentStateFromFileWithNoFileLoadsBaseOwnershipFromDcs()
    state.setCurrentStateFromFile([[filedoesnotexist.json]])
    local expectedState = mist.utils.deepCopy(state.defaultState)
    expectedState.baseOwnership = queryDcs.getAllBaseOwnership()
    lu.assertEquals(state.currentState, expectedState)
    lu.assertEquals(#state.currentState.persistentGroupData, 0)
end

function TestState:testSetCurrentStateFromFile()
    state.setCurrentStateFromFile([[tests\test_state.json]])
    lu.assertEquals(state.currentState.ctld.nextGroupId, 188)
    lu.assertEquals(state.currentState.ctld.nextUnitId, 848)
    lu.assertEquals(#state.currentState.baseOwnership.airbases.red, 3)
    lu.assertEquals(#state.currentState.baseOwnership.airbases.blue, 4)
    lu.assertEquals(#state.currentState.baseOwnership.farps.red, 0)
    lu.assertEquals(#state.currentState.baseOwnership.farps.blue, 2)
    lu.assertEquals(#state.currentState.persistentGroupData, 1)
end

local runner = lu.LuaUnit.new()
os.exit(runner:runSuite())

