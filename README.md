This is a parsing library in the spirit of Haskell's parsec.  For example:

``` elisp
(pl-parse
  (delete-region (pl-str "<xml>" :beg)
                 (pl-until
                   (pl-str "</xml>" :end))))
```

There are a few parsers, whose job is to inspect whatever is at the current
buffer position, and return zero or more details regarding what was found:

    pl-ch                Match a single character
    pl-str               Match a string
    pl-re                Match a regular expression
    pl-num               Match an integer or floating-point number

Other possibilities include: inspecting text properties, overlays, etc.

If the parser succeeds, it returns the object matched (a string by default),
and advances point to the next position after the match.  Keywords may be
given to return other details:

    :beg                 Beginning of the match
    :end                 End of the match
    :group N             A particular regexp group
    :props               All properties within the matched region
    :nil                 Return `nil` (same as using `ignore`)

If a parser fails, it throws the exception `failed`.  This is caught by the
macro `pl-try`, which returns `nil` upon encountering the exception.  This
makes it possible to build certain combinators out of these few parts:

    pl-or                Return result from first successful parser
    pl-and               Return last result, if all parsers succeed
    pl-until             If the parse fails, advance cursor position by
                         one character and try again.  Keywords can
                         change the advance amount.

For other constructs, such as returning the result of every parser as a list, just
combine parsers with regular Lisp forms (`pl-parse` is just a synonym for
`pl-try`):

``` elisp
(pl-parse
  (list (pl-str "Hello") (pl-str "World")))
```

Note that even though a parse may fail, and thus return no value, any
side-effects that occur during the course of the parse will of course be
retained.  This can be used to good effect, by continuing an action for as
long as a parse succeeds:

``` elisp
(pl-parse
  (while t
     (delete-region (pl-str "<xml>" :beg)
                    (pl-until
                      (pl-str "</xml>" :end)))))
```

This will delete blocks demarcated by `<xml>` and `</xml>`, for as long as
such blocks continue to occur contiguously to one another.
