FastTCPN
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

In current implementation of the tool, only the first passed
value will be used and the block will not be subsequently
evaluated.

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

### Simulation

TODO

### Callbacks

TODO
