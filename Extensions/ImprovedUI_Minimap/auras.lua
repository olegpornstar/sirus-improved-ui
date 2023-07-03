local addon = select(2,...);
if addon["ImprovedUI_Minimap"] == nil then addon["ImprovedUI_Minimap"] = {} end; addon = addon["ImprovedUI_Minimap"];
local config = addon.config;
local atlas = addon.SetAtlas;
local shown = addon.SetShown;
local mixin = addon.Mixin;
local select = select;
local pairs = pairs;
local ceil = math.ceil;
local _G = _G;

local Minimap = Minimap;
local TempEnchant1 = TempEnchant1;
local TempEnchant2 = TempEnchant2;
local ConsolidatedBuffs = ConsolidatedBuffs;
local ConsolidatedBuffsContainer = ConsolidatedBuffsContainer;
local UnitHasVehicleUI = UnitHasVehicleUI;
local hooksecurefunc = hooksecurefunc;

local AuraFrameMixin = {};

function AuraFrameMixin:UpdateCollapseAndExpandButtonAnchor()
	local arrow = CreateFrame('Button', 'CollapseAndExpandButton', _G.MinimapCluster)
	arrow:SetSize(13, 26)

	arrow:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -35, 24)
	arrow:SetNormalTexture''
	arrow:SetPushedTexture''
	arrow:SetHighlightTexture''
	arrow:RegisterForClicks('LeftButtonUp')

	local normal = arrow:GetNormalTexture()
	atlas(normal, 'ui-hud-aura-arrow-invert')

	local pushed = arrow:GetPushedTexture()
	atlas(pushed, 'ui-hud-aura-arrow-invert')

	local highlight = arrow:GetHighlightTexture()
	atlas(highlight, 'ui-hud-aura-arrow-invert')
	highlight:SetAlpha(.2)
	highlight:SetBlendMode('ADD')
	
	arrow.collapse = false
	arrow:SetScript('OnClick',function(self)
		self.collapse = not self.collapse
		if self.collapse then
			atlas(normal, 'ui-hud-aura-arrow')
			atlas(pushed, 'ui-hud-aura-arrow')
			atlas(highlight, 'ui-hud-aura-arrow')
			BuffFrame:Hide()
			TemporaryEnchantFrame:Hide()
			ConsolidatedBuffs:Hide()
		else
			atlas(normal, 'ui-hud-aura-arrow-invert')
			atlas(pushed, 'ui-hud-aura-arrow-invert')
			atlas(highlight, 'ui-hud-aura-arrow-invert')
			BuffFrame:Show()
			TemporaryEnchantFrame:Show()
			if GetCVar("consolidateBuffs") == "1" then
				ConsolidatedBuffs:Show()
			end
		end
	end)
	self.arrow = arrow
end

AuraFrameMixin:UpdateCollapseAndExpandButtonAnchor();

local firstButton = nil

function AuraFrameMixin:UpdateFirstButton(button)
	if button and button:IsShown() then
		button:ClearAllPoints()
		button:SetPoint('TOPRIGHT', CollapseAndExpandButton, 'TOPLEFT', -5, 0)
		firstButton = button
	end
end

local function IsBuffConsolidated(buff)
	return buff:GetParent() == ConsolidatedBuffsContainer
end

local buffCount = 0

function AuraFrameMixin:UpdateBuffsAnchor()
	local previousBuff, aboveBuff
	local numBuffs = 0
	local numEnchants = BuffFrame.numEnchants
	local numTotal = numEnchants
	for index = -2, BUFF_ACTUAL_DISPLAY, 1 do
		local buff
		if index == -2 then
			buff = ConsolidatedBuffs
		elseif index == -1 and numEnchants >= 1 then
			buff = TempEnchant1
		elseif index == 0 and numEnchants >= 2 then
			buff = TempEnchant2
		else
			buff = _G['BuffButton'..index]
		end
		if buff ~= nil then
			if buff:IsShown() and not IsBuffConsolidated(buff) then
			
				numBuffs = numBuffs + 1
				numTotal = numTotal + 1
		        
				buff:ClearAllPoints()
				if numBuffs == 1 then
					AuraFrameMixin:UpdateFirstButton(buff)
				elseif numBuffs > 1 and mod(numTotal, BUFFS_PER_ROW) == 1 then
					if numTotal == BUFFS_PER_ROW + 1 then
						buff:SetPoint('TOP', firstButton, 'BOTTOM', 0, -BUFF_ROW_SPACING)
					else
						buff:SetPoint('TOP', aboveBuff, 'BOTTOM', 0, -BUFF_ROW_SPACING)
					end
					aboveBuff = buff
				else
					local xOffset = 0
					if previousBuff == ConsolidatedBuffs or (previousBuff == aboveBuff and firstButton == ConsolidatedBuffs) then
						xOffset = -2
					end
					buff:SetPoint('TOPRIGHT', previousBuff, 'TOPLEFT', -5 + xOffset, 0)
				end
				previousBuff = buff
			end
		elseif index > 0 then
			return
		end
	end
	buffCount = numTotal
end

function AuraFrameMixin:UpdateDeBuffsAnchor(index)
	local numBuffs = buffCount
	local numRows = ceil(numBuffs/BUFFS_PER_ROW)
	local buffHeight = TempEnchant1:GetHeight();

	local buff = _G[self..index]
	if not buff then return end
	buff:ClearAllPoints()
	if index > 1 and mod(index, BUFFS_PER_ROW) == 1 then
		buff:SetPoint('TOP', _G[self..(index-BUFFS_PER_ROW)], 'BOTTOM', 0, -BUFF_ROW_SPACING);
	elseif index == 1 then
		if numRows < 2 then
			buff:SetPoint('TOPRIGHT', firstButton, 'BOTTOMRIGHT', 0, -1*((2*BUFF_ROW_SPACING)+buffHeight));
		else
			buff:SetPoint('TOPRIGHT', firstButton, 'BOTTOMRIGHT', 0, -numRows*(BUFF_ROW_SPACING+buffHeight));
		end
	else
		buff:SetPoint('RIGHT', _G[self..(index-1)], 'LEFT', -5, 0);
	end
end

function AuraFrameMixin:RefreshCollapseExpandButtonState(numBuffs)
	shown(self.arrow, numBuffs > 0);
end

hooksecurefunc('BuffFrame_UpdateAllBuffAnchors', AuraFrameMixin.UpdateBuffsAnchor)
hooksecurefunc('DebuffButton_UpdateAnchors', AuraFrameMixin.UpdateDeBuffsAnchor)

mixin(addon._map, AuraFrameMixin);