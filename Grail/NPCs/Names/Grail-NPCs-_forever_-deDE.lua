--
--
--	UTF-8 file
--

if not Grail.usesForeverQuests then return end

if GetLocale() ~= "deDE" then return end
local G = Grail.npc.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)
if release >= 0 then
end

if release >= 70009 then
G[1660739]='Ritualfeuer'
end

--	End of localized NPC names
