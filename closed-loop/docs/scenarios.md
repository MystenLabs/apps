# Closed Loop Scenarios

This document describes the possible applications of the closed loop token.

## Loyalty Points

It is common for loyalty points to be assigned to a customer's account after a purchase. The customer can then redeem these points for a discount on a future purchase. This is a closed loop system because the points can only be redeemed at the same merchant where they were earned.

Implementation steps for the merchant:

1. Initiate a new Closed Loop Token
2. Create a custom mint / burn applications for the token
3. The mint application defines the logic for how many points are awarded and under what conditions
4. The burn application defines the way of using the points (e.g. 100 points = $1 discount)

Public settings for the token:

- not transferable (loyalty points are gained per account)
- splittable (to perform purchases with partial amounts)
- mergeable (to combine points from multiple purchases into single balance)

## Gift Cards

A gift card is a fixed-value certificate that can be used as a payment method at a merchant. In a closed-loop economy, the gift card can only be used at the merchant that issued it and the values are defined by the merchant.

Implementation steps for the merchant:

1. Initiate a new Closed Loop Token
2. Create a custom functionality for purchasing the gift card
3. Create a custom functionality for redeeming the gift card

Public settings for the token:

- transferable (a gift card can be given to another person)
- not splittable (to prevent partial payments)
- not mergeable (to prevent combining multiple gift cards)

## Aggregate Campaigns

A group of merchants can implement a shared loyalty system where the points can be earned and redeemed at any of the participating merchants. The points gained at one merchant can be redeemed at another merchant or in a specified store.

Implementation steps for the campaign:

1. Initiate a new Closed Loop Token
2. Create custom resolvers for the mint functionality and authorize the participating merchants (configuring the value per operation and total)
3. Create a custom functionality for redeeming the points in one place or multiple places (depending on the campaign)

Public settings for the token:

- not transferable (may vary)
- splittable (to perform purchases with partial amounts)
- mergeable (to combine points from multiple merchants)

## Gems / in-Game Currency

A game can implement a closed loop token to be used as an in-game currency. The token can be used to purchase items in the game and can be earned by completing tasks or by purchasing it with real money.

Implementation steps for the game:

1. Initiate a new Closed Loop Token
2. Create a custom functionality for purchasing the token with real money. May use a custom resolver to hand it to the payment provider or use a custom functionality to handle the payment directly. The values can be defined by the game.
3. Create a custom functionality for redeeming the token for in-game items. The "burn" operation is defined by the game logic.

Public settings for the token:

- non transferable
- splittable (to perform purchases with partial amounts)
- mergeable (to aggregate the token from multiple sources)

## Scoring

Closed Loop Token can also be used for per-account scores in a game. Following a "snowball" pattern where experience or score is aggregated throughout the season / tournament and then depending on the value can be redeemed for a prize.

Implementation steps for the game:

1. Initiate a new Closed Loop Token
2. Create a custom functionality for awarding the token to the player. The values can be defined by the game.
3. Create a custom functionality for redeeming the token for a prize. The "burn" operation is defined by the game logic.

Public settings for the token:

- non transferable (score is gained per account)
- not splittable (score is consumed in full)
- mergeable (to grow a snowball)
