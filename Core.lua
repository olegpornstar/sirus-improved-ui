local DF = LibStub('AceAddon-3.0'):NewAddon('Sirus_ImprovedUI', 'AceConsole-3.0')
local db

local defaults = {
    profile = {
        modules = {['Actionbar'] = true, ['Castbar'] = true, ['Chat'] = true, ['Minimap'] = true, ['Unitframe'] = true},
        bestnumber = 42
    }
}

function DF:OnInitialize()
    -- Called when the addon is loaded
    self.db = LibStub('AceDB-3.0'):New('Sirus_ImprovedUI_DB', defaults, true)
    db = self.db.profile
    self:SetupOptions()
    self:RegisterSlashCommands()
end

function DF:OnEnable()
    -- Called when the addon is enabled
end

function DF:OnDisable()
    -- Called when the addon is disabled
end

function DF:GetModuleEnabled(module)
    return db.modules[module]
end

function DF:SetModuleEnabled(module, value)
    local old = db.modules[module]
    db.modules[module] = value
    if old ~= value then
        if value then
            self:EnableModule(module)
        else
            self:DisableModule(module)
        end
    end
end

local name, realm = UnitName('player')
function DF:Debug(m, value)
end

function DF:GetClassColor(class, alpha)
    local r, g, b, hex = GetClassColor(class)
    if alpha then
        return r, g, b, alpha
    else
        return r, g, b, 1
    end
end
