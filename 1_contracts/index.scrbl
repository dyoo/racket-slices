#lang scribble/manual

@(require (for-label racket/base))

@title{Racket Serve 1: use contracts to check inputs and outputs}
@author+email["Danny Yoo" "dyoo@cs.wpi.edu"]

This will be part of a series that talks about using
@link["http://racket-lang.org"]{Racket}, but not as an
@link["http://www.htdp.org/"]{educational language}, but as a
@emph{real-world} one.

That means that the shackles are off!  We're in
@racketmodname[racket/base] land now!  So if the simplest way to do
things is with
@link["http://docs.racket-lang.org/guide/classes.html"]{classes},
@link["http://docs.racket-lang.org/guide/for.html"]{for loops}, or
@racket[set!], we'll use these tools without hesitation.

Each of these @emph{serves} will be relatively short tutorials; the
point will be to show how to use Racket to solve problems.  That is,
the tone here should be more like one out of a cookbook, not out of an
encyclopedia.


@smaller{(Of course, it may be the case that, in the source of this
writing, we find the Racket libraries aren't as robust as we'd like.
Even if that's the case, I'd love to see where the runtime libraries
fail us, and fix the problems as they come along.  And document the
process along the way!)}


@section{The problem}

@section{The solution}