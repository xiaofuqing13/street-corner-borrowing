local UI = require("urhox-libs/UI")
local Game = require("game")
local Content = require("content")

local View = {}

local C = {
    paper = { 246, 245, 239, 255 },
    surface = { 252, 251, 246, 255 },
    ink = { 34, 38, 33, 255 },
    muted = { 94, 99, 92, 255 },
    line = { 205, 207, 194, 255 },
    green = { 48, 73, 58, 255 },
    greenHover = { 61, 88, 70, 255 },
    greenPressed = { 36, 58, 45, 255 },
    disabled = { 225, 226, 217, 255 },
    red = { 139, 56, 45, 255 },
    white = { 252, 251, 246, 255 },
}

local ITEM_ORDER = { "umbrella", "cart" }

local function Text(value, size, color, bold, options)
    ---@type LabelProps
    local props = {
        text = tostring(value or ""),
        width = "100%",
        fontSize = size or 15,
        fontColor = color or C.ink,
        fontWeight = bold and "bold" or "normal",
        whiteSpace = "normal",
        wordBreak = "break-word",
        lineHeight = 1.45,
        verticalAlign = "top",
        flexShrink = 0,
    }
    for key, optionValue in pairs(options or {}) do
        props[key] = optionValue
    end
    if props.width == "auto" then
        props.width = nil
        props.whiteSpace = "nowrap"
        props.flexShrink = 1
    end
    return UI.Label(props)
end

---@param children Widget[]
local function Row(children, options)
    local props = {
        width = "100%",
        flexDirection = "row",
        alignItems = "center",
        gap = 12,
        children = children,
    }
    for key, value in pairs(options or {}) do
        props[key] = value
    end
    return UI.Panel(props)
end

---@param children Widget[]
local function Section(children, options)
    local props = {
        width = "100%",
        borderWidth = 0,
        borderBottomWidth = 1,
        borderBottomColor = C.line,
        borderRadius = 0,
        paddingVertical = 14,
        gap = 10,
        flexShrink = 0,
        children = children,
    }
    for key, value in pairs(options or {}) do
        props[key] = value
    end
    return UI.Panel(props)
end

local function Button(text, onClick, secondary, disabled, options)
    ---@type ButtonProps
    local props = {
        text = text,
        width = "100%",
        height = 52,
        minWidth = 0,
        borderRadius = 2,
        fontSize = 14,
        fontWeight = "bold",
        paddingHorizontal = 14,
        backgroundColor = secondary and C.paper or C.green,
        hoverBackgroundColor = secondary and C.surface or C.greenHover,
        pressedBackgroundColor = secondary and C.disabled or C.greenPressed,
        disabledBackgroundColor = C.disabled,
        textColor = secondary and C.green or C.white,
        disabledTextColor = C.muted,
        borderWidth = 1,
        borderColor = secondary and C.line or C.green,
        hoverBorderWidth = 1,
        pressedBorderWidth = 1,
        padding = { 0, 14, 0, 14 },
        pressedPadding = { 0, 14, 0, 14 },
        boxShadow = false,
        hoverBoxShadow = false,
        pressedBoxShadow = false,
        disabledBoxShadow = false,
        disabled = disabled or false,
        onClick = function()
            if not disabled then
                onClick()
            end
        end,
    }
    for key, value in pairs(options or {}) do
        props[key] = value
    end
    if props.width == "auto" then
        props.width = nil
    end
    return UI.Button(props)
end

local function SmallButton(text, onClick)
    return Button(text, onClick, true, false, {
        width = "auto",
        height = 44,
        fontSize = 12,
        flexShrink = 1,
    })
end

local function Illustration()
    return UI.Panel {
        width = "38%",
        aspectRatio = 1.5,
        backgroundImage = "image/station-register-v2_20261023154401.png",
        backgroundFit = "contain",
        borderRadius = 0,
        flexShrink = 0,
    }
end

local function Entry(label, value, accent)
    return Row({
        Text(label, 13, C.muted, false, { width = 88 }),
        Text(value, 15, accent or C.ink, false, { width = 0, flexGrow = 1, flexBasis = 0 }),
    }, { alignItems = "flex-start", gap = 10 })
end

local function PersonName(personId)
    return Content.people[personId].name
end

local function ItemName(itemId)
    return Content.items[itemId].name
end

local function ReturnAction(model, actions)
    return function()
        if model.state then
            if model.state.finished then
                actions.show("result")
            else
                actions.continueGame()
            end
        else
            actions.home()
        end
    end
end

local function PageHeading(title, subtitle, back)
    return UI.Panel {
        width = "100%",
        gap = 8,
        children = {
            SmallButton("返回", back),
            Text(title, 24, C.ink, true),
            Text(subtitle, 13, C.muted),
        },
    }
end

local function Notice(model)
    local children = {}
    if model.notice and model.notice ~= "" then
        children[#children + 1] = Text(model.notice, 13, C.muted)
    elseif model.state and model.state.status ~= "" then
        children[#children + 1] = Text(model.state.status, 13, C.muted)
    end
    if model.saveWarning and model.saveWarning ~= "" then
        children[#children + 1] = Text(model.saveWarning, 13, C.red)
    end
    if #children == 0 then
        return nil
    end
    return UI.Panel { width = "100%", gap = 6, paddingLeft = 10,
        borderLeftWidth = 2, borderLeftColor = C.line, children = children }
end

local function Home(model, actions, body)
    body:AddChild(Row({
        Text("社区便民站 / 借用登记", 12, C.muted, false, { width = 0, flexGrow = 1, flexBasis = 0 }),
        SmallButton("设置", function() actions.show("settings") end),
    }))
    body:AddChild(Row({
        UI.Panel {
            width = 0, flexGrow = 1, flexBasis = 0, gap = 10,
            children = {
                Text("街角借物所", 26, C.ink, true),
                Text("两把雨伞，一辆手推车。按时归还，再借给下一位。", 14),
            },
        },
        Illustration(),
    }))
    if model.state and not model.state.finished then
        local scenario = Content.GetScenario(model.state.scenarioId)
        if scenario then
            body:AddChild(Section({
                Text("进行中的值班", 12, C.red, true),
                Entry("班次", scenario.title),
                Entry("当前时间", Game.Time(model.state.round)),
                Button("继续值班", actions.continueGame),
            }))
        else
            body:AddChild(Text("当前班次无法读取，请重新选择。", 14, C.red))
        end
    end
    body:AddChild(Row({
        Text("值班表", 18, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }),
        SmallButton("规则", function() actions.show("rules") end),
    }))
    for index, scenario in ipairs(Content.scenarios) do
        local scenarioId = scenario.id
        local record = model.profile.records[scenarioId]
        ---@type Widget[]
        local children = {
            Row({
                Text(string.format("%02d  %s", index, scenario.title), 18, C.ink, true,
                    { width = 0, flexGrow = 1, flexBasis = 0 }),
                SmallButton("开始", function() actions.start(scenarioId) end),
            }),
            Text("16:00—19:00 · " .. tostring(#scenario.requests) .. " 次来访", 13, C.muted),
        }
        if record then
            children[#children + 1] = Text("最佳 " .. tostring(record.best) .. " 次借用 · "
                .. tostring(record.stars) .. " 星 · 已值班 " .. tostring(record.attempts) .. " 次", 13, C.muted)
        end
        body:AddChild(Section(children))
    end
    body:AddChild(Text("累计完成 " .. tostring(model.profile.completed) .. " 次值班", 12, C.muted))
end

local function Inventory(state)
    local rows = {
        Row({
            Text("在所物品", 13, C.muted, false, { width = 0, flexGrow = 1, flexBasis = 0 }),
            Text("可借", 12, C.muted, false, { width = 62, textAlign = "right" }),
            Text("总数", 12, C.muted, false, { width = 62, textAlign = "right" }),
        }),
    }
    for _, itemId in ipairs(ITEM_ORDER) do
        rows[#rows + 1] = Row({
            Text(ItemName(itemId), 16, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }),
            Text(tostring(state.stock[itemId]), 16, state.stock[itemId] > 0 and C.ink or C.red, true,
                { width = 62, textAlign = "right" }),
            Text(tostring(Content.items[itemId].capacity), 14, C.muted, false,
                { width = 62, textAlign = "right" }),
        }, { paddingVertical = 5, borderTopWidth = 1, borderTopColor = C.line })
    end
    return Section(rows, { gap = 6, paddingTop = 8, paddingBottom = 10 })
end

---@param state BorrowGameState
local function UpcomingReturns(state)
    ---@type BorrowLoan[]
    local loans = {}
    for _, loan in ipairs(state.loans) do
        if not loan.returned then
            loans[#loans + 1] = loan
        end
    end
    table.sort(loans, function(a, b)
        if a.returnSlot == b.returnSlot then
            return a.requestId < b.requestId
        end
        return a.returnSlot < b.returnSlot
    end)
    local children = { Text("待归还", 14, C.ink, true) }
    if #loans == 0 then
        children[#children + 1] = Text("暂无外借物品。", 13, C.muted)
    else
        for index, loan in ipairs(loans) do
            if index > 3 then break end
            children[#children + 1] = Text(Game.Time(loan.returnSlot) .. "  "
                .. PersonName(loan.person) .. "归还" .. ItemName(loan.item), 13, C.muted)
        end
        if #loans > 3 then
            children[#children + 1] = Text("其余记录见完整安排。", 12, C.muted)
        end
    end
    return UI.Panel { width = "100%", gap = 6, children = children }
end

local function Forecast(state, actions)
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then
        return Text("到访预告暂时无法读取。", 14, C.red)
    end
    ---@type Widget[]
    local children = {
        Row({
            Text("到访预告", 14, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }),
            SmallButton("完整安排", function() actions.show("schedule") end),
        }),
    }
    local shown = 0
    for _, request in ipairs(scenario.requests) do
        if request.slot > state.round and shown < 2 then
            children[#children + 1] = Text(Game.Time(request.slot) .. "  "
                .. PersonName(request.person) .. "借" .. ItemName(request.item)
                .. "（" .. Game.Time(request.returnSlot) .. "还）", 13, C.muted)
            shown = shown + 1
        end
    end
    if shown == 0 then
        children[#children + 1] = Text("后面没有来访，19:00 清点归还。", 13, C.muted)
    end
    return UI.Panel { width = "100%", gap = 6, children = children }
end

local function RequestSection(state, request, actions)
    local person = Content.people[request.person]
    local available = state.stock[request.item]
    local children = {
        Text("当前来访", 12, C.red, true),
        Row({
            Text(person.name, 22, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }),
            Text(person.role, 12, C.muted, false, { width = "auto" }),
        }),
        Text(request.reason, 16),
        Entry("借用", ItemName(request.item) .. " 1 " .. (request.item == "umbrella" and "把" or "辆")
            .. "，" .. Game.Time(request.returnSlot) .. " 归还"),
        Row({
            Button("借出" .. ItemName(request.item), function() actions.lend(request.id) end,
                false, available <= 0, { width = 0, flexGrow = 1, flexBasis = 0 }),
            Button("这次不借", function() actions.decline(request.id) end,
                true, false, { width = 0, flexGrow = 1, flexBasis = 0 }),
        }),
    }
    if available <= 0 then
        children[#children + 1] = Text(ItemName(request.item) .. "暂无库存，本次无法借出。", 13, C.red)
    else
        children[#children + 1] = Text("借出后，库存将在约定归还时刻恢复。", 12, C.muted)
    end
    return Section(children, { paddingTop = 10, gap = 12 })
end

local function Play(model, actions, body)
    local state = model.state
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then
        body:AddChild(Section({ Text("班次无法读取，请重新选择。", 15, C.red),
            Button("回到班次表", actions.home) }))
        return
    end
    body:AddChild(Row({
        Text(scenario.title, 16, C.ink, true, { width = 0, flexGrow = 1, flexBasis = 0 }),
        SmallButton("规则", function() actions.show("rules") end),
        SmallButton("班次", actions.home),
    }))
    body:AddChild(Row({
        Text(Game.Time(state.round), 27, C.ink, true, { width = "auto", flexGrow = 1 }),
        Text("第 " .. tostring(math.min(state.round, 6)) .. " / 6 时段", 13, C.muted,
            false, { width = "auto" }),
    }))
    body:AddChild(Inventory(state))
    body:AddChild(Section({ UpcomingReturns(state), Forecast(state, actions) }, { gap = 10, paddingTop = 0 }))
    local request = Game.Current(state)
    if request then
        body:AddChild(RequestSection(state, request, actions))
    else
        local nextSlot = math.min(state.round + 1, 7)
        body:AddChild(Section({
            Text("本时段已处理完", 16, C.ink, true),
            Button(nextSlot == 7 and "19:00 清点归还并收班"
                or "前往 " .. Game.Time(nextSlot), actions.nextRound),
        }))
    end
    body:AddChild(Text("进入下一时段时，时间才会推进。", 12, C.muted))
end

local function Schedule(model, actions, body)
    body:AddChild(PageHeading("借还安排", "到访为预告，是否借出由你决定。",
        ReturnAction(model, actions)))
    if not model.state then
        body:AddChild(Section({ Text("选择班次后可查看安排。", 16),
            Button("选择班次", actions.home) }))
        return
    end
    local state = model.state
    local scenario = Content.GetScenario(state.scenarioId)
    if not scenario then
        body:AddChild(Section({ Text("到访预告无法读取，请重新选择班次。", 15, C.red),
            Button("回到班次表", actions.home) }))
        return
    end
    local decisions = {}
    for _, decision in ipairs(state.decisions) do
        decisions[decision.requestId] = decision.lent and "已借出" or "已婉拒"
    end
    for slot = 1, 7 do
        local children = { Text(Game.Time(slot) .. (slot == state.round and "  当前" or ""),
            17, slot == state.round and C.red or C.ink, true) }
        for _, loan in ipairs(state.loans) do
            if loan.returnSlot == slot then
                children[#children + 1] = Text((loan.returned and "已归还  " or "将归还  ")
                    .. PersonName(loan.person) .. " · " .. ItemName(loan.item), 13, C.green)
            end
        end
        for _, request in ipairs(scenario.requests) do
            if request.slot == slot then
                local status = decisions[request.id]
                children[#children + 1] = Text(PersonName(request.person) .. "想借"
                    .. ItemName(request.item) .. (status and (" · " .. status) or ""), 15, C.ink, true)
                children[#children + 1] = Text(request.reason, 13, C.muted)
                if not status then
                    children[#children + 1] = Text("若借出，" .. Game.Time(request.returnSlot) .. "归还。", 12, C.muted)
                end
            end
        end
        if slot == 7 then
            children[#children + 1] = Text("清点归还，不再借出。", 14, C.muted)
        end
        body:AddChild(Section(children))
    end
end

local function Rules(model, actions, body)
    body:AddChild(PageHeading("借用规则", "16:00 开始，19:00 收班。", ReturnAction(model, actions)))
    local rules = {
        { "01  物品", "雨伞两把，手推车一辆。到访预告不预扣库存，确认借出后才扣减一件。" },
        { "02  归还", "物品会在约定时刻归还。每个时段先归还，再接待来访；没有库存时不能借出。" },
        { "03  来访", "邻居到访时，可以借出，也可以这次不借。处理完本时段的来访后，再进入下一时段。" },
        { "04  时间", "16:00 到 18:30 共六个时段。阅读不会计时。所有物品最晚 19:00 归还，19:00 不再新借。" },
        { "05  记录", "借出并归还后计为一次完成借用。尽量安排更多次周转，结算时查看次数和星级，也可以重新排班。" },
    }
    for _, rule in ipairs(rules) do
        body:AddChild(Section({ Text(rule[1], 16, C.ink, true), Text(rule[2], 15) }))
    end
end

local function Result(model, actions, body)
    if not model.state then
        Home(model, actions, body)
        return
    end
    local scenario = Content.GetScenario(model.state.scenarioId)
    if not scenario then
        body:AddChild(Section({ Text("班次记录无法读取，可以开始新的班次。", 15, C.red),
            Button("选择班次", actions.home) }))
        return
    end
    local result = Game.Result(model.state)
    body:AddChild(Text("已收班", 13, C.red, true))
    body:AddChild(Text(scenario.title, 25, C.ink, true))
    body:AddChild(Text("19:00 / 本班借还登记", 13, C.muted))
    body:AddChild(Section({
        Entry("完成借用", tostring(result.completed) .. " 次"),
        Entry("服务邻居", tostring(result.neighbors) .. " 位"),
        Entry("未借出", tostring(result.declined) .. " 次"),
        Entry("本班上限", tostring(result.maximum) .. " 次借用"),
        Entry("星级", tostring(result.stars) .. " / 3", C.red),
        Text(result.message, 13, C.muted),
    }, { gap = 15 }))
    body:AddChild(Button("再值一次这个班", function() actions.start(scenario.id) end))
    body:AddChild(Button("选择其他班次", actions.home, true))
    body:AddChild(SmallButton("查看借还记录", function() actions.show("schedule") end))
end

local function Settings(model, actions, body)
    body:AddChild(PageHeading("设置", "声音与值班记录。", ReturnAction(model, actions)))
    body:AddChild(Section({
        Text("操作音效", 17, C.ink, true),
        Text("借出、归还、收班时播放提示音。", 14, C.muted),
        Button(model.profile.sound and "音效已开启 · 关闭" or "音效已关闭 · 开启",
            actions.toggleSound, true),
    }))
    body:AddChild(Section({
        Text("清除记录", 17, C.ink, true),
        Text("会清除进行中的值班和班次记录，操作前需再次确认。", 14, C.muted),
        Button("清除进度", actions.resetProgress, true, false, { textColor = C.red, borderColor = C.red }),
    }))
end

---@param model table
---@param actions table
---@return Panel
function View.Build(model, actions)
    local body = UI.Panel {
        width = "100%",
        maxWidth = 620,
        alignSelf = "center",
        paddingHorizontal = 24,
        paddingTop = 20,
        paddingBottom = 32,
        gap = model.screen == "game" and 10 or 14,
    }
    local notice = Notice(model)
    if notice then
        body:AddChild(notice)
    end
    if model.screen == "game" and model.state then
        if model.state.finished then
            Result(model, actions, body)
        else
            Play(model, actions, body)
        end
    elseif model.screen == "result" then
        Result(model, actions, body)
    elseif model.screen == "schedule" then
        Schedule(model, actions, body)
    elseif model.screen == "rules" then
        Rules(model, actions, body)
    elseif model.screen == "settings" then
        Settings(model, actions, body)
    else
        Home(model, actions, body)
    end
    return UI.Panel {
        width = "100%",
        height = "100%",
        backgroundColor = C.paper,
        children = {
            UI.SafeAreaView {
                width = "100%",
                height = "100%",
                nativeMenuInset = true,
                children = {
                    UI.ScrollView {
                        width = "100%",
                        flexGrow = 1,
                        flexShrink = 1,
                        flexBasis = 0,
                        scrollY = true,
                        scrollX = false,
                        showScrollbar = true,
                        children = { body },
                    },
                },
            },
        },
    }
end

return View
