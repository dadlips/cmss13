//There has to be a better way to define this shit. ~ Z
//can't equip anything
/mob/living/carbon/Xenomorph/attack_ui(slot_id)
	return

/mob/living/carbon/Xenomorph/attack_animal(mob/living/M as mob)

	if(isanimal(M))
		var/mob/living/simple_animal/S = M
		if(!S.melee_damage_upper)
			S.emote("[S.friendly] [src]")
		else
			M.animation_attack_on(src)
			M.flick_attack_overlay(src, "punch")
			visible_message(SPAN_DANGER("[S] [S.attacktext] [src]!"), null, null, 5)
			var/damage = rand(S.melee_damage_lower, S.melee_damage_upper)
			apply_damage(damage, BRUTE)
			S.attack_log += text("\[[time_stamp()]\] <font color='red'>attacked [src.name] ([src.ckey])</font>")
			attack_log += text("\[[time_stamp()]\] <font color='orange'>was attacked by [S.name] ([S.ckey])</font>")
			updatehealth()

/mob/living/carbon/Xenomorph/attack_paw(mob/living/carbon/monkey/M as mob)
	if(!ismonkey(M)) //Fix for aliens receiving double messages when attacking other aliens
		return 0

	..()

	switch(M.a_intent)

		if("help")
			help_shake_act(M)
		else
			if(istype(wear_mask, /obj/item/clothing/mask/muzzle))
				return 0
			if(health > 0)
				M.animation_attack_on(src)
				M.flick_attack_overlay(src, "punch")
				playsound(loc, 'sound/weapons/bite.ogg', 25, 1)
				visible_message(SPAN_DANGER("\The [M] bites \the [src]."), \
				SPAN_DANGER("You are bit by \the [M]."), null, 5)
				apply_damage(rand(1, 3), BRUTE)
				updatehealth()


/mob/living/carbon/Xenomorph/attack_hand(mob/living/carbon/human/M)

	..()
	M.next_move += 7 //Adds some lag to the 'attack'. This will add up to 10
	switch(M.a_intent)

		if("help")
			if(stat == DEAD)
				M.visible_message(SPAN_WARNING("\The [M] pokes \the [src], but nothing happens."), \
				SPAN_WARNING("You poke \the [src], but nothing happens."), null, 5)
			else
				M.visible_message(SPAN_WARNING("\The [M] pokes \the [src]."), \
				SPAN_WARNING("You poke \the [src]."), null, 5)

		if("grab")
			if(M == src || anchored)
				return 0

			M.start_pulling(src)

		else
			var/datum/unarmed_attack/attack = M.species.unarmed
			if(!attack.is_usable(M)) attack = M.species.secondary_unarmed
			if(!attack.is_usable(M))
				return 0

			M.animation_attack_on(src)
			M.flick_attack_overlay(src, "punch")

			var/damage = rand(1, 3)
			if(prob(85))
				if(HULK in M.mutations)
					damage += 5
					spawn(0)
						step_away(src, M, 15)
						sleep(3)
						step_away(src, M, 15)
				damage += attack.damage > 5 ? attack.damage : 0

				playsound(loc, attack.attack_sound, 25, 1)
				visible_message(SPAN_DANGER("[M] [pick(attack.attack_verb)]ed [src]!"), null, null, 5)
				apply_damage(damage, BRUTE)
				updatehealth()
			else
				playsound(loc, attack.miss_sound, 25, 1)
				visible_message(SPAN_DANGER("[M] tried to [pick(attack.attack_verb)] [src]!"), null, null, 5)

	return

//Hot hot Aliens on Aliens action.
//Actually just used for eating people.
/mob/living/carbon/Xenomorph/attack_alien(mob/living/carbon/Xenomorph/M)
	if (M.fortify || M.burrow)
		return 0

	if(src != M)
		if(isXenoLarva(M)) //Larvas can't eat people
			M.visible_message(SPAN_DANGER("[M] nudges its head against \the [src]."), \
			SPAN_DANGER("You nudge your head against \the [src]."))
			return 0

		switch(M.a_intent)
			if("help")
				if(on_fire)
					extinguish_mob(M)
				else
					M.visible_message(SPAN_NOTICE("\The [M] caresses \the [src] with its scythe-like arm."), \
					SPAN_NOTICE("You caress \the [src] with your scythe-like arm."), null, 5)

			if("grab")
				if(M == src || anchored)
					return 0

				if(Adjacent(M)) //Logic!
					M.start_pulling(src)

					M.visible_message(SPAN_WARNING("[M] grabs \the [src]!"), \
					SPAN_WARNING("You grab \the [src]!"), null, 5)
					playsound(loc, 'sound/weapons/thudswoosh.ogg', 25, 1, 7)

			if("hurt")//Can't slash other xenos for now. SORRY  // You can now! --spookydonut
				M.animation_attack_on(src)
				if(hivenumber == M.hivenumber)
					M.visible_message(SPAN_WARNING("\The [M] nibbles \the [src]."), \
					SPAN_WARNING("You nibble \the [src]."), null, 5)
					return 1
				else
					// copypasted from attack_alien.dm
					//From this point, we are certain a full attack will go out. Calculate damage and modifiers
					var/damage = rand(M.melee_damage_lower, M.melee_damage_upper)

					//Frenzy auras stack in a way, then the raw value is multipled by two to get the additive modifier
					if(M.frenzy_aura > 0)
						damage += (M.frenzy_aura * 2)

					//Somehow we will deal no damage on this attack
					if(!damage)
						playsound(M.loc, 'sound/weapons/alien_claw_swipe.ogg', 25, 1)
						M.visible_message(SPAN_DANGER("\The [M] lunges at [src]!"), \
						SPAN_DANGER("You lunge at [src]!"), null, 5)
						return 0

					M.visible_message(SPAN_DANGER("\The [M] slashes [src]!"), \
					SPAN_DANGER("You slash [src]!"), null, 5)
					src.attack_log += text("\[[time_stamp()]\] <font color='orange'>was slashed by [M.name] ([M.ckey])</font>")
					M.attack_log += text("\[[time_stamp()]\] <font color='red'>slashed [src.name] ([src.ckey])</font>")
					log_attack("[M.name] ([M.ckey]) slashed [src.name] ([src.ckey])")

					M.flick_attack_overlay(src, "slash")
					playsound(loc, "alien_claw_flesh", 25, 1)
					apply_damage(damage, BRUTE)

			if("disarm")
				M.animation_attack_on(src)
				M.flick_attack_overlay(src, "disarm")
				if(!(isXenoQueen(M)) || M.hivenumber != src.hivenumber)
					playsound(loc, 'sound/weapons/thudswoosh.ogg', 25, 1)
					M.visible_message(SPAN_WARNING("\The [M] shoves \the [src]!"), \
					SPAN_WARNING("You shove \the [src]!"), null, 5)
					if(ismonkey(src))
						KnockDown(8)
				else
					playsound(loc, 'sound/weapons/alien_knockdown.ogg', 25, 1)
					M.visible_message(SPAN_WARNING("\The [M] shoves \the [src] out of her way!"), \
					SPAN_WARNING("You shove \the [src] out of your way!"), null, 5)
					src.KnockDown(1)
		return 1
