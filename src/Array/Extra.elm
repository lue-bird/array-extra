module Array.Extra exposing
    ( all, any
    , reverse, update
    , pop, removeAt, removeWhen
    , insertAt, intersperse
    , sliceFrom, sliceUntil, splitAt
    , interweave, apply, map2, map3, map4, map5, zip, zip3, unzip
    , resizelRepeat, resizerRepeat, resizelIndexed, resizerIndexed
    , filterMap, mapToList, indexedMapToList
    )

{-| Convenience functions for working with `Array`


# scan

@docs all, any


# alter

@docs reverse, update
@docs pop, removeAt, removeWhen
@docs insertAt, intersperse


## part

@docs sliceFrom, sliceUntil, splitAt


## combine

@docs interweave, apply, map2, map3, map4, map5, zip, zip3, unzip


## resize

@docs resizelRepeat, resizerRepeat, resizelIndexed, resizerIndexed


# transform

@docs filterMap, mapToList, indexedMapToList

-}

import Array exposing (Array, append, empty, initialize, length, repeat, slice)


{-| Update the element at a given index based on its current value.
If the index is out of bounds, nothing is changed.

    import Array exposing (fromList)

    update 1 ((+) 10) (fromList [ 1, 2, 3 ])
    --> fromList [ 1, 12, 3 ]

    update 4 ((+) 10) (fromList [ 1, 2, 3 ])
    --> fromList [ 1, 2, 3 ]

    update -1 ((+) 10) (fromList [ 1, 2, 3 ])
    --> fromList [ 1, 2, 3 ]

-}
update : Int -> (a -> a) -> Array a -> Array a
update index alter array =
    case Array.get index array of
        Nothing ->
            array

        Just element ->
            Array.set index (alter element) array


{-| Drop a given number of elements from the start.
In other words, slice the `Array` from an index until the very end.
Given a negative argument, count the end of the slice from the end.

    import Array exposing (fromList)

    sliceFrom 3 (fromList (List.range 0 6))
    --> fromList [ 3, 4, 5, 6 ]

    sliceFrom -3 (fromList (List.range 0 6))
    --> fromList [ 4, 5, 6 ]

-}
sliceFrom : Int -> Array a -> Array a
sliceFrom lengthDropped array =
    slice lengthDropped (length array) array


{-| Take a number of elements from the start.
In other words, slice the `Array` from the very beginning until not including the index.
Given a negative argument, count the beginning of the slice from the end.

    import Array exposing (fromList)

    sliceUntil 3 (fromList (List.range 0 6))
    --> fromList [ 0, 1, 2 ]

    sliceUntil -3 (fromList (List.range 0 6))
    --> fromList [ 0, 1, 2, 3 ]

-}
sliceUntil : Int -> Array a -> Array a
sliceUntil newLength array =
    slice 0
        (if newLength >= 0 then
            newLength

         else
            length array + newLength
        )
        array


{-| Remove the last element.

    import Array exposing (fromList, empty)

    pop (fromList [ 1, 2, 3 ])
    --> fromList [ 1, 2 ]

    pop empty
    --> empty

-}
pop : Array a -> Array a
pop array =
    slice 0 -1 array


{-| Place a value between all members.

    import Array exposing (fromList)

    intersperse "on"
        (fromList [ "turtles", "turtles", "turtles" ])
    --> fromList
    -->     [ "turtles", "on", "turtles", "on", "turtles" ]

To interlace an `Array`, [`interweave`](#interweave).

-}
intersperse : a -> Array a -> Array a
intersperse separator array =
    array
        |> Array.toList
        |> List.intersperse separator
        |> Array.fromList


{-| Try transforming all elements but only keep the successes.

    import Array exposing (fromList)

    filterMap String.toInt
        (fromList [ "3", "4.0", "5", "hats" ])
    --> fromList [ 3, 5 ]

-}
filterMap : (a -> Maybe b) -> Array a -> Array b
filterMap tryMap array =
    array
        |> Array.toList
        |> List.filterMap tryMap
        |> Array.fromList


{-| Apply a given `Array` of changes to all elements.
If one `Array` is longer, its extra elements are not used.

    import Array exposing (fromList, repeat)

    apply
        (fromList
            [ \x -> -x, identity, (+) 10 ]
        )
        (repeat 5 100)
    --> fromList [ -100, 100, 110 ]

-}
apply : Array (a -> b) -> Array a -> Array b
apply maps array =
    map2 (\map element -> map element) maps array


{-| Apply a function to the elements in the array and collect the result in a List.

    import Array exposing (fromList)
    import Html

    mapToList Html.text
        (fromList [ "a", "b", "c" ])
    --> [ Html.text "a", Html.text "b", Html.text "c" ]

-}
mapToList : (a -> b) -> Array a -> List b
mapToList mapElement =
    Array.foldr (mapElement >> (::)) []


{-| Transform all elements with their indexes as the first argument
and collect the result in a `List`.

    import Array exposing (Array, fromList)
    import Html exposing (Html)

    type alias Exercise =
        { name : String }

    exerciseRender : Int -> Exercise -> Html msg
    exerciseRender index exercise =
        String.concat
            [ "Exercise #"
            , String.fromInt (index + 1)
            , " - "
            , exercise.name
            ]
            |> Html.text

    exercisesRender : Array Exercise -> Html msg
    exercisesRender exercises =
        indexedMapToList renderExercise exercises
            |> Html.div []

-}
indexedMapToList : (Int -> a -> b) -> Array a -> List b
indexedMapToList mapIndexAndElement array =
    Array.foldr
        (\element ( i, listSoFar ) ->
            ( i - 1, mapIndexAndElement i element :: listSoFar )
        )
        ( Array.length array - 1, [] )
        array
        |> Tuple.second


{-| Combine the elements of two `Array`s with a given function.
If one `Array` is longer, its extra elements are not used.

    import Array exposing (fromList)

    map2 (+)
        (fromList [ 1, 2, 3 ])
        (fromList [ 1, 2, 3, 4 ])
    --> fromList [ 2, 4, 6 ]

    map2 Tuple.pair
        (fromList [ 1, 2, 3 ])
        (fromList [ 'a', 'b' ])
    --> fromList [ ( 1, 'a' ), ( 2, 'b' ) ]

Note: [`zip`](Array-Extra#zip) can be used instead of `map2 Tuple.pair`.

-}
map2 :
    (a -> b -> combined)
    -> Array a
    -> Array b
    -> Array combined
map2 combineAb aArray bArray =
    List.map2 combineAb
        (aArray |> Array.toList)
        (bArray |> Array.toList)
        |> Array.fromList


{-| Combine the elements of three `Array`s with the given function. See [`map2`](Array-Extra#map2).

Note: [`zip3`](Array-Extra#zip3) can be used instead of `map3 (\a b c -> ( a, b, c ))`.

-}
map3 :
    (a -> b -> c -> combined)
    -> Array a
    -> Array b
    -> Array c
    -> Array combined
map3 combineAbc aArray bArray cArray =
    apply (map2 combineAbc aArray bArray) cArray


{-| Combine the elements of four `Array`s with the given function. See [`map2`](Array-Extra#map2).
-}
map4 :
    (a -> b -> c -> d -> combined)
    -> Array a
    -> Array b
    -> Array c
    -> Array d
    -> Array combined
map4 combineAbcd aArray bArray cArray dArray =
    apply (map3 combineAbcd aArray bArray cArray) dArray


{-| Combine the elements of five `Array`s with the given function. See [`map2`](Array-Extra#map2).
-}
map5 :
    (a -> b -> c -> d -> e -> combined)
    -> Array a
    -> Array b
    -> Array c
    -> Array d
    -> Array e
    -> Array combined
map5 combineAbcde aArray bArray cArray dArray eArray =
    apply (map4 combineAbcde aArray bArray cArray dArray) eArray


{-| Combine the elements of two `Array`s into tuples.
If one is longer, its extra elements are not used.

    import Array exposing (fromList)

    zip
        (fromList [ 1, 2, 3 ])
        (fromList [ 'a', 'b' ])
    --> fromList [ ( 1, 'a' ), ( 2, 'b' ) ]

-}
zip : Array a -> Array b -> Array ( a, b )
zip =
    map2 Tuple.pair


{-| Zip the elements of three `Array`s into 3-tuples.
Only the indexes of the shortest `Array` are used.

    import Array exposing (fromList)

    zip3
        (fromList [ 1, 2, 3 ])
        (fromList [ 'a', 'b' ])
        (fromList [ "a", "b", "c", "d" ])
    --> fromList
    -->     [ ( 1, 'a', "a" )
    -->     , ( 2, 'b', "b" )
    -->     ]

-}
zip3 : Array a -> Array b -> Array c -> Array ( a, b, c )
zip3 =
    map3 (\a b c -> ( a, b, c ))


{-| Split all tuple elements into a tuple of one `Array` with the first and one with the second values.

    import Array exposing (fromList)

    unzip
        (fromList
            [ ( 1, 'a' ), ( 2, 'b' ), ( 3, 'c' ) ]
        )
    --> ( fromList [ 1, 2, 3 ]
    --> , fromList [ 'a', 'b', 'c' ]
    --> )

-}
unzip : Array ( a, b ) -> ( Array a, Array b )
unzip tupleArray =
    ( tupleArray |> Array.map Tuple.first
    , tupleArray |> Array.map Tuple.second
    )


{-| Only keep elements which fail to satisfy a given predicate.
This is equivalent to `Array.filter (not << predicate)`.

    import Array exposing (fromList)

    removeWhen (\x -> x < 0)
        (fromList [ -1, 92, 0, 14, -3 ])
    --> fromList [ 92, 0, 14 ]

-}
removeWhen : (a -> Bool) -> Array a -> Array a
removeWhen isBad array =
    Array.filter (not << isBad) array


{-| Resize from the left, padding the right-hand side with a given value.

    import Array exposing (fromList, empty)

    resizelRepeat 4 0 (fromList [ 1, 2 ])
    --> fromList [ 1, 2, 0, 0 ]

    resizelRepeat 2 0 (fromList [ 1, 2, 3 ])
    --> fromList [ 1, 2 ]

    resizelRepeat -1 0 (fromList [ 1, 2 ])
    --> empty

-}
resizelRepeat : Int -> a -> Array a -> Array a
resizelRepeat newLength paddingValue array =
    if newLength <= 0 then
        Array.empty

    else
        let
            len =
                length array
        in
        case compare len newLength of
            GT ->
                sliceUntil newLength array

            LT ->
                append array (repeat (newLength - len) paddingValue)

            EQ ->
                array


{-| Resize from the right, padding the left-hand side with a given value.

    import Array exposing (fromList, empty)

    resizerRepeat 4 0 (fromList [ 1, 2 ])
    --> fromList [ 0, 0, 1, 2 ]

    resizerRepeat 2 0 (fromList [ 1, 2, 3 ])
    --> fromList [ 2, 3 ]

    resizerRepeat -1 0 (fromList [ 1, 2 ])
    --> empty

-}
resizerRepeat : Int -> a -> Array a -> Array a
resizerRepeat newLength defaultValue array =
    let
        len =
            length array
    in
    case compare len newLength of
        GT ->
            slice (len - newLength) len array

        LT ->
            append (repeat (newLength - len) defaultValue) array

        EQ ->
            array


{-| Resize from the left, padding the right-hand side with a given value based on index.

    import Array exposing (fromList, empty)

    resizelIndexed 5
        toLetterInAlphabet
        (fromList [ 'a', 'b', 'c' ])
    --> fromList [ 'a', 'b', 'c', 'd', 'e' ]

    resizelIndexed 2
        toLetterInAlphabet
        (fromList [ 'a', 'b', 'c' ])
    --> fromList [ 'a', 'b' ]

    resizelIndexed -1
        toLetterInAlphabet
        (fromList [ 'a', 'b', 'c' ])
    --> empty

    toLetterInAlphabet : Int -> Char
    toLetterInAlphabet inAlphabet =
        (Char.toCode 'a') + inAlphabet
            |> Char.fromCode

-}
resizelIndexed : Int -> (Int -> a) -> Array a -> Array a
resizelIndexed newLength defaultValueAtIndex array =
    if newLength <= 0 then
        Array.empty

    else
        let
            len =
                length array
        in
        case compare len newLength of
            GT ->
                sliceUntil newLength array

            LT ->
                append array
                    (initialize (newLength - len)
                        (defaultValueAtIndex << (\i -> i + len))
                    )

            EQ ->
                array


{-| Resize from the right, padding the left-hand side with a given value based on index.

    import Array exposing (fromList, empty)

    resizerIndexed 5
        ((*) 5)
        (fromList [ 10, 25, 36 ])
    --> fromList [ 0, 5, 10, 25, 36 ]

    resizerIndexed 2
        ((*) 5)
        (fromList [ 10, 25, 36 ])
    --> fromList [ 25, 36 ]

    resizerIndexed -1
        ((*) 5)
        (fromList [ 10, 25, 36 ])
    --> empty

-}
resizerIndexed : Int -> (Int -> a) -> Array a -> Array a
resizerIndexed newLength defaultValueAtIndex array =
    let
        len =
            length array
    in
    case compare len newLength of
        GT ->
            slice (len - newLength) len array

        LT ->
            append
                (initialize (newLength - len) defaultValueAtIndex)
                array

        EQ ->
            array


{-| Flip the element order.

    import Array exposing (fromList)

    reverse (fromList [ 1, 2, 3, 4 ])
    --> fromList [ 4, 3, 2, 1 ]

-}
reverse : Array a -> Array a
reverse array =
    array
        |> reverseToList
        |> Array.fromList


reverseToList : Array a -> List a
reverseToList =
    Array.foldl (::) []


{-| Split into two `Array`s, the first ending before and the second starting with a given index.

    import Array exposing (fromList, empty)

    splitAt 2 (fromList [ 1, 2, 3, 4 ])
    --> ( fromList [ 1, 2 ], fromList [ 3, 4 ] )

    splitAt 100 (fromList [ 1, 2, 3, 4 ])
    --> ( fromList [ 1, 2, 3, 4 ], empty )

    splitAt -1 (fromList [ 1, 2, 3, 4 ])
    --> ( empty, fromList [ 1, 2, 3, 4 ] )

-}
splitAt : Int -> Array a -> ( Array a, Array a )
splitAt index array =
    if index > 0 then
        ( sliceUntil index array
        , sliceFrom index array
        )

    else
        ( empty, array )


{-| Remove the element at a given index.
If the index is out of bounds, nothing is changed.

    import Array exposing (fromList)

    removeAt 2 (fromList [ 1, 2, 3, 4 ])
    --> fromList [ 1, 2, 4 ]

    removeAt -1 (fromList [ 1, 2, 3, 4 ])
    --> fromList [ 1, 2, 3, 4 ]

    removeAt 100 (fromList [ 1, 2, 3, 4 ])
    --> fromList [ 1, 2, 3, 4 ]

-}
removeAt : Int -> Array a -> Array a
removeAt index array =
    if index >= 0 then
        let
            ( beforeIndex, startingAtIndex ) =
                splitAt index array

            lengthStartingAtIndex =
                length startingAtIndex
        in
        if lengthStartingAtIndex == 0 then
            beforeIndex

        else
            append beforeIndex
                (slice 1 lengthStartingAtIndex startingAtIndex)

    else
        array


{-| Insert an element at a given index.
If the index is out of bounds, nothing is changed.

    import Array exposing (fromList)

    insertAt 1 'b' (fromList [ 'a', 'c' ])
    --> fromList [ 'a', 'b', 'c' ]

    insertAt -1 'b' (fromList [ 'a', 'c' ])
    --> fromList [ 'a', 'c' ]

    insertAt 100 'b' (fromList [ 'a', 'c' ])
    --> fromList [ 'a', 'c' ]

-}
insertAt : Int -> a -> Array a -> Array a
insertAt index val values =
    let
        length =
            Array.length values
    in
    if index >= 0 && index <= length then
        let
            before =
                Array.slice 0 index values

            after =
                Array.slice index length values
        in
        Array.append (Array.push val before) after

    else
        values


{-| Whether all elements satisfy a given test.

    import Array exposing (fromList, empty)

    all (\x -> x < 5) (fromList [ 2, 4 ])
    --> True

    all (\x -> x < 5) (fromList [ 4, 16 ])
    --> False

    all (\x -> x < 5) empty
    --> True

-}
all : (a -> Bool) -> Array a -> Bool
all isOkay array =
    array
        |> Array.foldl
            (\element -> (&&) (isOkay element))
            True


{-| Whether at least some elements satisfy a given test.

    import Array exposing (fromList, empty)

    any (\x -> x < 5) (fromList [ 6, 3 ])
    --> True

    any (\x -> x < 5) (fromList [ 12, 33 ])
    --> False

    any (\x -> x < 5) empty
    --> False

-}
any : (a -> Bool) -> Array a -> Bool
any isOkay array =
    array
        |> Array.foldl
            (\element -> (||) (isOkay element))
            False


{-| Place all elements of a given `Array` between all current elements.
Extra elements of either `Array` are glued to the end without anything in between.

    import Array exposing (fromList, repeat)

    fromList [ "turtles", "turtles", "turtles" ]
        |> interweave (repeat 2 "on")
    --> fromList [ "turtles", "on", "turtles", "on", "turtles" ]

    fromList [ "turtles", "turtles", "turtles" ]
        |> interweave (repeat 5 "on")
    --> fromList [ "turtles", "on", "turtles", "on", "turtles", "on", "on", "on" ]

    fromList [ "turtles", "turtles", "turtles" ]
        |> interweave (repeat 1 "on")
    --> fromList [ "turtles", "on", "turtles", "turtles" ]

-}
interweave : Array element -> (Array element -> Array element)
interweave toInterweave =
    \array ->
        let
            untilArrayEnd =
                array
                    |> Array.foldl
                        (\element soFar ->
                            case soFar.toInterweave of
                                [] ->
                                    { interwoven =
                                        element :: soFar.interwoven
                                    , toInterweave = []
                                    }

                                toInterweaveHead :: toInterweaveTail ->
                                    { interwoven =
                                        toInterweaveHead
                                            :: element
                                            :: soFar.interwoven
                                    , toInterweave = toInterweaveTail
                                    }
                        )
                        { interwoven = []
                        , toInterweave = toInterweave |> Array.toList
                        }
        in
        (untilArrayEnd.interwoven
            |> List.reverse
        )
            ++ untilArrayEnd.toInterweave
            |> Array.fromList
