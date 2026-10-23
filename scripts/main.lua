-- 基于官方 templates/scaffold-2d.lua：纯 UI、无物理、无现实倒计时。
local UI = require("urhox-libs/UI")
local Content = require("content")
local Game = require("game")
local View = require("view")

-- 内容为JSON；无扩展名的隔离存档槽位不是构建资产路径。
local SAVE_FILES = { "street_lending_slot_a", "street_lending_slot_b" }
local CLOUD_KEY = "street_lending_v1"
local model_ = {
    screen = "home", profile = { records = {}, completed = 0, sound = true },
    notice = "", saveWarning = "",
}
local actions_ = {}
---@type {model:table, actions:table}?
LendingApp = nil

local dirty_ = true
local sequence_ = 0
local runId_ = 0
local recordedRun_ = 0
---@type boolean
local stopped_ = false
-- 异步回调执行时重新读取生命周期，不沿用发起请求时的判断。
local function IsRunning()
    return not stopped_
end
local cloudReady_ = false
local cloudBusy_ = false
local cloudLoading_ = false
---@type number
local cloudElapsed_ = 0
local cloudGeneration_ = 0
---@type number
local retryElapsed_ = 0
local cloudQueue_ = ""
---@type table?
local confirmation_ = nil
---@type Scene?
local audioScene_ = nil
---@type SoundSource?
local soundSource_ = nil
local sounds_ = {}

local function Integer(value, low, high)
    return type(value) == "number" and value % 1 == 0 and value >= low and value <= high
end

local function DefaultProfile()
    return { records = {}, completed = 0, sound = true }
end

local function DecodeEnvelope(value)
    if type(value) == "string" then
        local ok, decoded = pcall(cjson.decode, value)
        if not ok then return nil end
        value = decoded
    end
    if type(value) ~= "table" or value.version ~= 1
        or not Integer(value.sequence, 0, 2147483646)
        or not Integer(value.runId, 0, 2147483646)
        or not Integer(value.recordedRun, 0, value.runId)
        or type(value.profile) ~= "table" then return nil end
    local source = value.profile
    if type(source.records) ~= "table" or type(source.sound) ~= "boolean"
        or not Integer(source.completed, 0, 1000000) then return nil end
    local profile = DefaultProfile()
    profile.sound, profile.completed = source.sound, source.completed
    for _, scenario in ipairs(Content.scenarios) do
        local record = source.records[scenario.id]
        if record ~= nil then
            if type(record) ~= "table" or not Integer(record.best, 0, scenario.maximum)
                or not Integer(record.stars, 0, 3) or not Integer(record.attempts, 1, 1000000) then
                return nil
            end
            profile.records[scenario.id] = {
                best = record.best, stars = record.stars, attempts = record.attempts,
            }
        end
    end
    local state
    if value.game ~= nil and value.game ~= cjson.null then
        state = Game.Restore(value.game)
        if not state then return nil end
    end
    return {
        version = 1, sequence = value.sequence, runId = value.runId,
        recordedRun = value.recordedRun, profile = profile, state = state,
    }
end

local function ApplyEnvelope(envelope)
    sequence_, runId_, recordedRun_ = envelope.sequence, envelope.runId, envelope.recordedRun
    model_.profile, model_.state = envelope.profile, envelope.state
    dirty_ = true
end

local function ReadLocal(path)
    if not fileSystem:FileExists(path) then return nil end
    local file = File(path, FILE_READ)
    if not file:IsOpen() then return nil end
    if file:GetSize() > 131072 then file:Close(); return nil end
    local text = file:ReadString()
    file:Close()
    return DecodeEnvelope(text)
end

local function LoadLocal()
    local found = false
    ---@type table?
    local best = nil
    for _, path in ipairs(SAVE_FILES) do
        if fileSystem:FileExists(path) then found = true end
        local ok, candidate = pcall(ReadLocal, path)
        if ok and candidate and (not best or candidate.sequence > best.sequence) then best = candidate end
    end
    if best then
        ApplyEnvelope(best)
    elseif found then
        model_.saveWarning = "原进度暂时无法读取，已保留原文件。开始新班次前可先检查存档。"
    end
end

local function HasCloudUser()
    return clientCloud ~= nil and type(clientCloud.userId) == "string" and clientCloud.userId ~= ""
end

---@type fun()
local PumpCloud

local function Save()
    local snapshot
    if model_.state then
        snapshot = Game.Snapshot(model_.state)
        if not snapshot then
            model_.saveWarning = "当前借还记录未通过校验，暂未覆盖存档。"
            dirty_ = true
            return false
        end
    end
    sequence_ = sequence_ + 1
    local envelope = {
        version = 1, sequence = sequence_, runId = runId_, recordedRun = recordedRun_,
        profile = model_.profile, game = snapshot,
    }
    local encoded = cjson.encode(envelope)
    local target = SAVE_FILES[sequence_ % 2 + 1]
    if not target then return false end
    local localOk = pcall(function()
        local file = File(target, FILE_WRITE)
        if not file:IsOpen() then error("存档文件无法写入") end
        local written = file:WriteString(encoded)
        file:Flush()
        file:Close()
        if written == false then error("存档写入未完成") end
        local check = ReadLocal(target)
        if not check or check.sequence ~= sequence_ then error("存档回读校验失败") end
    end)
    if not localOk then model_.saveWarning = "本地保存暂未完成，请先不要退出。" end
    if HasCloudUser() then
        cloudQueue_ = encoded
        if cloudReady_ then PumpCloud() end
    elseif localOk then
        model_.saveWarning = ""
    end
    dirty_ = true
    return localOk
end

PumpCloud = function()
    if stopped_ or not cloudReady_ or cloudBusy_ or cloudQueue_ == "" then return end
    local payload = cloudQueue_
    cloudQueue_ = ""
    cloudBusy_ = true
    local accepted = pcall(function()
        clientCloud:Set(CLOUD_KEY, payload, {
            ok = function()
                cloudBusy_ = false
                if not IsRunning() then return end
                model_.saveWarning = cloudQueue_ == "" and "" or "正在同步最新进度。"
                dirty_ = true
                PumpCloud()
            end,
            error = function()
                cloudBusy_ = false
                if cloudQueue_ == "" then cloudQueue_ = payload end
                if not IsRunning() then return end
                model_.saveWarning = "云端同步暂未完成，请在网络恢复后稍候。"
                retryElapsed_ = 0
                dirty_ = true
            end,
        })
    end)
    if not accepted then
        cloudBusy_ = false
        if cloudQueue_ == "" then cloudQueue_ = payload end
        model_.saveWarning = "云端同步暂不可用，进度仍在等待同步。"
        dirty_ = true
    end
end

local function LoadCloud()
    if not HasCloudUser() then return end
    cloudGeneration_ = cloudGeneration_ + 1
    local generation = cloudGeneration_
    cloudLoading_, cloudElapsed_ = true, 0
    local initialSequence = sequence_
    model_.notice = "正在读取值班记录，马上就好。"
    local ok = pcall(function()
        clientCloud:Get(CLOUD_KEY, {
            ok = function(values)
                if stopped_ or generation ~= cloudGeneration_ or not cloudLoading_ then return end
                local remote = type(values) == "table" and DecodeEnvelope(values[CLOUD_KEY]) or nil
                cloudLoading_ = false
                if sequence_ == initialSequence and remote and remote.sequence > sequence_ then
                    if sequence_ > 0 then
                        confirmation_ = { kind = "cloud", envelope = remote }
                        model_.notice = "发现另一份云端记录，请选择保留哪一份。"
                        dirty_ = true
                        return
                    end
                    ApplyEnvelope(remote)
                    cloudQueue_ = ""
                    cloudReady_ = true
                    model_.notice, model_.saveWarning = "", ""
                    Save()
                else
                    cloudReady_ = true
                    model_.notice, model_.saveWarning = "", ""
                    if sequence_ > 0 and (not remote or sequence_ > remote.sequence) then Save() end
                end
                dirty_ = true
            end,
            error = function()
                if stopped_ or generation ~= cloudGeneration_ or not cloudLoading_ then return end
                cloudLoading_ = false
                model_.notice = ""
                model_.saveWarning = "暂未读到云端记录。当前仅使用本地进度，请保持网络后重试。"
                dirty_ = true
            end,
        })
    end)
    if not ok then
        cloudLoading_ = false
        model_.notice = ""
        model_.saveWarning = "云端记录暂不可用，当前仅使用本地进度。"
    end
end

local function PlaySound(name)
    if model_.profile.sound and soundSource_ and sounds_[name] then
        soundSource_:Play(sounds_[name], 0, 0.28)
    end
end

local function RecordResult()
    if not model_.state or not model_.state.finished or recordedRun_ == runId_ then return end
    local result = Game.Result(model_.state)
    local key = model_.state.scenarioId
    local old = model_.profile.records[key] or { best = 0, stars = 0, attempts = 0 }
    model_.profile.records[key] = {
        best = math.max(old.best, result.completed), stars = math.max(old.stars, result.stars),
        attempts = old.attempts + 1,
    }
    model_.profile.completed = model_.profile.completed + 1
    recordedRun_ = runId_
end

local function StartShift(id)
    local state, message = Game.New(id)
    if not state then model_.notice = message or "这个班次暂不可用。"; dirty_ = true; return end
    runId_ = runId_ + 1
    model_.state, model_.screen, model_.notice = state, "game", state.status
    confirmation_ = nil
    PlaySound("page")
    Save()
end

function actions_.start(id)
    if stopped_ or cloudLoading_ or confirmation_ then return end
    if model_.state and not model_.state.finished then
        confirmation_ = { kind = "new", scenarioId = id }
        dirty_ = true
    else
        StartShift(id)
    end
end

function actions_.continueGame()
    model_.screen = model_.state and (model_.state.finished and "result" or "game") or "home"
    model_.notice = ""
    dirty_ = true
end

function actions_.home()
    model_.screen, model_.notice = "home", ""
    dirty_ = true
end

function actions_.show(screen)
    if screen == "rules" or screen == "schedule" or screen == "settings" or screen == "result" then
        model_.screen, model_.notice = screen, ""
        dirty_ = true
    end
end

local function Decide(lend, requestId)
    if cloudLoading_ or confirmation_ or not model_.state then return end
    local ok, message = Game.Decide(model_.state, lend, requestId)
    model_.notice = message or ""
    if ok then PlaySound(lend and "lend" or "page"); Save() end
    dirty_ = true
end

function actions_.lend(requestId) Decide(true, requestId) end
function actions_.decline(requestId) Decide(false, requestId) end

function actions_.nextRound()
    if cloudLoading_ or confirmation_ or not model_.state then return end
    local ok, message = Game.NextRound(model_.state)
    model_.notice = message or ""
    if ok then
        if model_.state.finished then
            RecordResult()
            model_.screen = "result"
            PlaySound("finish")
        else
            PlaySound("page")
        end
        Save()
    end
    dirty_ = true
end

function actions_.toggleSound()
    if cloudLoading_ or confirmation_ then return end
    model_.profile.sound = not model_.profile.sound
    Save()
    if model_.profile.sound then PlaySound("page") end
end

function actions_.resetProgress()
    if cloudLoading_ or confirmation_ then return end
    confirmation_ = { kind = "reset" }
    dirty_ = true
end

local function ConfirmOverlay()
    local resetting = confirmation_ and confirmation_.kind == "reset"
    local cloudConflict = confirmation_ and confirmation_.kind == "cloud"
    local function Cancel()
        if cloudConflict and confirmation_ then
            sequence_ = math.max(sequence_, confirmation_.envelope.sequence)
            cloudQueue_, cloudReady_ = "", true
            confirmation_ = nil
            Save()
        else
            confirmation_ = nil
        end
        dirty_ = true
    end
    local function Confirm()
        if not confirmation_ then return end
        local pending = confirmation_
        confirmation_ = nil
        if pending.kind == "new" then
            StartShift(pending.scenarioId)
        elseif pending.kind == "cloud" then
            ApplyEnvelope(pending.envelope)
            cloudQueue_, cloudReady_ = "", true
            model_.screen, model_.notice = "home", "已恢复云端值班记录。"
            Save()
        else
            model_.state, model_.profile = nil, DefaultProfile()
            recordedRun_ = runId_
            model_.screen, model_.notice = "home", "已清除本游戏的值班记录。"
            Save()
        end
    end
    return UI.Panel {
        position = "absolute", left = 0, top = 0, right = 0, bottom = 0,
        backgroundColor = { 17, 34, 29, 190 }, pointerEvents = "auto",
        justifyContent = "center", alignItems = "center", padding = 28,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 380, padding = 24, gap = 18,
                backgroundColor = { 255, 253, 247, 255 }, borderRadius = 18,
                children = {
                    UI.Label { text = cloudConflict and "选择要保留的记录" or (resetting and "确认清除记录？" or "重新开始这个班次？"),
                        fontSize = 21, fontColor = { 38, 55, 51, 255 }, whiteSpace = "normal" },
                    UI.Label { text = cloudConflict and "当前值班与云端记录不同，暂不能自动合并。选择一份继续，随后同步这份记录。"
                        or (resetting and "进行中的值班和个人纪录会被清除。"
                        or "进行中的班次会被替换，已完成的个人纪录会保留。"),
                        fontSize = 15, whiteSpace = "normal", fontColor = { 91, 110, 102, 255 } },
                    UI.Button { text = cloudConflict and "保留本次值班并同步" or "保留当前进度", height = 48, onClick = Cancel },
                    UI.Button { text = cloudConflict and "恢复云端记录" or (resetting and "确认清除" or "确认重新开始"),
                        height = 48, onClick = Confirm },
                },
            },
        },
    }
end

local function Render()
    local root = View.Build(model_, actions_)
    if confirmation_ then root:AddChild(ConfirmOverlay()) end
    UI.SetRoot(root, true)
    dirty_ = false
end

function Start()
    graphics.windowTitle = "街角借物所"
    stopped_ = false
    UI.Init({ theme = "default-taptap", scale = UI.Scale.DEFAULT })
    LoadLocal()
    audioScene_ = Scene()
    soundSource_ = audioScene_:CreateChild("InterfaceSounds"):CreateComponent("SoundSource")
    for _, name in ipairs({ "page", "lend", "finish" }) do
        sounds_[name] = cache:GetResource("Sound", "audio/sfx/" .. name .. ".wav")
    end
    LoadCloud()
    Render()
    SubscribeToEvent("Update", "HandleUpdate")
    LendingApp = { model = model_, actions = actions_ }
end

---@param _eventType string
---@param eventData UpdateEventData
function HandleUpdate(_eventType, eventData)
    if not IsRunning() then return end
    local dt = eventData:GetFloat("TimeStep")
    if cloudLoading_ then
        cloudElapsed_ = cloudElapsed_ + dt
        if cloudElapsed_ > 15 then
            cloudGeneration_ = cloudGeneration_ + 1
            cloudLoading_ = false
            model_.notice = ""
            model_.saveWarning = "云端记录暂未响应，当前仅使用本地进度。"
            dirty_ = true
        end
    elseif HasCloudUser() and not cloudReady_ and not confirmation_ then
        retryElapsed_ = retryElapsed_ + dt
        if retryElapsed_ > 30 then retryElapsed_ = 0; LoadCloud() end
    elseif cloudQueue_ ~= "" and not cloudBusy_ then
        retryElapsed_ = retryElapsed_ + dt
        if retryElapsed_ > 8 then retryElapsed_ = 0; PumpCloud() end
    end
    if dirty_ then Render() end
end

function Stop()
    stopped_ = true
    cloudGeneration_ = cloudGeneration_ + 1
    UnsubscribeFromEvent("Update")
    if not cloudLoading_ then Save() end
    UI.Shutdown()
    if audioScene_ then audioScene_:Dispose(); audioScene_ = nil end
    soundSource_ = nil
    LendingApp = nil
end

