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
G[132]='The Defias Brotherhood'
G[141]='The Defias Brotherhood'
G[170]='A New Threat'
G[179]='Dwarven Outfitters'
G[182]='The Troll Cave'
G[183]='The Boar Hunter'
G[218]='The Stolen Journal'
G[233]='Coldridge Valley Mail Delivery'
G[234]='Coldridge Valley Mail Delivery'
G[282]="Senir's Observations"
G[363]='Rude Awakening'
G[783]='A Threat Within'
G[788]='Cutting Teeth'
G[789]='Sting of the Scorpid'
G[790]='Sarkoth'
G[792]='Vile Familiars'
G[794]='Burning Blade Medallion'
G[805]="Report to Sen'jin Village"
G[918]='Timberling Seeds'
G[919]='Timberling Sprouts'
G[922]='Rellian Greenspyre'
G[923]='Tumors'
G[1599]='Beginnings'
G[2158]='Rest and Relaxation'
G[3087]='Etched Parchment'
G[3100]='Simple Letter'
G[3106]='Simple Rune'
G[3107]='Consecrated Rune'
G[3108]='Etched Rune'
G[3109]='Encrypted Rune'
G[3110]='Hallowed Rune'
G[3112]='Simple Memorandum'
G[3113]='Encrypted Memorandum'
G[3114]='Glyphic Memorandum'
G[3115]='Tainted Memorandum'
G[3116]='Simple Sigil'
G[3117]='Etched Sigil'
G[3118]='Encrypted Sigil'
G[3119]='Hallowed Sigil'
G[3361]="A Refugee's Quandary"
G[3364]='Scalding Mornbrew Delivery'
G[3365]='Bring Back the Mug'
G[4402]="Galgar's Cactus Apple Surprise"
G[4641]='Your Place In The World'
G[5261]='Eagan Peltskinner'
G[5441]='Lazy Peons'
G[8830]='One Commendation Signet'
G[8831]='Ten Commendation Signets'
end

--	End of localized quest names
