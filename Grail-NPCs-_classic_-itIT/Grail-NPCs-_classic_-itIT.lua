--
--
--	UTF-8 file
--

if GetLocale() ~= "itIT" then return end
local G = Grail.npc.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if release >= 0 then
G[0]='Se stesso'
G[1]=ADVENTURE_JOURNAL
end

--	End of localized NPC names
