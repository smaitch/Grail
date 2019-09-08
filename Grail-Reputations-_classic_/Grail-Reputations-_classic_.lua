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
G[14]={'048350'}
G[15]={'048250'}
G[18]={'048250'}
G[21]={'048250'}
G[33]={'048250'}
G[47]={'048250'}
G[54]={'04875'}
G[62]={'048150'}
G[132]={'04875'}
G[141]={'04825'}
G[170]={'02F250','036250'}
G[179]={'02F250','036250'}
G[182]={'02F250','036250'}
G[183]={'02F250','036250'}
G[218]={'02F350','036500'}
G[233]={'02F150','036150'}
G[234]={'02F150','036150'}
G[282]={'02F150','036150'}
G[363]={'04475'}
G[475]={'04575'}
G[476]={'045250'}
G[483]={'045250'}
G[487]={'045250'}
G[783]={'04875'}
G[788]={'04C250','212250'}
G[789]={'04C250','212250'}
G[790]={'04C250','212250'}
G[792]={'04C350','212350'}
G[794]={'04C500','212500'}
G[804]={'04C25','21225'}
G[805]={'04C75','21275'}
G[808]={'04C250','212250'}
G[817]={'04C250','212250'}
G[818]={'04C250','212250'}
G[823]={'04C75','21275'}
G[826]={'04C250','212250'}
G[918]={'045250'}
G[919]={'045350'}
G[922]={'04575'}
G[923]={'045350'}
G[929]={'045250'}
G[933]={'045250'}
G[997]={'04575'}
G[1599]={'02F250','036250'}
G[2158]={'04825'}
G[2159]={'04525'}
G[2161]={'04C25','21225'}
G[3087]={'04C75'}
G[3100]={'04875'}
G[3106]={'02F75'}
G[3107]={'02F75'}
G[3108]={'02F75'}
G[3109]={'02F75'}
G[3110]={'02F75'}
G[3112]={'03675'}
G[3113]={'03675'}
G[3114]={'03675'}
G[3115]={'03675'}
G[3116]={'04575'}
G[3117]={'04575'}
G[3118]={'04575'}
G[3119]={'04575'}
G[3120]={'04575'}
G[3361]={'02F250','036250'}
G[3364]={'02F75','03675'}
G[3365]={'02F250','036250'}
G[4402]={'04C500','212500'}
G[4641]={'04C75','21275'}
G[5261]={'04875'}
G[5441]={'04C350','212350'}
G[6394]={'04C350','212350'}
G[8831]={'045150'}
end

if release >= 31650 then
G[6]={'048150'}
G[747]={'051250'}
G[3102]={'04875'}
G[3103]={'04875'}
G[3903]={'04810'}
G[3904]={'04875'}
end

if release >= 31687 then
G[11]={'048250'}
G[35]={'04875'}
G[37]={'04825'}
G[39]={'048350'}
G[40]={'04810'}
G[45]={'04875'}
G[46]={'048250'}
G[52]={'048150'}
G[59]={'04825'}
G[60]={'048150'}
G[61]={'048350'}
G[71]={'04825'}
G[76]={'048250'}
G[83]={'048250'}
G[84]={'04825'}
G[85]={'04825'}
G[86]={'048150'}
G[87]={'048350'}
G[88]={'048250'}
G[109]={'048150'}
G[176]={'048250'}
G[239]={'04825'}
G[750]={'051250'}
G[752]={'05175'}
G[753]={'051250'}
G[755]={'051250'}
G[757]={'051350'}
G[763]={'051150'}
G[3094]={'05175'}
G[3376]={'051500'}
G[8837]={'048150'}
end

if release >= 31727 then
G[1]={'211150','057-250'}
G[38]={'048250'}
G[184]={'048150'}
G[224]={'02F250'}
G[267]={'02F250'}
G[313]={'02F250','036250'}
G[317]={'02F350','036350'}
G[331]={'048250'}
G[353]={'02F250'}
G[384]={'02F250','036250'}
G[399]={'048250'}
G[400]={'02F25','03625'}
G[414]={'02F150','036150'}
G[719]={'02F250'}
G[729]={'02F150'}
G[944]={'04575'}
G[945]={'045250'}
G[947]={'045250'}
G[948]={'04575'}
G[949]={'045250'}
G[950]={'045150'}
G[951]={'045350'}
G[952]={'045250'}
G[953]={'045250'}
G[954]={'045150'}
G[955]={'045250'}
G[956]={'045250'}
G[957]={'045150'}
G[958]={'045250'}
G[963]={'045150'}
G[965]={'04575'}
G[966]={'045250'}
G[967]={'045150'}
G[970]={'045250'}
G[973]={'045250'}
G[982]={'045250'}
G[984]={'045150'}
G[985]={'045250'}
G[986]={'045250'}
G[990]={'04525'}
G[993]={'04575'}
G[995]={'04575'}
G[1001]={'036350'}
G[1002]={'036250'}
G[1003]={'036250'}
G[1138]={'02F250'}
G[1140]={'045250'}
G[1275]={'045350'}
G[1580]={'036250'}
G[1582]={'045250'}
G[1657]={'044350'}
G[2039]={'03625'}
G[2078]={'02F250'}
G[2098]={'02F250'}
G[2118]={'045250'}
G[2138]={'045250'}
G[2139]={'045250'}
G[2160]={'02F25','03625'}
G[2178]={'045250'}
G[2518]={'045350'}
G[4161]={'045250'}
G[4722]={'04575'}
G[4723]={'04575'}
G[4725]={'04575'}
G[4727]={'04575'}
G[4728]={'04575'}
G[4730]={'04575'}
G[4731]={'04575'}
G[4732]={'04575'}
G[4733]={'04575'}
G[4740]={'045350'}
G[4761]={'04510'}
G[4762]={'045150'}
G[4763]={'045350'}
G[4811]={'04575'}
G[4812]={'04575'}
G[4813]={'045250'}
G[5321]={'045250'}
G[5541]={'02F250','036250'}
G[5713]={'045250'}
G[7383]={'045150'}
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
