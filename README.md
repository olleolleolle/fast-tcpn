FastTCPN (fast-tcpn) library technical documentation
========

Fast simulation tool for Timed Colored Petri Nets (TCPN)
described using convenient DSL and imperative programming
language (Ruby).

This tool provides library to represent TCPN model and exposing
require API. It also provides DSL that facilitates creating the
TCPN model.

TCPN DSL
--------

DSL is meant to enable convenient creation of the TCPN model. It
can be interpreted from a file or directly from a block in Ruby
program.

TCPN described using the DSL consists of at least one page, thus
the description must start with `page` statement. Inside page,
timed and not timed places can be defined using `timed_place` and
`place` statements. Objects returned by these statements
represent places. Transitions are created using `transition`
statement. For each transition one defines its input and output
places.

### Pages

Pages of TCPN have a name and their content is defined by block
of code:

     page "My first model" do
       # put your model here
     end

Page names are used in error messages to facilitate location of
problems.

### Places

Places of TCPN are identified by their names. Each place can
appear on numerous pages. For the sake of efficiency, the tool
provides two statements defining places. If tokens in a place
should not consider time, one should use normal `place`
statement. If time is important and tokens should be delayed in a
place if their timestamp requires, one should create such place
using `timed_place` statement. Simulation with not timed places
is faster, especially for significant number of tokens, thus one
should use not timed places wherever it is possible.

Marking implemented in this tool use hashes to efficiently store,
match and remove tokens from places. However, defining proper
criterions to index tokens in places is responsibility of the
person creating model. Thus defining places, one can pass
additional parameter defining keys that will be used to quickly
locate tokens in this particular place. For instance if one knows
that tokens in place called `:process` will be used in two
transitions, first of the need to match process tokens using
their `name` and second using value returned by `valid?` method
of token value, these two values can be used to index tokens in
this place. This place would be created using e.g.

     place :process, name: :name, valid: :valid?

The first value of pair is the name of the criterion (key),
second is the method that will be called on token's value, to
obtain actual value used while indexing. Tokens from the above
defined place will be be easily accessible using key `:name` and
values returned by their method `name` and using key `:valid` and
values returned by their method `:valid?`.

If the method called on token value needs parameter, then the value of
in the hash may be an array: [ :method_name, method, parameters ], e.g.:

     place :process, name: :name, valid: :valid?, owner: [ :get_owner, "Jack" ]

If a place exists on different pages with different keys, the
keys from different place definitions will be merged.
This method of token indexing is used in both: timed and not
timed places.


### Transitions

Transitions are defined using `transition` statement and
identified by name. They must exist on at most one page of the
model. Block passed to transition defines its input and output
places.

#### Input places

This example defines transition with one input place and no
output places. Variable `process` passed to the `input` statement
must be a `place` object returned by `place` or `timed_place`
statement. There are no input arc inscriptions. Read description
of `sentry` to see how tokens from input places are used.

     transition "work" do
       input process
     end

#### Output places

Output places of transition are defined using its `output`
statement. This statement gets `place` object (returned by `place`
or `timed_place` statement) and a block of code. The block states
for output arc expression and is used to decide what token should
be put in the output place, for specified binding and simulation clock.

The block passed to `output` statement gets two parameters:
+binding+ and +clock+. The +binding+ is a hash with names of
input places as keys and tokens that will be removed from these
places as values. Currently only single tokens are removed. Value
returned by the block will be treated as value of token that
should be put in output place. Or if correct token object is
returned it will be put it the place.

If output place is timed, it is possible to set both: value nad
timestamp of the output token. It can be done by returning hash:

     { val: token_value, ts: token_timestamp }

If input place is also timed and only timestamp of token should
be changed when putting it in output place, this can be done
using `with_timestamp` method:

     binding[:cpu].with_timestamp + 100

To return more then one token to a place just return an Array --
all definitions or tokens from the Array will be put into the
place's marking.

Complete definition of two places and transition with one input
and one output place can be defined as follows:

     process = place :process, { name: :name, valid: :valid? }
     done = place :done

     transition "work" do
       input process
       output done do
         binding[:process].name + "_done"
       end
     end

When fired it will get a process token from the place called
`:process` and put in place called `:done` a token with value
being a string being the process name with string `"_done"`
appended.


#### Sentries (variation of guards)

For the sake of efficiency, this tool does not implement
traditional guard, understood as a method that gets a binding and
returns true or false. For TCPNs described using imperative
language, this approach requires analysis of whole Cartesian
product of input markings. 

Instead a `sentry` can be defined for a transition, that lets the
person that create TCPN model implement significantly faster
solution for the same problem. The sentry is a block of code that
receives markings of subsequent places and is supposed to
generate a list of valid bindings. It should do it in the most
efficient way, that is best known to the model creator, as he is
the person that knows all specifics of modeled reality and token
values used. The tool for each place provides access to its
marking in random order, to ensure fairness, consequently the
only concern of the person implementing sentry is to correctly
match tokens. If keys used to index tokens in input places are
defined correctly, one can immediately access list of tokens
matching selected criterion and iterate.

The block defining `sentry` takes three arguments:
* `marking_for` -- a hash with place names as keys and place
  markings as values
* `clock` -- current value of simulation clock
* `result` -- variable used to collect valid bindings.
Using information from `marking_for` and `clock` parameters, the
block is supposed to push subsequent valid bindings to the
`result` variable using `<<` operator. Each valid binding must be
of the form of Hash with input place names as keys and token
as values:

     result << { process: token1, cpu: cpu5 }

To get more then one token to fire a transition, you can put
array of tokens as value in the mapping passed to the `result`
like this:

     result << { process: [ token1, token2 ], cpu: cpu5 }

In current implementation of the tool, only the first mapping
passed to the `result` will be used and the sentry block will not
be subsequently evaluated. It is however better to implement it
as iteration over all possible valid bindings for possible future
uses.

Example model with one transition that is supposed to match
process tokens with correct CPUs, pass process names to `done`
place and return delayed CPUs to their place will look as
follows.


    page "Example model" do
       p1 = place :process, { name: :name }
       cpu = timed_place :cpu, { process: :process }
       p2 = place :done

       transition 'run' do
         input p1
         input cpu
         output p2 do |binding|
           binding[:process].value.name.to_s + "_done"
         end
         output cpu do |binding, clock|
           binding[:cpu].with_timestamp clock + 100
         end

         sentry do |marking_for, clock, result|
           marking_for[:process].each do |p|
             marking_for[:cpu].each(:process, p.value.name) do |c|
               result << { process: p, cpu: c }
             end
           end
         end
       end
     end

Place `:process` uses key `:name` as an index, it is not however
used in this model. As cpus are matched to processes using value
returned by `cpu.process` method, the CPUs are indexed by this
value. This allows in `sentry` iteration over cpu tokens that
match process name selected before:

      marking_for[:cpu].each(:process, p.value.name) do |c|

In this case the first matching pair is returned as no additional
conditions should be met.

If we know that every process from `:process` place can be
used to fire transition and only correct CPU must be matched, we
start iteration from processes. If we started from CPUs, we could
find some CPUs without matching processes and the sentry would be
slower. This reasoning is however responsibility of model
creator, as it strongly depends on specifics of the model (one
should know that every process has at least one CPU, but some
CPUs may match processes that were already served).

### Pages in pages in pages ...

One page can contain not only places and transitions, but also
definitions of subsequent pages.

### Subpages from files

It is possible to load a subpages from separate files using
`sub_page` statement:

     page "Test model" do
       sub_page 'network.rb'
       sub_page 'cpus.rb'
     end

A subpage can also contain subpages loaded from another files.
Paths used to locate files mentioned in subpages are interpreted
as relative to location of currently interpreted file.

Using TCPN model
----------------

### Loading model

The model described by the DSL can be saved in separate file and
loaded using `TCPN.read` method:

     tcpn = TCPN.read 'model/example.rb'

If the model contains subpages in separate files, they will be
loaded from paths relative to the location of the `example.rb`
file.

One can also embed the model directly in Ruby program and
interpret using `TCPN.model method`

     tcpn = TCPN.model do
       page "Example model" do
         # places and transitions here...
       end
     end

Model objects returned by these methods can be used to start
simulation and define callbacks.


### Place Marking

After the model is created, place marking can be set. It can be
done using one of the following methods.

* Find place by name and add tokens to it

     tcpn.find_place(:process).add a_process_object
     tcpn.find_place(:process).add array_of_process_objects

* Add marking for specified place of the TCPN (old API, derived
  from tcpn gem)

     tcpn.add_marking_for(:process, a_process_object)

To check marking, use one of the following methods:

* Find place by name and iterate over its marking:

     tcpn.find_place(:process).marking.each

* Get marking of specified place of TCPN (old API, derived
  from tcpn gem)

     tcpn.marking_for(:process).each

More details on methods of the model can be found in [API doc for
TCPN class](link:FastTCPN/TCPN.html). More details on methods of
the place objects can be found in [API doc for Place
class](link:FastTCPN/Place.html).

### Simulation

Simulation of the model can be started using `sim` method.

    tcpn.sim

This method will return when simulation is finished.

Simulation finishes whe there is no more transitions to fire even after
advancing simulation clock. It can also be stopped manually by calling
`#stop` method:

    tcpn.stop

This method can be used e.g. in callbacks (see below).

After simulation has finished, it is possible to check if it was
finished manually using `#stopped?` method.

    if tcpn.stopped?
      puts "Simulation was stopped manually."
    else
      puts "Simulation has finished. No more transitions to fire."
    end

### Callbacks

Convenient way to obtain results of simulation is provided by
callbacks. They can be defined 

* for transitions (before and after firing)
* for places (when adding and when removing tokens)
* for clock (before and after changes)

Callbacks are defined using `TCPN#cb_for` method. First parameter
of the method defines if the callback concerns transitions
(`:transition`), places (`:place`) or clock (`:clock`). Second
optional parameter defines when callback should be fired:

* for transition it can be either `:before` or `:after`
* for place it can be `:add` or `:remove` 
* for clock it can be either `:before` or `:after`

If this parameter is omitted, callback will be fired in both cases.

The block passed to `#cb_for` gets two parameters: first is value
of the tag defining when callback is fired (`:before` or `:after`
transition is fired, while `:add`ing or `:remove`ing tokens from
places). Second parameter is event object holding details of the
event. It is:

* for transition callback -- Transition::Event object with
  fields:
    * `transition` -- name of transition being fired
    * `binding` -- token binding used to fire (`place => token(s)`
    Hash)
    * `clock` -- current clock value
    * `tcpn` -- TCPN object representing network being run
* for place callback -- Place::Event
    * `place` -- name of place being changed
    * `tokens` -- list of tokens added ore removed
    * `clock` -- current simulation clock (only for timed places,
    for not timed this is `nil`
    * `tcpn` -- TCPN object representing network being run
* for clock callback -- TCPN::ClockEvent object
    * `clock` -- current value of simulation clock
    * `previous_clock` -- previous value of simulation clock (for
    `:before` this one is `nil`)
    * `tcpn` -- TCPN object representing network being run

## Known Errors and Pitfalls

### Arrays and Hashes as token values

Arrays and Hashes are used to describe tokens (their list, values and
timestamps). Therefore passing an Array or a Hash that itself should be
a token value will not work. If you need to do it, either encapsulate
the Array or the Hash into your own class or just create an empty class
that extends Array or Hash -- this should work too.

### Cloning problems

Due to nature of TCPN based on functional paradigm TCPN tokens
are immutable. To achieve this in Ruby (and other imperative
languages cloning token values is crucial for correct behavior of
TCPN simulation.

Unfortunately, some Ruby objects cannot be cloned. One example is
Enumerator that was already started (#next was called at least
once). If you put such value in a token, simulation will fail, as
the token will not be cloned. Use your own implementation of
enumeration instead. Please report any other built-in classes
that cause simulation problems.


### TODO

* Possible optimization can be achieved by implementing
  clone-on-write instead of eager cloning every time when a token
  is passed to user-provided code. We can use
  https://github.com/dkubb/ice_nine to deeple freeze token
  objects, catch exception indicating that a modification was
  tried, clone object and redo the modification on the clone. In
  short. It is not easy and there is no guarantee that overhead
  of the solution won't level gains resulting from lazy cloning.
* Add traditional guard to enable quick prototyping. This however
  requires a king of input arc inscriptions, as currently this is
  implemented in sentry and will not have its place in the
  traditional guard. Maybe we could allow traditional guards only
  for transitions that remove single tokens? They will not be
  recommended way of implementing this anyway.
* Currently, HashMarking uses own implementation of
  `lazy_shuffle` to provide tokens in random order. This is meant
  to be possibly fast for small number of tokens yielded. It
  requires benchmarking for cases when most or all tokens from
  marking should be yielded and probably should be reworked for
  these cases. I expect it to be a problem for cases when there
  are tokens in input places, but they do not meed requirements
  and transition cannot be fired -- then probably all tokens will
  be checked by sentry of this transition.
  
  
  
  
# Copyright

Copyright (c) 2014-2018 Wojciech Rząsa. See LICENSE.txt for further details. Contact me if interested in different license conditions.
