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
G[1180715]='Macchina Conserva Agrifoglio'
G[1180743]='Regalo Incartato con Cura'
G[1180746]='Dono Dolcemente Scosso'
G[1180747]='Regalo Incartato Gioiosamente'
G[1180748]='Regalo Ticchettante'
G[1180793]='Dono Festivo'
end

--	End of localized NPC names
