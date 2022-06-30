# Contributing to Naikari

Want to contribute to Naikari? Great! We appreciate your generosity.
This document provides a general guideline for how to contribute to this
project.

## Code of Conduct

All contributors, including leaders, are expected to follow our
[Code of Conduct](code_of_conduct.md). If you find unacceptable
behavior, please report it as instructed within the Code of Conduct.

## Reporting Issues

If you find a problem in Naikari of any sort, or have a proposal for how
to make Naikari better, please don't hesitate to submit an issue to the
[Naikari issue tracker](https://github.com/naikari/naikari/issues). All
ideas and input are welcome so long as the Code of Conduct is respected.

When submitting a bug report, please do your best to provide steps to
reproduce the problem, being as specific as possible.

## Questions and Discussions

To ask questions about or generally discuss Naikari (in a way that is
outside the scope of the issue tracker), you can use
[Discussions](https://github.com/naikari/naikari/discussions). If you
have a question, please also see our
[FAQ](https://github.com/naikari/naikari/wiki/FAQ) as it may be answered
there.

## Contributing Code

In general, the best way to contribute to Naikari's code is to fork the
repository, make changes to your fork, and then submit a pull request.
Be sure to also add your name to [dat/AUTHORS](dat/AUTHORS) under the
Naikari Development section so you can be recognized for your work.

See [GitHub's documentation](https://docs.github.com/en/pull-requests)
for information on how to get started with pull requests.

### Code Conventions

This section details Naikari's coding style. This is mostly based on
Naev's coding style (as Naev is what Naikari was forked from), but with
some key differences. Except where otherwise noted, all guidelines apply
to both C and Lua code.

As a general rule, 3-space indentation is used. It isn't the most
convenient number of spaces, but we continue to use it for most files
to maintain consistency. It is acceptable, however, for Lua files to use
4-space indents so long as the entire file follows this convention.

C code uses a braces style which is a variant of K&R style, but in
addition to using 3-space indents instead of 4-space indents, `else`
statements following bracketed `if` statements are to be placed on the
line following the closing bracket, rather than on the same line, as
seen in this example from [src/menu.c](src/menu.c):

```c
   /* Load background and friends. */
   if (curlocaltime.tm_mon == 3) {
      /* Autism Acceptance Month */
      tex = gl_newImage(GFX_PATH"naikari-red.png", 0);
      main_tagline = _("Lighting up red for Autism Acceptance Month."
            " ##ActuallyAutistic");
   }
   else if (curlocaltime.tm_mon == 5) {
      /* Queer Pride Month */
      tex = gl_newImage(GFX_PATH"naikari-rainbow.png", 0);
      main_tagline = _("We're here. We're queer. Get used to it. ##QueerPride");
   }
   else {
```

Lines should never exceed 80 characters in length if possible. As a
general rule, statements which take up more than 80 characters of space
when put on a single line should be split into additional lines which
are indented two further tabs in. For compound statements, the statement
should be split such that operators lead the next line rather than
trailing the previous line. Additional indentation should also be used
for compound statements that contain inner compound statements, to make
it clear through indentation where the scope is. For example, here is a
shippet of C code following these guidelines (taken from
[src/player.c](src/player.c):

```c
         /* Try to select the nearest planet that the player can simply
          * land on without bribes. If that's not possible, select the
          * closest landable planet (excluding those which have been
          * overrided to blanket deny landing). */
         if (planet_isKnown(planet)
               && planet_hasService(planet, PLANET_SERVICE_LAND)
               && (planet->land_override >= 0)
               && ((tp == -1) || (td == -1)
                  || (!cur_system->planets[tp]->can_land
                     && (cur_system->planets[tp]->land_override <= 0)
                     && (planet->can_land || (planet->land_override > 0)
                        || (td > d)))
                  || ((planet->can_land || (planet->land_override > 0))
                     && (td > d)))) {
            tp = i;
            td = d;
         }
```

For Lua code, it is impossible to split a line containing a long text
string without causing problems, so in that case, effort should be made
to place the long text string on its own line instead. Here is an
example taken from [dat/events/escorts.lua](dat/events/escorts.lua):

```lua
      if tk.yesno("", fmt.f(
               _("Are you sure you want to dock {pilot}? They will still be paid royalties, but will not join you in space until you undock them."),
               {pilot=edata.name})) then
         edata.docked = true
         evt.npcRm(npc_id)
         npcs[npc_id] = nil
         spawnNPC(edata)
      end
```

The examples shown above also demonstrate proper spacing around
operators within the Naikari project.

One thing that you will see in old code inherited from the Naev project
which we ask that you never do is using whitespace to construct a
table-like visual appearance. For example, the following code is
**not acceptable** for new Naikari code:

```c
/* Never, ever do this, please. */
x         = 3;
foobarvar = 6;
y         = 7000;
```

While on paper this sort of spacing seems to make reading values easier,
it also means that changes that don't involve some of these lines could
require changing them or wrecking the visual. These sorts of constructs
have also in the past led to ridiculously long lines that were virtually
unreadable in a narrow text editor, and to an extent still do, since
many examples of this sort of practice still remain in old code. These
and other drawbacks aren't worth the minor subjective visual benefit, so
please instead write such code like this:

```c
x = 3;
foobarvar = 6;
y = 7000;
```

Other than that, please use your best judgment and focus on making the
code readable and consistent above all else.

## Contributing Artwork

Artwork is stored in a separate repository, known as a submodule, so if
you wish to contribute artwork, that should go to the
[naikari-artwork](https://github.com/naikari/naikari-artwork)
repository. That repository hosts the source files.

The files actually used by the game are stored in the
[naikari-artwork-production](https://github.com/naikari/naikari-artwork-production)
repository. This repository also contains authorship and licensing
information. All artwork contributed to the Naikari project should be
under an open content license. Usually CC BY or CC BY-SA is a good
choice.

As a general rule, when contributing artwork, it is best to submit both
a pull request to `naikari-artwork` and to `naikari-artwork-production`,
ensuring that your authorship and licensing is properly documented in
`naikari-artwork-production`. You should also add your name to
[dat/AUTHORS](dat/AUTHORS) under the appropriate section so you can be
recognized for your work; this can be done via a pull request to the
`naikari` repository.

See [GitHub's documentation](https://docs.github.com/en/pull-requests)
for information on how to get started with pull requests.

If this is too involved, feel free to instead open an issue on the
[issue tracker](https://github.com/naikari/naikari/issues), and we can
get it sorted for you. Be sure to indicate the open content license your
contribution is under and how you wish to be credited.

## Contributing Without GitHub

If you cannot or don't wish to use GitHub, you are still welcome to
contribute. In that case, the easiest way to do so is to contact us via
email at [diligentcircle@riseup.net](mailto:diligentcircle@riseup.net).
For contributing code, diff patches are acceptable, or (more preferably)
you can send us a link to your own public Naikari Git repository clone
with your changes committed. If you need assistance with this, feel free
to ask.
