--
--
--	UTF-8 file
--

if GetLocale() ~= "itIT" then return end
local G = Grail.quest.description
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if interface >= 100207 then return end

if release >= 0 then
end

--	End of localized quest descriptions
