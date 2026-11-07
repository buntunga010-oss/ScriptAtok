-- ==========================================
-- MALAM BERSAMA ATOK - ULTIMATE UPDATE
-- Fitur: Jarak Visual Holo, Simpan 2 Tempat, 
--        Menu Deteksi Item + TP, Speed, Noclip
-- ==========================================

-- ===== 1. ANTI KICK =====
local p = game:GetService("Players").LocalPlayer
local o = getrawmetatable(game)
local s = o.__namecall
local w = newcclosure(function(self, ...)
    local m = getnamecallmethod()
    if m == "Kick" and self == p then return end
    return s(self, ...)
end)
setreadonly(o, false)
o.__namecall = w
setreadonly(o, true)

-- ===== 2. VARIABLE =====
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local espAtokEnabled = true
local espKeyEnabled = true
local speedEnabled = true
local noclipEnabled = true
local currentSpeed = 30
local espObjects = {}

local savedPos1 = nil
local savedPos2 = nil

-- ===== 3. FUNGSI HIGHLIGHT =====
local function createHighlight(obj, color)
    if not obj or not obj.Parent then return end
    local target = obj:IsA("Model") and obj or obj.Parent
    if target:FindFirstChild("HoloGlow") then return end
    
    local h = Instance.new("Highlight")
    h.Name = "HoloGlow"
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.5
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = target
    h.Parent = target
end

local function clearESP()
    for _, data in pairs(espObjects) do
        if data then data:Destroy() end
    end
    espObjects = {}
end

local function updateESP()
    clearESP()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myPos = char.HumanoidRootPart.Position

    -- HOLOGRAM ATOK (Scan Visual: Apapun yang deket lu selain player)
    if espAtokEnabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= char and not Players:GetPlayerFromCharacter(obj) then
                local humanoid = obj:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local dist = (obj:GetPivot().Position - myPos).Magnitude
                    if dist <= 25 then -- Jarak 25 studs (biar gak salah scan jauh)
                        createHighlight(obj, Color3.new(1,0,0)) -- Merah
                        table.insert(espObjects, obj:FindFirstChild("HoloGlow"))
                    end
                end
            end
        end
    end

    -- HOLOGRAM KEY (Pake ProximityPrompt)
    if espKeyEnabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local prompt = obj:FindFirstChild("ProximityPrompt") or (obj.Parent and obj.Parent:FindFirstChild("ProximityPrompt"))
                if prompt then
                    local dist = (obj.Position - myPos).Magnitude
                    if dist <= 100 then
                        local target = obj:IsA("Model") and obj or obj.Parent
                        createHighlight(target, Color3.new(1,1,0)) -- Kuning
                        table.insert(espObjects, target:FindFirstChild("HoloGlow"))
                    end
                end
            end
        end
    end
end

-- ===== 4. SIMPAN TEMPAT =====
local function saveLocation(slot)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if slot == 1 then
            savedPos1 = char.HumanoidRootPart.CFrame
            print("✅ Tempat 1 disimpan!")
        else
            savedPos2 = char.HumanoidRootPart.CFrame
            print("✅ Tempat 2 disimpan!")
        end
    end
end

local function teleportToSaved(slot)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = (slot == 1) and savedPos1 or savedPos2
        if pos then
            char.HumanoidRootPart.CFrame = pos + Vector3.new(0, 3, 0)
            print("✅ Teleport ke Tempat " .. slot)
        else
            print("❌ Tempat " .. slot .. " belum disimpan!")
        end
    end
end

-- ===== 5. MENU DETEKSI ITEM =====
local function openItemMenu()
    local itemGui = Instance.new("ScreenGui", PlayerGui)
    itemGui.Name = "ItemMenu"
    
    local bg = Instance.new("Frame", itemGui)
    bg.Size = UDim2.new(0, 200, 0, 250)
    bg.Position = UDim2.new(0.5, -100, 0.5, -125)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    bg.BorderColor3 = Color3.fromRGB(0, 255, 0)
    bg.BorderSizePixel = 2
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel", bg)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "📦 DETEKSI ITEM"
    title.TextColor3 = Color3.fromRGB(0, 255, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    
    local scroll = Instance.new("ScrollingFrame", bg)
    scroll.Size = UDim2.new(0.9, 0, 0.8, -40)
    scroll.Position = UDim2.new(0.05, 0, 0, 35)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 4
    
    local closeBtn = Instance.new("TextButton", bg)
    closeBtn.Size = UDim2.new(0.9, 0, 0, 25)
    closeBtn.Position = UDim2.new(0.05, 0, 0.9, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    closeBtn.Text = "TUTUP"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function() itemGui:Destroy() end)

    local yPos = 0
    local foundItems = false

    -- Scan semua part/model yg ada ProximityPrompt
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local prompt = obj:FindFirstChild("ProximityPrompt") or (obj.Parent and obj.Parent:FindFirstChild("ProximityPrompt"))
            if prompt then
                foundItems = true
                local itemBtn = Instance.new("TextButton", scroll)
                itemBtn.Size = UDim2.new(1, 0, 0, 30)
                itemBtn.Position = UDim2.new(0, 0, 0, yPos)
                itemBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                itemBtn.Text = "📍 " .. obj.Name
                itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                itemBtn.Font = Enum.Font.Gotham
                itemBtn.TextScaled = true
                Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 4)
                
                itemBtn.MouseButton1Click:Connect(function()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                        itemGui:Destroy() -- Tutup menu setelah TP
                    end
                end)
                yPos = yPos + 35
            end
        end
    end
    
    if not foundItems then
        local noItem = Instance.new("TextLabel", scroll)
        noItem.Size = UDim2.new(1, 0, 0, 30)
        noItem.BackgroundTransparency = 1
        noItem.Text = "Gak ada item..."
        noItem.TextColor3 = Color3.fromRGB(150, 150, 150)
        noItem.TextScaled = true
    end
    
    scroll.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- ===== 6. SPEED & NOCLIP =====
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = speedEnabled and currentSpeed or 16
        if noclipEnabled then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

-- ===== 7. UI UTAMA =====
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name = "AtokUltimateUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 160, 0, 420) -- UI ditinggiin
frame.Position = UDim2.new(0.02, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderColor3 = Color3.fromRGB(255, 50, 50)
frame.BorderSizePixel = 2
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "ATOK ULTIMATE"
title.TextColor3 = Color3.fromRGB(255, 50, 50)
title.TextScaled = true
title.Font = Enum.Font.GothamBold

local function makeBtn(text, y, callback, bgColor)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.9, 0, 0, 28)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = bgColor or Color3.fromRGB(30, 30, 30)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local state = true
    btn.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        if bgColor then return end -- Kalau tombol aksi, jangan ganti warna
        btn.Text = state and text:gsub("OFF", "ON") or text:gsub("ON", "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(30, 30, 30)
    end)
end

makeBtn("✅ ATOK ON", 30, function(s) espAtokEnabled = s end)
makeBtn("✅ KEY ON", 65, function(s) espKeyEnabled = s end)
makeBtn("✅ SPEED ON", 100, function(s) speedEnabled = s end)
makeBtn("✅ NOCLIP ON", 135, function(s) noclipEnabled = s end)

-- Simpan 1
makeBtn("💾 SIMPAN TEMPAT 1", 175, function() saveLocation(1) end, Color3.fromRGB(200, 150, 0))
makeBtn("🏠 TP TEMPAT 1", 210, function() teleportToSaved(1) end, Color3.fromRGB(0, 150, 0))

-- Simpan 2
makeBtn("💾 SIMPAN TEMPAT 2", 250, function() saveLocation(2) end, Color3.fromRGB(200, 150, 0))
makeBtn("🏠 TP TEMPAT 2", 285, function() teleportToSaved(2) end, Color3.fromRGB(0, 150, 0))

-- Menu Item
makeBtn("📦 DETEKSI ITEM", 325, function() openItemMenu() end, Color3.fromRGB(0, 100, 200))

-- Minimize
local minBtn = Instance.new("TextButton", frame)
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -25, 0, 2)
minBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 10)

local isMin = false
minBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    if isMin then
        for _, v in ipairs(frame:GetChildren()) do
            if v:IsA("TextButton") and v ~= minBtn then v.Visible = false end
            if v:IsA("TextLabel") then v.Visible = false end
        end
        frame.Size = UDim2.new(0, 30, 0, 30)
        frame.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        minBtn.Text = "B"
        minBtn.Size = UDim2.new(1,0,1,0)
        minBtn.Position = UDim2.new(0,0,0,0)
        minBtn.BackgroundTransparency = 1
    else
        for _, v in ipairs(frame:GetChildren()) do
            if v:IsA("TextButton") and v ~= minBtn then v.Visible = true end
            if v:IsA("TextLabel") then v.Visible = true end
        end
        frame.Size = UDim2.new(0, 160, 0, 420)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        minBtn.Text = "-"
        minBtn.Size = UDim2.new(0, 20, 0, 20)
        minBtn.Position = UDim2.new(1, -25, 0, 2)
        minBtn.BackgroundTransparency = 0
    end
end)

-- ===== 8. LOOP =====
task.spawn(function()
    while wait(1) do
        updateESP()
    end
end)

print("🚀 ATOK ULTIMATE AKTIF! (Menu Item, 2 Tempat, Visual Holo)")
