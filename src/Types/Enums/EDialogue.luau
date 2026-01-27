local EDialogue = {
	--==[ First Scene: The Beginning ]==--

	First_Hero_0 = [[I have traveled for <font color="rgb(255, 215, 0)">years</font> for this moment. <speed val="0.03">I will <font color="rgb(255, 50, 50)"><b>kill you</b></font> and free the world from your tyranny!</speed>]],
	First_DemonKing_0 = [[<speed val="0.1">So... this is how it is...</speed>]],

	First_Hero_1 = [[<speed val="0.2">I...</speed> I couldn't even see it...]],
	First_Hero_2 = [[It cannot end like this...]],
	First_Hero_3 = [[<speed val="0.02">IT CANNOT END LIKE THIS!</speed>]],

	First_White_Mech_0 = [[<pitch val="0.9">His guard is <font color="rgb(150, 150, 150)">impenetrable</font>. <speed val="0.1"><font color="rgb(255, 80, 80)">Survive for 5 minutes</font></speed>, and his guard will fall.</pitch>]],
	First_White_Mech_1 = [[<pitch val="0.9"><font color="rgb(255, 50, 50)"><b>Destroy</b></font> the <font color="rgb(0, 255, 255)">souls</font>.</pitch>]],
	First_White_Mech_2 = [[<pitch val="0.9">Gather enough, and you may <font color="rgb(255, 215, 0)"><b>Wish</b></font> for <font color="rgb(255, 50, 50)">power</font> without <font color="rgb(180, 0, 0)">making a sacrifice</font>.</pitch>]],

	First_White_0 = [[<pitch val="0.9">I hear your plea, <font color="rgb(255, 255, 200)">brave soul</font>.</pitch>]],
	First_White_1 = [[<pitch val="0.9">The <font color="rgb(150, 0, 150)">Vessel of the Demon God</font>... <speed val="0.06">it must be destroyed.</speed></pitch>]],
	First_White_2 = [[<pitch val="0.9">My power is yours, but be warned: the <font color="rgb(0, 255, 255)">soul</font> is fragile, and <font color="rgb(255, 50, 50)">power</font> is heavy.</pitch>]],
	First_White_3 = [[<pitch val="0.9">Make a wish to overcome this trial. Choose only what is <i>necessary</i>.</pitch>]],

	First_White_4 = [[<pitch val="0.9">Farewell. May you find <font color="rgb(255, 215, 0)">victory</font> in this new life.</pitch>]],

	--==[ Second Scene: The Descent ]==--

	-- Level 0: Determination
	Second_Hero_Start_0 = [[I will <font color="rgb(255, 215, 0)">save this world</font>, <speed val="0.03">no matter how many times I die!</speed>]],
	Second_DemonKing_Start_0 = [[<pitch val="0.95">Save the world? <speed val="0.08">You barely saved yourself.</speed></pitch>]],

	-- Level 1: Frustration
	Second_Hero_Start_1 = [[<speed val="0.03">Why won't you just <font color="rgb(255, 0, 0)"><b>die?!</b></font></speed>]],
	Second_DemonKing_Start_1 = [[<pitch val="0.95">Persistence is a virtue. Until it becomes a shackle.</pitch>]],

	-- Level 2: Desperation
	Second_Hero_Start_2 = [[I don't care how much it takes. <speed val="0.02">I will crush you to <font color="rgb(150, 150, 150)">dust!</font></speed>]],
	Second_DemonKing_Start_2 = [[<pitch val="0.95">Yes... let the anger guide your hand. It's easier that way.</pitch>]],

	-- Level 3: Obsession
	Second_Hero_Start_3 = [[<pitch val="1.05">I'm going to enjoy tearing that armor off your corpse. <speed val="0.08">Piece by Piece.</speed></pitch>]],
	Second_DemonKing_Start_3 = [[<pitch val="0.95">You have forgotten why you came here, haven't you?</pitch>]],

	-- Level 4: Complete Corruption
	Second_Hero_Start_4 = [[<pitch val="1.1"><speed val="0.02"><font color="rgb(180, 0, 0)">MORE! I NEED MORE! FIGHT ME! FEED ME!</font></speed></pitch>]],
	Second_DemonKing_Start_4 = [[<pitch val="0.95">And there it is. The eyes of a beast.</pitch>]],

	-- Level 5: Loop Dialogues
	Second_Hero_Start_5 = [[]],
	Second_DemonKing_Start_5 = [[]],

	-- Battle Finish
	Second_DemonKing_Finish_0 = [[<pitch val="0.95">Disappointing.</pitch>]],
	Second_DemonKing_Finish_1 = [[<pitch val="0.95">Is that all the '<font color="rgb(255, 255, 0)">divine power</font>' gave you?</pitch>]],
	Second_DemonKing_Finish_2 = [[<pitch val="0.95">You are losing yourself.</pitch>]],
	Second_DemonKing_Finish_3 = [[<pitch val="0.95">Rest now. The cycle... it breaks us all eventually.</pitch>]],
	Second_DemonKing_Finish_4 = [[<pitch val="0.95">Pitiful. You are not ready.</pitch>]],
	Second_DemonKing_Finish_5 = [[<pitch val="0.95">What a shame, after all that power you still cannot defeat me.</pitch>]],

	Second_White_Start_0 = [[<pitch val="0.9">What do you <font color="rgb(255, 0, 0)">crave</font>?</pitch>]],
	Second_White_Start_1 = [[<pitch val="0.9">The enemy is strong. Do not be afraid to ask for help.</pitch>]],
	Second_White_Start_2 = [[<pitch val="0.9">Your soul is resilient. It can handle a little more burden.</pitch>]],
	Second_White_Start_3 = [[<pitch val="0.9">You are so close. You just need that extra edge. <speed val="0.03">Take it.</speed></pitch>]],
	Second_White_Start_4 = [[<pitch val="0.9">Forget the cost. Focus on the <font color="rgb(255, 50, 50)">power</font>. <speed val="0.05">Wish for it.</speed></pitch>]],
	Second_White_Start_5 = [[...]],

	-- Missing Dialogues Added Here
	Second_White_Finish_0 = [[<pitch val="0.9">So be it. Let this power serve your will.</pitch>]],
	Second_White_Finish_1 = [[<pitch val="0.9">Wise. <font color="rgb(100, 100, 100)">Pride</font> is of no use to the dead.</pitch>]],
	Second_White_Finish_2 = [[<pitch val="0.9">Bear this weight. It will anchor you against the storm.</pitch>]],

	Second_White_Finish_3 = [[<pitch val="0.9">You cannot fail anymore.</pitch>]],
	Second_White_Finish_4 = [[<pitch val="0.9">See you on the other side.</pitch>]],
	Second_White_Finish_5 = [[...]],

	--==[ Third Scene: The Revelation ]==--

	Third_DemonKing_0 = [[<speed val="0.08">You... you actually pushed me this far...</speed>]],
	Third_DemonKing_1 = [[But I cannot die. <speed val="0.1">Not like this.</speed>]],

	Third_DemonKing_2 = [[<pitch val="0.92">Do you think you are the first? This throne is a <font color="rgb(150, 0, 0)">curse</font>, not a prize.</pitch>]],
	Third_DemonKing_3 = [[<pitch val="0.92">I am but an unholy copy of life. A mockery of its freedom.</pitch>]],
	Third_DemonKing_4 = [[<pitch val="0.92">Now... it is your turn.</pitch>]],

	Third_Hero_0 = [[<speed val="0.1">This cannot be...</speed>]],
	Third_Hero_1 = [[<speed val="0.02"><pitch val="1.1">I GAVE EVERYTHING! MY <font color="rgb(0, 255, 255)">SOUL</font>! MY <font color="rgb(255, 255, 0)">HUMANITY</font>!</pitch></speed>]],
	Third_Hero_2 = [[<speed val="0.02"><pitch val="1.15">I NEED MORE <font color="rgb(255, 0, 0)">POWER</font> to finish this! I CRAVE IT!</pitch></speed>]],
	Third_Hero_3 = [[<speed val="0.02"><pitch val="1.2">WHITE FLAME! GOD! WHY DO YOU NOT ANSWER?!</pitch></speed>]],
	Third_Hero_4 = [[<speed val="0.02"><pitch val="1.1">DID YOU USE ME? WAS I JUST A PAWN FOR YOUR AMUSEMENT?</pitch></speed>]],
	Third_Hero_5 = [[<speed val="0.01"><pitch val="1.3">ANSWER MEEEE!</pitch></speed>]],

	-- Whispers
	Whisper_0 = [[<flicker text="you are alone...|y..u .re .lo.e..." speed="0.1"><font color="rgb(100, 100, 100)">you are alone...</font></flicker>]],
	Whisper_1 = [[<flicker text="no longer a hero...|no lo..er a h.ro..." speed="0.15"><font color="rgb(100, 100, 100)">no longer a hero...</font></flicker>]],
	Whisper_2 = [[<flicker text="one of us...|o.e .f u..." speed="0.2"><font color="rgb(150, 0, 0)">one of us...</font></flicker>]],
	Whisper_3 = [[<flicker text="you belong down here...|y.u b.lo.g d.wn h.re..." speed="0.1"><font color="rgb(100, 100, 100)">you belong down here...</font></flicker>]],

	Third_DemonGod_0 = [[<pitch val="0.7"><speed val="0.08">The voices of the sky cannot longer reach you down here.</speed></pitch>]],
	Third_Hero_6 = [[Who dares speak from the shadows? <speed val="0.03">Show yourself! I am the <font color="rgb(255, 215, 0)">Chosen One!</font></speed>]],

	Third_DemonGod_1 = [[<pitch val="0.7">The light abandons those who corrupt. But I... <font color="rgb(100, 0, 150)">I give them a new purpose.</font></pitch>]],
	Third_Hero_7 = [[Corrupted...? No... <speed val="0.1">I am the <font color="rgb(255, 255, 255)">Savior</font>...</speed>]],

	Third_DemonGod_2 = [[<pitch val="0.7">Look at yourself. You don't want to save the world anymore. You just want to <font color="rgb(150, 0, 0)">kill, battle, and consume.</font></pitch>]],
	Third_Hero_8 = [[<speed val="0.05">No... I... I can stop! I can still go back!</speed>]],

	Third_DemonGod_3 = [[<pitch val="0.7">Can you? After all you've sacrificed? After that god of yours played you for a fool? If you stop now, you die a failure.</pitch>]],
	Third_Hero_9 = [[<speed val="0.03">I... I cannot lose... <font color="rgb(255, 0, 0)">GIVE ME MORE POWER!</font></speed>]],

	Third_DemonGod_4 = [[<pitch val="0.7">Good. Then become my next <font color="rgb(100, 0, 255)"><b>Vessel</b></font>.</pitch>]],

	Third_Hero_10 = [[<speed val="0.02"><pitch val="1.3">AGH! <font color="rgb(255, 50, 0)">IT BURNS!</font></pitch></speed>]],
	Third_Hero_11 = [[<speed val="0.02"><pitch val="1.3">IT'S... OVERWHELMING!</pitch></speed>]],

	Third_DemonGod_5 = [[<pitch val="0.7">Stabilize yourself. <font color="rgb(150, 0, 0)">Consume the Old King.</font> Take his place.</pitch>]],

	Third_DemonKing_5 = [[<pitch val="0.9">So, you've returned. And it seems that it's finally my time to rest.</pitch>]],

	Third_NewDemonKing_0 = [[<pitch val="1.1"><speed val="0.03">I DID IT. THIS IS WHAT YOU WANTED, RIGHT? I'VE COMPLETED MY MISSION, GIVE ME MY <font color="rgb(255, 215, 0)">REWARD</font>.</speed></pitch>]],

	Third_White_0 = [[<pitch val="0.9">My wayward son... you are no longer deserving of a reward. Just look at what you have become.</pitch>]],

	Third_NewDemonKing_1 = [[<pitch val="1.1"><speed val="0.03">No... NO! It's your fault! You pushed me to this! I only followed your orders!</speed></pitch>]],

	Third_White_1 = [[<pitch val="0.9">I offered you the tools to save the world. You used them to feed yourself. The <font color="rgb(100, 100, 100)">throne</font>... is your reward.</pitch>]],

	Third_NewDemonKing_2 = [[<pitch val="0.85"><speed val="0.1">But it is so <font color="rgb(0, 200, 255)">cold</font>... and silent.</speed></pitch>]],

	Third_NewHero_0 = [[I have traveled for <font color="rgb(255, 215, 0)">years</font> for this moment. I will <font color="rgb(255, 50, 50)">kill you</font> and free the world from your tyranny!]],
	Third_NewDemonKing_3 = [[<pitch val="0.85"><speed val="0.1">So... this is how it is...</speed></pitch>]],

	Third_NewDemonKing_4 = [[<pitch val="0.85">The <font color="rgb(255, 255, 255)">next vessel of god</font>... <speed val="0.08">it starts again.</speed></pitch>]],
}

return table.freeze(EDialogue)
