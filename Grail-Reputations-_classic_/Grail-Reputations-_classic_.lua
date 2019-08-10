--
--	Grail Reputations
--	Written by scott@mithrandir.com
--
--	Version History
--		001	Initial version
--		002	Converted to be a load-on-demand addon.
--		003 Converted codes to be more MoP-friendly.
--		004	Removed the version check because live has MoP data.
--		005 Changes the technique of how reputation data is stored, which reduces memory by over 0.6 MB.
--			Basically each reputation change is converted to a four-character code (representing a bitmap)
--			that is stored in a separate table whose index is the questId.  For quests that change more
--			than one reputation the four-character codes are appended, so no more tons of little tables.
--		006	Interface 50300
--		007	Switches to not relying on Grail.quests any more.
--
--	Known Issues
--
--	UTF-8 file
--

local pairs, strsub, tonumber = pairs, strsub, tonumber
local GetBuildInfo = GetBuildInfo
local COMBAT_TEXT_SHOW_REPUTATION_TEXT = COMBAT_TEXT_SHOW_REPUTATION_TEXT

local Grail_Reputations_File_Version = 007

if Grail.reputationsVersionNumber < Grail_Reputations_File_Version then
	Grail.reputationsVersionNumber = Grail_Reputations_File_Version

local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

local G = Grail.questReputations

local originalMem = gcinfo()

if release >= 0 then
G[456]={'045250'}
G[457]={'045250'}
G[458]={'04575'}
G[459]={'045250'}
G[916]={'045250'}
G[917]={'045350'}
G[920]={'04510'}
G[921]={'045150'}
G[928]={'04575'}
G[3519]={'04525'}
G[3521]={'045250'}
G[3522]={'045350'}
G[4495]={'045150'}
end

if release >= 31407 then
G[7]={'048250'}
G[9]={'048250'}
G[12]={'048250'}
G[15]={'048250'}
G[18]={'048250'}
G[21]={'048250'}
G[33]={'048250'}
G[47]={'048250'}
G[54]={'04875'}
G[62]={'048150'}
G[141]={'04825'}
G[475]={'04575'}
G[476]={'045250'}
G[483]={'045250'}
G[487]={'045250'}
G[783]={'04875'}
G[918]={'045250'}
G[919]={'045350'}
G[922]={'04575'}
G[923]={'045350'}
G[929]={'045250'}
G[933]={'045250'}
G[997]={'04575'}
G[2158]={'04825'}
G[2159]={'04525'}
G[3100]={'04875'}
G[3120]={'04575'}
G[5261]={'04875'}
G[8831]={'045150'}
end

--	Now the reputation data gets processed into its own table to save space

for questId, reps in pairs(Grail.questReputations) do
	if reps ~= nil then
		local index, mapId, factionId
		local s = ""
		for _, v in pairs(reps) do
			index = strsub(v, 1, 3)
			factionId = tonumber(index, 16)
			mapId = factionId  + Grail.mapAreaBaseReputationChange
if (index == nil) then print("index is nil "..v) end
if (Grail.reputationMapping[index] == nil) then print("no reputation mapping for ", index) end
			Grail:AddQuestToMapArea(questId, mapId, COMBAT_TEXT_SHOW_REPUTATION_TEXT .. " - " .. (Grail.reputationMapping[index] or "EEK"))
			s = s .. Grail:_ReputationCode(v)
		end
		if "" == s then s = nil end
		Grail.questReputations[questId] = s		-- replaces the table with a string to save space
	end
end
Grail:_CleanDatabase()	-- this is called because Grail will do it before this loadable addon is loaded, which means its reputation data will be dirty
Grail.memoryUsage.Reputations = gcinfo() - originalMem


end
