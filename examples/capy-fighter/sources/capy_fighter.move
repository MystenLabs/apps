// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
///
///
module capy_fighter::capy_fighter {
    use suifrens::suifrens::{Self as sf, SuiFren};
    use suifrens::capy::Capy;
    use sui::bcs;

    /// The max number of hits is 4. We're splitting the 32-bit range into 5
    /// sections: [_1_] [_2_] [_3_] [_4_] 5
    /// The number of attacks performed in a single round is the SPEED / HIT_ROUND.
    const HIT_ROUND: u32 = 255 / 5;

    /// A stats for the Capy Fighter mini-game. Stats are defined based on the
    /// genes of the Capy. See the `stats` function for more details on how they
    /// are calculated.
    struct Stats has drop {
        /// Defines the attack power of the Capy.
        attack: u8,
        /// Defines the defense power of the Capy.
        defense: u8,
        /// Defines the speed of the Capy: the higher modifier may result in an
        /// additional "hit" during the fight.
        speed: u8,
        /// The health of the Capy. The higher - the more resistive the Capy is
        /// to attacks; who knows, the may be a Capy glass-cannon out there!
        health: u8,
    }

    /// Read stats from Capy genes.
    ///
    /// Uses BCS reader and treats the vector of genes as a BCS data. Given that
    /// it uses `u8` as the value parameter and the gene mechanics are using
    /// `u8`, inheritance in the `mixing` logic won't affect the Stats in a
    /// predictable way!
    public fun stats(fren: &SuiFren<Capy>): Stats {
        let bcs = bcs::new(*sf::genes(fren));
        let (attack, defense, speed, health) = (
            bcs::peel_u8(&mut bcs),
            bcs::peel_u8(&mut bcs),
            bcs::peel_u8(&mut bcs),
            bcs::peel_u8(&mut bcs),
        );

        Stats { attack, defense, speed, health }
    }

    /// Calculate the result of the fight between two Capys.
    ///
    /// The seed parameter should be randomized and provided by a third, not
    /// interested party, so that the fight is not favoring any of the players.
    public fun compete(
        capy1: &SuiFren<Capy>,
        capy2: &SuiFren<Capy>,
    ): bool {
        let (one, two) = (stats(capy1), stats(capy2));
        loop {
            if (!round(&mut one, &mut two)) {
                return false
            };

            if (!round(&mut two, &mut one)) {
                return true
            };
        }
    }

    /// Perform a single round of the fight.
    /// Returns `true` if the defender lost, true otherwise.
    public fun round(attacker: &mut Stats, defender: &mut Stats): bool {
        // attacker params
        let speed = (attacker.speed as u32);
        let attack = (attacker.attack as u32);

        // defender params
        let health = (defender.health as u32);
        let defense = (defender.defense as u32);

        // Formula: ATTACK * (ATTACK / DEFENSE * 100)
        // So that the Defense is decreasing the Attack power by a percentage.
        let hit_points = (attack * (attack * 100 / defense));

        // Max number of hits is 4. We're splitting the 32-bit range into 5 buckets
        // and the number of attacks performed in a single round is the SPEED / 5.
        let num_hits = speed / HIT_ROUND;

        // The health of the defender is decreased by the number of hits.
        if (health > (hit_points * num_hits)) {
            defender.health = ((health - (hit_points * num_hits)) as u8);
        } else {
            return false
        };

        true
    }


    #[test_only] use sui::tx_context;

    #[test]
    fun test_compete() {
        let ctx = &mut tx_context::dummy();
        let (capy2, capy1) = (
            sf::mint_for_testing(ctx),
            sf::mint_for_testing(ctx),
        );

        let result = compete(&capy1, &capy2);

        assert!(result == false, 0);

        sf::burn_for_testing(capy1);
        sf::burn_for_testing(capy2);
    }
}
