--
--
--	UTF-8 file
--

if GetLocale() ~= "frFR" then return end
local G = Grail.npc.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if release >= 0 then
G[0]='Soi-même'
G[1]=ADVENTURE_JOURNAL
G[1000031]='Statue du vieux lion'
G[1000033]='Coffre verrouillé'
G[1000034]='Vieille cruche'
G[1000035]='Cantine du capitaine'
G[1000036]='Tonneau cassé'
G[1000047]='On recherche : lieutenant Fangore'
G[1000055]='Un corps à moitié dévoré'
G[1000056]='Cadavre de Rolf'
G[1000059]='Monticule de poussière'
G[1000060]="Recherché : Gath'Ilzogg"
G[1000061]='Un tombeau dégradé par les intempéries'
G[1000068]='Avis de recherche'
G[1000256]='ON RECHERCHE'
G[1000257]='Tonneau suspect'
G[1000270]='Tonneau de Thunder Ale non gardé'
G[1001561]='Caisse scellée'
G[1001585]='Charge explosive'
G[1002059]='Un cadavre de nain'
G[1003643]='Vieille Cantine'
G[1006751]='Plante aux fruits étranges'
G[1006752]='Plantes aux feuilles étranges'
G[1010076]='Coupe de divination'
G[1012666]='Tome du crépuscule'
G[1017182]='Bigobox 827'
G[1017183]='Bigobox 411'
G[1017184]='Bigobox 323'
G[1017185]='Bigobox 525'
G[1051708]="Boue du tombeau d'Eliza"
G[1113791]="Brasero d'Everfount"
G[1156561]='Avis de recherche'
G[1175226]='Créature marine échouée'
G[1175227]='Créature marine échouée'
G[1175233]='Créature marine échouée'
G[1175524]='Mystérieux Cristal rouge'
G[1176190]='Tortue de mer échouée'
G[1176191]='Tortue de mer échouée'
G[1176196]='Tortue de mer échouée'
G[1176197]='Tortue de mer échouée'
G[1176198]='Tortue de mer échouée'
end

--	End of localized NPC names
