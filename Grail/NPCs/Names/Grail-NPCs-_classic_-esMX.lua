--
--
--	UTF-8 file
--

if GetLocale() ~= "esMX" then return end
local G = Grail.npc.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if interface >= 100207 then return end

if release >= 0 then
G[0]='Auto'
G[1000031]='Estatua de león antigua'
G[1000033]='Cofre cerrado'
G[1000034]='Jarra antigua'
G[1000035]='Baúl del Capitán'
G[1000036]='Barril roto'
G[1000047]='Se busca: Teniente Fangore'
G[1000055]='Un cadáver medio comido'
G[1000056]='Cadáver de Rolf'
G[1000059]='Montón de tierra'
G[1000060]="Se busca: Gath'Ilzogg"
G[1000061]='Una tumba erosionada'
G[1000068]='Cartel de Se busca'
G[1000076]='Una jarra vacía'
G[1000256]='SE BUSCA'
G[1000257]='Barril sospechoso'
G[1000259]='Barril semienterrado'
G[1000261]='Cajón dañado'
G[1000269]='Barril de Cerveza del Trueno custodiado'
G[1000270]='Barril de Cerveza del Trueno sin vigilar'
G[1000287]='Documentos de Bookie Herod'
G[1000288]='Caja fuerte de Bookie Herod'
G[1000711]='¡Se busca!'
G[1001557]='Mesa de cena de Lillith'
G[1001561]='Cajón sellado'
G[1001585]='Carga explosiva'
G[1001586]='Cajón de velas'
G[1001593]='Barco cargado de cadáveres'
G[1001599]='Tumba poco profunda'
G[1001609]='Catapulta Faucedraco'
G[1001627]='Caja de Dalaran'
G[1001728]='Alfombra polvorienta'
G[1001740]='Documentos del Sindicato'
G[1001763]='SE BUSCA'
G[1001765]='Cofre de madera gastado'
G[1001767]='Tumba de Helcular'
G[1002008]='¡Peligro!'
G[1002059]='Un cadáver de enano'
G[1002076]='Caldera en ebullición'
G[1002083]='Correspondencia de los Velasangre'
G[1002289]='Bote salvavidas inservible'
G[1002382]='Entidades'
G[1002553]='Un viejo pergamino'
G[1002555]='Pergamino enmohecido'
G[1002556]='El tesoro de Cortello'
G[1002560]='Botella semienterrada'
G[1002652]='Cadáver de Ebenezer Herrumbra'
G[1002688]='Piedra angular'
G[1002701]='Fragmentos iridiscentes'
G[1002702]='Piedra de Vínculo Interior'
G[1002703]='Tumba de Aterratrols'
G[1002713]='Tabla de Se busca'
G[1002734]='Cofre con marcas de agua'
G[1002868]='Mapa arrugado'
G[1002875]='Esqueleto de enano maltrecho'
G[1002908]='Cajón de provisiones sellado'
G[1003080]='Entidades'
G[1003238]='Barril vacío de Chen'
G[1003239]='Cofre de Benedicto'
G[1003643]='Baúl antiguo'
G[1003972]='SE BUSCA'
G[1004141]='Consola de control'
G[1006751]='Planta extraña con frutos'
G[1006752]='Planta extraña con frutos'
G[1007510]='Fronda crecida'
G[1010076]='Cuenco de visión'
G[1012666]='Libro del Crepúsculo'
G[1017182]='Caja mecánica 827'
G[1017183]='Caja mecánica 411'
G[1017184]='Caja mecánica 323'
G[1017185]='Caja mecánica 525'
G[1019024]='Santuario Oculto'
G[1020805]='Planes vigilados de Rizzle'
G[1020985]='Porquería blanda'
G[1020992]='Escudo negro'
G[1021015]='Huellas pezuñales'
G[1021016]='Huellas pezuñales'
G[1021042]='Identificación de guardia de Theramore'
G[1024776]='Lápida de Yuriv'
G[1032569]='Caja fuerte de Galen'
G[1035251]='Cofre de Karnitol'
G[1050961]='Cofre de Malem'
G[1051708]='Tierra de la tumba de Eliza'
G[1061934]='Blandón de la Llama Latente'
G[1089931]="Caldera de Bath'rah"
G[1112888]='Estantería polvorienta'
G[1112948]='Caja fuerte de Intrepid cerrada'
G[1113791]='Blandón de Siemprefuente'
G[1138492]='Fragmentos de Myzrael'
G[1141980]='Arcón espectral'
G[1142071]='Huevomático'
G[1142127]="El secreto de Rin'ji"
G[1142151]='Barril selllado'
G[1142179]='Glorieta de Solarsal'
G[1142194]='¡Tesoro de pirata!'
G[1142702]='Botella de veneno'
G[1142703]='Botella de veneno'
G[1142704]='Botella de veneno'
G[1142705]='Botella de veneno'
G[1142706]='Botella de veneno'
G[1142707]='Botella de veneno'
G[1142708]='Botella de veneno'
G[1142709]='Botella de veneno'
G[1142710]='Botella de veneno'
G[1142711]='Botella de veneno'
G[1142712]='Botella de veneno'
G[1142713]='Botella de veneno'
G[1142714]='Botella de veneno'
G[1144063]='Monolito de Equinex'
G[1148498]='Altar de Suntara'
G[1148504]='Una lápida llamativa'
G[1156561]='Cartel de Se busca'
G[1161504]='Un paquetito'
G[1161505]='Una balsa estropeada'
G[1164909]='Restos de un bote de remos'
G[1164953]='Mochilas de piel grandes'
G[1164955]='Torre de cristal del Norte'
G[1164956]='Torre de cristal del Oeste'
G[1164957]='Torre de cristal del Este'
G[1173265]='Banco de madera'
G[1173327]='Flor del viento corrupta'
G[1174594]='Melodía corrupta'
G[1174600]='Flor del viento corrupta'
G[1174604]='Flor del viento corrupta'
G[1174682]='Cuidado con los pterrordáctilos'
G[1174709]='Flor del viento corrupta'
G[1175226]='Criatura marina varada'
G[1175227]='Criatura marina varada'
G[1175230]='Criatura marina varada'
G[1175233]='Criatura marina varada'
G[1175524]='Cristal rojo misterioso'
G[1175586]='Carro de Jaron'
G[1175587]='Cajón dañado'
G[1175704]='Carta chamuscada'
G[1175894]='Paquete de Janice'
G[1175924]='Armario cerrado'
G[1175925]='Baños'
G[1175926]='Diario de la señora Dalson'
G[1175927]='Catálogo de Malyfous'
G[1176090]='Restos humanos'
G[1176091]='Caldera de Muertobosque'
G[1176190]='Tortuga marina varada'
G[1176191]='Tortuga marina varada'
G[1176196]='Tortuga marina varada'
G[1176197]='Tortuga marina varada'
G[1176198]='Tortuga marina varada'
G[1176361]='Caldera de la Plaga'
G[1176392]='Caldera de la Plaga'
G[1176393]='Caldera de la Plaga'
G[1177289]='Caldera de la Plaga'
G[1177491]='Barril de termitas'
G[1177786]='Cofre de Rackmore'
G[1177787]='Cuaderno de bitácora de Rackmore'
G[1179485]='Trampa rota'
G[1179551]='Arca de Hydraxis'
G[1179880]='La marca de Drakkisath'
G[1179913]='¡A las armas!'
G[1180024]='[Mysterious Deadmines Chest]'
G[1180025]='Misterioso fardo de heno de la Vega del Este'
G[1180055]='Cofre misterioso de las Cuevas de los Lamentos'
G[1180056]='Tocón misterioso'
G[1180570]='Doodad_BeerKeg101'
G[1180633]='Lágrima cristalina'
G[1180642]='Caja inadvertida'
G[1180652]='[Freshly Dug Dirt]'
G[1180715]='Conservante de acebo'
G[1180717]='[The Scarab Gong]'
G[1180743]='Presente envuelto con cuidado'
G[1180746]='Obsequio ligeramente agitado'
G[1180747]='Presente con envoltorio alegre'
G[1180748]='Presente que hace tic-tac'
G[1180793]='Obsequio festivo'
G[1181073]='Caldera apetitosa'
end

--	End of localized NPC names
