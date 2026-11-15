--
--
--	UTF-8 file
--

if not Grail.usesForeverQuests then return end

if GetLocale() ~= "enUS" then return end
local G = Grail.npc.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if release >= 0 then
end

if release >= 70790 then
G[1654846]='Lost Journal'
end

if release >= 70938 then
G[1610954]='Bounty Available: Vulgara the Insatiable!'
end
