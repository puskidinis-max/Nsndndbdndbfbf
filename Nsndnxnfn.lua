-- =====================================================================================
-- SWILL MOBILE SKELETON ESP & SILENT AIM v5.0 (ULTRA PREMIUM)
-- =====================================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    SilentAimEnabled = true,
    WallCheck = true,
    FOV = 200,
    TeamCheck = false,
    ESPEnabled = true
}

-- Перехват для Silent Aim
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

local function GetSilentTarget()
    local bestTarget = nil
    local shortestDist = Config.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head")
            
            if hum and hum.Health > 0 and head then
                if not Config.TeamCheck or player.Team ~= LocalPlayer.Team then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist <= shortestDist then
                            if not Config.WallCheck then
                                shortestDist = dist
                                bestTarget = head
                            else
                                local rayParams = RaycastParams.new()
                                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                rayParams.FilterDescendantsInstances = {LocalPlayer.Character, char}
                                local result = Workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, rayParams)
                                if not result then
                                    shortestDist = dist
                                    bestTarget = head
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if Config.SilentAimEnabled and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "Raycast") then
        local targetHead = GetSilentTarget()
        if targetHead then
            if method == "Raycast" and #args >= 2 then
                local origin = args[1]
                args[2] = (targetHead.Position - origin).Unit * 1000
                return oldNamecall(self, unpack(args))
            elseif method == "FindPartOnRay" and #args >= 1 then
                local ray = args[1]
                args[1] = Ray.new(ray.Origin, (targetHead.Position - ray.Origin).Unit * 1000)
                return oldNamecall(self, unpack(args))
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

-- Интерфейс и круг FOV
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SwillSkeletonUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local FOVCircle = Instance.new("Frame")
FOVCircle.Parent = ScreenGui
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FOVCircle

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = FOVCircle
UIStroke.Color = Color3.fromRGB(0, 255, 170)
UIStroke.Thickness = 1.5

-- Продвинутый ESP: Скелет, Линии к игрокам (Tracers), Боксы и HP
local ESPCache = {}

local function CreateSkeletonLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(0, 255, 170)
    line.Thickness = 1.5
    return line
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    -- Биллборд для хп, ника и бокса
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SwillESP_Full"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 80, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    
    local box = Instance.new("Frame")
    box.Parent = billboard
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    box.BackgroundTransparency = 0.85
    box.BorderColor3 = Color3.fromRGB(0, 255, 170)
    box.BorderSizePixel = 1
    box.Size = UDim2.new(1, 0, 1, 0)
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = box
    
    local name = Instance.new("TextLabel")
    name.Parent = billboard
    name.BackgroundTransparency = 1
    name.Position = UDim2.new(0, 0, -0.3, 0)
    name.Size = UDim2.new(1, 0, 0.3, 0)
    name.Font = Enum.Font.Code
    name.Text = player.Name
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextSize = 10
    name.TextStrokeTransparency = 0.2

    -- Полоска здоровья (HP Bar)
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Parent = box
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Position = UDim2.new(0, -6, 0, 0)
    hpBarBg.Size = UDim2.new(0, 3, 1, 0)
    
    local hpBarFill = Instance.new("Frame")
    hpBarFill.Parent = hpBarBg
    hpBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hpBarFill.BorderSizePixel = 0
    hpBarFill.Size = UDim2.new(1, 0, 1, 0)

    billboard.Parent = CoreGui

    -- Линии скелета (используем Drawing линии для плавности)
    local skeletonData = {
        HeadToChest = CreateSkeletonLine(),
        ChestToLeftArm = CreateSkeletonLine(),
        ChestToRightArm = CreateSkeletonLine(),
        ChestToLeftLeg = CreateSkeletonLine(),
        ChestToRightLeg = CreateSkeletonLine(),
    }

    -- Линия от низа экрана до игрока (Tracer)
    local tracerLine = Drawing.new("Line")
    tracerLine.Visible = false
    tracerLine.Color = Color3.fromRGB(0, 255, 170)
    tracerLine.Thickness = 1

    ESPCache[player] = {
        Gui = billboard,
        Fill = hpBarFill,
        Skeleton = skeletonData,
        Tracer = tracerLine
    }
end

local function RemoveESP(player)
    if ESPCache[player] then
        ESPCache[player].Gui:Destroy()
        for _, line in pairs(ESPCache[player].Skeleton) do
            line:Remove()
        end
        ESPCache[player].Tracer:Remove()
        ESPCache[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- Отрисовка в реальном времени
RunService.RenderStepped:Connect(function()
    FOVCircle.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)
    FOVCircle.Visible = Config.SilentAimEnabled

    for player, data in pairs(ESPCache) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        local head = char and char:FindFirstChild("Head")
        local upperTorso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
        local leftArm = char and (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"))
        local rightArm = char and (char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"))
        local leftLeg = char and (char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"))
        local rightLeg = char and (char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"))

        if Config.ESPEnabled and char and root and hum and hum.Health > 0 then
            data.Gui.Adornee = root
            data.Gui.Enabled = true
            
            local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            data.Fill.Size = UDim2.new(1, 0, healthPercent, 0)
            data.Fill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)

            -- Рендер линий скелета и трейсеров
            if head and upperTorso then
                local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
                local torsoPos, torsoOn = Camera:WorldToViewportPoint(upperTorso.Position)
                
                if headOn and torsoOn then
                    data.Skeleton.HeadToChest.From = Vector2.new(headPos.X, headPos.Y)
                    data.Skeleton.HeadToChest.To = Vector2.new(torsoPos.X, torsoPos.Y)
                    data.Skeleton.HeadToChest.Visible = true
                else
                    data.Skeleton.HeadToChest.Visible = false
                end
                
                -- Линия снизу экрана (Tracer)
                data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                data.Tracer.To = Vector2.new(torsoPos.X, torsoPos.Y)
                data.Tracer.Visible = true
            else
                for _, line in pairs(data.Skeleton) do line.Visible = false end
                data.Tracer.Visible = false
            end
        else
            data.Gui.Enabled = false
            for _, line in pairs(data.Skeleton) do line.Visible = false end
            data.Tracer.Visible = false
        end
    end
end)

-- Менюшка
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -150)
MainFrame.Size = UDim2.new(0, 320, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
TopBar.Size = UDim2.new(1, 0, 0, 35)

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(0, 220, 1, 0)
Title.Font = Enum.Font.Code
Title.Text = "SWILL SKELETON ESP v5.0"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Position = UDim2.new(1, -30, 0, 7)
CloseBtn.Size = UDim2.new(0, 21, 0, 21)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 11

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

local OpenButton = Instance.new("TextButton")
OpenButton.Parent = ScreenGui
OpenButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
OpenButton.Position = UDim2.new(0, 10, 0.4, 0)
OpenButton.Size = UDim2.new(0, 50, 0, 50)
OpenButton.Font = Enum.Font.SourceSansBold
OpenButton.Text = "OPEN"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextSize = 11
OpenButton.Visible = false

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 25)
OpenCorner.Parent = OpenButton

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)

local function CreateButton(text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    btn.Position = UDim2.new(0, 20, 0, posY)
    btn.Size = UDim2.new(0, 280, 0, 35)
    btn.Font = Enum.Font.Code
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    return btn
end

CreateButton("Silent Aim: ON", 45, function(b)
    Config.SilentAimEnabled = not Config.SilentAimEnabled
    b.Text = "Silent Aim: " .. (Config.SilentAimEnabled and "ON" or "OFF")
end)

CreateButton("WallCheck: ON", 90, function(b)
    Config.WallCheck = not Config.WallCheck
    b.Text = "WallCheck: " .. (Config.WallCheck and "ON" or "OFF")
end)

CreateButton("Skeleton ESP: ON", 135, function(b)
    Config.ESPEnabled = not Config.ESPEnabled
    b.Text = "Skeleton ESP: " .. (Config.ESPEnabled and "ON" or "OFF")
end)

CreateButton("FOV Size: 200", 180, function(b)
    Config.FOV = Config.FOV + 50
    if Config.FOV > 400 then Config.FOV = 100 end
    b.Text = "FOV Size: " .. Config.FOV
end)

print("[SWILL]: Skeleton ESP & Silent v5.0 loaded successfully.")
