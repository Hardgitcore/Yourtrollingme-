local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Global Variables
local player = Players.LocalPlayer
local loopActive = false
local skyFarmActive = false
local orbitOnlyActive = false
local autoResetActive = false
local auto1HPSafetyActive = false
local autoClaimDailyActive = false

-- Stat Tracker Variables
local totalEarnedVolts = 0
local totalEarnedXP = 0
local totalDamageTaken = 0
local totalDeaths = 0
local totalHealthRegained = 0
local totalRemsTouched = 0

local lastVolts = nil
local lastXP = nil
local lastHealth = nil

-- Purchase Variables
local disasterAmount = 1

local Window = Rayfield:CreateWindow({
    Name = "Parkour Pandemic (YamYum Edit)",
    LoadingTitle = "Requested by Frostyry",
    LoadingSubtitle = "Scripts made by yamyum!",
    ConfigurationSaving = { Enabled = false }
})

-- UI Tabs
local InfoTab = Window:CreateTab("Information", 0) -- Inserted as the 1st tab
local Tab = Window:CreateTab("Main Features", 0)
local PurchaseTab = Window:CreateTab("Purchase", 0)
local TrollingTab = Window:CreateTab("Trolling", 0)
local AchievementTab = Window:CreateTab("Achievements", 0)

-- Configuration Variables
local CIRCLE_SPEED = 0.04 
local CIRCLE_RADIUS = 300 
local HAZARD_SAFE_RADIUS = 90 
local HEAL_THRESHOLD = 50 
local BANNED_KEYWORDS = {"void", "warning", "baseplatewater", "tide floor", "tornado"}

-- // Helper: Parse numbers from strings
local function parseNumber(val)
    if typeof(val) == "number" then return val end
    if not val then return nil end
    local str = tostring(val)
    local firstNum = str:match("([%d,]+)")
    if firstNum then
        local clean = firstNum:gsub(",", "")
        return tonumber(clean)
    end
    return nil
end

-- // Helper: Format numbers with commas
local function formatNumber(n)
    local formatted = tostring(math.floor(n))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- // Helper: Safely get current Volts value from GUI
local function GetVoltsValue()
    local voltsObj = player:FindFirstChild("PlayerGui")
        and player.PlayerGui:FindFirstChild("MONEY")
        and player.PlayerGui.MONEY:FindFirstChild("Volts")
    
    if voltsObj then
        if voltsObj:IsA("TextLabel") or voltsObj:IsA("TextBox") then
            return parseNumber(voltsObj.Text)
        elseif voltsObj:IsA("ValueBase") then
            return parseNumber(voltsObj.Value)
        end
    end
    return nil
end

-- // Helper: Safely get current XP value from GUI
local function GetXPValue()
    local xpObj = player:FindFirstChild("PlayerGui")
        and player.PlayerGui:FindFirstChild("PlayerUi")
        and player.PlayerGui.PlayerUi:FindFirstChild("ImageLabel")
        and player.PlayerGui.PlayerUi.ImageLabel:FindFirstChild("Container")
        and player.PlayerGui.PlayerUi.ImageLabel.Container:FindFirstChild("BarBackground")
        and player.PlayerGui.PlayerUi.ImageLabel.Container.BarBackground:FindFirstChild("XPText")
    
    if xpObj then
        if xpObj:IsA("TextLabel") or xpObj:IsA("TextBox") then
            return parseNumber(xpObj.Text)
        elseif xpObj:IsA("ValueBase") then
            return parseNumber(xpObj.Value)
        end
    end
    return nil
end

-- =================================================================
-- // INFORMATION TAB ELEMENTS
-- =================================================================
InfoTab:CreateSection("Welcome to Parkour Pandemic YamYum Edit!")

InfoTab:CreateParagraph({
    Title = "About This Script",
    Content = "This is a customized auto-farming and utillity script Parkour Pandemic, this script was created before the request i could not upload to script to Sb due to my acc being new Enjoy!\nRequested by: Frostyry\nScripted/Edited by: yamyum"
})

InfoTab:CreateSection("Script Overview")

InfoTab:CreateLabel("-> Main Features: Auto-farming, Auto get wins, and stat tracking.")
InfoTab:CreateLabel("-> Purchase: Buy gears and disasters automatically.")
InfoTab:CreateLabel("-> Trolling: Super ring parts and more to come soon.")
InfoTab:CreateLabel("-> Achievements: Automation for game-specific achievements (more to come soon)")

InfoTab:CreateSection("Important Notes (PLEASE READ)")
InfoTab:CreateParagraph({
    Title = "Safety & Evasion",
    Content = "I tried my best to get this working so heres a few notes \n1. Why does it stop purifying beacons when theres a tornado? This is so you dont get hit during the tornado\n2. The script is not suitable for blackhole and tornado\n3. If your asking which autofarm i reccommend its Sky autofarm\n4. Yes both autofarms have an auto use heal system using vitallity gear.\n5. 100% suggest more stuff in the comments Thanks!"
})


-- =================================================================
-- // ACHIEVEMENTS TAB ELEMENTS
-- =================================================================
AchievementTab:CreateSection("All Death Achievement Farm")

AchievementTab:CreateToggle({
    Name = "Auto Reset on Round",
    CurrentValue = false,
    Callback = function(Value)
        autoResetActive = Value

        if autoResetActive then
            task.spawn(function()
                while autoResetActive do
                    local map = workspace:FindFirstChild("ActiveMap")
                    if map then
                        task.wait(10)
                        
                        if autoResetActive and workspace:FindFirstChild("ActiveMap") == map then
                            local char = player.Character
                            if char then
                                local humanoid = char:FindFirstChild("Humanoid")
                                if humanoid and humanoid.Health > 0 then
                                    humanoid.Health = 0
                                end
                            end
                            
                            repeat 
                                task.wait(1) 
                            until not autoResetActive or workspace:FindFirstChild("ActiveMap") ~= map
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

AchievementTab:CreateSection("Undying Achievement, not perfect")

-- Tracker to know if we are currently dipping in the water to reach 1 HP
local doingWaterDip = false

AchievementTab:CreateToggle({
    Name = "Undying Farm (Manual <10 -> Sky -> 16 Water -> 1 HP)",
    CurrentValue = false,
    Callback = function(Value)
        auto1HPSafetyActive = Value
        
        -- Reset the dip tracker if the toggle is turned off
        if not Value then 
            doingWaterDip = false 
        end

        if auto1HPSafetyActive then
            task.spawn(function()
                while auto1HPSafetyActive do
                    local char = player.Character
                    if char then
                        local humanoid = char:FindFirstChild("Humanoid")
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        
                        if humanoid and hrp and humanoid.Health > 0 then
                            
                            -- Safety reset: If player heals fully manually, reset the sequence
                            if humanoid.Health > 25 then
                                doingWaterDip = false
                            end

                            if not doingWaterDip then
                                if humanoid.Health <= 10 then
                                    -- Step 1: User took damage manually. TP to sky to regen.
                                    pcall(function()
                                        hrp.Anchored = true
                                        hrp.CFrame = CFrame.new(hrp.Position.X, 2000, hrp.Position.Z)
                                    end)
                                -- Step 2: EXACTLY 16 HP. 16 - 15 water damage = exactly 1 HP!
                                elseif math.floor(humanoid.Health) == 16 then
                                    doingWaterDip = true
                                    pcall(function()
                                        local waterPart = workspace:FindFirstChild("BaseplateWater")
                                        if waterPart then
                                            hrp.Anchored = false
                                            hrp.CFrame = waterPart.CFrame + Vector3.new(0, 3, 0)
                                        end
                                    end)
                                end
                            else
                                -- Step 3: We are in the water dipping process. Wait until that 15 dmg hits.
                                if humanoid.Health <= 1.5 then
                                    doingWaterDip = false
                                    -- Fast rescue to sky
                                    pcall(function()
                                        hrp.Anchored = true
                                        hrp.CFrame = CFrame.new(hrp.Position.X, 2000, hrp.Position.Z)
                                    end)
                                end
                            end
                        end
                    end
                    -- Extremely fast check (0.05) to instantly catch that 15 damage tick
                    task.wait(0.05) 
                end
            end)
        end
    end
})


-- =================================================================
-- // PURCHASE TAB ELEMENTS
-- =================================================================
PurchaseTab:CreateSection("Gear Auto-Buy")

PurchaseTab:CreateToggle({
    Name = "Buy BoostGear",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local remote = ReplicatedStorage:FindFirstChild("BuyGearEvent")
            if remote then
                remote:FireServer("BoostGear")
            end
        end
    end
})

PurchaseTab:CreateToggle({
    Name = "Buy PowerGear",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local remote = ReplicatedStorage:FindFirstChild("BuyGearEvent")
            if remote then
                remote:FireServer("PowerGear")
            end
        end
    end
})

PurchaseTab:CreateToggle({
    Name = "Buy SpeedGear",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local remote = ReplicatedStorage:FindFirstChild("BuyGearEvent")
            if remote then
                remote:FireServer("SpeedGear")
            end
        end
    end
})

PurchaseTab:CreateSection("Disaster Purchases")

PurchaseTab:CreateSlider({
    Name = "Extra Disaster Amount",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Disasters",
    CurrentValue = 1,
    Flag = "DisasterAmountSlider",
    Callback = function(Value)
        disasterAmount = Value
    end,
})

PurchaseTab:CreateButton({
    Name = "Buy Extra Disasters",
    Callback = function()
        task.spawn(function()
            local remote = ReplicatedStorage:FindFirstChild("BuyExtraDisaster")
            if remote then
                for i = 1, disasterAmount do
                    remote:FireServer()
                    task.wait(0.1)
                end
            end
        end)
    end,
})

-- =================================================================
-- // TROLLING TAB ELEMENTS
-- =================================================================
TrollingTab:CreateSection("External Scripts")

TrollingTab:CreateButton({
    Name = "Super Ring Parts",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Natural-Disaster-Survival-super-ring-parts-open-source-NO-TEXT-CHAT-MESSAGE-212258"))()
    end,
})

-- =================================================================
-- // MAIN FEATURES TAB ELEMENTS
-- =================================================================
Tab:CreateSection("Session Stats")

local VoltsLabel = Tab:CreateLabel("Volts Earned: 0")
local XPLabel = Tab:CreateLabel("XP Earned: 0")
local RemsTouchedLabel = Tab:CreateLabel("Remnants Touched: 0")
local DamageLabel = Tab:CreateLabel("Damage Taken: 0")
local HealthRegainedLabel = Tab:CreateLabel("Health Regained: 0")
local DeathsLabel = Tab:CreateLabel("Deaths: 0")

Tab:CreateButton({
    Name = "Reset Session Stats",
    Callback = function()
        totalEarnedVolts = 0
        totalEarnedXP = 0
        totalDamageTaken = 0
        totalDeaths = 0
        totalHealthRegained = 0
        totalRemsTouched = 0
        
        lastVolts = GetVoltsValue()
        lastXP = GetXPValue()
        
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            lastHealth = player.Character.Humanoid.Health
        end

        VoltsLabel:Set("Volts Earned: 0")
        XPLabel:Set("XP Earned: 0")
        RemsTouchedLabel:Set("Remnants Touched: 0")
        DamageLabel:Set("Damage Taken: 0")
        HealthRegainedLabel:Set("Health Regained: 0")
        DeathsLabel:Set("Deaths: 0")
    end,
})

Tab:CreateSection("Farming")

-- // Stat Tracker Setup for Health & Deaths
local function SetupCharacterStatListeners(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    lastHealth = humanoid.Health

    humanoid.HealthChanged:Connect(function(newHealth)
        if lastHealth then
            if newHealth < lastHealth then
                local damage = lastHealth - newHealth
                totalDamageTaken = totalDamageTaken + damage
                DamageLabel:Set("Damage Taken: " .. formatNumber(totalDamageTaken))
            elseif newHealth > lastHealth then
                local healed = newHealth - lastHealth
                totalHealthRegained = totalHealthRegained + healed
                HealthRegainedLabel:Set("Health Regained: " .. formatNumber(totalHealthRegained))
            end
        end
        lastHealth = newHealth
    end)

    humanoid.Died:Connect(function()
        totalDeaths = totalDeaths + 1
        DeathsLabel:Set("Deaths: " .. formatNumber(totalDeaths))
    end)
end

if player.Character then
    SetupCharacterStatListeners(player.Character)
end
player.CharacterAdded:Connect(SetupCharacterStatListeners)

-- // Stat Tracker Loop for Volts & XP
task.spawn(function()
    while true do
        pcall(function()
            local currentVolts = GetVoltsValue()
            if currentVolts then
                if lastVolts == nil then
                    lastVolts = currentVolts
                else
                    local deltaVolts = currentVolts - lastVolts
                    if deltaVolts > 0 then
                        totalEarnedVolts = totalEarnedVolts + deltaVolts
                        VoltsLabel:Set("Volts Earned: " .. formatNumber(totalEarnedVolts))
                    end
                    lastVolts = currentVolts
                end
            end

            local currentXP = GetXPValue()
            if currentXP then
                if lastXP == nil then
                    lastXP = currentXP
                else
                    local deltaXP = currentXP - lastXP
                    if deltaXP > 0 then
                        totalEarnedXP = totalEarnedXP + deltaXP
                        XPLabel:Set("XP Earned: " .. formatNumber(totalEarnedXP))
                    end
                    lastXP = currentXP
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- // Helper: Check if a remnant is directly parented under a hazard
local function IsDangerous(instance)
    local current = instance
    while current and current ~= game do
        local name = current.Name:lower()
        for _, keyword in pairs(BANNED_KEYWORDS) do
            if name:find(keyword) then return true end
        end
        current = current.Parent
    end
    return false
end

-- // Helper: Check if target position is near dynamic hazards or active warnings
local function IsPosNearHazard(pos)
    if not pos then return false end
    local isUnsafe = false
    
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Model") then
                local name = v.Name:lower()
                for _, keyword in pairs(BANNED_KEYWORDS) do
                    if name:find(keyword) then
                        local hPos = (v:IsA("Model") and v:GetPivot().Position) or v.Position
                        if hPos and (pos - hPos).Magnitude < HAZARD_SAFE_RADIUS then
                            isUnsafe = true
                            break
                        end
                    end
                end
            end
            if isUnsafe then break end
        end
    end)
    
    return isUnsafe
end

-- // Helper: Calculate the highest point of an object
local function GetHighestPointCFrame(target)
    local cframe, size
    
    if target:IsA("Model") then
        cframe, size = target:GetBoundingBox()
    elseif target:IsA("BasePart") then
        cframe = target.CFrame
        size = target.Size
    else
        return nil
    end
    
    if cframe and size then
        local topPosition = cframe.Position + Vector3.new(0, (size.Y / 2) + 1, 0)
        return CFrame.new(topPosition) * cframe.Rotation
    end
    
    return nil
end

-- // Helper: Get Stud Border center position directly
local function GetOrbitCenterPoint()
    local centerPos = nil
    pcall(function()
        local target = workspace.wall["wall mod"]:GetChildren()[24]["Stud Border"]
        if target then
            if target:IsA("Model") then
                centerPos = target:GetPivot().Position
            elseif target:IsA("BasePart") then
                centerPos = target.Position
            end
        end
    end)
    
    if not centerPos then
        local map = workspace:FindFirstChild("ActiveMap")
        centerPos = (map and map:GetPivot().Position) or Vector3.new(0, 0, 0)
    end
    
    return centerPos
end

-- // Global Background Loop: Smart Auto-Heal & Standard Auto-Reward
task.spawn(function()
    local lastRewardTime = 0
    while true do
        if loopActive or skyFarmActive or orbitOnlyActive then
            pcall(function()
                local char = player.Character
                
                if char then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health < HEAL_THRESHOLD then
                        local HealRemote = ReplicatedStorage:FindFirstChild("VitalityHealEvent")
                        if HealRemote then HealRemote:FireServer() end
                    end
                end
                
                if tick() - lastRewardTime >= 10 then
                    lastRewardTime = tick()
                    local ClaimRemote = ReplicatedStorage:FindFirstChild("ClaimReward")
                    if ClaimRemote then ClaimRemote:FireServer() end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- // Global Background Loop: Auto Claim Daily Rewards
task.spawn(function()
    while true do
        if autoClaimDailyActive then
            pcall(function()
                local dailyRemote = ReplicatedStorage:WaitForChild("ClaimDailyReward", 5)
                if dailyRemote then
                    for day = 1, 7 do
                        dailyRemote:FireServer(day)
                        task.wait(0.1)
                    end
                end
            end)
            task.wait(60)
        else
            task.wait(1)
        end
    end
end)


-- // TOGGLE 1: Full Farming Loop (Dynamic Hazard & Warning Evasion)
Tab:CreateToggle({
    Name = "AutoFarm (Normal)",
    CurrentValue = false,
    Callback = function(Value)
        loopActive = Value

        task.spawn(function()
            local angle = 0

            while loopActive do
                local char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    task.wait(1)
                    continue
                end
                
                local hrp = char.HumanoidRootPart
                local tempTargets = {}
                
                pcall(function()
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name:find("Remanat") and not IsDangerous(v) then
                            table.insert(tempTargets, v)
                        end
                    end
                end)
                
                if #tempTargets > 0 then
                    for _, target in ipairs(tempTargets) do
                        if not loopActive then break end
                        
                        if target and target.Parent then
                            local targetPos = (target:IsA("Model") and target:GetPivot().Position) or (target:IsA("BasePart") and target.Position)
                            
                            if targetPos then
                                if IsPosNearHazard(targetPos) then
                                    local waitStart = tick()
                                    
                                    while loopActive and target and target.Parent and (tick() - waitStart < 8) do
                                        local currentPos = (target:IsA("Model") and target:GetPivot().Position) or (target:IsA("BasePart") and target.Position)
                                        
                                        if not currentPos or not IsPosNearHazard(currentPos) then
                                            break
                                        end
                                        
                                        pcall(function()
                                            hrp.Anchored = true
                                            local centerPos = GetOrbitCenterPoint()
                                            angle = angle + CIRCLE_SPEED
                                            hrp.CFrame = CFrame.new(
                                                centerPos.X + (math.cos(angle) * CIRCLE_RADIUS), 
                                                centerPos.Y, 
                                                centerPos.Z + (math.sin(angle) * CIRCLE_RADIUS)
                                            )
                                        end)
                                        RunService.Heartbeat:Wait()
                                    end
                                end
                                
                                local finalPosCheck = (target:IsA("Model") and target:GetPivot().Position) or (target:IsA("BasePart") and target.Position)
                                
                                if loopActive and target and target.Parent and finalPosCheck and not IsPosNearHazard(finalPosCheck) then
                                    pcall(function()
                                        hrp.Anchored = false
                                        local targetCFrame = GetHighestPointCFrame(target)
                                        if targetCFrame then
                                            hrp.CFrame = targetCFrame
                                            totalRemsTouched = totalRemsTouched + 1
                                            RemsTouchedLabel:Set("Remnants Touched: " .. formatNumber(totalRemsTouched))
                                            task.wait(0.25)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                else
                    pcall(function()
                        hrp.Anchored = true
                        local centerPos = GetOrbitCenterPoint()
                        angle = angle + CIRCLE_SPEED
                        hrp.CFrame = CFrame.new(
                            centerPos.X + (math.cos(angle) * CIRCLE_RADIUS), 
                            centerPos.Y, 
                            centerPos.Z + (math.sin(angle) * CIRCLE_RADIUS)
                        )
                    end)
                    RunService.Heartbeat:Wait()
                end
            end
            
            pcall(function()
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.Anchored = false
                    local map = workspace:FindFirstChild("ActiveMap")
                    local groundPos = (map and map:GetPivot().Position) or Vector3.new(0, 10, 0)
                    char.HumanoidRootPart.CFrame = CFrame.new(groundPos + Vector3.new(0, 5, 0))
                end
            end)
        end)
    end
})

-- // TOGGLE 2: Sky AutoFarm (High Altitude Evasion)
Tab:CreateToggle({
    Name = "Sky AutoFarm",
    CurrentValue = false,
    Callback = function(Value)
        skyFarmActive = Value

        task.spawn(function()
            local angle = 0

            while skyFarmActive do
                local char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    task.wait(1)
                    continue
                end
                
                local hrp = char.HumanoidRootPart
                local tempTargets = {}
                
                pcall(function()
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name:find("Remanat") and not IsDangerous(v) then
                            table.insert(tempTargets, v)
                        end
                    end
                end)
                
                if #tempTargets > 0 then
                    for _, target in ipairs(tempTargets) do
                        if not skyFarmActive then break end
                        
                        if target and target.Parent then
                            local targetPos = (target:IsA("Model") and target:GetPivot().Position) or (target:IsA("BasePart") and target.Position)
                            
                            if targetPos then
                                if IsPosNearHazard(targetPos) then
                                    local waitStart = tick()
                                    
                                    while skyFarmActive and target and target.Parent and (tick() - waitStart < 8) do
                                        local currentPos = (target:IsA("Model") and target:GetPivot().Position) or (target:IsA("BasePart") and target.Position)
                                        
                                        if not currentPos or not IsPosNearHazard(currentPos) then
                                            break
                                        end
                                        
                                        pcall(function()
                                            hrp.Anchored = true
                                            local centerPos = GetOrbitCenterPoint()
                                            angle = angle + CIRCLE_SPEED
                                            hrp.CFrame = CFrame.new(
                                                centerPos.X + (math.cos(angle) * CIRCLE_RADIUS), 
                                                2000, -- Rests and evades highly up in the sky
                                                centerPos.Z + (math.sin(angle) * CIRCLE_RADIUS)
                                            )
                                        end)
                                        RunService.Heartbeat:Wait()
                                    end
                                end
                                
                                local finalPosCheck = (target:IsA("Model") and target:GetPivot().Position) or (target:IsA("BasePart") and target.Position)
                                
                                if skyFarmActive and target and target.Parent and finalPosCheck and not IsPosNearHazard(finalPosCheck) then
                                    pcall(function()
                                        hrp.Anchored = false
                                        local targetCFrame = GetHighestPointCFrame(target)
                                        if targetCFrame then
                                            hrp.CFrame = targetCFrame
                                            totalRemsTouched = totalRemsTouched + 1
                                            RemsTouchedLabel:Set("Remnants Touched: " .. formatNumber(totalRemsTouched))
                                            task.wait(0.25)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                else
                    pcall(function()
                        hrp.Anchored = true
                        local centerPos = GetOrbitCenterPoint()
                        angle = angle + CIRCLE_SPEED
                        hrp.CFrame = CFrame.new(
                            centerPos.X + (math.cos(angle) * CIRCLE_RADIUS), 
                            2000, -- Idles safely in the sky if no remnants found
                            centerPos.Z + (math.sin(angle) * CIRCLE_RADIUS)
                        )
                    end)
                    RunService.Heartbeat:Wait()
                end
            end
            
            pcall(function()
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.Anchored = false
                    local map = workspace:FindFirstChild("ActiveMap")
                    local groundPos = (map and map:GetPivot().Position) or Vector3.new(0, 10, 0)
                    char.HumanoidRootPart.CFrame = CFrame.new(groundPos + Vector3.new(0, 5, 0))
                end
            end)
        end)
    end
})

-- // TOGGLE 3: Direct Orbit around Stud Border
Tab:CreateToggle({
    Name = "Safe Orbit (no beacons/use if you wanna grind wins/get untouchable)",
    CurrentValue = false,
    Callback = function(Value)
        orbitOnlyActive = Value

        task.spawn(function()
            local angle = 0
            while orbitOnlyActive do
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    
                    pcall(function()
                        hrp.Anchored = true
                        local centerPos = GetOrbitCenterPoint()
                        
                        angle = angle + CIRCLE_SPEED
                        hrp.CFrame = CFrame.new(
                            centerPos.X + (math.cos(angle) * CIRCLE_RADIUS), 
                            centerPos.Y, 
                            centerPos.Z + (math.sin(angle) * CIRCLE_RADIUS)
                        )
                    end)
                end
                RunService.Heartbeat:Wait()
            end

            pcall(function()
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.Anchored = false
                    local map = workspace:FindFirstChild("ActiveMap")
                    local groundPos = (map and map:GetPivot().Position) or Vector3.new(0, 10, 0)
                    char.HumanoidRootPart.CFrame = CFrame.new(groundPos + Vector3.new(0, 5, 0))
                end
            end)
        end)
    end
})

-- // TOGGLE 4: Auto Claim Daily Rewards
Tab:CreateToggle({
    Name = "Auto Claim Daily Rewards",
    CurrentValue = false,
    Callback = function(Value)
        autoClaimDailyActive = Value
    end
})

Tab:CreateSection("Teleports")

-- // BUTTON: Teleport to Stud Border
Tab:CreateButton({
    Name = "Tp to a safe place(be active during tornado or bh if u want no hit)",
    Callback = function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local target = workspace.wall["wall mod"]:GetChildren()[24]["Stud Border"]
                
                if target then
                    local targetCFrame
                    if target:IsA("Model") then
                        targetCFrame = target:GetBoundingBox()
                    elseif target:IsA("BasePart") then
                        targetCFrame = target.CFrame
                    end
                    
                    if targetCFrame then
                        char.HumanoidRootPart.Anchored = false
                        char.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 5, 0)
                    end
                end
            end)
        end
    end,
})

-- // BUTTON: Teleport to TitleTemplate(Tester)
Tab:CreateButton({
    Name = "Tp to another safe place (Better imo)",
    Callback = function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local target = workspace:FindFirstChild("TitleTemplate(Tester)")
                
                if target then
                    local targetCFrame
                    if target:IsA("Model") then
                        targetCFrame = target:GetBoundingBox()
                    elseif target:IsA("BasePart") then
                        targetCFrame = target.CFrame
                    end
                    
                    if targetCFrame then
                        char.HumanoidRootPart.Anchored = false
                        char.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 5, 0)
                    end
                end
            end)
        end
    end,
})
