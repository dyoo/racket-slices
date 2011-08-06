#lang scribble/manual
@(require scribble/eval
          racket/sandbox
	  "scribble-helpers.rkt"
          (for-label net/url
                     racket))

@(define my-evaluator
   (call-with-trusted-sandbox-configuration 
    (lambda ()
      (parameterize ([sandbox-output 'string]
                     [sandbox-error-output 'string])
        (make-evaluator 'racket)))))


@inject-javascript|{
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-24146890-1']);
  _gaq.push(['_trackPageview']);
 
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();      
}|


@title{A Racket Slice: munging IRC chat logs}
@author+email["Danny Yoo" "dyoo@hashcollision.org"]

@centered{@smaller{Source code can be found at:
@url{https://github.com/dyoo/racket-slices}.  The latest version of this
document lives in @url{http://hashcollision.org/racket-slices/irc-parsing}.}}




Let's say that we have some source of text, such as IRC chat logs, and we'd
like to extract information from them.
To use the precise technical term, we'd like to 
@link["http://www.catb.org/jargon/html/M/munge.html"]{munge}.


@margin-note{The following is an interactive session between
             us and the Racket @link["http://docs.racket-lang.org/guide/intro.html#(part._.Interacting_with_.Racket)"]{REPL}, using the full-fledged @racketmodname[racket] language.}
Can we take a slice at this problem using the @link["http://racket-lang.org"]{Racket}
language?

Let's explore this and fire up Racket.
@interaction[#:eval my-evaluator
                    (require net/url)]
We'll want to use the @racketmodname[net/url] library, which allows us to suck
the content out of a URL.  First, let's open up an input port.  
@interaction[#:eval my-evaluator
                    (define irc-port 
                      (get-pure-port
                       (string->url "http://racket-lang.org/irc-logs/20110802.txt")))
                    ]

@margin-note{Note that the following: ``@racket[get-pure-port]'' in this document
                                        is hyperlinked.
                                        When you click the link, it shows
                                        where the function lives.  In this case,
                                        @racket[get-pure-port] lives in
                                        @racketmodname[net/url], as does
                                        @racket[string->url].}


An @link["http://docs.racket-lang.org/guide/i_o.html"]{input port}
is a source for stuff.  Let's suck up ten lines of stuff and see what
it looks like.  We can walk along the lines in our port with a @racket[for] loop.
@interaction[#:eval my-evaluator
                    (for ([line (in-lines irc-port)]
                          [i (in-range 10)])
                      (printf "~s\n" line))]

Ok, good!  It looks like we're getting back strings.  When we look at those strings
more closely, it seems that have a
fairly regular structure.  There's
some chunk in front that looks like a timestamp, followed by one of two things:
@itemize[
         @item{An IRC administrative action, like @racket["00:00 (join) neilv"], or}
          @item{A chat message, like @racket["00:04 offby1: couldn't tell ya"].}]

When we have strings with regular structure, we can use @emph{regular expressions}
to search through it.  For example, we can try to match a regular expression
pattern against a string like this:
@interaction[#:eval my-evaluator
                    (regexp-match #px"^(\\d\\d):(\\d\\d)"
                                  "12:42")
                    (regexp-match #px"^(\\d\\d):(\\d\\d)"
                                  "twelve:forty-two")]

@margin-note{You can find more details about regular expressions in the
             @link["http://docs.racket-lang.org/guide/regexp.html"]{Guide}.}
The @racket[#px"^(\\d\\d):(\\d\\d)"] is a Perl-compatible regular expression that
captures the pattern: ``two grouped digits, followed by a colon,
followed by two more grouped digits.''  When we match, we get back a list which includes the groups.  If we don't,
well, we get back @racket[#f], which is fine.

Let's squirrel away two regular expressions that we'll use to pattern match
those IRC chat lines.
@interaction[#:eval my-evaluator
                    (define action-regexp
                      #px"^(\\d\\d):(\\d\\d) [(](.+)[)] (.+)")
                    (define chat-regexp
                      #px"^(\\d\\d):(\\d\\d) ([^()]+) (.+)")]

Can we use these patterns to match across all of them?  Let's see!  Let's go
through a few more lines and see if we can match them.
@interaction[#:eval my-evaluator
                    (for ([line (in-lines irc-port)]
                          [i (in-range 5)])
                      (cond
                        [(regexp-match action-regexp line)
                         (printf "I matched an action.\n")]
                        [(regexp-match chat-regexp line)
                         (printf "I matched a message\n")]
                        [else
                         (error 'oops-i-did-it-again)]))]

@margin-note{... uh.  Probably not.  We're certainly munging.}
If things had broken, we'd have seen an error.
We don't, so obviously things are perfect.


We don't necessarily want to deal with strings all the time.  We can
use structures to represent the parsed data we're getting from this
IRC log.  Let's define two of them.
@interaction[#:eval my-evaluator
                    (struct action (hour minute type msg) #:transparent)
                    (struct chat (hour minute who msg) #:transparent)]
We want to make the structure @emph{transparent} by using the @racket[#:transparent]
option to @racket[struct].  Otherwise, structures
act very much like black boxes, and we don't get to @racket[printf] them out in
a way that makes it easy to see their contents.

Ok, now that we've defined our structures, let's do this.  We'll write a function
to take a line and parse it into either an @racket[action] or a @racket[chat].
@interaction[#:eval my-evaluator
                    (define (parse-irc a-line)
                      (define (on-action-line a-match)
                        (action (second a-match)
                                (third a-match)
                                (fourth a-match)
                                (fifth a-match)))
                      
                      (define (on-chat-line a-match)
                        (chat (second a-match)
                              (third a-match)
                              (fourth a-match)
                              (fifth a-match)))
                      
                      (cond
                        [(regexp-match action-regexp a-line)
                         => on-action-line]
                        [(regexp-match chat-regexp a-line)
                         => on-chat-line]
                        [else
                         (error 'oops-i-did-it-again)]))]
@interaction[#:eval my-evaluator
                    (parse-irc (read-line irc-port))
                    (parse-irc (read-line irc-port))]
Nice!  We're using an advanced feature of @racket[cond]; the arrow (@racket[=>])
lets us say that if the left-hand-side evaluates to a true value, 
then it calls the function, named by the right-hand-side, against that value.


Hmmm.  But in retrospect, though, using @racket[second], @racket[third], etc.
is a slightly verbose, error-prone way to destructure the list 
that we're getting back from
@racket[regexp-match].  Can we do better?

@margin-note{See the documentation of @racketmodname[racket/match] for more
information on the pattern-matching library.}
We can, with the structure-matching library @racket[match],
which lets us express the code more nicely.  Let's try this again...
@interaction[#:eval my-evaluator
                    (define (parse-irc a-line)
                      (define (on-action-line a-match)
                        (match a-match
                          [(list whole-match hour minute type msg)
                           (action hour minute type msg)]))
                      
                      (define (on-chat-line a-match)
                        (match a-match
                          [(list whole-match hour minute who msg)
                           (chat hour minute who msg)]))
                      
                      (cond
                        [(regexp-match action-regexp a-line)
                         => on-action-line]
                        [(regexp-match chat-regexp a-line)
                         => on-chat-line]
                        [else
                         (error 'oops-i-did-it-again)]))]
@interaction[#:eval my-evaluator
                    (parse-irc (read-line irc-port))
                    (parse-irc (read-line irc-port))]

Ok, better.  We can probably keep at it to make @racket[parse-irc] even smaller,
but we should probably stop fiddling with it.

Let's use this function on a few lines.
@interaction[#:eval my-evaluator
                    (for ([line (in-lines irc-port)]
                          [i (in-range 5)])
                      (printf "~s\n" (parse-irc line)))]
Wow!  That's a lot of @tt{quit}ting.
That's probably a sign that this session should wind down as well.
Let's look through just a few more, just to see a few @racket[chat]s.
@interaction[#:eval my-evaluator
                    (define chat-lines
                      (for/list ([line (in-lines irc-port)]
                                 #:when (chat? (parse-irc line)))
                        (parse-irc line)))
                                          
                    (for ([a-chat chat-lines]
                          [i (in-range 5)])
                      (printf "~s\n" a-chat))]

@margin-note{No ``maybe'' about it.
             See @racketmodname[rackunit]
             for more details on how to write
             unit test cases.}
Ooops!  It looks like our regular expression pattern @racket[chat-regexp]
isn't quite right.  That's why it's called munging, I suppose.
But maybe we should have written test cases.
 


Finally, let's go back and package what we've learned into a module
(and add a test case to let us know that we'll need to fix something).
@filebox["parse-irc.rkt"]{
 @codeblock|{
#lang racket

;; Munging IRC chat logs

(require net/url
         rackunit)

;; An IRC port contains both actions and chats.
(struct action (hour minute type msg) #:transparent)
(struct chat (hour minute who msg) #:transparent)

;; Regular expressions to parse out the lines in a chat log.
(define action-regexp
  #px"^(\\d\\d):(\\d\\d) [(](.+)[)] (.+)")

;; FIXME: this pattern is not quite right...
(define chat-regexp
  #px"^(\\d\\d):(\\d\\d) ([^()]+) (.+)")


;; parse-irc: string -> (U action chat)
(define (parse-irc a-line)
  (define (on-action-line a-match)
    (match a-match
      [(list whole-match hour minute type msg)
       (action hour minute type msg)]))
  
  (define (on-chat-line a-match)
    (match a-match
      [(list whole-match hour minute who msg)
       (chat hour minute who msg)]))
  
  (cond
    [(regexp-match action-regexp a-line)
     => on-action-line]
    [(regexp-match chat-regexp a-line)
     => on-chat-line]
    [else
     (error 'oops-i-did-it-again)]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Let's try it out:
(define irc-port 
  (get-pure-port
   (string->url "http://racket-lang.org/irc-logs/20110802.txt")))

(define parsed-irc
  (for/list ([line (in-lines irc-port)])
    (parse-irc line)))             

;; We can look at the final results here:
parsed-irc


;; A test case that, at the present, will fail on us.
(check-equal? (parse-irc "01:42 dyoo: ... And that's a wrap!  See you around!")
              (chat "01" "42" "dyoo" "... And that's a wrap!  See you around!"))
    }|
  }
