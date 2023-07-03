local DF = LibStub('AceAddon-3.0'):GetAddon('Sirus_ImprovedUI')

local moduleOptions = {}
local options = {
    type = 'group',
    args = {
    }
}

function DF:SetupOptions()
    self.optFrames = {}
    LibStub('AceConfigRegistry-3.0'):RegisterOptionsTable('Sirus_ImprovedUI', options)
    self.optFrames['Sirus_ImprovedUI'] =
        LibStub('AceConfigDialog-3.0'):AddToBlizOptions('Sirus_ImprovedUI', 'Sirus: Improved UI')

    local profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(self.db)
    profiles.order = 999
    LibStub('AceConfig-3.0'):RegisterOptionsTable('Sirus_ImprovedUI_Profiles', profiles)
    LibStub('AceConfigDialog-3.0'):AddToBlizOptions('Sirus_ImprovedUI_Profiles', 'Profiles', 'Sirus: Improved UI')
end

function DF:RegisterModuleOptions(name, options)
    --self:Print('RegisterModuleOptions()', name, options)
    moduleOptions[name] = options
    -- function AceConfigDialog:AddToBlizOptions(appName, name, parent, ...)
    LibStub('AceConfigRegistry-3.0'):RegisterOptionsTable('Sirus_ImprovedUI_' .. name, options)

    self.optFrames[name] =
        LibStub('AceConfigDialog-3.0'):AddToBlizOptions('Sirus_ImprovedUI_' .. name, name, 'Sirus: Improved UI')
end

function DF:RegisterSlashCommands()
    self:RegisterChatCommand('iu', 'SlashCommand')
    self:RegisterChatCommand('improvedui', 'SlashCommand')
end

function DF:SlashCommand(msg)
    --self:Print('Slash: ' .. msg)
    InterfaceOptionsFrame_OpenToCategory('Sirus_ImprovedUI')
    InterfaceOptionsFrame_OpenToCategory('Sirus_ImprovedUI')
end
