--
--
--	UTF-8 file
--

if GetLocale() ~= "enUS" then return end
local G = Grail.quest.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if release >= 0 then
G[456]='The Balance of Nature'
G[457]='The Balance of Nature'
G[458]='The Woodland Protector'
G[459]='The Woodland Protector'
G[475]='A Troubling Breeze'
G[476]='Gnarlpine Corruption'
G[483]='The Relics of Wakening'
G[487]='The Road to Darnassus'
G[916]='Webwood Venom'
G[917]='Webwood Egg'
G[920]="Tenaron's Summons"
G[921]='Crown of the Earth'
G[928]='Crown of the Earth'
G[929]='Crown of the Earth'
G[933]='Crown of the Earth'
G[997]="Denalan's Earth"
G[2159]='Dolanaar Delivery'
G[3120]='Verdant Sigil'
G[3519]='A Friend in Need'
G[3521]="Iverron's Antidote"
G[3522]="Iverron's Antidote"
G[4495]='A Good Friend'
end

if release >= 31407 then
G[7]='Kobold Camp Cleanup'
G[9]='The Killing Fields'
G[12]="The People's Militia"
G[15]='Investigate Echo Ridge'
G[18]='Brotherhood of Thieves'
G[21]='Skirmish at Echo Ridge'
G[33]='Wolves Across the Border'
G[47]='Gold Dust Exchange'
G[54]='Report to Goldshire'
G[62]='The Fargodeep Mine'
G[141]='The Defias Brotherhood'
G[783]='A Threat Within'
G[918]='Timberling Seeds'
G[919]='Timberling Sprouts'
G[922]='Rellian Greenspyre'
G[923]='Tumors'
G[2158]='Rest and Relaxation'
G[3100]='Simple Letter'
G[5261]='Eagan Peltskinner'
G[8830]='One Commendation Signet'
G[8831]='Ten Commendation Signets'
end

--	End of localized quest names
