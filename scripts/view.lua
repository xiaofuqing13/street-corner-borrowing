local UI = require("urhox-libs/UI")
local Game = require("game")
local Content = require("content")
local View = {}
local C = {
    paper = { 247, 246, 240, 255 }, surface = { 255, 254, 249, 255 },
    ink = { 36, 43, 38, 255 }, muted = { 92, 104, 97, 255 }, line = { 217, 222, 210, 255 },
    green = { 48, 73, 58, 255 }, disabled = { 225, 229, 220, 255 }, white = { 255, 254, 249, 255 },
    red = { 147, 65, 51, 255 }, blue = { 66, 101, 122, 255 },
}
local ACCENTS = {
    { 66, 101, 122, 255 }, { 152, 96, 77, 255 }, { 145, 110, 53, 255 },
    { 76, 110, 84, 255 }, { 144, 94, 115, 255 }, { 91, 94, 132, 255 },
}
local PEOPLE = { "amei", "laozhou", "xiaolin", "chenshu", "xiaotang", "zhaoyi" }
local ITEMS = { "umbrella", "cart" }
---@type table<string, boolean>
local expandedNeighbors = {}
local lastRequestKey = ""
local busyAtBuild = false

local function Count(value) return tostring(math.floor(value or 0)) end
local function Tint(color)
    return { math.floor(color[1] * 0.1 + C.paper[1] * 0.9), math.floor(color[2] * 0.1 + C.paper[2] * 0.9),
        math.floor(color[3] * 0.1 + C.paper[3] * 0.9), 255 }
end
local function Accent(id)
    for index, scenario in ipairs(Content.scenarios) do
        if scenario.id == id then return ACCENTS[(index - 1) % #ACCENTS + 1] end
    end
    return C.green
end
local function Text(value, size, color, bold, options)
    ---@type LabelProps
    local props = { text = tostring(value or ""), width = "100%", fontSize = size or 14,
        fontColor = color or C.ink, fontWeight = bold and "bold" or "normal", whiteSpace = "normal",
        wordBreak = "break-word", lineHeight = 1.4, verticalAlign = "top", flexShrink = 0 }
    for key, optionValue in pairs(options or {}) do props[key] = optionValue end
    if props.width == "auto" then props.width, props.whiteSpace, props.flexShrink = nil, "nowrap", 1 end
    return UI.Label(props)
end
---@param children Widget[]
local function Column(children, options)
    ---@type PanelProps
    local props = { width = "100%", gap = 10, flexShrink = 0, children = children }
    for key, value in pairs(options or {}) do props[key] = value end
    return UI.Panel(props)
end
---@param children Widget[]
local function Row(children, options)
    ---@type PanelProps
    local props = { width = "100%", flexDirection = "row", alignItems = "center", gap = 10,
        flexShrink = 0, children = children }
    for key, value in pairs(options or {}) do props[key] = value end
    return UI.Panel(props)
end
---@param children Widget[]
local function Sheet(children, options)
    ---@type PanelProps
    local props = { width = "100%", backgroundColor = C.surface, borderWidth = 1, borderColor = C.line,
        borderRadius = 6, padding = 16, gap = 12, flexShrink = 0, children = children }
    for key, value in pairs(options or {}) do props[key] = value end
    return UI.Panel(props)
end
local function Icon(name, light, size, opacity)
    return UI.Svg { src = "image/ui_v2/" .. name .. (light and "-light" or "") .. ".svg",
        width = size or 22, height = size or 22, objectFit = "contain", opacity = opacity or 1,
        pointerEvents = "none", flexShrink = 0 }
end
local function Picture(path, width, height, fit)
    return UI.Panel { width = width, height = height, backgroundImage = path, backgroundFit = fit or "cover",
        borderRadius = 5, overflow = "hidden", pointerEvents = "none", flexShrink = 0 }
end
local function Portrait(id, size) return Picture("image/v2/portrait-" .. id .. ".png", size or 72, size or 72) end
local function Scene(scenario, width, height)
    return Picture(scenario.image or ("image/v2/shift-" .. scenario.id .. ".png"), width, height)
end
local function Button(text, callback, secondary, disabled, options, iconName)
    ---@type ButtonProps
    local props = { width = "100%", height = 52, minWidth = 0, borderRadius = 4,
        alignItems = "center", justifyContent = "center",
        padding = { 0, 14, 0, 14 }, pressedPadding = { 0, 14, 0, 14 },
        backgroundColor = secondary and C.paper or C.green,
        hoverBackgroundColor = secondary and C.surface or { 61, 88, 70, 255 },
        pressedBackgroundColor = secondary and C.disabled or { 36, 58, 45, 255 },
        disabledBackgroundColor = C.disabled, textColor = secondary and C.green or C.white,
        disabledTextColor = C.muted, fontSize = 14, borderWidth = 1, borderColor = secondary and C.line or C.green,
        hoverBorderWidth = 1, pressedBorderWidth = 1, boxShadow = false, hoverBoxShadow = false,
        pressedBoxShadow = false, disabledBoxShadow = false, disabled = disabled or busyAtBuild,
        transition = "backgroundColor 0.12s easeOut" }
    for key, value in pairs(options or {}) do props[key] = value end
    if props.width == "auto" then props.width = nil end
    ---@type Widget[]
    local content = {}
    if iconName then content[#content + 1] = Icon(iconName, not secondary and not props.disabled, 20,
        props.disabled and 0.5 or 1) end
    content[#content + 1] = Text(text, props.fontSize, props.disabled and C.muted or props.textColor,
        true, { width = "auto", lineHeight = 1.1 })
    props.children = { Row(content, { width = "auto", alignSelf = "center",
        justifyContent = "center", pointerEvents = "none", gap = 8 }) }
    props.onClick = function() if not props.disabled then callback() end end
    return UI.Button(props)
end
local function SmallButton(text, callback, iconName, disabled)
    return Button(text, callback, true, disabled, { width = "auto", height = 44, fontSize = 12, flexShrink = 1 }, iconName)
end
local function Entry(label, value, color)
    return Row({ Text(label, 12, C.muted, false, { width = 76 }),
        Text(value, 14, color or C.ink, false, { width = 0, flexGrow = 1, flexBasis = 0 }) }, { alignItems = "flex-start" })
end
local function PersonName(id) return Content.people[id].name end
local function ItemName(id) return Content.items[id].name end
local function SavedObjectives(profile, id) return (profile.objectives and profile.objectives[id]) or {} end
local function ObjectiveCounts(profile, scenario)
    local completed = 0
    local saved = SavedObjectives(profile, scenario.id)
    for _, goal in ipairs(scenario.objectives or {}) do if saved[goal.id] then completed = completed + 1 end end
    return completed, #(scenario.objectives or {})
end
local function AllObjectiveCounts(profile)
    local completed, total = 0, 0
    for _, scenario in ipairs(Content.scenarios) do
        local done, count = ObjectiveCounts(profile, scenario)
        completed, total = completed + done, total + count
    end
    return completed, total
end
local function Back(model, actions)
    return function()
        if not model.state then actions.home()
        elseif model.state.finished then actions.show("result")
        else actions.continueGame() end
    end
end
local function GoalRow(goal, saved, progress)
    local preview = progress and progress.complete and not saved
    local status = saved and "已完成" or (preview and "本局达成" or "待完成")
    if not saved and not preview and progress then status = "本局 " .. Count(progress.current) .. "/" .. Count(progress.target) end
    return Row({ UI.Panel { width = 24, height = 24, borderRadius = 3, backgroundColor = saved and C.green or C.paper,
        borderWidth = 1, borderColor = C.line, alignItems = "center", justifyContent = "center", flexShrink = 0,
        children = { Icon(saved and "check" or "star", saved, 17, saved and 1 or 0.5) } },
        Column({ Text(goal.title, 14, C.ink, true), Text(goal.description, 12, C.muted) },
            { id = "goal-copy-" .. goal.id, width = 0, flexGrow = 1, flexBasis = 0, gap = 3, paddingBottom = 2 }),
        Text(status, 11, saved and C.green or (preview and C.blue or C.muted), saved, { width = 88, textAlign = "right" }) },
        { alignItems = "flex-start", paddingVertical = 5 })
end
local function GoalList(model, scenario, includeCurrent)
    local saved = SavedObjectives(model.profile, scenario.id)
    local previews = {}
    if includeCurrent and model.state and model.state.scenarioId == scenario.id then
        for _, progress in ipairs(Game.Objectives(model.state)) do previews[progress.id] = progress end
    end
    ---@type Widget[]
    local children = {}
    for _, goal in ipairs(scenario.objectives or {}) do children[#children + 1] = GoalRow(goal, saved[goal.id] == true, previews[goal.id]) end
    return Column(children, { id = "goals-" .. scenario.id, gap = 4, paddingBottom = 2 })
end
local function Feedback(model, actions)
    ---@type Widget[]
    local children = {}
    local message = model.notice or ""
    if message == "" and model.state then message = model.state.status or "" end
    if message ~= "" then
        if model.state and message == model.state.status and message:find("\n", 1, true) then
            children[#children + 1] = Row({ Text("本时段借还记录已更新。", 13, C.green, false,
                { width = 0, flexGrow = 1, flexBasis = 0 }), SmallButton("回看", function() actions.show("history") end, "records") })
        else children[#children + 1] = Text(message, 13, C.green) end
    end
    if model.saveWarning and model.saveWarning ~= "" then children[#children + 1] = Text(model.saveWarning, 13, C.red) end
    if model.soundWarning and model.soundWarning ~= "" then children[#children + 1] = Text(model.soundWarning, 13, C.muted) end
    if #children == 0 then return nil end
    return Column(children, { paddingLeft = 10, borderLeftWidth = 2, borderLeftColor = C.line, gap = 6 })
end
local function Home(model, actions, body)
    body:AddChild(Row({ Column({ Text("今天，轮到你接待街坊。", 21, C.ink, true),
        Text("两把伞，一辆推车。\n看好借还时间，再借给街坊", 14, C.muted) },
        { width = 0, flexGrow = 1, flexBasis = 0 }),
        Picture("image/station-register-v2_20261023154401.png", 120, 90, "contain") }))
    if model.state and not model.state.finished then
        local active = Content.GetScenario(model.state.scenarioId)
        if active then body:AddChild(Sheet({ Text("正在值班 · " .. active.title, 15, C.ink, true),
            Button("继续 " .. Game.Time(model.state.round) .. " 的值班", actions.continueGame, false, false, nil, "counter") },
            { backgroundColor = Tint(Accent(active.id)) })) end
    end
    local done, total = AllObjectiveCounts(model.profile)
    body:AddChild(Row({ Text("选择班次", 19, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }),
        SmallButton("委托 " .. Count(done) .. "/" .. Count(total), function() actions.show("records") end, "star") }))
    for index, scenario in ipairs(Content.scenarios) do
        local id = scenario.id
        local count, goalTotal = ObjectiveCounts(model.profile, scenario)
        local record = model.profile.records[id]
        ---@type Widget[]
        local details = { Text(string.format("%02d  %s", index, scenario.title), 18, C.ink, true),
            Text("16:00—19:00 · " .. Count(#scenario.requests) .. " 次来访", 12, C.muted),
            Text("委托 " .. Count(count) .. "/" .. Count(goalTotal)
                .. (record and (" · 最佳 " .. Count(record.best) .. " 次") or " · 尚未值班"), 12, C.muted),
            Button("开始值班", function() actions.start(id) end, true, false,
                { id = "start-" .. id, height = 46, fontSize = 12 }, "counter") }
        body:AddChild(Sheet({ Row({ Scene(scenario, 112, 116), Column(details,
            { width = 0, flexGrow = 1, flexBasis = 0, gap = 7 }) }, { gap = 14 }) },
            { borderLeftWidth = 3, borderLeftColor = Accent(id), padding = 14 }))
    end
    body:AddChild(Text("委托可分多次值班完成，已完成的目标会保留。", 12, C.muted))
end
local function Inventory(state, actions)
    ---@type Widget[]
    local tiles = {}
    for _, itemId in ipairs(ITEMS) do
        local item = itemId
        local available = state.stock[item]
        tiles[#tiles + 1] = Sheet({ Row({ Picture("image/v2/item-" .. item .. ".png", 66, 66, "contain"),
            Column({ Text(ItemName(item), 14, C.ink, true), Text(Count(available) .. "/" .. Count(Content.items[item].capacity)
                .. " 可借", 19, available > 0 and C.ink or C.red, true) },
                { width = 0, flexGrow = 1, flexBasis = 0, gap = 3 }) }, { gap = 8, pointerEvents = "none" }) },
            { id = "stock-" .. item, width = 0, flexGrow = 1, flexBasis = 0, padding = 10,
                backgroundColor = Tint(Accent(state.scenarioId)),
                onClick = function() if not busyAtBuild then actions.show("schedule") end end })
    end
    return Row(tiles, { alignItems = "stretch" })
end
---@param state BorrowGameState
local function MiniSchedule(state, actions)
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then return Text("到访安排暂时无法读取。", 13, C.red) end
    ---@type BorrowLoan[]
    local loans = {}
    for _, loan in ipairs(state.loans) do if not loan.returned then loans[#loans + 1] = loan end end
    table.sort(loans, function(a, b) return a.returnSlot < b.returnSlot end)
    ---@type Widget[]
    local lines = { Row({ Icon("clock", false, 18), Text("稍后的安排", 13, C.ink, true,
        { width = 0, flexGrow = 1, flexBasis = 0 }), SmallButton("完整安排", function() actions.show("schedule") end, "schedule") }) }
    local first = loans[1]
    if first then lines[#lines + 1] = Text(Game.Time(first.returnSlot) .. "  " .. PersonName(first.person)
        .. "归还" .. ItemName(first.item), 12, C.green) end
    local shown = 0
    for _, request in ipairs(scenario.requests) do
        if request.slot > state.round and shown < 2 then
            lines[#lines + 1] = Text(Game.Time(request.slot) .. "  " .. PersonName(request.person) .. "想借" .. ItemName(request.item)
                .. "，" .. Game.Time(request.returnSlot) .. "还", 12, C.muted)
            shown = shown + 1
        end
    end
    if not first and shown == 0 then lines[#lines + 1] = Text("19:00 清点归还，不再接新借用。", 12, C.muted) end
    return Column(lines, { gap = 5, paddingBottom = 10, borderBottomWidth = 1, borderBottomColor = C.line })
end
local function RoundProgress(state)
    ---@type Widget[]
    local slots = {}
    for slot = 1, 6 do
        slots[#slots + 1] = Column({ UI.Panel { width = "100%", height = 4, borderRadius = 1,
            backgroundColor = slot <= state.round and Accent(state.scenarioId) or C.line },
            Text(Game.Time(slot), 10, slot == state.round and C.ink or C.muted, slot == state.round, { textAlign = "center" }) },
            { width = 0, flexGrow = 1, flexBasis = 0, gap = 4 })
    end
    return Column({ Row({ Icon("clock", false, 22), Text(Game.Time(state.round), 25, C.ink, true,
        { width = 0, flexGrow = 1, flexBasis = 0 }), Text("第 " .. Count(math.min(state.round, 6)) .. "/6 时段", 12, C.muted,
        false, { width = "auto" }) }), Row(slots, { gap = 6, marginTop = 8 }) }, { gap = 0 })
end
local function RequestPanel(state, request)
    local person = Content.people[request.person]
    local panel = Sheet({ Row({ Portrait(request.person, 80), Column({ Text("窗口来访", 11, Accent(state.scenarioId), true),
        Text(person.name, 23, C.ink, true), Text(person.role, 12, C.muted) },
        { id = "request-person", width = 0, flexGrow = 1, flexBasis = 0, gap = 4, paddingBottom = 2 }) }, { gap = 14 }), Text(request.reason, 17),
        Row({ Icon(request.item, false, 20), Text(ItemName(request.item) .. " 1 " .. (request.item == "umbrella" and "把" or "辆"),
            14, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }), Icon("return", false, 18),
            Text(Game.Time(request.returnSlot) .. " 归还", 13, C.green, true, { width = "auto" }) },
            { id = "request-item-return", minHeight = 30, gap = 7, paddingVertical = 2, paddingHorizontal = 2 }) },
        { id = "current-request", borderLeftWidth = 3, borderLeftColor = Accent(state.scenarioId), padding = 18, gap = 14 })
    local key = state.scenarioId .. ":" .. Count(state.round) .. ":" .. request.id
    if key ~= lastRequestKey then
        lastRequestKey = key
        panel:Animate({ keyframes = { [0] = { opacity = 0, translateY = 5 }, [1] = { opacity = 1, translateY = 0 } },
            duration = 0.16, easing = "easeOut", fillMode = "forwards" })
    end
    return panel
end
local function DisabledReason(state, request)
    if state.stock[request.item] > 0 then return "" end
    local earliest = 8
    for _, loan in ipairs(state.loans) do
        if not loan.returned and loan.item == request.item then earliest = math.min(earliest, loan.returnSlot) end
    end
    return ItemName(request.item) .. "暂无库存。" .. (earliest <= 7 and ("最近 " .. Game.Time(earliest) .. " 归还。") or "")
end
local function PlayFooter(model, actions)
    local state = model.state
    local request = Game.Current(state)
    local ad = model.ad or { busy = false, available = false, cooldown = 0, reason = "" }
    ---@type Widget[]
    local children = {}
    if request then
        local reason = DisabledReason(state, request)
        if reason ~= "" then children[#children + 1] = Text(reason, 12, C.red) end
        children[#children + 1] = Row({
            Button("借出" .. ItemName(request.item), function() actions.lend(request.id) end, false,
                reason ~= "" or ad.busy, { id = "action-lend", width = 0, flexGrow = 1, flexBasis = 0 }, "check"),
            Button("这次不借", function() actions.decline(request.id) end, true, ad.busy,
                { id = "action-decline", width = 0, flexGrow = 1, flexBasis = 0 }, "return") },
            { id = "play-main-actions", paddingHorizontal = 2 })
    else
        local nextSlot = math.min(state.round + 1, 7)
        children[#children + 1] = Button(nextSlot == 7 and "19:00 清点归还并收班" or "前往 " .. Game.Time(nextSlot),
            actions.nextRound, false, ad.busy, { id = "action-next-round" }, "clock")
    end
    local allowed, reason = Game.CanReplan(state, false)
    if (state.freeReplans or 0) == 0 then
        children[#children + 1] = Button("重排本时段 · 本班免费一次", actions.replan, true,
            not allowed or ad.busy, { id = "action-replan", height = 44, fontSize = 12 }, "replan")
        if not allowed and reason then children[#children + 1] = Text(reason, 11, C.muted) end
    elseif (state.rewardReplans or 0) == 0 and model.profile.completed > 0 then
        local rewardedAllowed, rewardedReason = Game.CanReplan(state, true)
        children[#children + 1] = Button(ad.busy and "视频处理中，请稍候" or "看完整视频，再重排一次", actions.rewardReplan,
            true, not rewardedAllowed or not ad.available or ad.busy,
            { id = "action-reward-replan", height = 44, fontSize = 12 }, "video")
        local explanation = not rewardedAllowed and rewardedReason or (not ad.available and ad.reason or "")
        if explanation and explanation ~= "" then children[#children + 1] = Text(explanation, 11, C.muted) end
    else children[#children + 1] = Text("本班免费重排已使用。", 11, C.muted) end
    return Column(children, { gap = 7 })
end
local function Play(model, actions, body)
    local state = model.state
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then body:AddChild(Text("班次无法读取，请回借物所重新选择。", 14, C.red)); return nil end
    body:AddChild(RoundProgress(state))
    body:AddChild(Inventory(state, actions))
    body:AddChild(MiniSchedule(state, actions))
    local request = Game.Current(state)
    if request then body:AddChild(RequestPanel(state, request))
    else body:AddChild(Sheet({ Icon("check", false, 28), Text("本时段的来访已处理完。", 17, C.ink, true),
        Text("可以前往下一时段，也可以用重排机会调整本时段的选择。", 13, C.muted) })) end
    body:AddChild(Row({ Icon("star", false, 20), Text("本班委托", 15, C.ink, true,
        { width = 0, flexGrow = 1, flexBasis = 0 }), SmallButton("全部记录", function() actions.show("records") end, "records") }))
    body:AddChild(GoalList(model, scenario, true))
    body:AddChild(Text("本局达成的委托在正常收班后登记，可分多次完成。", 11, C.muted))
    return PlayFooter(model, actions)
end
local function Schedule(model, actions, body)
    body:AddChild(Text("到访只是预告，确认借出时才占用库存。", 13, C.muted))
    if not model.state then
        body:AddChild(Sheet({ Text("先选择一个班次，再查看借还安排。", 15),
            Button("选择班次", actions.home, false, false, nil, "counter") }))
        return
    end
    local state = model.state
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then body:AddChild(Text("这份安排暂时无法读取。", 14, C.red)); return end
    body:AddChild(Scene(scenario, "100%", 126))
    local decisions = {}
    for _, decision in ipairs(state.decisions) do decisions[decision.requestId] = decision.lent and "已借出" or "未借出" end
    for slot = 1, 7 do
        ---@type Widget[]
        local entries = { Row({ Icon("clock", false, 19), Text(Game.Time(slot) .. (slot == state.round and "  当前" or ""),
            17, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }) },
            { id = "schedule-time-" .. Count(slot), minHeight = 30, paddingVertical = 2 }) }
        for _, loan in ipairs(state.loans) do
            if loan.returnSlot == slot then entries[#entries + 1] = Row({ Icon("return", false, 17),
                Text(PersonName(loan.person) .. "归还" .. ItemName(loan.item) .. (loan.returned and " · 已归还" or ""),
                    13, C.green, false, { width = 0, flexGrow = 1, flexBasis = 0 }) }) end
        end
        for _, request in ipairs(scenario.requests) do
            if request.slot == slot then
                entries[#entries + 1] = Row({ Portrait(request.person, 34), Column({
                    Text(PersonName(request.person) .. "想借" .. ItemName(request.item)
                        .. (decisions[request.id] and (" · " .. decisions[request.id]) or ""), 14, C.ink, true),
                    Text(request.reason, 12, C.muted, false, { marginTop = 3 }),
                    Text(Game.Time(request.returnSlot) .. " 归还", 11, C.muted, false, { marginTop = 3 }) },
                    { id = "schedule-request-" .. request.id, width = 0, flexGrow = 1, flexBasis = 0,
                        gap = 0, paddingBottom = 2 }) }, { alignItems = "flex-start" })
            end
        end
        if slot == 7 then entries[#entries + 1] = Text("只收回物品，不再新借。", 13, C.muted) end
        body:AddChild(Sheet(entries, { borderLeftWidth = slot == state.round and 3 or 1,
            borderLeftColor = slot == state.round and Accent(state.scenarioId) or C.line }))
    end
end
local function NeighborEntries(personId, completedItems)
    ---@type Widget[]
    local entries = {}
    for _, scenario in ipairs(Content.scenarios) do
        for _, request in ipairs(scenario.requests) do
            if request.person == personId and completedItems[request.id] then
                entries[#entries + 1] = Column({ Text(scenario.title, 11, C.muted),
                    Text(request.returnText or request.reason, 13) },
                    { gap = 3, paddingVertical = 7, borderTopWidth = 1, borderTopColor = C.line })
            end
        end
    end
    if #entries == 0 then entries[#entries + 1] = Text("还没有已完成事项，正常收班后会在这里登记。", 13, C.muted) end
    return entries
end
local function Neighbors(model, actions, body)
    body:AddChild(Text("六位街坊，各有各的事情。完成借用并收班后，事项会留在这里。", 14, C.muted))
    for _, personId in ipairs(PEOPLE) do
        local id = personId
        local person = Content.people[id]
        local record = (model.profile.neighbors and model.profile.neighbors[id]) or { completed = 0, items = {} }
        local detail = Column(NeighborEntries(id, record.items or {}), { visible = expandedNeighbors[id] == true, gap = 3 })
        body:AddChild(Sheet({ Row({ Portrait(id, 88), Column({ Text(person.name, 20, C.ink, true),
            Text(person.role, 12, C.muted, false, { marginTop = 5 }),
            Text(person.description or "", 13, C.muted, false, { marginTop = 5 }),
            Text("已完成 " .. Count(record.completed) .. " 次借用", 12, C.green, true, { marginTop = 5 }) },
            { id = "neighbor-copy-" .. id, width = 0, flexGrow = 1, flexBasis = 0, gap = 0 }) },
            { alignItems = "flex-start", gap = 14 }),
            SmallButton("查看 / 收起已完成事项", function()
                expandedNeighbors[id] = not expandedNeighbors[id]
                detail:SetVisible(expandedNeighbors[id])
            end, "records"), detail }))
    end
    body:AddChild(SmallButton("回到值班", Back(model, actions), "counter"))
end
local function Records(model, actions, body)
    local done, total = AllObjectiveCounts(model.profile)
    body:AddChild(Sheet({ Row({ Icon("star", false, 28), Column({ Text(Count(done) .. " / " .. Count(total) .. " 项委托",
        23, C.ink, true), Text("可以分多次值班完成，不要求同一局全部做到。", 13, C.muted) },
        { width = 0, flexGrow = 1, flexBasis = 0 }) }), Text("累计值班 " .. Count(model.profile.completed) .. " 次", 12, C.muted) },
        { backgroundColor = Tint(C.blue) }))
    for _, scenario in ipairs(Content.scenarios) do
        local record = model.profile.records[scenario.id]
        local count, goalTotal = ObjectiveCounts(model.profile, scenario)
        body:AddChild(Sheet({ Row({ Scene(scenario, 112, 72), Column({ Text(scenario.title, 18, C.ink, true),
            Text("委托 " .. Count(count) .. "/" .. Count(goalTotal) .. (record and (" · 最佳 " .. Count(record.best)
                .. " 次 · " .. Count(record.stars) .. " 星") or " · 尚未值班"), 12, C.muted) },
                { width = 0, flexGrow = 1, flexBasis = 0, gap = 5 }) }), GoalList(model, scenario, true) },
            { borderLeftWidth = 3, borderLeftColor = Accent(scenario.id) }))
    end
    body:AddChild(SmallButton("选择其他班次", actions.home, "counter"))
end
local function History(model, actions, body)
    if not model.state or #model.state.history == 0 then
        body:AddChild(Sheet({ Icon("records", false, 32), Text("当前没有故事记录。", 17, C.ink, true),
            Text("开始值班后，借出、归还和来访的经过会记录在这里。", 14, C.muted),
            Button("回到借物所", actions.home, false, false, nil, "counter") }))
        return
    end
    body:AddChild(Text("按发生顺序记录这一班的经过。", 13, C.muted))
    for _, entry in ipairs(model.state.history) do
        body:AddChild(Column({ Row({ Icon("clock", false, 18), Text(entry.time, 12, C.green, true,
            { width = 0, flexGrow = 1, flexBasis = 0 }) }), Text(entry.text, 15) },
            { paddingVertical = 12, borderBottomWidth = 1, borderBottomColor = C.line, gap = 7 }))
    end
end
local function Rules(model, actions, body)
    local rules = {
        { "umbrella", "物品与库存", "雨伞两把，手推车一辆。到访预告不预扣库存，确认借出后才占用一件。" },
        { "return", "先归还，再借出", "每个时段先收回约定归还的物品，再接待来访。没有库存时不能借出。" },
        { "clock", "六个时段", "16:00 到 18:30 共六个时段。进入下一时段才推进时间，19:00 只清点归还，不再新借。" },
        { "star", "委托可分局完成", "每班有三个目标。正常收班后保存已达成目标，之后再值班可以尝试不同安排。" },
        { "replan", "只重排当前时段", "每班有一次免费重排，撤回本时段已经做过的选择。此前时段不变，已用重排次数不会退回。" },
    }
    for _, rule in ipairs(rules) do body:AddChild(Sheet({ Row({ Icon(rule[1], false, 24),
        Text(rule[2], 17, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }) }), Text(rule[3], 14) })) end
    if model.profile.completed > 0 then
        body:AddChild(Sheet({ Row({ Icon("video", false, 24), Text("自选激励重排", 17, C.ink, true,
            { width = 0, flexGrow = 1, flexBasis = 0 }) }),
            Text("免费机会用过后，可主动观看完整视频，再重排一次当前时段。不可回到此前时段，不增加物品或最高星上限。", 14) }))
    end
    body:AddChild(SmallButton("返回值班", Back(model, actions), "counter"))
end
local function Tutorial(model, actions, body)
    local steps = {
        { "umbrella", "先看手边的物品", "雨伞两把、手推车一辆。借出会占用库存，按时归还后才能再借。" },
        { "schedule", "再看看稍后来访", "先看谁会归还、谁想来借。现在借得出去，也可以为稍后的街坊留一件。" },
        { "check", "接待与收班", "选择借出或这次不借。处理完本时段来访再推进；19:00 收班，保存目标与街坊事项。" },
    }
    body:AddChild(Row({ Picture("image/v2/item-umbrella.png", 82, 82, "contain"),
        Picture("image/v2/item-cart.png", 82, 82, "contain"), Column({ Text("第一次值班", 22, C.ink, true),
            Text("三件事，看完就能开始。", 13, C.muted) }, { width = 0, flexGrow = 1, flexBasis = 0 }) }))
    for index, step in ipairs(steps) do body:AddChild(Sheet({ Row({ Icon(step[1], false, 25),
        Text(Count(index) .. "  " .. step[2], 17, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }) }), Text(step[3], 15) })) end
    return Column({ Button(model.state and "开始值班" or "完成教学", actions.finishTutorial, false, false,
        { id = "tutorial-finish" }, "counter"), SmallButton("跳过教学", actions.finishTutorial) }, { gap = 7 })
end
local function Result(model, actions, body)
    if not model.state then Home(model, actions, body); return nil end
    local scenario = Content.GetScenario(model.state.scenarioId)
    if not scenario then body:AddChild(Text("班次记录暂时无法读取。", 14, C.red)); return nil end
    local result = Game.Result(model.state)
    body:AddChild(Scene(scenario, "100%", 136))
    ---@type Widget[]
    local stars = {}
    for index = 1, 3 do stars[#stars + 1] = Icon("star", false, 27, index <= result.stars and 1 or 0.25) end
    body:AddChild(Row({ Column({ Text("已收班 · " .. scenario.title, 20, C.ink, true),
        Text("完成 " .. Count(result.completed) .. " 次借用", 27, Accent(scenario.id), true) },
        { width = 0, flexGrow = 1, flexBasis = 0, gap = 7 }), Row(stars, { id = "result-stars", width = "auto", gap = 5 }) }))
    body:AddChild(Text(result.message, 13, C.muted))
    body:AddChild(Sheet({ Entry("服务街坊", Count(result.neighbors) .. " 位"), Entry("未借出", Count(result.declined) .. " 次"),
        Entry("本班上限", Count(result.maximum) .. " 次借用") }))
    ---@type Widget[]
    local faces = {}
    for _, neighbor in ipairs(result.neighborRecords or {}) do
        faces[#faces + 1] = Column({ Portrait(neighbor.personId, 44), Text(PersonName(neighbor.personId), 10, C.muted,
            false, { textAlign = "center" }) }, { width = 54, alignItems = "center", gap = 4 })
    end
    if #faces > 0 then body:AddChild(Row(faces, { flexWrap = "wrap", gap = 8 })) end
    body:AddChild(Row({ Icon("star", false, 22), Text("本班委托", 18, C.ink, true,
        { width = 0, flexGrow = 1, flexBasis = 0 }) }))
    body:AddChild(GoalList(model, scenario, true))
    body:AddChild(Text("已完成的委托会保留。下次可以换一种安排。", 12, C.muted))
    body:AddChild(Row({ SmallButton("街坊事项", function() actions.show("neighbors") end, "people"),
        SmallButton("故事回看", function() actions.show("history") end, "records") }, { flexWrap = "wrap" }))
    return Row({ Button("再值这一班", function() actions.start(scenario.id) end, false, false,
        { width = 0, flexGrow = 1, flexBasis = 0 }, "replan"), Button("选择班次", actions.home, true, false,
        { width = 0, flexGrow = 1, flexBasis = 0 }, "counter") })
end
local function Settings(model, actions, body)
    body:AddChild(Sheet({ Row({ Icon("sound", false, 26), Text("操作音效", 18, C.ink, true,
        { width = 0, flexGrow = 1, flexBasis = 0 }) }), Text("借出、归还和收班时播放轻提示。", 13, C.muted),
        Button(model.profile.sound and "音效已开启 · 关闭" or "音效已关闭 · 开启", actions.toggleSound, true, false, nil, "sound") }))
    body:AddChild(Sheet({ Text("规则与教学", 18, C.ink, true), Button("查看借用规则", function() actions.show("rules") end,
        true, false, nil, "records"), Button("重新看教学", function() actions.show("tutorial") end, true, false, nil, "counter") }))
    body:AddChild(Sheet({ Text("进度与记录", 18, C.ink, true),
        Text("值班进度、个人最佳、委托与街坊事项会随操作保存。清除前会再次确认。", 13, C.muted),
        Button("清除进度", actions.resetProgress, true, false, { textColor = C.red, borderColor = C.red }, "return") }))
end
local function TopBar(model, actions)
    local screen = model.screen
    local titles = { home = "街角借物所", game = "窗口值班", result = "本班小结", neighbors = "街坊", records = "值班记录",
        schedule = "借还安排", settings = "设置", rules = "借用规则", history = "故事回看", tutorial = "第一次值班" }
    local icons = { home = "counter", game = "counter", result = "star", neighbors = "people", records = "records",
        schedule = "schedule", settings = "settings", rules = "records", history = "records", tutorial = "counter" }
    local title = titles[screen] or titles.home
    if screen == "game" and model.state then
        local scenario = Content.GetScenario(model.state.scenarioId)
        if scenario then title = scenario.title end
    end
    ---@type Widget[]
    local children = { Icon(icons[screen] or "counter", false, 24), Text(title, 19, C.ink, true,
        { width = 0, flexGrow = 1, flexBasis = 0 }) }
    if screen == "settings" or screen == "rules" or screen == "history" then children[#children + 1] = SmallButton("返回", Back(model, actions))
    elseif screen == "tutorial" then children[#children + 1] = SmallButton("跳过", actions.finishTutorial)
    else children[#children + 1] = SmallButton("设置", function() actions.show("settings") end, "settings") end
    return Row(children, { id = "view-topbar", maxWidth = 720, alignSelf = "center", paddingHorizontal = 20,
        paddingVertical = 10, borderBottomWidth = 1, borderBottomColor = C.line })
end
local function Navigation(model, actions)
    local screen = model.screen
    local active = screen == "neighbors" and "neighbors" or (screen == "schedule" and "schedule"
        or ((screen == "records" or screen == "history" or screen == "result") and "records" or "home"))
    ---@type { id: string, label: string, icon: string, action: fun() }[]
    local entries = { { id = "home", label = "借物所", icon = "counter", action = actions.home },
        { id = "neighbors", label = "街坊", icon = "people", action = function() actions.show("neighbors") end },
        { id = "schedule", label = "安排", icon = "schedule", action = function() actions.show("schedule") end },
        { id = "records", label = "记录", icon = "records", action = function() actions.show("records") end } }
    ---@type Widget[]
    local buttons = {}
    for _, entry in ipairs(entries) do
        local selected = active == entry.id
        local callback = entry.action
        buttons[#buttons + 1] = UI.Button {
            id = "nav-" .. entry.id, width = 0, flexGrow = 1, flexBasis = 0, height = 64, minWidth = 0,
            backgroundColor = C.paper, hoverBackgroundColor = C.surface, pressedBackgroundColor = C.disabled,
            borderWidth = 0, borderTopWidth = selected and 2 or 0, borderTopColor = C.green, borderRadius = 0,
            boxShadow = false, hoverBoxShadow = false, pressedBoxShadow = false, padding = 0, pressedPadding = 0,
            alignItems = "center", justifyContent = "center",
            disabled = model.ad and model.ad.busy or false,
            children = { Column({ Icon(entry.icon, false, 23, selected and 1 or 0.5), Text(entry.label, 11,
                selected and C.green or C.muted, selected, { width = "auto" }) },
                { width = "100%", gap = 4, alignItems = "center", justifyContent = "center", pointerEvents = "none" }) },
            onClick = function() if not (model.ad and model.ad.busy) then callback() end end,
        }
    end
    return Row(buttons, { id = "view-bottom-nav", maxWidth = 720, alignSelf = "center", gap = 0,
        borderTopWidth = 1, borderTopColor = C.line })
end
---@param model table
---@param actions table
---@return Panel
function View.Build(model, actions)
    busyAtBuild = model.ad and model.ad.busy or false
    local body = Column({}, { id = "view-content", maxWidth = 720, alignSelf = "center", paddingHorizontal = 20,
        paddingTop = 16, paddingBottom = 24, gap = 14 })
    local feedback = Feedback(model, actions)
    if feedback then body:AddChild(feedback) end
    ---@type Widget?
    local footer = nil
    local screen = model.screen or "home"
    if screen == "game" and model.state then
        if model.state.finished then footer = Result(model, actions, body) else footer = Play(model, actions, body) end
    elseif screen == "result" then footer = Result(model, actions, body)
    elseif screen == "schedule" then Schedule(model, actions, body)
    elseif screen == "neighbors" then Neighbors(model, actions, body)
    elseif screen == "records" then Records(model, actions, body)
    elseif screen == "history" then History(model, actions, body)
    elseif screen == "rules" then Rules(model, actions, body)
    elseif screen == "tutorial" then footer = Tutorial(model, actions, body)
    elseif screen == "settings" then Settings(model, actions, body)
    else Home(model, actions, body) end
    ---@type Widget[]
    local layout = { TopBar(model, actions), UI.ScrollView { id = "view-scroll", width = "100%", flexGrow = 1,
        flexShrink = 1, flexBasis = 0, scrollY = true, scrollX = false, showScrollbar = true, children = { body } } }
    if footer then layout[#layout + 1] = Column({ footer }, { id = "view-fixed-actions", maxWidth = 720, alignSelf = "center",
        paddingHorizontal = 20, paddingVertical = 10, backgroundColor = C.surface, borderTopWidth = 1, borderTopColor = C.line }) end
    if screen ~= "tutorial" then layout[#layout + 1] = Navigation(model, actions) end
    return UI.Panel { id = "view-root", width = "100%", height = "100%", backgroundColor = C.paper, pointerEvents = "box-none",
        children = { UI.SafeAreaView { id = "view-safe-area", width = "100%", height = "100%", nativeMenuInset = true, children = layout } } }
end

return View
