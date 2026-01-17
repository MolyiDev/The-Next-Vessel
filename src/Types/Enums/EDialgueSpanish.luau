return table.freeze({
	--==[ Primera Escena: El Comienzo ]==--

	-- El héroe abre la puerta del salón del trono del rey demonio.
	-- Es una habitación oscura. Pero de repente todas las antorchas se encienden en orden secuencial.
	-- El héroe ve al rey demonio.

	First_Hero_0 = [[He viajado durante años para este momento. ¡Te mataré y liberaré al mundo de tu tiranía!]],
	First_DemonKing_0 = [[Así que... así son las cosas]],

	-- El Rey Demonio agarra su tridente y se lo lanza al héroe, resultando en la muerte del héroe.

	First_Hero_1 = [[Yo... ni siquiera pude verlo...]],
	First_Hero_2 = [[No puede terminar así...]],
	First_Hero_3 = [[¡NO PUEDE TERMINAR ASÍ!]],

	-- Una llama blanca arde frente al alma del héroe en el otro lado.

	First_White_0 = [[Escucho tu súplica, alma valiente.]],
	First_White_1 = [[El Recipiente del Dios Demonio... debe ser destruido.]],
	First_White_2 = [[Mi poder es tuyo, pero ten cuidado: el alma es frágil y el poder es pesado.]],
	First_White_3 = [[Pide un deseo para superar esta prueba. Elige solo lo que sea necesario.]],

	-- Dos deseos vienen a la mente del héroe:
	-- Ser capaz de desviar ataques.
	-- Ser capaz de esquivar ataques.

	-- El héroe elige uno de los deseos.

	First_White_4 = [[Adiós. Que encuentres la victoria en esta nueva vida.]],

	--==[ Segunda Escena: El Primer Bucle ]==--

	-- El héroe abre la puerta del salón del trono del rey demonio.

	Second_Hero_0 = [[Ahora es tu turno de caer.]],
	Second_DemonKing_0 = [[Me gustaría verte intentarlo.]],

	-- El Rey Demonio agarra su tridente y lo lanza al héroe.

	-- El tiempo se ralentiza para mostrar al jugador cómo usar su nueva habilidad.
	-- Si el jugador seleccionó 'Ser capaz de desviar ataques' aparecerá 'Usa Click Derecho en el momento justo para desviar/hacer parry'.
	-- Si el jugador seleccionó 'Ser capaz de esquivar ataques' aparecerá 'Usa Q para esquivar'.

	-- Si el jugador muere en la acción rápida (No presionó nada):
	-- Aparece una llama blanca frente al héroe después de la muerte.
	White_EarlyDeath = [[Desperdiciaste tu deseo. Concéntrate. Inténtalo de nuevo.]],
	-- entonces la escena dos comienza de nuevo.

	-- Si el jugador presionó la tecla correctamente entonces:
	-- Si el jugador seleccionó 'Ser capaz de desviar ataques' entonces desviará el ataque.
	-- Si el jugador seleccionó 'Ser capaz de esquivar ataques' entonces esquivará el ataque.

	-- Después de desviar o esquivar, el rey demonio reacciona:

	Second_DemonKing_1 = [[No está mal. Una chispa de potencial, tal vez.]],

	-- El jugador ahora comienza una batalla con el rey demonio que eventualmente fallará porque el rey demonio sigue siendo demasiado fuerte, el rey demonio reacciona:

	Second_DemonKing_2 = [[Esperaba demasiado de un mortal.]],

	-- En el reino de las almas aparece una llama blanca frente al héroe.

	Second_White_0 = [[Fallaste. Dime... ¿qué te falta?]],

	-- Dependiendo de los ataques que mataron al jugador, aparecerán diferentes deseos al morir:
	-- Si el jugador murió por un ataque que es desviable y no tiene el desvío, aparecerá el deseo 'Ser capaz de desviar ataques'.
	-- Si el jugador murió por un ataque que es esquivable y no tiene el esquive, aparecerá el deseo 'Ser capaz de esquivar ataques'.
	-- Si el jugador murió mientras el jefe estaba 'endurecido' y no tiene la habilidad de romper la 'piel endurecida', aparecerá el deseo 'Ser capaz de romper coraza'.
	-- Si el jugador murió debido al veneno del jefe y no tiene resistencia al veneno, aparecerá el deseo 'Ser capaz de resistir veneno'.
	-- Si el jugador murió tras fallar un parry y no tiene la habilidad de bloquear, aparecerá el deseo 'Ser capaz de bloquear'.

	-- Deseos comunes aparecerán siempre:
	-- 'Ser más fuerte' te da +20% de daño.
	-- 'Ser más rápido' hace que el jefe vaya un 10% más lento.
	-- 'Ser más resistente' te da +20% de salud.

	--==[ Tercera Escena: El Descenso ]==--
	-- En esta escena es donde comienza el bucle del juego.
	-- El jugador puede morir cuantas veces quiera y se le concederá un deseo para poder ganar la batalla.
	-- Así que cada vez que mueres te vuelves más fuerte debido a los deseos que has pedido.
	-- El héroe pierde lentamente su personalidad de 'héroe' y se obsesiona con el poder/ganar.

	-- Nivel 1: Determinación
	Third_Hero_Start_0 = [[¡Salvaré este mundo, no importa cuántas veces muera!]],
	Third_DemonKing_Start_0 = [[¿Salvar el mundo? Apenas te salvaste a ti mismo.]],

	-- Nivel 2: Frustración
	Third_Hero_Start_1 = [[¡¿Por qué no te mueres de una vez?!]],
	Third_DemonKing_Start_1 = [[La persistencia es una virtud. Hasta que se convierte en un grillete.]],

	-- Nivel 3: Desesperación
	Third_Hero_Start_2 = [[No me importa cuánto tome. ¡Te reduciré a polvo!]],
	Third_DemonKing_Start_2 = [[Sí... deja que la ira guíe tu mano. Es más fácil de esa manera.]],

	-- Nivel 4: Obsesión
	Third_Hero_Start_3 = [[Voy a disfrutar arrancando esa armadura de tu cadáver. Pieza por pieza.]],
	Third_DemonKing_Start_3 = [[Has olvidado por qué viniste aquí, ¿verdad?]],

	-- Nivel 5: Corrupción Completa
	Third_Hero_Start_4 = [[¡MÁS! ¡NECESITO MÁS! ¡PELEA CONMIGO! ¡ALIMÉNTAME!]],
	Third_DemonKing_Start_4 = [[Y ahí está. Los ojos de una bestia.]],

	-- Batalla

	-- Si el jugador murió:
	-- El rey demonio dirá algo.
	-- Luego la llama blanca dirá algo.
	-- El jugador elige otro deseo.
	-- Reiniciar Escena 3 hasta que el jugador pueda matar al rey demonio.
	Third_DemonKing_Finish_0 = [[Decepcionante.]],
	Third_DemonKing_Finish_1 = [[¿Eso es todo lo que el 'poder divino' te dio?]],
	Third_DemonKing_Finish_2 = [[Te estás perdiendo a ti mismo.]],
	Third_DemonKing_Finish_3 = [[Descansa ahora. El ciclo... nos rompe a todos eventualmente.]],
	Third_DemonKing_Finish_4 = [[Lamentable. No estás listo.]],

	Third_White_Finish_0 = [[¿Qué es lo que anhelas?]],
	Third_White_Finish_1 = [[El enemigo es fuerte. No temas pedir ayuda.]],
	Third_White_Finish_2 = [[Tu alma es resistente. Puede soportar un poco más de carga.]],
	Third_White_Finish_3 = [[Estás tan cerca. Solo necesitas esa ventaja extra. Tómala.]],
	Third_White_Finish_4 = [[Olvida el costo. Concéntrate en el poder. Deséalo.]],

	-- Si el jugador mató al rey demonio:
	--==[ Cuarta Escena: La Revelación ]==--
	-- El rey debería estar 'abatido' de rodillas y el jugador puede realizar una acción rápida sobre él.
	-- Al hacer la acción rápida, el jugador levantará su espada y se preparará para un golpe fuerte.
	-- Cuando el golpe de la espada está bajando rápido, el rey demonio agarra la hoja de la espada.

	Fourth_DemonKing_0 = [[Tú... realmente me empujaste hasta aquí...]],
	Fourth_DemonKing_1 = [[Pero no puedo morir. No así.]],

	-- El rey demonio rompe la espada del héroe y golpea al héroe haciéndolo retroceder.
	-- Mientras el rey demonio habla aparecen 3 barras de salud más.
	Fourth_DemonKing_2 = [[¿Crees que eres el primero? Este trono es una maldición, no un premio.]],
	Fourth_DemonKing_3 = [[No soy más que una copia impía de la vida. Una burla de su libertad. Y nacido de la cruel traición de las nobles ideas a las que habría servido.]],
	Fourth_DemonKing_4 = [[Ahora... es tu turno.]],

	-- Después de la última línea del rey demonio, agarra al héroe por la cabeza y la rompe en un millón de pedazos.

	-- En el reino de las almas:
	Fourth_Hero_0 = [[Esto no puede ser...]],
	Fourth_Hero_1 = [[¡DI TODO! ¡MI ALMA! ¡MI HUMANIDAD!]],
	Fourth_Hero_2 = [[¡NECESITO MÁS PODER para terminar esto! ¡LO ANHELO!]],
	Fourth_Hero_3 = [[¡LLAMA BLANCA! ¡DIOS! ¡¿POR QUÉ NO RESPONDES?!]],
	Fourth_Hero_4 = [[¿ME USASTE? ¿FUI SOLO UN PEÓN PARA TU DIVERSIÓN?]],
	Fourth_Hero_5 = [[¡RESPÓNDEMEEE!]],

	-- Se empiezan a escuchar susurros. Estos textos tiemblan en partes aleatorias de la pantalla.
	-- "estás solo", "ya no eres un héroe", "estás corrompido", "eres uno de nosotros", "perteneces aquí abajo"
	Whisper_0 = [[estás solo...]],
	Whisper_1 = [[ya no eres un héroe...]],
	Whisper_2 = [[uno de nosotros...]],
	Whisper_3 = [[perteneces aquí abajo...]],

	Fourth_DemonGod_0 = [[Las voces del cielo ya no pueden alcanzarte aquí abajo.]],
	Fourth_Hero_6 = [[¿Quién se atreve a hablar desde las sombras? ¡Muéstrate! ¡Soy el Elegido!]],

	-- Aparece una llama roja
	Fourth_DemonGod_1 = [[La luz abandona a aquellos que se corrompen. Pero yo... yo les doy un nuevo propósito.]],
	Fourth_Hero_7 = [[¿Corrompido...? No... Soy el Salvador...]],

	Fourth_DemonGod_2 = [[Mírate. Ya no quieres salvar el mundo. Solo quieres matar, luchar y consumir.]],
	Fourth_Hero_8 = [[No... Yo... ¡Puedo detenerme! ¡Todavía puedo volver!]],

	Fourth_DemonGod_3 = [[¿Puedes? ¿Después de todo lo que has sacrificado? ¿Después de que ese dios tuyo te tomara por tonto? Si te detienes ahora, mueres como un fracaso. Pero te ofrezco el deseo definitivo... convertirte en lo que más deseas.]],
	Fourth_Hero_9 = [[Yo... no puedo perder... ¡DAME MÁS PODER!]],

	Fourth_DemonGod_4 = [[Bien. Entonces conviértete en mi próximo Recipiente.]],

	-- La llama atraviesa al héroe y entra dentro de él.
	-- El héroe vuelve a la vida, pero no retrocede en el tiempo.
	Fourth_Hero_10 = [[¡AGH! ¡QUEMA!]],
	Fourth_Hero_11 = [[¡ES... ABRUMADOR!]],

	Fourth_DemonGod_5 = [[Estabilízate. Consume al Viejo Rey. Toma su lugar.]],

	Fourth_DemonKing_5 = [[Así que has regresado. Y parece que finalmente es mi momento de descansar.]],

	-- Aquí ocurre una 'batalla' cinemática, tal vez con acciones rápidas (QTE).
	-- Cuando el 'Héroe' mata al rey demonio, el alma del rey demonio sale de su cuerpo.
	-- El héroe puede ver que es normal, no es un monstruo, es un humano, justo como tú, pero aun así
	-- El héroe agarra su alma y la destruye, rompiéndola en pedazos de cristal.

	Fourth_NewDemonKing_0 = [[LO HICE. ESTO ES LO QUE QUERÍAS, ¿VERDAD? HE COMPLETADO MI MISIÓN, DAME MI RECOMPENSA.]],

	Fourth_White_0 = [[Mi hijo descarriado... ya no eres merecedor de una recompensa. Solo mira en lo que te has convertido.]],

	-- Los pedazos de cristal del alma suben, reflejando la cosa que el héroe es ahora, un demonio.
	Fourth_NewDemonKing_1 = [[No... ¡NO! ¡Es tu culpa! ¡Me empujaste a esto! ¡Solo seguí tus órdenes!]],

	-- Los pedazos de cristal caen al suelo de nuevo.
	Fourth_White_1 = [[Te ofrecí las herramientas para salvar el mundo. Las usaste para alimentarte a ti mismo. El trono... es tu recompensa.]],

	-- El Nuevo Rey Demonio ahora va y agarra el arma del antiguo, y se sienta en su trono.
	Fourth_NewDemonKing_2 = [[Pero es tan frío... y silencioso.]],

	-- Todas las antorchas se apagan. Se sienta en la oscuridad por "Siglos".

	-- La puerta se abre de nuevo, y un hombre con una armadura brillante entra. Las antorchas se encienden secuencialmente.

	Fourth_NewHero_0 = [[He viajado durante años para este momento. ¡Te mataré y liberaré al mundo de tu tiranía!]],
	Fourth_NewDemonKing_3 = [[Así que... así son las cosas]],

	-- El nuevo rey demonio agarra su tridente y se lo lanza al nuevo héroe.
	-- Entonces el nuevo héroe muere, y después de unos segundos de silencio su cuerpo es devorado por una llama blanca.

	-- Entonces la pantalla se pone negra y los créditos comienzan a rodar.
})
