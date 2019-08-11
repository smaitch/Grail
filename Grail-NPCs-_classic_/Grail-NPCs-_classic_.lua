--
--	Grail NPCs
--	Written by scott@mithrandir.com
--
--	Version History
--		Stopped keeping history as it was not maintained.
--
--	Each NPC value is a table that can contain:
--		[1]	code information (see below) like map location
--		[2] optional friendly notes
--		[3] optional faction association
--
--	NPC Codes
--		A:npcId			npcId that is what Blizzard returns for this alias NPC
--		Created			indicates item is created by player
--		D:<npc list>	comma separated list of NPC IDs that drop this item
--		H<holidayCode>	holidayCode is a single character indicating the holiday the NPC is available
--		K:<quest list>	comma separated list of quest IDs for which this is killed
--		Mailbox			indicates item in a mailbox (any map area)
--		Mailbox<mapId>	indicates item in a mailbox in the specified map area
--		N:npcId			npcId whose name is to be used for this NPC
--		Near			indicates the NPC is nearby (any map area)
--		Near<mapId>		indicates the NPC is nearby in the specified map area
--		Preowned		indicates item is already owned
--		Q:<quest list>	comma separated list of quest IDs to which this is associated
--		Self			special NPC indicator for Self (the player)
--		X				indicates NPC is in heroic only
--		Z<mapId>		indicates NPC found in the map area
--		anything else should be the format (without spaces):
--			mapId [mapLevel] : xx.xx , yy.yy > realMapId
--		the "[mapLevel]" is only required for maps with levels, most do not need it
--		the "> realMapId" indicates the coordinates are in a map that contains the realMap...this allows an outer map to show a point for maps that are contained within
--
--	Known issues
--
--
--	Alliance Garrison small plot top step locations:
--		18:	971:46.99,59.27
--		19:	971:50.03,57.75
--		20:	971:51.19,63.58
--	Alliance Garrison medium plot basic entrance locations:
--		22:	971:35.53,49.36
--		25: 971:51.21,47.04
--	Alliance Garrison large plot basic entrance locations:
--		23:	971:45.25,42.49
--		24:	971:40.09,56.58
--
--	Horde Garrison small plot top step locations:
--		18:	976:52.44,37.06
--		19:	976:48.38,33.59
--		20: 976:52.59,40.81
--	Horde Garrison medium plot basic entrance locations:
--		22: 976:51.43,57.39
--		25:	976:57.75,28.14
--	Horde Garrison large plot basic entrance locations:
--		23: 976:58.88,49.06
--		24: 976:60.36,36.51
--
--	Dungeon entrances:
--		Ulduar					495:41.57,17.83
--		Thunder					928:63.73,32.23
--		SM Graveyard 762[1]		20:84.87,30.61
--		SM Cathedral 762[4]		20:85.35,30.62
--		SM Library 762[2]		20:85.29,32.14
--		SM Armory 762[3]		20:85.62,31.59
--		Mechanar				479:70.59,69.73
--		Tempest Keep			479:73.73,63.74
--		Botanica				479:71.72,55.02
--		Arcatraz				479:74.37,57.74
--		Auchanai Crypts			478:34.34,65.61
--		Sethekk Halls			478:44.91,65.61
--		Shadow Labyrinth		478:39.63,73.54
--		Mana Tombs				478:39.63,57.67
--		Blood Furnace			465:46.03,51.79
--		Shattered Halls			465:47.68,51.99
--		Hellfire Ramparts		465:47.63,53.57
--		Black Temple			473:71.05,46.45
--		Grim Batol				700:19.18,54.01
--		Gate of the Setting Sun	811:15.84,74.39
--		Shado-Pan Monastery		809:36.66,47.33
--		Temple of Jade Serpent	806:56.18,57.87
--		Auchindoun				946:46.31,73.93
--		Bloodmaul Slag Mines	941:49.85,24.75
--		Zul Aman				463:82.14,64.35
--
--	UTF-8 file
--
Grail_NPCs_File_Version = 015

if Grail.npcsVersionNumber >= Grail_NPCs_File_Version then return end
Grail.npcsVersionNumber = Grail_NPCs_File_Version

local originalMem = gcinfo()

Grail.npcs = {}

local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

local G = Grail.npcs

if release >= 0 then
G[196]={'1429:48.94,40.16'}
G[197]={'1429:48.92,41.60'}
G[240]={'1429:42.11,65.93'}
G[241]={'1429:42.14,67.25'}
G[295]={'1429:43.77,65.81'}
G[460]={'1426:28.65,66.14'}
G[658]={'1426:29.93,71.21'}
G[713]={'1426:29.71,71.25'}
G[714]={'1426:22.60,71.43'}
G[786]={'1426:25.08,75.71'}
G[823]={'1429:48.16,42.95'}
G[836]={'1426:28.77,66.38'}
G[837]={'1426:28.60,66.39'}
G[895]={'1426:29.17,67.46'}
G[911]={'1429:50.24,42.28'}
G[912]={'1426:28.83,67.24'}
G[916]={'1426:28.37,67.51'}
G[926]={'1426:28.83,68.33'}
G[944]={'1426:28.71,66.37'}
G[1992]={'1438:57.73,45.05'}
G[2077]={'1438:59.92,42.48'}
G[2078]={'1438:55.95,57.27'}
G[2079]={'1438:58.69,44.27'}
G[2080]={'1438:60.90,68.49'}
G[2082]={'1438:57.81,41.66'}
G[2083]={'1438:56.08,57.72'}
G[2107]={'1438:66.26,58.52'}
G[2151]={'1438:55.81,58.31'}
G[3143]={'1411:42.06,68.33'}
G[3145]={'1411:42.85,69.14'}
G[3154]={'1411:42.84,69.33'}
G[3287]={'1411:40.60,62.59'}
G[3514]={'1438:59.07,39.44'}
G[3515]={'1438:56.14,61.71'}
G[3517]={'1457:38.19,21.64'}
G[3593]={'1438:59.63,38.45'}
G[3594]={'1438:59.63,38.67'}
G[3595]={'1438:59.18,40.45'}
G[3596]={'1438:58.65,40.45'}
G[3597]={'1438:58.62,40.28'}
G[6736]={'1438:55.62,59.79'}
G[6774]={'1429:45.57,47.75'}
G[6780]={'1438:61.16,47.64'}
G[8416]={'1426:28.48,67.67'}
G[8583]={'1438:60.90,41.96'}
G[8584]={'1438:54.59,32.99'}
G[9796]={'1411:42.73,67.24'}
G[10176]={'1411:43.28,68.54'}
G[11378]={'1411:44.62,68.65'}
G[12738]={'1426:24.98,75.94'}
end

local N = Grail.npc
for key, value in pairs(Grail.npcs) do
	if value[1] then
		N.locations[key] = {}
		local codeArray = { strsplit(" ", value[1]) }
		local controlCode
		for _, code in pairs(codeArray) do
			controlCode = strsub(code, 1, 1)
			if 'A' == controlCode then
				if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
					local alias = tonumber(strsub(code, 3))
					if nil ~= alias then
						N.nameIndex[key] = alias
						N.aliases[alias] = N.aliases[alias] or {}
						tinsert(N.aliases[alias], key)
					else
						print("*** NPC processing of",key,"has improper alias")
					end
				end
			elseif 'C' == controlCode then
				tinsert(N.locations[key], { created = true })
			elseif 'D' == controlCode then
				if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
					N.droppedBy[key] = N.droppedBy[key] or {}
					local npcIds = { strsplit(',', strsub(code, 3)) }
					for _, anNPCId in pairs(npcIds) do
						local npcNumber = tonumber(anNPCId)
						if nil ~= npcNumber then
							tinsert(N.droppedBy[key], npcNumber)
							N.has[npcNumber] = N.has[npcNumber] or {}
							tinsert(N.has[npcNumber], key)
						end
					end
				end
			elseif 'H' == controlCode then
				-- the "has" codes are deprecated as we will populate the data based on "drop" codes instead
				if 2 < strlen(code) then
					local subcode = strsub(code, 2, 2)
					if ':' ~= subcode then
						local holidays = N.holiday[key]
						if nil == holidays then
							holidays = ''
						end
						N.holiday[key] = holidays .. subcode
					end
				end
			elseif 'K' == controlCode then
				if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
					N.kill[key] = N.kill[key] or {}
					local questList = { strsplit(',', strsub(code, 3)) }
					for _, questId in pairs(questList) do
						tinsert(N.kill[key], tonumber(questId))
					end
				end
			elseif 'M' == controlCode then
				local t1 = { mailbox = true }
				if 7 < strlen(code) then
					t1.mapArea = tonumber(strsub(code, 8))
				end
				tinsert(N.locations[key], t1)
			elseif 'N' == controlCode then
				if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
					local nameIndexToUse = tonumber(strsub(code, 3))
					N.nameIndex[key] = nameIndexToUse
				else
					local t1 = { near = true }
					if 4 < strlen(code) then
						t1.mapArea = tonumber(strsub(code, 5))
					end
					tinsert(N.locations[key], t1)
				end
			elseif 'P' == controlCode then
				-- we do nothing special for "Preowned" at the moment
			elseif 'Q' == controlCode then
				if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
					N.questAssociations[key] = N.questAssociations[key] or {}
					local questList = { strsplit(',', strsub(code, 3)) }
					for _, questId in pairs(questList) do
						tinsert(N.questAssociations[key], tonumber(questId))
					end
				end
			elseif 'S' == controlCode then
				-- we do nothing special for "Self" at the moment
			elseif 'X' == controlCode then
				N.heroic[key] = true
			elseif 'Z' == controlCode then
				tinsert(N.locations[key], { ["mapArea"]=tonumber(strsub(code, 2)) })
			else	-- a real coordinate
				tinsert(N.locations[key], Grail:_LocationStructure(code))
			end
		end
	end
	if value[2] then N.comment[key] = value[2] end
	if value[3] then N.faction[key] = value[3] end

end
-- TODO: Go through all the Grail.npc.droppedBy values and make sure the locations for the NPCs are added to those keys

Grail.npcs = nil
--	18.84/19.29 idle after a couple minutes at startup without these changes.
--	18.25/18.69	idle after a couple minutes at startup WITH these changes.

Grail.memoryUsage.NPCs = gcinfo() - originalMem

-- 81152 garrison level 1: 582:46.56,54.33 539:30.46,18.28

