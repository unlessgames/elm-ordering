module Ordering
    exposing
        ( Ordering
        , natural
        , byToString
        , byFieldWith
        , byField
        , breakTiesWith
        , explicit
        , reverse
        , isOrdered
        , greaterThanBy
        , lessThanBy
        )

{-| Library for building comparison functions.

This library makes it easy to create comparison functions for arbitary types by composing
smaller comparison functions. For instance, suppose you are defining a data type to represent
a standard deck of cards. You might define it as:

    type alias Card = { value : Value, suite : Suite }
    type Suite = Clubs | Hearts | Diamonds | Spades
    type Value = Two | Three | Four | Five | Six | Seven
               | Eight | Nine | Ten | Jack | Queen | King | Ace

With this representation, you could define an ordering for `Card` values compositionally:

    import Ordering exposing (Ordering)


    cardOrdering : Ordering Card
    cardOrdering =
        Ordering.byFieldWith suiteOrdering .suite
            |> Ordering.breakTiesWith
                   (Ordering.byFieldWith valueOrdering .value)


    suiteOrdering : Ordering Suite
    suiteOrdering =
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

# Definition
@docs Ordering

# Construction
@docs natural, byToString, explicit, byField, byFieldWith

# Composition
@docs breakTiesWith, reverse

# Utility
@docs isOrdered, greaterThanBy, lessThanBy
-}


{-| A function that compares two values and returns whether
the first is less than, equal to, or greater than the second.

Though the type alias is provided by this library, its
definition is chosen to be compatible with existing Elm functions
that accept ordering functions. So, for instance, you can
pass an ordering to `List.sortWith` directly:

    type alias Point = { x : Int, y : Int }

    myOrdering : Ordering Point
    myOrdering =
        Ordering.byField .x
            |> Ordering.breakTiesWith (Ordering.byField .y)

    List.sortWith myOrdering [Point 1 2, Point 2 3]
-}
type alias Ordering a =
    a -> a -> Order


{-| Ordering that works with any built-in comparable type.

    -- orders in numeric order: 1, 2, 3, ...
    intOrdering : Ordering Int
    intOrdering = natural


    -- orders lexicographically: "a", "ab", "b", ...
    stringOrdering : Ordering String
    stringOrdering : natural
-}
natural : Ordering comparable
natural =
    compare


fromLessThan : (a -> a -> Bool) -> Ordering a
fromLessThan lt x y =
    if lt x y then
        LT
    else if lt y x then
        GT
    else
        EQ


{-| Ordering that orders values lexicographically by their string representation.
This ordering can be useful for prototyping but it's usually better to replace it
with a hand-made ordering for serious use since `byToString` gives no way of tuning
the resulting ordering.
-}
byToString : Ordering a
byToString =
    byField toString


{-| Creates an ordering that orders items in the order given in the input list.
Items that are not part of the input list are all considered to be equal to each
other and less than anything in the list.

    type Day = Mon | Tue | Wed | Thu | Fri | Sat | Sun

    dayOrdering : Ordering Day
    dayOrdering =
        Ordering.explicit
            [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
-}
explicit : List a -> Ordering a
explicit items x y =
    let
        scanForEither items =
            case items of
                z :: zs ->
                    if z == x then
                        scanForY zs
                    else if z == y then
                        scanForX zs
                    else
                        scanForEither zs

                [] ->
                    EQ

        scanForX items =
            case items of
                z :: zs ->
                    if z == x then
                        GT
                    else
                        scanForX zs

                [] ->
                    LT

        scanForY items =
            case items of
                z :: zs ->
                    if z == y then
                        LT
                    else
                        scanForY zs

                [] ->
                    GT
    in
        scanForEither items


{-| Produces an ordering that orders its elements using the natural ordering of the
field selected by the given function.

    type alias Point = { x : Int, y : Int }

    List.sort (Ordering.byField .x) [Point 3 5, Point 1 6]
        == [Point 1 6, Point 3 5]
    List.sort (Ordering.byField .y) [Point 3 5, Point 1 6]
        == [Point 3 5, Point 1 6]
-}
byField : (a -> comparable) -> Ordering a
byField =
    byFieldWith natural


{-| Produces an ordering that orders its elements using the given ordering on the
field selected by the given function.

    cards =
        [ { value = Two, suite = Spades }
        , { value = King, suite = Hearts }
        ]

    List.sort
        (Ordering.byFieldWith valueOrdering .value)
        cards
        == [ { value = Two, suite = Spades }
           , { value = King, suite = Hearts }
           ]
    List.sort
        (Ordering.byFieldWith suiteOrdering .suite)
        cards
        == [ { value = King, suite = Hearts }
           , { value = Two, suite = Spades }
           ]
-}
byFieldWith : Ordering b -> (a -> b) -> Ordering a
byFieldWith compareField extractField x y =
    compareField (extractField x) (extractField y)


{-| Produces an ordering that refines the second input ordering by using the first
ordering as a tie breaker. (Note that the second argument is the primary sort, and
the first argument is a tie breaker. This argument ordering is intended to support
function chaining with `|>`.)

    type alias Point = { x : Int, y : Int }

    pointOrdering : Ordering Point
    pointOrdering =
        Ordering.byField .x
            |> Ordering.breakTiesWith (Ordering.byField .y)
-}
breakTiesWith : Ordering a -> Ordering a -> Ordering a
breakTiesWith tiebreaker mainOrdering x y =
    case mainOrdering x y of
        LT ->
            LT

        GT ->
            GT

        EQ ->
            tiebreaker x y


{-| Returns an ordering that reverses the input ordering.

    List.sortWith
        (Ordering.reverse Ordering.natural)
        [1, 2, 3, 4, 5]
        == [5, 4, 3, 2, 1]
-}
reverse : Ordering a -> Ordering a
reverse ordering x y =
    case ordering x y of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT


{-| Determines if the given list is ordered according to the given ordering.

    Ordering.isOrdered Ordering.natural [1, 2, 3]
        == True
    Ordering.isOrdered Ordering.natural [2, 1, 3]
        == False
    Ordering.isOrdered Ordering.natural []
        == True
    Ordering.isOrdered
        (Ordering.reverse Ordering.natural)
        [1, 2, 3]
        == False
-}
isOrdered : Ordering a -> List a -> Bool
isOrdered ordering items =
    case items of
        x :: ((y :: _) as rest) ->
            case ordering x y of
                LT ->
                    isOrdered ordering rest

                EQ ->
                    isOrdered ordering rest

                GT ->
                    False

        -- lists of one or zero elements are always ordered
        _ ->
            True


{-| Determines if one value is less than another according to the given ordering.

    lessThanBy
        xThenYOrdering
        { x = 7, y = 8 }
        { x = 10, y = 2 }
        == True

    lessThanBy
        yThenXOrdering
        { x = 7, y = 8 }
        { x = 10, y = 2 }
        == False
-}
lessThanBy : Ordering a -> a -> a -> Bool
lessThanBy ordering x y =
    case ordering x y of
        LT ->
            True

        _ ->
            False


{-| Determines if one value is greater than another according to the given ordering.

    greaterThanBy
        xThenYOrdering
        { x = 7, y = 8 }
        { x = 10, y = 2 }
        == False

    greaterThanBy
        yThenXOrdering
        { x = 7, y = 8 }
        { x = 10, y = 2 }
        == True
-}
greaterThanBy : Ordering a -> a -> a -> Bool
greaterThanBy ordering x y =
    case ordering x y of
        GT ->
            True

        _ ->
            False
