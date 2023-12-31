--[[
	Nine-slice utility for creating themed background frames without rewriting a lot of boilerplate code.
	There are some utilities to help with anchoring, and others to create a border and theme it from scratch.
	AnchorUtil.ApplyLayout makes use of a layout table, and is probably what most setups will use.

	What the layout table should look like:
	- A table of tables, where each inner table describes a corner, edge, or center of the nine-slice frame.

	- Inner table keys should exactly match the nine-slice API for setting up the various pieces (TitleCase matters here), and will also be used as the name of the parentKey on the container frame.

	- e.g. Layout = { TopLeftCorner = { ... }, LeftEdge = { ... }, Center = { ... }

	- Global attributes:
		- mirrorLayout: The nine slice atlases only exist for topLeftCorner, topEdge, leftEdge.  Create the rest of the pieces from those assets.

	- Key-values in each inner table:
		- Required:
			atlas: the atlas for this piece
		- Optional:
			- layer: texture draw layer, defaults to "BORDER"
			- subLevel: texture sublevel, defaults to the same default as the CreateTexture API.
			- point: which point on the piece you want to anchor from, defaults to whatever is appropriate for the piece (e.g. TopLeftCorner = TOPLEFT)
			- relativePoint: which point on the container frame you want to anchor to, same default as point.
			- x, y: the offsets for the piece, defaults to SetPoint API default.
			- x1, y1: the second offsets (ONLY for the edge and center pieces), defaults to SetPoint API default.

	- Legacy frames may not be authored such that the pieces of the nine-slice are named TopLeftCorner, BottomEdge, etc...for this reason,
	the container is allowed to provide a lookup override function for those pieces, in case they already existed.
	The API signature is: <container>.GetNineSlicePiece(pieceName).
	It's not required, if it's missing the fallbacks are:
	1. Look up the piece by key using the default piece name (e.g. container.TopLeft)
	2. Create a new texture and add it to the container, accessible by key (e.g. container.TopLeft = container:CreateTexture()).

	- The idea is that borders should be easy to set up, by describing the art theme in data, there should be minimal effort to setup a frame's background.
 	Offsets exist to provide some proper alignment for legacy frames, most new frames shouldn't need custom offsets.
	The NineSlice itself isn't intended to exist beyond frame setup, just release the reference to it after use.
]]
local addon = select(2,...);
if addon["ImprovedUI_ActionBar"] == nil then addon["ImprovedUI_ActionBar"] = {} end; addon = addon["ImprovedUI_ActionBar"];
local C_Texture = addon.c_texture;

local function GetNineSlicePiece(container, pieceName)
	if container.GetNineSlicePiece then
		local piece = container:GetNineSlicePiece(pieceName)
		if piece then
			return piece, true
		end
	end
	
	local piece = container[pieceName];
	if piece then
		return piece, true;
	else
		piece = container:CreateTexture()
		container[pieceName] = piece;
		return piece, false;
	end

	-- return container[pieceName] or container:CreateTexture(), false
end

local function PropagateLayoutSettingsToPieceLayout(userLayout, pieceLayout)
	-- Only apply mirrorLayout if it wasn't explicitly defined
	if pieceLayout.mirrorLayout == nil then
		pieceLayout.mirrorLayout = userLayout.mirrorLayout
	end

	-- ... and other settings that apply to the whole nine-slice
end

local function SetupTextureCoordinates(piece, setupInfo, pieceLayout, userLayout)
	local left, right, top, bottom = 0, 1, 0, 1;

	local pieceMirrored = pieceLayout.mirrorLayout;
	if pieceMirrored == nil then
		pieceMirrored = userLayout and userLayout.mirrorLayout;
	end

	if pieceMirrored then
		if setupInfo.mirrorVertical then
			top, bottom = bottom, top;
		end

		if setupInfo.mirrorHorizontal then
			left, right = right, left;
		end
	end
	-- piece:SetHorizTile(setupInfo.tileHorizontal)
	-- piece:SetVertTile(setupInfo.tileVertical)
	piece:SetSubTexCoord(left, right, top, bottom);
end

local function SetupPieceVisuals(piece, setupInfo, pieceLayout, textureKit)
	-- Change texture coordinates before applying atlas.
	SetupTextureCoordinates(piece, setupInfo, pieceLayout)
	
	-- textureKit is optional, that's fine but if it's nil the caller should ensure that there are no format specifiers in .atlas
	local atlasName = C_Texture.GetFinalNameFromTextureKit(pieceLayout.atlas, textureKit)
	local info = C_Texture.GetAtlasInfo(atlasName)
	piece:SetHorizTile(info and info.tilesHorizontally or false)
	piece:SetVertTile(info and info.tilesVertically or false)
	piece:set_atlas(atlasName, true)
end

local function SetupCorner(container, piece, setupInfo, pieceLayout)
	piece:ClearAllPoints()
	piece:SetPoint(pieceLayout.point or setupInfo.point, container, pieceLayout.relativePoint or setupInfo.point, pieceLayout.x, pieceLayout.y)
end

local function SetupEdge(container, piece, setupInfo, pieceLayout)
	piece:ClearAllPoints();

	local userLayout = NineSliceUtils.GetLayout(container.layoutType);
	if userLayout and (userLayout.threeSliceVertical or userLayout.threeSliceHorizontal) then
		piece:SetPoint(setupInfo.point, container, setupInfo.relativePoint, pieceLayout.x, pieceLayout.y);
		piece:SetPoint(setupInfo.relativePoint, container, setupInfo.point, pieceLayout.x1, pieceLayout.y1);
	else
		piece:SetPoint(setupInfo.point, GetNineSlicePiece(container, setupInfo.relativePieces[1]), setupInfo.relativePoint, pieceLayout.x, pieceLayout.y);
		piece:SetPoint(setupInfo.relativePoint, GetNineSlicePiece(container, setupInfo.relativePieces[2]), setupInfo.point, pieceLayout.x1, pieceLayout.y1);
	end
end

local function SetupCenter(container, piece, setupInfo, pieceLayout)
	piece:ClearAllPoints();

	local userLayout = NineSliceUtils.GetLayout(container.layoutType);
	if userLayout and userLayout.threeSliceVertical then
		piece:SetPoint("TOPLEFT", GetNineSlicePiece(container, "TopEdge"), "BOTTOMLEFT", pieceLayout.x, pieceLayout.y);
		piece:SetPoint("BOTTOMRIGHT", GetNineSlicePiece(container, "BottomEdge"), "TOPRIGHT", pieceLayout.x1, pieceLayout.y1);
	elseif userLayout and userLayout.threeSliceHorizontal then
		piece:SetPoint("TOPLEFT", GetNineSlicePiece(container, "LeftEdge"), "TOPRIGHT", pieceLayout.x, pieceLayout.y);
		piece:SetPoint("BOTTOMRIGHT", GetNineSlicePiece(container, "RightEdge"), "BOTTOMLEFT", pieceLayout.x1, pieceLayout.y1);
	else
		piece:SetPoint("TOPLEFT", GetNineSlicePiece(container, "TopLeftCorner"), "BOTTOMRIGHT", pieceLayout.x, pieceLayout.y);
		piece:SetPoint("BOTTOMRIGHT", GetNineSlicePiece(container, "BottomRightCorner"), "TOPLEFT", pieceLayout.x1, pieceLayout.y1);
	end
end

-- Defines the order in which each piece should be set up, and how to do the setup.
--
-- Mirror types: As a texture memory and effort savings, many borders are assembled from a single topLeft corner, and top/left edges.
-- That's all that's required if everything is symmetrical (left edge is also superfluous, but allows for more detail variation)
-- The mirror flags specify which texture coords to flip relative to the piece that would use default texture coordinates: left = 0, top = 0, right = 1, bottom = 1
local nineSliceSetup =
{
	{ pieceName = "TopLeftCorner", point = "TOPLEFT", fn = SetupCorner, },
	{ pieceName = "TopRightCorner", point = "TOPRIGHT", mirrorHorizontal = true, fn = SetupCorner, },
	{ pieceName = "BottomLeftCorner", point = "BOTTOMLEFT", mirrorVertical = true, fn = SetupCorner, },
	{ pieceName = "BottomRightCorner", point = "BOTTOMRIGHT", mirrorHorizontal = true, mirrorVertical = true, fn = SetupCorner, },
	{ pieceName = "TopEdge", point = "TOPLEFT", relativePoint = "TOPRIGHT", relativePieces = { "TopLeftCorner", "TopRightCorner" }, fn = SetupEdge, tileHorizontal = true },
	{ pieceName = "BottomEdge", point = "BOTTOMLEFT", relativePoint = "BOTTOMRIGHT", relativePieces = { "BottomLeftCorner", "BottomRightCorner" }, mirrorVertical = true, tileHorizontal = true, fn = SetupEdge, },
	{ pieceName = "LeftEdge", point = "TOPLEFT", relativePoint = "BOTTOMLEFT", relativePieces = { "TopLeftCorner", "BottomLeftCorner" }, tileVertical = true, fn = SetupEdge, },
	{ pieceName = "RightEdge", point = "TOPRIGHT", relativePoint = "BOTTOMRIGHT", relativePieces = { "TopRightCorner", "BottomRightCorner" }, mirrorHorizontal = true, tileVertical = true, fn = SetupEdge, },
	{ pieceName = "Center", fn = SetupCenter, },
};

local layouts =
{
	UniqueCornersLayout = {
		TopRightCorner = {atlas = "%s-nineslice-cornertopright"},
		TopLeftCorner = {atlas = "%s-nineslice-cornertopleft"},
		BottomLeftCorner = {atlas = "%s-nineslice-cornerbottomleft"},
		BottomRightCorner = {atlas = "%s-nineslice-cornerbottomright"},
		TopEdge = {atlas = "_%s-nineslice-edgetop"},
		BottomEdge = {atlas = "_%s-nineslice-edgebottom"},
		LeftEdge = {atlas = "!%s-nineslice-edgeleft"},
		RightEdge = {atlas = "!%s-nineslice-edgeright"},
		Center = {atlas = "%s-nineslice-center"}
	},
	
	-- ThreeSliceVerticalLayout = {
		-- threeSliceVertical = true,
		-- TopEdge = {atlas = "%s-threeslice-edgetop"},
		-- BottomEdge = {atlas = "%s-threeslice-edgebottom"},
		-- Center = {atlas = "!%s-threeslice-center"},
	-- },

	-- ThreeSliceHorizontalLayout = {
		-- threeSliceHorizontal = true,
		-- LeftEdge = {atlas = "%s-threeslice-edgeleft"},
		-- RightEdge = {atlas = "%s-threeslice-edgeright"},
		-- Center = {atlas = "_%s-threeslice-center"},
	-- },
}

--------------------------------------------------
-- NINE SLICE UTILS
NineSliceUtils = {}

function NineSliceUtils.ApplyUniqueCornersLayout(self, textureKit)
	NineSliceUtils.ApplyLayout(self, layouts.UniqueCornersLayout, textureKit);
end

function NineSliceUtils.ApplyIdenticalCornersLayout(self, textureKit)
	NineSliceUtils.ApplyLayout(self, layouts.IdenticalCornersLayout, textureKit);
end

function NineSliceUtils.ApplyLayout(container, userLayout, textureKit)
	for pieceIndex, setup in ipairs(nineSliceSetup) do
		local pieceName = setup.pieceName
		local pieceLayout = userLayout[pieceName]
		if pieceLayout then
			PropagateLayoutSettingsToPieceLayout(userLayout, pieceLayout)

			local piece, pieceAlreadyExisted = GetNineSlicePiece(container, pieceName)
			if not pieceAlreadyExisted then
				container[pieceName] = piece
				piece:SetDrawLayer(pieceLayout.layer or "BORDER", pieceLayout.subLevel)
			end

			-- Piece setup can change arbitrary properties, do it before changing the texture.
			setup.fn(container, piece, setup, pieceLayout)
			SetupPieceVisuals(piece, setup, pieceLayout, textureKit)
		end
	end
end

function NineSliceUtils.ApplyLayoutByName(container, userLayoutName, textureKit)
	return NineSliceUtils.ApplyLayout(container, NineSliceUtils.GetLayout(userLayoutName), textureKit)
end

function NineSliceUtils.GetLayout(layoutName)
	return layouts[layoutName]
end

function NineSliceUtils.AddLayout(layoutName, layout)
	layouts[layoutName] = layout
end

--------------------------------------------------
-- NINE SLICE PANEL MIXIN
 NineSlicePanelUiMixin = {};

function NineSlicePanelUiMixin:GetFrameLayoutType()
	return self:GetAttribute("layoutType") or self:GetParent():GetAttribute("layoutType")
end

function NineSlicePanelUiMixin:GetFrameLayoutTextureKit()
	return self:GetAttribute("layoutTextureKit") or self:GetParent():GetAttribute("layoutTextureKit")
end

function NineSlicePanelUiMixin:OnLoad()
	local layout = NineSliceUtils.GetLayout(self:GetFrameLayoutType())
	if layout then
		NineSliceUtils.ApplyLayout(self, layout, self:GetFrameLayoutTextureKit());
	end
end