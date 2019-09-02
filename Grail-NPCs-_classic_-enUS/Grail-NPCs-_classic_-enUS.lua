--
--
--	UTF-8 file
--

if GetLocale() ~= "enUS" then return end
local G = Grail.npc.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if release >= 0 then
G[0]='Self'
G[1]=ADVENTURE_JOURNAL
G[1000055]='A half-eaten body'
G[1000056]="Rolf's corpse"
end

--	End of localized NPC names
