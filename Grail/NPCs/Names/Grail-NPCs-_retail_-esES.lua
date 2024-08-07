--
--
--	UTF-8 file
--

if GetLocale() ~= "esES" then return end
local G = Grail.npc.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if interface < 100207 then return end

if release >= 0 then
G[0]='Auto'
G[500022]='Cubo de caramelos'
G[500032]='Nozdormu'
G[562180]='Korven el Perfecto'
G[562295]='Mago Omnia'
G[562378]='Sacerdote Omnia'
G[563195]='Maestro cervecero guardanegro'
G[563196]='Maestro de batalla guardanegro'
G[563197]='Adepto guardanegro'
G[563622]='Pícaro Wu Kao'
G[563623]='Asesina Wu Kao'
G[563624]='Maestro de halcones Wu Kao'
G[1000033]='Cofre cerrado'
G[1000034]='Vieja jarra'
G[1000035]='Baúl del Capitán'
G[1000036]='Barrica rota'
G[1000055]='Un cadáver medio comido'
G[1000056]='Cadáver de Rolf'
G[1000061]='Una tumba erosionada'
G[1000068]='Cartel de Se busca'
G[1000256]='¡Se busca!'
G[1000259]='Barrica semienterrada'
G[1000261]='Cajón dañado'
G[1002059]='Un cadáver de enano'
G[1002076]='Caldera en ebullición'
G[1002083]='Correspondencia de los Velasangre'
G[1002688]='Piedra angular'
G[1002701]='Fragmentos iridiscentes'
G[1002702]='Piedra de Vínculo Interior'
G[1002713]='Tablón de Se busca'
G[1002908]='Cajón de suministros sellado'
G[1003972]='SE BUSCA'
G[1004141]='Consola de control'
G[1006751]='Planta con extraños frutos'
G[1006752]='Planta con extrañas hojas'
G[1007510]='Fronda crecida'
G[1007923]='Maceta de Denalan'
G[1020985]='Porquería blanda'
G[1020992]='Escudo negro'
G[1021042]='Identificación de guardia de Theramore'
G[1024776]='Lápida de Yuriv'
G[1035251]='Cofre de Karnitol'
G[1112948]='Caja fuerte de El Intrépido cerrada'
G[1131474]='Los Discos de Norgannon'
G[1138492]='Fragmentos de Myzrael'
G[1142151]='Barrica sellada'
G[1142195]='Mapa de batalla de los Zarpaleña'
G[1142487]='El Destellamatic 5200'
G[1151286]='Escrito sobre invocación kaldorei'
G[1152097]='Blandón de Belnistrasz'
G[1161521]='Equipo de investigación'
G[1161526]='Cajón de comestibles'
G[1164869]='Cáliz espectral'
G[1164955]='Torre de cristal del Norte'
G[1164956]='Torre de cristal del Oeste'
G[1164957]='Torre de cristal del Este'
G[1176091]='Caldera de Muertobosque'
G[1176392]='Caldera de la Plaga'
G[1177544]='Cofre de Joseph'
G[1179485]='Trampa rota'
G[1179517]="Tesoro de los Shen'dralar"
G[1179551]='Arca de Hydraxis'
G[1179697]='Arqueta de la arena'
G[1179880]='Enseña de Drakkisath'
G[1180025]='Misterioso fardo de heno de la Vega del Este'
G[1180056]='Tocón misterioso'
G[1180366]='Caja de aparejos maltrecha'
G[1180448]='Cartel de Se busca: Pinzamorten'
G[1180503]='Libro de cocina de Sandy'
G[1180715]='Conservante de acebo'
G[1180743]='Presente envuelto con cuidado'
G[1180746]='Obsequio ligeramente agitado'
G[1180747]='Presente con envoltorio alegre'
G[1180748]='Presente que hace tic-tac'
G[1180793]='Obsequio festivo'
G[1180918]='Se busca: Thaelis el Hambriento'
G[1181011]='Diario del magister Ocaso Marchito'
G[1181150]='Diario polvoriento'
G[1181153]="Cartel de Se busca: Kel'gash el Malvado"
G[1181748]='Cristal de sangre'
G[1181756]='Libro antiguo maltrecho'
G[1181758]='Montón de tierra'
G[1182032]='Diario de Galaen'
G[1182392]='Tablón de anuncios de Garadar'
G[1182393]='Tablón de anuncios de Telaar'
G[1182549]='Planos de orcos viles'
G[1182947]='El Códice de Sangre'
G[1183770]="Consola de control B'naar"
G[1183877]='Panel de control de teletransporte etéreo'
G[1184300]='Foco nigromántico'
G[1184825]="Escrito Lashh'an"
G[1185126]='Prisión de cristal'
G[1185165]='Comunicador de la Legión'
G[1186585]='Pergamino de piel de dragón'
G[1186887]='Calabaza iluminada'
G[1187236]='Obsequio del Festival de Invierno'
G[1187273]='Huella de casco sospechosa'
G[1187559]='Fogata de la Horda'
G[1187564]='Fogata de la Alianza'
G[1187565]='Ancestro Atkanok'
G[1187851]='Santuario de cultor'
G[1187905]='Huevo gigante resplandeciente'
G[1188085]='Grano apestado'
G[1188261]='Diario maltrecho'
G[1188364]='Trampa de cangrejos destrozada'
G[1188365]='Corazón de los ancestros'
G[1188419]="Ancestro Mana'loa"
G[1188667]='Grano ámbar'
G[1189311]='Escrito encuadernado en carne'
G[1189989]='Restos de la máquina topo Hierro Negro'
G[1190768]='Arca desgastada'
G[1190777]='Filacteria de Artruis'
G[1190917]='Correo abandonado'
G[1190936]='Caldera de peste'
G[1191760]='Consola de la Biblioteca del Inventor'
G[1191761]='Consola prototipo'
G[1191766]='Órdenes de Drakuru'
G[1192060]='Yunque de Fjorn'
G[1192072]='Cajón de arpones'
G[1192078]='Cuerno de Hodir'
G[1192079]='Lanza de Hodir'
G[1192080]='Yelmo de Hodir'
G[1192524]='Arngrim el Insaciable'
G[1192833]='Posesiones de Bridenbrad'
G[1193195]='Cristal pulsante'
G[1193400]='Montón de bombas de saronita'
G[1194105]='Caja mecánica 413'
G[1194122]='Caja mecánica 723'
G[1194378]='Documento de la Liga de Expedicionarios robado'
G[1194555]='Consola de El Archivum'
G[1194714]='Banco de trabajo desagradable'
G[1195134]='La bomba'
G[1195431]='Radio de puesto de mando'
G[1195433]='Tablillas antiguas'
G[1195435]='Armario de armas'
G[1195438]='Copa de Elune'
G[1195445]='Piedra rúnica del vórtice antigua'
G[1195497]='Blandón de Elune'
G[1195517]='Fámulas de Elune'
G[1195600]='Piedra ardiente'
G[1195642]='Piedra de energía naga'
G[1195676]='Graznófono del Laboratorio Secreto'
G[1196393]='Reliquia rota'
G[1196394]='Cajón de esencia de mandrágora'
G[1196832]='Piedra de visión alta'
G[1196833]='Piedra de visión baja'
G[1201578]='Póster de reclutamiento de manijeros'
G[1201742]='Forja de runas'
G[1202135]='Tumba de Dadanga'
G[1202264]='Saco de Ringo'
G[1202335]='Cañón de campo de Paxton'
G[1202407]='Cofre de Rascadunas'
G[1202474]='Cofre antediluviano'
G[1202598]='Desatascador asqueroso grande'
G[1202613]='Panel de control de la plataforma'
G[1202697]='Ojo del Crepúsculo'
G[1202701]='Letrina escondrijo'
G[1202706]='Caldero Crepuscular'
G[1202712]='El Apócrifo Crepuscular'
G[1202714]='Calavera enorme'
G[1202759]='Cofre de la Horda sumergido'
G[1202859]='Baúl semienterrado'
G[1202871]='Cajón hundido'
G[1202916]='Túmulo de arena'
G[1202975]='Letrina sumergida'
G[1203128]='Botella rota'
G[1203134]='Pedestal vacío'
G[1203140]='Punta rota'
G[1203186]='¡FUERA!'
G[1203207]='Códice de las Sombras'
G[1203301]='Tridentes de naga'
G[1203305]='Crisol de Nazsharin'
G[1203395]='Equipo G.O.E.V. de la Alianza'
G[1203733]='Tablón de recompensas'
G[1203734]='Escrituras de los Páramos de Poniente'
G[1204050]='Planos del Rasgadversarios'
G[1204274]='Diario del Capitán'
G[1204351]='Orbe de control de ettin'
G[1204406]='Botella semienterrada'
G[1204450]='Cartas del capitán Aguasmansas'
G[1204578]='Barril de ron doble'
G[1204817]='Vara forjada con luz'
G[1204824]='Arco forjado con luz'
G[1204825]='Blasón forjado con luz'
G[1204959]='Racimo de painita gigante'
G[1205134]='Cuaderno del maestro de forja'
G[1205143]='Letrina abandonada'
G[1205198]='Pila de explosivos'
G[1205207]='Diario de Maziel'
G[1205258]='Cajón de armas roto'
G[1205266]='Disco elaborado'
G[1205350]='Panel de comunicación de la Horda'
G[1205540]='Esqueleto decrépito'
G[1205874]='Jeroglíficos cubiertos de arena'
G[1205875]='Bengala de cruzado'
G[1206109]='Tablón de mando del Jefe de Guerra'
G[1206111]='Tablero de ¡Se busca héroe!'
G[1206293]='Terminal A.I.D.A.'
G[1206335]='Losa de piedra'
G[1206336]='Losa de mármol'
G[1206374]='Tesoro de los Vigías'
G[1206504]='Última nota de Rhea'
G[1206585]='Tótem de Ruumbo'
G[1206944]='Pala'
G[1207104]='Bomba de control maestro'
G[1207125]='Cajón de suministros abandonados'
G[1207179]='Caldera de Nevada'
G[1207291]='Eco Tres'
G[1207303]='Tablón de aventuras'
G[1207359]='Huevo Crepuscular puro'
G[1207406]='Fuente extraña'
G[1207407]='Pilar Partido'
G[1207408]='Blandón mágico'
G[1207409]="Tumba de tol'vir"
G[1207410]='Obelisco de piedra grande'
G[1207411]='Pila de huesos de enano'
G[1207412]='Tablilla de piedra'
G[1208184]='Fogata del Anillo de la Tierra'
G[1208420]='Arqueta'
G[1208535]='Bellota seca'
G[1208549]='Montón vudú'
G[1208825]='Santuario de los Ancestros'
G[1209072]='Cajón robado'
G[1209673]='Pilar de tigre de jade'
G[1209845]='Brebaje apetitoso'
G[1211316]='Alijo del comandante'
G[1211754]='Texto curioso'
G[1212181]='Estatua antigua'
G[1212389]='Pergamino de auspicios'
G[1213767]='Tesoro escondido'
G[1213770]='Tesoro de duende robado'
G[1213771]='Estatua de Xuen'
G[1213793]='Cofre diminuto de Rikktik'
G[1214062]='Ámbar resplandeciente'
G[1214218]='Revoltijo'
G[1214438]='Tablilla mogu antigua'
G[1214562]='Cristal embrujado por el sha'
G[1214871]='Destructor destruido'
G[1215705]='Santuario de labradores'
G[1215844]='Asta'
G[1216837]='Cofre de joyas de Wrathion'
G[1217848]='Fogata del Solsticio de Verano'
G[1218077]='Base del chambelán'
G[1218750]='Pedidos'
G[1218765]='Cajón vacío'
G[1220832]='Tesoro hundido'
G[1220901]='Cofre del tesoro reluciente'
G[1220902]='Cofre del tesoro atado con cuerda'
G[1220903]='Estatua de la Grulla reluciente'
G[1220986]='Trastos del Guardanegro'
G[1221376]='Fragmento de cartel viejo'
G[1221413]='Pergamino de la familia Lin'
G[1221617]='Cofre adornado de calaveras'
G[1222684]='Arena centelleante'
G[1225726]='Órdenes de desmantelamiento de la trituradora'
G[1225778]='Notas de Barum'
G[1229314]='Dispositivo de control mental goblin'
G[1229330]='Anillo misterioso'
G[1229331]='Un sombrero místico'
G[1230741]='Mesa de bocetos'
G[1230865]='Lista de ingredientes'
G[1230882]='Oromática 9000'
G[1230933]='Consola de control central de torre de defensa'
G[1231183]='Peana del ojo de Anzu'
G[1231184]='Cuenco para ofrendas'
G[1231901]='Pergaminos ogros'
G[1231918]='Pergamino de Laanda'
G[1232353]='Silla de sobrestante'
G[1232397]='Tablón de anuncios'
G[1234243]='Nota excesivamente llamativa'
G[1235129]='Semillas enriquecidas'
G[1237016]="Se busca: Kuu'rat"
G[1237021]='Se busca: el aguijón de Kliaa'
G[1237821]='Órdenes de Furiafilo'
G[100001307]='Planificación de recogida de oro'
G[100001357]='Mapa del tesoro del capitán Sanders'
G[100003082]='Calavera de Dargol'
G[100004854]='Capa con marca de demonio'
G[100005179]='Corazón musgoso'
G[100008244]='Esfera draenetista perfecta'
G[100008623]='Localizador de emergencia OOX-17/TN'
G[100008704]='Localizador de emergencia OOX-09/TI'
G[100008705]='Localizador de emergencia OOX-22/FE'
G[100009326]='Anillo con mugre incrustada'
G[100010593]='Trozo draenetista imperfecto'
G[100012842]='Registro escrito de forma rudimentaria'
G[100016303]='Pata de Ursangous'
G[100016304]='Cabeza de Shadumbra'
G[100016305]='Garfa de Garfafilada'
G[100016408]='Globo de agua contaminada'
G[100016782]='Globo de agua extraño'
G[100017203]='Lingote de sulfuron'
G[100018356]='Garona: Un Estudio sobre el Sigilo y la Traición'
G[100018357]='Códice de Defensa'
G[100018358]='El libro de cocina del arcanista'
G[100018359]='La Luz y cómo alterarla'
G[100018360]='Sombras acechadoras'
G[100018361]='La mejor raza de cazadores'
G[100018362]='Sagrada Bologna: lo que la Luz nunca te dirá'
G[100018363]='El choque de Escarcha y tú'
G[100018364]='El Sueño Esmeralda'
G[100018628]='Contrato de la Hermandad del Torio'
G[100018706]='Maestro de arena'
G[100018769]='Pergamino roto'
G[100018987]='Orden de Puño Negro'
G[100019002]='Cabeza de Nefarian'
G[100019016]='Vasija de renacer'
G[100019018]='Hoja besada por el viento durmiente'
G[100019228]='Baraja de Bestias'
G[100019257]='Baraja de Señores de la Guerra'
G[100019267]='Baraja de Elementales'
G[100019277]='Baraja de Portales'
G[100019423]='Fortuna de Sayge n.º 23'
G[100019424]='Fortuna de Sayge n.º 24'
G[100019443]='Fortuna de Sayge n.º 25'
G[100019452]='Fortuna de Sayge n.º 27'
G[100019802]='Corazón de Hakkar'
G[100020461]='Carta perdida de Brann Barbabronce'
G[100020483]='Esquirla arcana mácula'
G[100020644]='Objeto envuelto en pesadillas'
G[100020741]='Tótem de ritual Muertobosque'
G[100020765]='Documentos incriminadores'
G[100021220]='Cabeza de Osirio el Sinmarcas'
G[100021221]="Ojo de C'Thun"
G[100021230]='Artefacto qiraji antiguo'
G[100021776]='Rutas perdidas de la capitana Kelisendra'
G[100022597]='El collar de Sylvanas'
G[100022727]='Armazón de Atiesh'
G[100022733]='Cabeza del báculo Atiesh'
G[100023179]='Llama de Orgrimmar'
G[100023180]='Llama de Cima del Trueno'
G[100023181]='Llama de Entrañas'
G[100023182]='Llama de Ventormenta'
G[100023183]='Llama de Forjaz'
G[100023184]='Llama de Darnassus'
G[100023228]='Colgante del viejo Cortezablanca'
G[100023249]='Planes de invasión Amani'
G[100023338]='Estuche de cuero desgastado'
G[100023580]='Orbe de Avruu'
G[100023678]='Cristal con resplandor tenue'
G[100023759]='Tablilla cubierta de runas'
G[100023777]='Planes diabólicos'
G[100023837]='Mapa del tesoro deteriorado'
G[100023850]='Dignidad de Gurf'
G[100023870]='Colgante de cristal rojo'
G[100023900]='Placa de la armadura de Tzerak'
G[100023910]='Comunicación de elfos de sangre'
G[100024132]='Una carta del almirante'
G[100024330]='Planos de conducto'
G[100024367]='Órdenes de Lady Vashj'
G[100024407]='Especie sin catalogar'
G[100024414]='Planes de los elfos de sangre'
G[100024483]='Basidio marchito'
G[100024504]='Viento aullador'
G[100024558]='Planes de invasión Sangreoscura'
G[100025459]='Mandíbula del "conde" Ungula'
G[100028552]='Un escrito misterioso'
G[100029233]='Hoja de Dathric'
G[100029234]='Escrito de Belmara'
G[100029235]='Manto de Luminrath'
G[100029236]='Sombrero de Cohlien'
G[100029476]='Fragmento de cristal carmesí'
G[100029588]='Misiva de la Legión Ardiente'
G[100030431]='Artefacto del clan Señor del Trueno'
G[100030579]='Fragmento aterraillidari'
G[100031120]='Nota de cita'
G[100031345]="El diario de Val'zareq"
G[100031363]='Favor de Gorgrom'
G[100031384]='Máscara dañada'
G[100031489]='Orbe de los Grishna'
G[100031707]='Órdenes de la Cábala'
G[100031890]='Baraja de Bendiciones'
G[100031891]='Baraja de Tormentas'
G[100031907]='Baraja de Furias'
G[100031914]='Baraja de Locuras'
G[100032385]='Cabeza de Magtheridon'
G[100032405]='Esfera glauca'
G[100032523]='Anuario de Ishaal'
G[100032621]='Mano parcialmente digerida'
G[100032726]='Planes de fuga de los Sangreoscura'
G[100033289]='Planes de ataque de Gjalerbron'
G[100033314]='Pergamino de ascensión vrykul'
G[100033961]='Artefacto de la Plaga'
G[100034090]='Escritos de Mezhen'
G[100034469]='Pieza de motor extraña'
G[100034777]="Caparazón endurecido de Ith'rix"
G[100034815]='Vial de sangre fresca'
G[100034984]='El destornillador ultrasónico'
G[100035568]='Llama de Lunargenta'
G[100035569]='Llama de El Exodar'
G[100035648]='Fragmento centelleante'
G[100035723]='Fragmentos de Ahune'
G[100036742]='Extraño dispositivo de Goramosh'
G[100036744]='Escrito encuadernado en carne'
G[100036756]='Carta de la capitana Malin'
G[100036780]="Carta del teniente Ta'zinni"
G[100036855]='Cuerno de batalla blasonado'
G[100036940]='Diario de Mikhail'
G[100036958]='El Favor de Zangus'
G[100037163]='Baraja de Pícaros'
G[100037164]='Baraja de Espadas'
G[100037432]='Vara de torturador'
G[100037736]='Formulario de socio del Club de la "Cerveza del Mes"'
G[100037833]='Broche de rubíes'
G[100038280]='Cerveza temible de Cerveza Temible'
G[100038321]='Mojo extraño'
G[100038567]='Manifiesto de prisionero Maraudine'
G[100038660]='Gargantilla sin vida'
G[100038673]='Gargantilla aviesa'
G[100040666]='Nota del Almirante general'
G[100041267]='Tarjeta de acceso de CHATARR-A'
G[100041556]='Metal cubierto de escoria'
G[100042203]='Placa de armadura oscura'
G[100042772]='"Cómo construir un gigante de carne mejor" del Dr. Terrible'
G[100043242]='Fragmentos dentados'
G[100043297]='Collar dañado'
G[100043512]='Hongo cubierto de moco'
G[100043876]='Una guía para rebuscar tela del norte'
G[100044148]='Baraja de Magos'
G[100044158]='Baraja de Demonios'
G[100044259]='Baraja de Prismas'
G[100044276]='Baraja de Caos'
G[100044294]='Baraja de No-muertos'
G[100044326]='Baraja de Nobles'
G[100044569]='Llave del Iris de enfoque'
G[100044577]='Llave heroica del Iris de enfoque'
G[100044725]='Esquirla de siemprescarcha'
G[100044927]='Llave maestra de corruptor'
G[100044979]='Órdenes de sobrestante'
G[100045040]='Llave de jaula de torturador Rompelanzas'
G[100045506]='Disco de datos de El Archivum'
G[100045858]='Caña de pescar de la suerte de Nat'
G[100046004]='Vial de veneno sellado'
G[100046052]='Código de respuesta Alfa'
G[100046128]='Talismán trol'
G[100046318]='Misiva de Grito Infernal'
G[100046544]='Cachorro wolvar curioso'
G[100046545]='Prole de Oráculo curiosa'
G[100046856]='Llaves del bólido'
G[100046955]='Diente de Kraken'
G[100047039]='Órdenes de explorador'
G[100048679]='Receta encharcada'
G[100049010]='Oreja del clan Filo Ardiente'
G[100049200]='Batería infernal'
G[100049643]='Cabeza de Onyxia'
G[100049676]='Planes de ataque Kvaldir'
G[100049776]='Diseños de carretera'
G[100049932]='Ídolo de jabalí tallado'
G[100050320]='Tarjeta preciosa descolorida'
G[100050379]='Empuñadura maltrecha'
G[100051315]='Cofre sellado'
G[100052079]='Una carta Escarlata'
G[100052197]='Figurilla: pantera demoníaca'
G[100052843]='Piedra rúnica enana'
G[100053053]='Mapa del tesoro ajado'
G[100054345]='Mapa del tesoro arrugado'
G[100054614]='Perla luminiscente'
G[100054639]='Diario encharcado'
G[100055166]='Pellejo de yeti prístino'
G[100055167]='Pellejo de yeti perfecto'
G[100055181]='Carta de orco ilegible'
G[100055186]='Collar de Lady La-La'
G[100055243]='Núcleo de oleada de inundación'
G[100056474]='Órdenes del campamento base'
G[100056571]='Huevo de anguila enorme'
G[100056836]='Jarra de la Fiesta de la Cerveza púrpura repleta'
G[100057102]='Llave de jaula Crepuscular'
G[100057935]='Corazón de vigía de la cosecha'
G[100058117]='Pañuelo rojo'
G[100058491]="Mano Mosh'Ogg desfigurada"
G[100058898]='Pergamino manchado'
G[100059143]='Moneda deteriorada por el tiempo'
G[100060816]='Investigación de Maziel'
G[100060956]='Segunda cabeza de Korok'
G[100061378]='Misiva de la baronesa'
G[100061505]='Cabeza parcialmente digerida'
G[100062021]='Baraja de Volcanes'
G[100062044]='Baraja de Tsunamis'
G[100062045]='Baraja de Huracanes'
G[100062046]='Baraja de Terremotos'
G[100062056]='Documentos falsificados'
G[100062138]='Cabeza de Gnash'
G[100062281]='Inscripciones élficas antiguas'
G[100062483]='Comunicador A.I.D.A.'
G[100062768]='Excavaciones fructíferas'
G[100062933]='Almohada de la ayudante de cámara Pilaprieta'
G[100063090]='Aleta de Branquimugre'
G[100063127]='Pergamino de Altonato'
G[100063128]='Tablilla trol'
G[100063250]='La Batalla por Trabalomas'
G[100063686]='Planes de ataque Espinadaga'
G[100063700]='Cabeza de Myzerian'
G[100064353]='Frasco vacío de aguardiente'
G[100064397]="Jeroglífico Tol'vir"
G[100064450]='Escrituras del heraldo oscuro'
G[100065894]='Figurilla: búho onírico'
G[100065895]='Figurilla: rey de los jabalíes'
G[100065896]='Figurilla: serpiente con joyas'
G[100065897]='Figurilla: guardián terráneo'
G[100069854]='Guardapelo manchado de humo'
G[100071635]='Cristal infundido'
G[100071636]='Huevo monstruoso'
G[100071637]='Grimorio misterioso'
G[100071638]='Arma ornamentada'
G[100071715]='Un tratado sobre estrategia'
G[100071716]='Runas de veritas'
G[100071951]='Estandarte de los Caídos'
G[100071952]='Insignia recogida'
G[100071953]='Diario de aventurero caído'
G[100074642]='Filete de tigre a la brasa'
G[100074643]='Zanahorias salteadas'
G[100074644]='Sopa de niebla espiral'
G[100074645]='Pescado de Flor Eterna'
G[100074647]='Revuelto del valle'
G[100074649]='Tortuga estofada'
G[100074651]='Empanadillas de gambas'
G[100074652]='Salmón de espíritu de fuego'
G[100074654]='Ave silvestre asada'
G[100074655]='Fuente de peces gemelos'
G[100077957]='Misiva Crepuscular urgente'
G[100078960]='Huevo de dragón verde'
G[100078961]='Huevo de dragón amarillo'
G[100078962]='Huevo de dragón azul'
G[100079264]='Fragmento de rubí'
G[100079265]='Pluma azul'
G[100079266]='Gato de jade'
G[100079267]='Manzana preciosa'
G[100079268]='Lirio de marisma'
G[100079323]='Baraja del Tigre'
G[100079326]='Baraja del Dragón'
G[100080240]='Piedra esférica extraña'
G[100080241]='Recuerdo de Zarpa Lanuda'
G[100080827]='Mapa del tesoro confuso'
G[100082870]='Reliquia extraña'
G[100083767]='Caparazón de Krosh'
G[100083769]='Entre el saurok y la pared'
G[100083770]='Hozen en la niebla'
G[100083771]='Cuentos de peces'
G[100083772]='El corazón oscuro de los mogu'
G[100083773]='Corazón del enjambre mántide'
G[100083774]='Por qué merece la pena luchar'
G[100083777]='La canción de los yaungol'
G[100083779]='Las siete cargas de Shaohao'
G[100083780]='La balada de Liu Lang'
G[100085477]='Moneda mogu prístina'
G[100085557]='Juego de té pandaren prístino'
G[100085558]='Tablero de juego prístino'
G[100085783]='Cabeza del capitán Jack'
G[100086404]='Mapa antiguo'
G[100086425]='Campana de escuela de cocina'
G[100086433]='Collar bonito'
G[100086434]='Tiara distinguida'
G[100086435]='Pendiente exquisito'
G[100086436]='Broche hermoso'
G[100086542]='Gurami tigre volador'
G[100086544]='Pez espinoso alfa'
G[100086545]='Pulpo imitador'
G[100087871]='Núcleo de kyparita macizo'
G[100087878]='Mandíbulas de kunchong enormes'
G[100088715]='Cenizas del señor de la guerra Gurthan'
G[100089155]='Huevo de ónice'
G[100089169]='Esposas de rebelión prístinas'
G[100089170]='Piedra rúnica mogu prístina'
G[100089171]='Brazo de terracota prístino'
G[100089172]='Látigo de huesos petrificado prístino'
G[100089173]='Insignia del Rey del Trueno prístina'
G[100089174]='Edictos del Rey del Trueno prístinos'
G[100089175]='Amuleto de hierro prístino'
G[100089176]='Hierro de marcar prístino'
G[100089178]='Jarras gemelas prístinas'
G[100089179]='Bastón para caminar prístino'
G[100089180]='Barril vacío prístino'
G[100089181]='Espejo de bronce tallado prístino'
G[100089182]='Figurilla taraceada en oro prístina'
G[100089183]='Tarros de boticario prístinos'
G[100089184]="Perla de Yu'lon prístina"
G[100089185]='Confalón de Niuzao prístino'
G[100089209]='Libro mayor de monumentos prístino'
G[100089317]='Garra de ira'
G[100089812]='Sistema de irrigación "Princesa Jinyu"'
G[100089813]='Pesticidas "Rey del Trueno"'
G[100089814]='Arado maestro "Abretierras"'
G[100091819]='Cepo para grullas robusto'
G[100091821]='Trampa para tigres robusta'
G[100091822]='Cajón robusto de cangrejo'
G[100092441]='El códice de Xerrath'
G[100094721]='Lingote de metal extraño'
G[100095383]='Estandarte prístino del Imperio mántido'
G[100095384]='Alimentador de savia antiguo prístino'
G[100095385]='Mántide religiosa prístina'
G[100095386]='Baliza de sonido prístina'
G[100095387]='Restos de un dechado prístinos'
G[100095388]='Lámpara mántide prístina'
G[100095389]='Recolector de polen prístino'
G[100095390]='Contenedor de savia kypari prístino'
G[100097979]='El Oso y la Doncella'
G[100097982]='Vial de moco rojizo'
G[100097985]='Viejo robot polvoriento'
G[100097986]='Hoja de tierra de maestro de excavación'
G[100097988]='Piedra cubierta de papel'
G[100102225]='Enigma de Rolo'
G[100104257]='Huevo de tormenta de Fuego prístino'
G[100104264]='Pata de grulla carnosa'
G[100104265]='Carne de gran tortuga'
G[100104266]='Costillar de yak pesado'
G[100104267]='Anca de tigre gruesa'
G[100109121]='Rollo de cuerda resistente'
G[100109258]='Taller de ingeniería, nivel 1'
G[100111812]='Laboratorio de alquimia, nivel 1'
G[100111813]='La forja, nivel 1'
G[100111814]='Tenderete de gemas, nivel 1'
G[100111815]='Dependencias del escriba, nivel 1'
G[100111816]='Emporio de sastrería, nivel 1'
G[100111817]='Estudio de encantamiento, nivel 1'
G[100111818]='La peletería, nivel 1'
G[100112378]='Vaina roja resplandeciente'
G[100113080]='Núcleo de magma'
G[100113103]='Frasco misterioso'
G[100113107]='Flecha de Rangari'
G[100113109]='Hacha Lobo Gélido'
G[100113448]='Trozo de señor de cráter'
G[100113453]='Champiñón precioso'
G[100113461]='Escama fulgurante'
G[100114037]='Cristal elemental'
G[100114054]='Llave de Dedo Dorado'
G[100114877]='Nota sucia'
G[100114965]='Martillo de forja fracturado'
G[100114972]='Escrito de sastrería críptico'
G[100114973]='Kit de sastre Lobo Gélido'
G[100114984]='Cartera misteriosa'
G[100115008]='Brazal de Ogrópolis encantado'
G[100115278]='Transpondedor de ubicación gnómico'
G[100115281]='Brazal de Ogrópolis encantado'
G[100115287]='Colgante carmesí intrincado'
G[100115343]='Cartera de Haephest'
G[100115467]='Escrito sobre Piel de corteza'
G[100115507]='Fragmento de cristal drenado'
G[100115517]='Tabardo de la Vanguardia de Wrynn'
G[100115593]='Notas manchadas de hollín ilegibles'
G[100116120]='Comida de Talador sabrosa'
G[100116159]='Zarcillo verde avieso'
G[100116173]='Embozo Lobo Gélido andrajoso'
G[100116438]='Cañón de mano quemado'
G[100119208]='Arcanum del Profeta'
G[100119317]='Brote curioso'
G[100122224]='Rollo de música: Mountains'
G[100122226]='Rollo de música: Magic'
G[100122239]='Rollo de música: Shalandis Isle'
G[100122399]='Misiva de exploración: Magnarok'
G[100122401]='Misiva de exploración: Acantilados Rocafuria'
G[100122404]='Misiva de exploración: Fronda del Vergel'
G[100122406]='Misiva de exploración: Factoría de Hierro'
G[100122407]='Misiva de exploración: Skettis'
G[100122409]='Misiva de exploración: Pilares del Destino'
G[100122412]='Misiva de exploración: Puerto de Shattrath'
G[100122414]='Misiva de exploración: Velo Perdido de Anzu'
G[100122415]='Misiva de exploración: Alto de Socrethar'
G[100122417]='Misiva de exploración: Nidal Marea Oscura'
G[100122420]='Misiva de exploración: Terreno de Pruebas Goriano'
G[100122422]="Misiva de exploración: Puesto de Vigilancia Mok'gol"
G[100122423]='Misiva de exploración: Despeñadero Quebrado'
G[100126950]='Plano de equipo: Bomba de pantoque'
G[100127989]='Manifiesto encharcado'
G[100128231]='Plano de equipo: Tanque de tiburones adiestrados'
G[100128232]='Plano de equipo: Luces antiniebla de alta intensidad'
G[100128250]='Plano de equipo: Insumergible'
G[100128252]='Plano de equipo: Timón de verahierro'
G[100128255]='Plano de equipo: Rompehielos'
G[100128256]='Plano de equipo: Estabilizador interno giroscópico'
G[100128257]='Plano de equipo: Catalejo fantasmal'
G[100128258]='Plano de equipo: Lanzadores de humo vil'
G[100128491]='Plano de equipo: Red de pesca colmillarr'
G[100129747]='Vial turbulento distorsionado por el tiempo'
G[100129928]='Prisma gélido distorsionado por el tiempo'
G[100133377]='Ascua humeante distorsionada por el tiempo'
end

--	End of localized NPC names
