-- Этот скрипт нужно залить на GitHub Raw или Pastebin
-- Именно его будет подтягивать загрузчик из autoexecute

repeat task.wait() until game:IsLoaded()

-- Защита от повторного запуска на одном сервере
if _G.QuartzExecuted then return end
_G.QuartzExecuted = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Авто-кликер по кнопкам загрузки (Skip/Play)
local function skipLoading()
    task.spawn(function()
        local skipNames = {"Skip", "Play", "Start", "Proceed"}
        for i = 1, 30 do
            for _, gui in ipairs(PlayerGui:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                    for _, name in ipairs(skipNames) do
                        if gui.Name:lower():find(name:lower()) or (gui:IsA("TextButton") and gui.Text:lower():find(name:lower())) then
                            if gui.Visible and gui.AbsoluteSize.X > 0 then
                                GuiService.SelectedObject = gui
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                task.wait(0.05)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                return
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- Функция смены сервера
local function serverHop()
    -- Снова ставим себя в очередь перед прыжком
    if queue_on_teleport then
        queue_on_teleport('loadstring(game:HttpGet("'.._G.CurrentScriptUrl..'"))()')
    end

    local success, result = pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")).data
        for _, v in ipairs(servers) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                return v.id
            end
        end
    end)
    
    if success and result then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, result)
    else
        TeleportService:Teleport(game.PlaceId)
    end
end

-- Основной цикл фарма
local function startFarming()
    skipLoading()
    
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local RootPart = Character:WaitForChild("HumanoidRootPart")
    local QuartzFolder = workspace:WaitForChild("QuartzCollectibles", 10)
    local CollectRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ScavengerHunt")

    while _G.QuartzExecuted do
        local items = QuartzFolder and QuartzFolder:GetChildren() or {}
        if #items > 0 then
            for _, item in ipairs(items) do
                local target = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                if target then
                    RootPart.CFrame = target.CFrame
                    task.wait(0.3)
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    pcall(function() CollectRemote:FireServer(item) end)
                    task.wait(0.2)
                end
            end
            task.wait(1)
            serverHop()
            break
        else
            task.wait(5)
            serverHop()
            break
        end
    end
end

task.spawn(startFarming)
