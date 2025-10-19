setclipboard("https://discord.gg/cpshub")

local Windui = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players, RunService, UserInputService = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService")
local LocalPlayer, Camera = Players.LocalPlayer, workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Window = Windui:CreateWindow{
    Title = "CPS Network - Combat GUI",
    Icon = "sword",
    Author = "Enhanced Integration",
    Size = UDim2.fromOffset(650, 210),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 130
}

local DetectTab = Window:Tab{ Title = "Auto Combat", Icon = "shield" }
local CounterTab = Window:Tab{ Title = "Auto Counter", Icon = "zap" }
local UtilitiesTab = Window:Tab{ Title = "Utilities", Icon = "tools" }
local ReadMeTab = Window:Tab{ Title = "Read Me", Icon = "book" }

-- Auto Combat Variables
local m1AfterEnabled, m1CatchEnabled = false, false
local normalRange, specialRange, skillRange, skillDelay = 30, 50, 50, 1.2
local detectActive, counterActive, counterRange = true, true, 8

DetectTab:Toggle{ Title = "Auto Block", Value = true, Callback = function(v) detectActive = v end }
DetectTab:Toggle{ Title = "M1 After Block", Value = false, Callback = function(v) m1AfterEnabled = v end }
DetectTab:Toggle{ Title = "M1 Catch", Value = false, Callback = function(v) m1CatchEnabled = v end }
DetectTab:Slider{ Title = "Normal Range", Value = { Min=10, Max=100, Default=30 }, Callback = function(v) normalRange = v end }
DetectTab:Slider{ Title = "Special Range", Value = { Min=10, Max=100, Default=50 }, Callback = function(v) specialRange = v end }
DetectTab:Slider{ Title = "Skill Range", Value = { Min=10, Max=100, Default=50 }, Callback = function(v) skillRange = v end }
DetectTab:Slider{ Title = "Skill Delay", Step = 0.1, Value = { Min=0.1, Max=5, Default=1.2 }, Callback = function(v) skillDelay = v end }

CounterTab:Toggle{ Title = "Auto Counter", Value = true, Callback = function(v) counterActive = v end }
CounterTab:Slider{ Title = "Counter Range", Value = { Min=5, Max=25, Default=8 }, Callback = function(v) counterRange = v end }

function getPlayerInView()
    local closest, minangle = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum.Health > 0 and plr.Character.HumanoidRootPart:IsDescendantOf(workspace) then
                local hrp = plr.Character.HumanoidRootPart
                local angle = math.acos((hrp.Position - Camera.CFrame.Position).Unit:Dot(Camera.CFrame.LookVector))
                if angle < math.rad(25) and angle < minangle then
                    closest, minangle = plr, angle
                end
            end
        end
    end
    return closest
end

local camlockEnabledPC, camlockKey = false, Enum.KeyCode.C
local camlockTargetPC, camlockHighlightPC, camlockBillboardPC

DetectTab:Toggle{
    Title = "Camlock (PC)",
    Value = false,
    Callback = function(state)
        camlockEnabledPC = state
        if state then
            local p = getPlayerInView()
            if p then camlockTargetPC = p; lockCamlockPC() else clearCamlockPC() end
        else
            clearCamlockPC()
        end
    end,
}

DetectTab:Keybind{
    Default = camlockKey.Name,
    Callback = function(name)
        local code = Enum.KeyCode[name]
        if code then camlockKey = code end
    end
}

function lockCamlockPC()
    clearCamlockPC()
    if not camlockEnabledPC or not camlockTargetPC or not camlockTargetPC.Character then return end
    local char = camlockTargetPC.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp and hum.Health > 0) then clearCamlockPC() return end

    camlockHighlightPC = Instance.new("Highlight", char)
    camlockHighlightPC.Adornee = char
    camlockHighlightPC.FillColor = Color3.new(1, 0, 0)
    camlockHighlightPC.FillTransparency = 0.5
    camlockHighlightPC.OutlineTransparency = 1

    camlockBillboardPC = Instance.new("BillboardGui", char)
    camlockBillboardPC.Adornee = hrp
    camlockBillboardPC.Size = UDim2.new(3, 0, 0.7, 0)
    camlockBillboardPC.StudsOffset = Vector3.new(0, 3.5, 0)
    camlockBillboardPC.AlwaysOnTop = true

    local txt = Instance.new("TextLabel", camlockBillboardPC)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.Text = "Fighting: " .. (camlockTargetPC.DisplayName or camlockTargetPC.Name)
    txt.Font = Enum.Font.SourceSansBold
    txt.TextColor3 = Color3.new(1, 0, 0)
    txt.TextScaled = true
    txt.BackgroundTransparency = 1

    RunService:UnbindFromRenderStep("PC_CamlockLook")
    RunService:BindToRenderStep("PC_CamlockLook", Enum.RenderPriority.Camera.Value + 5, function()
        if camlockEnabledPC and camlockTargetPC and camlockTargetPC.Character and camlockTargetPC.Character:FindFirstChild("HumanoidRootPart")
           and camlockTargetPC.Character:FindFirstChildOfClass("Humanoid") and camlockTargetPC.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local root = camlockTargetPC.Character.HumanoidRootPart
            local myPos = Camera.CFrame.Position
            Camera.CFrame = CFrame.new(myPos, root.Position)
        else
            clearCamlockPC()
        end
    end)
end

function clearCamlockPC()
    RunService:UnbindFromRenderStep("PC_CamlockLook")
    if camlockBillboardPC then camlockBillboardPC:Destroy() camlockBillboardPC = nil end
    if camlockHighlightPC then camlockHighlightPC:Destroy() camlockHighlightPC = nil end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == camlockKey then
        camlockEnabledPC = not camlockEnabledPC
        if camlockEnabledPC then
            local p = getPlayerInView()
            if p then camlockTargetPC = p; lockCamlockPC() else clearCamlockPC() end
        else
            clearCamlockPC()
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if camlockTargetPC and plr == camlockTargetPC then clearCamlockPC() end
end)

-- MOBILE CAMLOCK GUI EXACT FROM YOUR .TXT
camlockGui = Instance.new("ScreenGui", PlayerGui)
camlockGui.Name = "CPSMobileCamlockGui"
camlockGui.ResetOnSpawn = false
camlockGui.Enabled = true

camlockFrame = Instance.new("Frame", camlockGui)
camlockFrame.Size = UDim2.new(0, 170, 0, 70)
camlockFrame.Position = UDim2.new(0.5, -85, 0.95, -80)
camlockFrame.AnchorPoint = Vector2.new(0.5, 1)
camlockFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
camlockFrame.BorderSizePixel = 0
Instance.new("UIStroke", camlockFrame).Color = Color3.new(1, 0, 0)
Instance.new("UICorner", camlockFrame).CornerRadius = UDim.new(0, 14)
local UIGradient = Instance.new("UIGradient", camlockFrame)
UIGradient.Color = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(0.5, 0, 0))
UIGradient.Rotation = 45

camlockText = Instance.new("TextLabel", camlockFrame)
camlockText.Size = UDim2.new(1, -10, 0.4, -10)
camlockText.Position = UDim2.new(0, 5, 0, 4)
camlockText.BackgroundTransparency = 1
camlockText.Text = "Camlock: OFF"
camlockText.TextColor3 = Color3.new(1, 0, 0)
camlockText.Font = Enum.Font.SourceSansBold
camlockText.TextScaled = true

fightingText = Instance.new("TextLabel", camlockFrame)
fightingText.Size = UDim2.new(1, -10, 0.4, -10)
fightingText.Position = UDim2.new(0, 5, 0, 30)
fightingText.BackgroundTransparency = 1
fightingText.Text = ""
fightingText.TextColor3 = Color3.new(1, 0, 0)
fightingText.Font = Enum.Font.SourceSansItalic
fightingText.TextScaled = true

keybindText = Instance.new("TextLabel", camlockFrame)
keybindText.Size = UDim2.new(1, -10, 0.2, -5)
keybindText.Position = UDim2.new(0, 5, 0, 56)
keybindText.BackgroundTransparency = 1
keybindText.Text = "PC Keybind: " .. camlockKey.Name
keybindText.TextColor3 = Color3.new(1, 0, 0)
keybindText.Font = Enum.Font.SourceSansItalic
keybindText.TextScaled = true

camlockFrame.Active = true
local camlockMobileState, camlockTargetMobile, camlockHighlightMobile, camlockBillboardMobile = false
local dragging, dragInput, dragStart, startPos

camlockFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        camlockFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

camlockFrame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not dragging then
        dragging = true
        dragStart = input.Position
        startPos = camlockFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
        camlockMobileState = not camlockMobileState
        if camlockMobileState then lockCamlockMobile() else clearCamlockMobile() end
    end
end)

function lockCamlockMobile()
    clearCamlockMobile()
    local target = getPlayerInView()
    if not camlockMobileState then
        camlockText.Text = "Camlock: OFF"
        fightingText.Text = ""
        RunService:UnbindFromRenderStep("Mobile_CamlockLook")
        return
    end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart")
       or not target.Character:FindFirstChildOfClass("Humanoid") or target.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
        camlockText.Text = "Camlock: ON"
        fightingText.Text = "No valid target"
        RunService:UnbindFromRenderStep("Mobile_CamlockLook")
        return
    end
    camlockTargetMobile = target.Character
    local hum = camlockTargetMobile:FindFirstChildOfClass("Humanoid")
    local hrp = camlockTargetMobile:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp and hum.Health > 0) then
        camlockText.Text = "Camlock: ON"
        fightingText.Text = "No valid target"
        RunService:UnbindFromRenderStep("Mobile_CamlockLook")
        return
    end

    camlockHighlightMobile = Instance.new("Highlight", camlockTargetMobile)
    camlockHighlightMobile.Adornee = camlockTargetMobile
    camlockHighlightMobile.FillColor = Color3.new(1, 0, 0)
    camlockHighlightMobile.FillTransparency = 0.5
    camlockHighlightMobile.OutlineTransparency = 1

    camlockBillboardMobile = Instance.new("BillboardGui", camlockTargetMobile)
    camlockBillboardMobile.Adornee = hrp
    camlockBillboardMobile.Size = UDim2.new(3, 0, 0.7, 0)
    camlockBillboardMobile.StudsOffset = Vector3.new(0, 3.5, 0)
    camlockBillboardMobile.AlwaysOnTop = true

    local txt = Instance.new("TextLabel", camlockBillboardMobile)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.Text = "Fighting: " .. (target.DisplayName or target.Name)
    txt.Font = Enum.Font.SourceSansBold
    txt.TextColor3 = Color3.new(1, 0, 0)
    txt.TextScaled = true
    txt.BackgroundTransparency = 1

    camlockText.Text = "Camlock: ON"
    fightingText.Text = "Fighting: " .. (target.DisplayName or target.Name)
    keybindText.Text = "PC Keybind: " .. camlockKey.Name

    RunService:UnbindFromRenderStep("Mobile_CamlockLook")
    RunService:BindToRenderStep("Mobile_CamlockLook", Enum.RenderPriority.Camera.Value + 5, function()
        if camlockMobileState and camlockTargetMobile and camlockTargetMobile:FindFirstChild("HumanoidRootPart")
           and camlockTargetMobile:FindFirstChildOfClass("Humanoid") and camlockTargetMobile:FindFirstChildOfClass("Humanoid").Health > 0 then
            local root = camlockTargetMobile:FindFirstChild("HumanoidRootPart")
            local myPos = Camera.CFrame.Position
            Camera.CFrame = CFrame.new(myPos, root.Position)
        else
            clearCamlockMobile()
        end
    end)
end

function clearCamlockMobile()
    RunService:UnbindFromRenderStep("Mobile_CamlockLook")
    if camlockBillboardMobile then camlockBillboardMobile:Destroy() camlockBillboardMobile = nil end
    if camlockHighlightMobile then camlockHighlightMobile:Destroy() camlockHighlightMobile = nil end
    camlockTargetMobile = nil
    camlockText.Text = "Camlock: OFF"
    fightingText.Text = ""
end

Players.PlayerRemoving:Connect(function(plr)
    if camlockTargetPC and plr == camlockTargetPC then clearCamlockPC() end
    if camlockTargetMobile and plr.Character == camlockTargetMobile then clearCamlockMobile() end
end)

-- End of first snippet, continuing in next snippet...
-- AutoCombat and AutoCounter core logic, including no push on autoblock
local comboIDs = {10480793962, 10480796021}
local allIDs = {
    Saitama={10469493270,10469630950,10469639222,10469643643, special=10479335397},
    Garou={13532562418,13532600125,13532604085,13294471966, special=10479335397},
    Cyborg={13491635433,13296577783,13295919399,13295936866, special=10479335397},
    Sonic={13370310513,13390230973,13378751717,13378708199, special=13380255751},
    Metal={14004222985,13997092940,14001963401,14136436157, special=13380230951},
    Blade={15259161390,15240216931,15240176873,15162694192, special=13380255751},
    Tatsumaki={16515503507,16515520431,16515448089,16552234590, special=10479335397},
    Dragon={17889458563,17889461810,17889471098,17889290569, special=10479335397},
    Tech={123005629431309,100059874351664,104895379416342,134775406437626, special=10479335397},
}
local skillIDs = {
    [10468665991]=true,[10466974800]=true,[10471336737]=true,[12510170988]=true,[15290930205]=true,[18179181663]=true,
}
local Live = workspace:WaitForChild("Live")
local lastCatch, lastFire, firecd = 0, {}, 1.0

local Communicate, Character, HRP
local function resetCharVars()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HRP = Character:WaitForChild("HumanoidRootPart")
    Communicate = Character:WaitForChild("Communicate")
end
resetCharVars()
LocalPlayer.CharacterAdded:Connect(resetCharVars)

local function fireRemote(goal)
    Communicate:FireServer({Goal=goal, Key=(goal=="KeyPress" or goal=="KeyRelease") and Enum.KeyCode.F or nil})
end

local function doAfterBlock(hrp)
    if m1AfterEnabled and hrp and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local dist = (hrp.Position - root.Position).Magnitude
            if dist <= 10 then
                fireRemote("Communicate")
                task.delay(0.3, function()
                    local newDist = (hrp.Position - root.Position).Magnitude
                    if newDist <= 10 then fireRemote("LeftClickRelease") end
                end)
            end
        end
    end
end

local function isBlocking()
    local blockingVal = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Blocking")
    if blockingVal and blockingVal:IsA("BoolValue") then return blockingVal.Value end
    return false
end

local function checkAnims()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character.Parent == Live then
            local char, hrp, hum = player.Character, player.Character:FindFirstChild("HumanoidRootPart"), player.Character:FindFirstChildWhichIsA("Humanoid")
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hum and myHRP then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    local anims = {}
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        local id = tonumber(track.Animation.AnimationId:match("%d+"))
                        if id then anims[id] = true end
                    end
                    local comboCount = 0
                    for _, id in ipairs(comboIDs) do if anims[id] then comboCount = comboCount + 1 end end
                    for _, group in pairs(allIDs) do
                        local normalHits, special = 0, anims[group.special]
                        for i = 1,4 do if anims[group[i]] then normalHits = normalHits + 1 end end
                        if comboCount == 2 and normalHits >= 2 and dist <= specialRange then
                            fireRemote("KeyPress")
                            task.wait(0.7)
                            fireRemote("KeyRelease")
                            break
                        elseif normalHits > 0 and dist <= normalRange then
                            fireRemote("KeyPress")
                            task.wait(0.15)
                            fireRemote("KeyRelease")
                            doAfterBlock(hrp)
                            break
                        elseif special and dist <= specialRange and not m1CatchEnabled then
                            fireRemote("KeyPress")
                            task.delay(1, function() fireRemote("KeyRelease") end)
                            break
                        end
                    end
                    for animId in pairs(anims) do
                        if skillIDs[animId] and dist <= skillRange then
                            fireRemote("KeyPress")
                            task.delay(skillDelay, function() fireRemote("KeyRelease") end)
                            break
                        end
                    end
                end
            end
        end
    end
end

local function checkM1Catch()
    if not m1CatchEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character.Parent == Live then
            local char, hrp, hum = player.Character, player.Character:FindFirstChild("HumanoidRootPart"), player.Character:FindFirstChildWhichIsA("Humanoid")
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hum and myHRP then
                local dist1 = (hrp.Position - myHRP.Position).Magnitude
                if dist1 <= 30 then
                    local animator = hum:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            local id = tonumber(track.Animation.AnimationId:match("%d+"))
                            if id == 10479335397 then
                                task.delay(0.1, function()
                                    local dist2 = (hrp.Position - myHRP.Position).Magnitude
                                    if dist2 < dist1 - 0.5 and tick() - lastCatch >= 5 then
                                        lastCatch = tick()
                                        fireRemote("Communicate")
                                        task.delay(0.2, function() fireRemote("LeftClickRelease") end)
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game)
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                                        task.delay(1, function()
                                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
                                        end)
                                    end
                                end)
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if detectActive then
        pcall(checkAnims)
        pcall(checkM1Catch)
    end
end)

local delayed = {
    ["rbxassetid://10479335397"] = true,
    ["rbxassetid://13380255751"] = true,
    ["rbxassetid://134775406437626"] = true,
}

local normal = {}
for _, group in pairs(allIDs) do
    for i = 1,4 do
        normal["rbxassetid://" .. tostring(group[i])] = true
    end
    if group.special then
        normal["rbxassetid://" .. tostring(group.special)] = true
    end
end
for id in pairs(skillIDs) do
    normal["rbxassetid://" .. tostring(id)] = true
end

local function closeEnough(a, b, dist)
    return (a - b).Magnitude <= dist
end

local function fireCounter()
    local prey = LocalPlayer.Backpack:FindFirstChild("Prey's Peril")
    if prey then
        Communicate:FireServer({Tool = prey, Goal = "Console Move"})
    end
    local split = LocalPlayer.Backpack:FindFirstChild("Split Second Counter")
    if split then
        Communicate:FireServer({Tool = split, Goal = "Console Move"})
    end
end

RunService.Heartbeat:Connect(function()
    if not counterActive then return end
    local blocking = isBlocking()
    for _, model in pairs(Live:GetChildren()) do
        if model:IsA("Model") and model ~= Character and model:FindFirstChild("HumanoidRootPart") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local anim = hum and hum:FindFirstChildOfClass("Animator")
            local root = model.HumanoidRootPart
            if anim and closeEnough(HRP.Position, root.Position, counterRange) then
                if blocking then
                    -- do not push if already autoblocking
                    return
                end
                for _, track in pairs(anim:GetPlayingAnimationTracks()) do
                    local id = track.Animation.AnimationId
                    if normal[id] or delayed[id] then
                        local key = model:GetDebugId() .. id
                        if not lastFire[key] or os.clock() - lastFire[key] > firecd then
                            lastFire[key] = os.clock()
                            if delayed[id] then
                                task.delay(0.05, fireCounter)
                            else
                                fireCounter()
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Utilities Tab setup with ESP as blue outline stroke (not filled)
local espEnabled = false
local espBoxes = {}

UtilitiesTab:Toggle{
    Title = "Player ESP (Outline)",
    Default = false,
    Callback = function(val)
        espEnabled = val
        if not val then
            for _, box in pairs(espBoxes) do
                box:Destroy()
            end
            espBoxes = {}
        end
    end
}

local function createEspBox(player)
    local box = Instance.new("BoxHandleAdornment")
    if player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        box.Adornee = hrp
    end
    box.Color3 = Color3.fromRGB(0, 0, 255) -- Blue color
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Size = Vector3.new(4, 6, 0.1)
    box.Transparency = 0.8
    box.LineThickness = 2
    box.Parent = Camera
    return box
end

local function updateEsp()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not espBoxes[player] then
                espBoxes[player] = createEspBox(player)
            end
            espBoxes[player].Adornee = player.Character.HumanoidRootPart
        else
            if espBoxes[player] then
                espBoxes[player]:Destroy()
                espBoxes[player] = nil
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if espEnabled then
        updateEsp()
    end
end)

ReadMeTab:Button{
    Text = "Join discord server for Auto Tech, Auto Farm etc!",
    Callback = function()
        setclipboard("https://discord.gg/cpshub")
        Windui:Notify{ Title = "Copied!", Content = "Discord invite copied to clipboard.", Duration = 3, Icon = "check" }
    end,
}

Window:SelectTab(1)
Windui:Notify{ Title = "CPS Network", Content = "ALL features final, OG OG, always work.", Duration = 6, Icon = "check" }
