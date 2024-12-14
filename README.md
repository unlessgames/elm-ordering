# elm-ordering
Library that makes it easier to write comparison functions in Elm.

For instance, suppose you are defining a data type to represent
a standard deck of cards. You might define it as:

    type alias Card = { value : Value, suit : Suit }
    type Suit = Clubs | Hearts | Diamonds | Spades
    type Value = Two | Three | Four | Five | Six | Seven
               | Eight | Nine | Ten | Jack | Queen | King | Ace

With this representation, you could define an ordering for `Card` values compositionally:

    import Ordering exposing (Ordering)


    cardOrdering : Ordering Card
    cardOrdering =
        Ordering.byFieldWith suitOrdering .suit
            |> Ordering.breakTiesWith
                   (Ordering.byFieldWith valueOrdering .value)


    suitOrdering : Ordering Suit
    suitOrdering =
        Ordering.explicit [Clubs, Hearts, Diamonds, Spades]


    valueOrdering : Ordering Value
    valueOrdering =
        Ordering.explicit
            [ Two , Three , Four , Five , Six , Seven
            , Eight, Nine, Ten, Jack, Queen, King, Ace
            ]


You can then use this ordering to sort cards, make comparisons, and so on. For instance,
to sort a deck of cards you can use `cardOrdering` directly:

    sortCards : List Card -> List Card
    sortCards = List.sortWith cardOrdering
