---@class BorrowItem
---@field name string
---@field capacity integer

---@class BorrowPerson
---@field name string
---@field role string
---@field initial string

---@class BorrowRequest
---@field id string
---@field slot integer
---@field item string
---@field person string
---@field returnSlot integer
---@field reason string
---@field acceptText string
---@field declineText string
---@field returnText string

---@class BorrowScenario
---@field id string
---@field title string
---@field subtitle string
---@field intro string
---@field maximum integer
---@field requests BorrowRequest[]

local Content = {}

---@type table<string, BorrowItem>
Content.items = {
    umbrella = { name = "雨伞", capacity = 2 },
    cart = { name = "手推车", capacity = 1 },
}

---@type table<string, BorrowPerson>
Content.people = {
    amei = { name = "阿梅", role = "点心铺店主", initial = "梅" },
    laozhou = { name = "老周", role = "社区志愿者", initial = "周" },
    xiaolin = { name = "小林", role = "图书室管理员", initial = "林" },
    chenshu = { name = "陈叔", role = "维修师傅", initial = "陈" },
    xiaotang = { name = "小唐", role = "花店店员", initial = "唐" },
    zhaoyi = { name = "赵姨", role = "老街坊", initial = "赵" },
}

-- slot 1 至 6 为 16:00 至 18:30，returnSlot 7 为 19:00 收班清算。
-- 请求按到访顺序排列，归还时间确定；后一次对话不假定前一次曾获借。
---@type BorrowScenario[]
Content.scenarios = {
    {
        id = "first-rain",
        title = "雨里的第一班",
        subtitle = "一把伞，一辆车，接住街坊的小事。",
        intro = "雨刚落下，街角的小站亮起灯。邻居们把今天的借用打算写在到访单上。看看谁先回来，再决定手里的物品借给谁。",
        maximum = 10,
        requests = {
            {
                id = "rain-01", slot = 1, item = "umbrella", person = "amei", returnSlot = 3,
                reason = "我给隔壁巷送两盒点心，纸袋可不能淋湿。",
                acceptText = "阿梅把点心袋护在伞下，朝你点点头。",
                declineText = "阿梅看看雨，先回铺子给纸袋再套一层。",
                returnText = "阿梅把伞放回接水桶，袋里的点心已经送到。",
            },
            {
                id = "rain-02", slot = 1, item = "cart", person = "laozhou", returnSlot = 2,
                reason = "活动室要摆几把折叠椅，借辆车搬一趟。",
                acceptText = "老周试了试车轮，推着空车去了活动室。",
                declineText = "老周把椅子数记下，打算分几趟慢慢搬。",
                returnText = "老周还车时把轮子擦了擦：椅子已经摆好了。",
            },
            {
                id = "rain-03", slot = 2, item = "umbrella", person = "xiaolin", returnSlot = 4,
                reason = "去对街取今天归还的书，想让书封干干爽爽。",
                acceptText = "小林把书袋扣好，撑伞走进雨里。",
                declineText = "小林给对街打了个电话，请他们把书先放屋里。",
                returnText = "小林收起伞，轻轻拍了拍干燥的书袋。",
            },
            {
                id = "rain-04", slot = 2, item = "cart", person = "chenshu", returnSlot = 5,
                reason = "几台修好的小电器要送回去，这趟得多走几户。",
                acceptText = "陈叔把绑带理顺，准备把电器一件件装稳。",
                declineText = "陈叔翻开送货单，重新安排今天的路程。",
                returnText = "陈叔推回空车，最后一台收音机也送到了。",
            },
            {
                id = "rain-05", slot = 3, item = "umbrella", person = "xiaotang", returnSlot = 5,
                reason = "送一束花到前街，花纸碰了雨就不好看了。",
                acceptText = "小唐把花束抱在伞下，走得很小心。",
                declineText = "小唐回店里找了防水套，准备换个送法。",
                returnText = "小唐把伞合好：花送到时，包装还是平整的。",
            },
            {
                id = "rain-06", slot = 3, item = "cart", person = "zhaoyi", returnSlot = 4,
                reason = "去楼下取洗好的床单，一小车正好装下。",
                acceptText = "赵姨扶住车把，念叨着要把床单放稳。",
                declineText = "赵姨说店里能代放，晚一点再去取也行。",
                returnText = "赵姨把车送回门边，床单已经收进柜子。",
            },
            {
                id = "rain-07", slot = 4, item = "cart", person = "amei", returnSlot = 6,
                reason = "铺子要收摊了，几个空蒸笼得送回后院。",
                acceptText = "阿梅比了比蒸笼的大小，推车回铺子装。",
                declineText = "阿梅决定先收小件，蒸笼等会儿再搬。",
                returnText = "阿梅还回推车，围裙上的面粉也拍干净了。",
            },
            {
                id = "rain-08", slot = 4, item = "umbrella", person = "laozhou", returnSlot = 5,
                reason = "把活动室钥匙送给门卫，过条街就回来。",
                acceptText = "老周把钥匙放进口袋，撑伞出门。",
                declineText = "老周给门卫留了话，约好在屋檐下交接。",
                returnText = "老周放好雨伞：钥匙交接清楚了。",
            },
            {
                id = "rain-09", slot = 5, item = "cart", person = "xiaolin", returnSlot = 7,
                reason = "这几箱旧书要挪到里间，我想一车一车分好类。",
                acceptText = "小林把空车推走，准备先从最重的一箱开始。",
                declineText = "小林把箱子靠墙摆好，先整理伸手够得到的书。",
                returnText = "小林在收班前推回空车，书架终于空出了走道。",
            },
            {
                id = "rain-10", slot = 5, item = "umbrella", person = "chenshu", returnSlot = 7,
                reason = "去后街取一袋修理零件，顺路把工具带回店里。",
                acceptText = "陈叔拉好工具袋拉链，把伞举过肩头。",
                declineText = "陈叔联系了零件铺，先把东西留在柜台。",
                returnText = "陈叔还伞时掸去水珠，工具袋安稳地挎在肩上。",
            },
            {
                id = "rain-11", slot = 6, item = "cart", person = "xiaotang", returnSlot = 7,
                reason = "把花店门口的箱子搬进屋，搬完就能关门了。",
                acceptText = "小唐推车回店，先给门口留出一条小路。",
                declineText = "小唐把箱子分成小摞，打算慢慢往屋里搬。",
                returnText = "小唐把空车推回灯下：花店也收好摊啦。",
            },
            {
                id = "rain-12", slot = 6, item = "umbrella", person = "zhaoyi", returnSlot = 7,
                reason = "去公交站接下班的家人，回来正好做晚饭。",
                acceptText = "赵姨看了看站牌方向，把伞握在手里。",
                declineText = "赵姨发了条消息，约家人在站台屋檐下等。",
                returnText = "赵姨把伞送回柜台，窗外有人招呼她回家吃饭。",
            },
        },
    },
    {
        id = "between-showers",
        title = "雨歇的空当",
        subtitle = "长借与短借之间，留一点周转的余地。",
        intro = "雨势时大时小，街坊的事也各有长短。今天有人要借很久，也有人只走一个来回。到访单已经排好，归还时间都写得清清楚楚。",
        maximum = 10,
        requests = {
            {
                id = "showers-01", slot = 1, item = "umbrella", person = "chenshu", returnSlot = 6,
                reason = "去巷尾查看几扇漏雨的窗，得在外头待一阵。",
                acceptText = "陈叔带上卷尺，撑伞去看今天的活。",
                declineText = "陈叔回店取雨衣，重新理了一遍工具。",
                returnText = "陈叔放回雨伞，量好的尺寸整齐记在本子上。",
            },
            {
                id = "showers-02", slot = 1, item = "umbrella", person = "xiaolin", returnSlot = 5,
                reason = "去街道图书室核对书册，来回加上整理要些时间。",
                acceptText = "小林把书册夹进包里，出门前又核对了地址。",
                declineText = "小林先和图书室通了电话，商量另一种交接办法。",
                returnText = "小林把伞挂回原处，书册的页角没有受潮。",
            },
            {
                id = "showers-03", slot = 2, item = "umbrella", person = "laozhou", returnSlot = 3,
                reason = "把一张临时绕行的通知送给门卫，很快回来。",
                acceptText = "老周把通知夹在文件板上，撑开雨伞。",
                declineText = "老周拍了张通知的照片，先发给门卫看。",
                returnText = "老周放下伞：通知已经贴在大家看得见的地方。",
            },
            {
                id = "showers-04", slot = 2, item = "cart", person = "zhaoyi", returnSlot = 3,
                reason = "小店有一袋米要取，推到楼下就好搬了。",
                acceptText = "赵姨拍拍车板，说这尺寸放一袋米正合适。",
                declineText = "赵姨请小店先替她留着米，回家收拾腾地方。",
                returnText = "赵姨还回推车，车板上的米袋印子已经擦净。",
            },
            {
                id = "showers-05", slot = 3, item = "umbrella", person = "amei", returnSlot = 4,
                reason = "给后街送一盒刚做好的糕点，路不远。",
                acceptText = "阿梅把糕点盒提稳，撑伞绕过门口的水洼。",
                declineText = "阿梅把盒子放回保温袋，和收件人另约了时间。",
                returnText = "阿梅把伞靠好，糕点盒已经交到收件人手中。",
            },
            {
                id = "showers-06", slot = 3, item = "cart", person = "xiaotang", returnSlot = 4,
                reason = "把花店后门的空花筐移进库房，只搬一趟。",
                acceptText = "小唐推着车，先去清出库房门边的空地。",
                declineText = "小唐决定一次提两个筐，边搬边整理。",
                returnText = "小唐推回空车，后门的花筐已经码整齐了。",
            },
            {
                id = "showers-07", slot = 4, item = "cart", person = "chenshu", returnSlot = 5,
                reason = "取一卷防水布送到巷尾，推着比抱着省力。",
                acceptText = "陈叔摸了摸车板，把绑带留在方便拿的位置。",
                declineText = "陈叔给材料店打电话，请他们先放在门内。",
                returnText = "陈叔把车送回，防水布已经放到干燥的地方。",
            },
            {
                id = "showers-08", slot = 4, item = "cart", person = "xiaolin", returnSlot = 6,
                reason = "图书室门口有几箱捐书，要搬进去逐箱摆放。",
                acceptText = "小林看好车轮方向，推着车去接那几箱书。",
                declineText = "小林先把箱子垫高，等腾出手再慢慢搬。",
                returnText = "小林还回空车，说门口现在能顺畅进出了。",
            },
            {
                id = "showers-09", slot = 5, item = "umbrella", person = "laozhou", returnSlot = 6,
                reason = "往公告栏补一张值班表，别让纸在路上淋软了。",
                acceptText = "老周卷好值班表，把它护在雨伞下。",
                declineText = "老周先把电子版发进街坊群，纸表晚些再送。",
                returnText = "老周收伞时笑了笑：明天找谁，大家都看得清。",
            },
            {
                id = "showers-10", slot = 5, item = "cart", person = "zhaoyi", returnSlot = 6,
                reason = "给楼下茶摊送一箱空杯，送到就把车推回来。",
                acceptText = "赵姨在车板上垫了块布，准备把杯箱放稳。",
                declineText = "赵姨和茶摊约好分两趟交接，空杯先不急着搬。",
                returnText = "赵姨还回车，茶摊的空杯已经摆上架子。",
            },
            {
                id = "showers-11", slot = 6, item = "umbrella", person = "amei", returnSlot = 7,
                reason = "去街口取晚饭用的菜，回铺子路上再绕来还。",
                acceptText = "阿梅把菜袋折好放进口袋，撑开伞走了。",
                declineText = "阿梅先在铺子门口等雨小些，顺手理好围裙。",
                returnText = "阿梅提着菜袋来还伞，铺子里的灯也暖暖地亮着。",
            },
            {
                id = "showers-12", slot = 6, item = "cart", person = "xiaotang", returnSlot = 7,
                reason = "把收好的花盆送进侧屋，今晚就能放心关窗。",
                acceptText = "小唐推着车走向侧屋，先把过道里的门撑住。",
                declineText = "小唐给花盆排了个次序，准备一盆盆抱进去。",
                returnText = "小唐把车停回原位，抬头看了看渐渐停下的雨。",
            },
        },
    },
    {
        id = "lamplight",
        title = "收班前的灯",
        subtitle = "看好后面的到访，让物品多走几个来回。",
        intro = "小站里备好了两把伞和一辆推车。今天的事都不大，却有几趟凑在一起。把归还和下一次到访接上，收班时就能留下更多完成的记录。",
        maximum = 10,
        requests = {
            {
                id = "light-01", slot = 1, item = "cart", person = "zhaoyi", returnSlot = 4,
                reason = "把家里几箱换季衣物送去女儿家，得走一段路。",
                acceptText = "赵姨拿出绑绳，推着车回家装那几箱衣物。",
                declineText = "赵姨先把箱子归拢好，重新约了送过去的时间。",
                returnText = "赵姨还回推车，叠好的衣物已经放进新柜子。",
            },
            {
                id = "light-02", slot = 1, item = "umbrella", person = "xiaotang", returnSlot = 4,
                reason = "去几家店确认明天的花束订单，想顺着街走一圈。",
                acceptText = "小唐把订单本放进防水袋，撑伞出门。",
                declineText = "小唐回到店里，先挨家打电话核对订单。",
                returnText = "小唐合起伞，订单本上多了几行整齐的备注。",
            },
            {
                id = "light-03", slot = 2, item = "cart", person = "amei", returnSlot = 3,
                reason = "把一袋面粉从巷口搬到铺子，过来还车很方便。",
                acceptText = "阿梅按了按车把，盘算着从平整的那边走。",
                declineText = "阿梅请店家把面粉暂存柜台，先回去腾地方。",
                returnText = "阿梅推回车，面粉已经安稳放进铺子。",
            },
            {
                id = "light-04", slot = 2, item = "umbrella", person = "laozhou", returnSlot = 3,
                reason = "去对街送明天活动的签到纸，一个来回就好。",
                acceptText = "老周把纸夹进薄夹板，撑伞走向对街。",
                declineText = "老周先把名单拍给对方，纸张留在干燥处。",
                returnText = "老周把伞撑在桶边沥水，签到纸已交接好了。",
            },
            {
                id = "light-05", slot = 3, item = "cart", person = "xiaolin", returnSlot = 4,
                reason = "把门厅的一摞杂志送进阅览室，搬完便归还。",
                acceptText = "小林推走车，打算先把杂志码得平一些。",
                declineText = "小林分出几摞小份，先抱最上面的一摞进去。",
                returnText = "小林推回空车，杂志已经按月份排在架上。",
            },
            {
                id = "light-06", slot = 3, item = "umbrella", person = "chenshu", returnSlot = 5,
                reason = "去前街送一只修好的台灯，灯罩得避着雨。",
                acceptText = "陈叔抱好包着软布的台灯，把伞撑高了一点。",
                declineText = "陈叔先把台灯放回工作台，等方便时再送。",
                returnText = "陈叔放回雨伞：台灯接上电，亮得很稳。",
            },
            {
                id = "light-07", slot = 4, item = "umbrella", person = "zhaoyi", returnSlot = 7,
                reason = "去菜场再逛一圈，回来时顺路经过小站。",
                acceptText = "赵姨把购物袋揣好，说会按单上的时刻还伞。",
                declineText = "赵姨看看时间，准备先把家里的事收拾妥当。",
                returnText = "赵姨拎着菜来还伞，柜台边多了几句家常话。",
            },
            {
                id = "light-08", slot = 4, item = "cart", person = "xiaotang", returnSlot = 5,
                reason = "给隔壁店送一盆落地绿植，车板比手抱平稳。",
                acceptText = "小唐先把车停稳，准备给花盆垫好底。",
                declineText = "小唐请隔壁店先留好位置，约好晚一点再送。",
                returnText = "小唐推回空车：绿植摆在窗边，正合适。",
            },
            {
                id = "light-09", slot = 5, item = "umbrella", person = "amei", returnSlot = 7,
                reason = "去街尾买些明早用的食材，得把几家小店走完。",
                acceptText = "阿梅叠好采购单，撑伞去赶小店收摊前的空当。",
                declineText = "阿梅翻了翻采购单，先联系熟悉的店家备货。",
                returnText = "阿梅按时还了伞，明早要用的食材也备齐了。",
            },
            {
                id = "light-10", slot = 5, item = "cart", person = "laozhou", returnSlot = 6,
                reason = "把活动室的靠垫送进储物间，推一趟正合适。",
                acceptText = "老周扶着车，回去把靠垫一摞摞码稳。",
                declineText = "老周决定先抱轻的靠垫，储物间的门已经开着。",
                returnText = "老周把车放回门边，活动室也收拾清爽了。",
            },
            {
                id = "light-11", slot = 6, item = "umbrella", person = "xiaolin", returnSlot = 7,
                reason = "把借书登记册送到值班室，纸页不想沾水。",
                acceptText = "小林夹紧登记册，撑伞向值班室走去。",
                declineText = "小林找了个文件袋，把登记册先封好。",
                returnText = "小林送回雨伞，图书室的门口也亮起了灯。",
            },
            {
                id = "light-12", slot = 6, item = "cart", person = "chenshu", returnSlot = 7,
                reason = "把门外的工具箱挪进店里，搬好就来交车。",
                acceptText = "陈叔推车回店，先把路上的小石子踢到一边。",
                declineText = "陈叔扣紧工具箱，准备分两趟提回屋。",
                returnText = "陈叔把车停好。街边的店门收了，小站也该关灯了。",
            },
        },
    },
}

---@param id string
---@return BorrowScenario?
function Content.GetScenario(id)
    for _, scenario in ipairs(Content.scenarios) do
        if scenario.id == id then
            return scenario
        end
    end
    return nil
end

return Content
