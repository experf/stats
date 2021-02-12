Welcome!
==============================================================================

To the sparse documentation of our nascent statistics system.

We have...

[Elixir API Reference][]
------------------------------------------------------------------------------

Strait from the source itself! Technical documentation generated directly from
the definitions and `@doc` annotations in our Elixir files.

Covers the various modules and `Mix` tasks that make up our main service.

Stats is an _umbrella_ project where the functionality is divided between
several _applications_, found in the `apps` directory of the repo. Each 
_application_ is its own `Mix` project, with inter-dependencies declared
in their `apps/${APP_NAME}/mix.exs` files.

### Core Modules

#### [Cortex](`Cortex`)

The "head" of the stats system — core business logic and data handling. In
charge of the _state_ of the service.

Communicates "down" the stack to the data storage services (Postgres, Kafka)
and exposes an interface to `CortexWeb` and any future _applications_ "up" the
stack to interact with the _state_.

#### [CortexWeb](`CortexWeb`)

Web interface using the `Phoenix` framework. Speaks `HTTP`.

Depends on `Cortex` to query and operate on the service _state_.

### Support Modules

Independent modules that the code _applications_ depend on for various
functionality. These are broken out from the core modules because:

1.  Provides a clean separation and enforces a clear boundary around the module.
    
2.  Helps keep module names, directory lists and file paths short.
    
3.  Provides a iterative path for functionality that may be destined to become
    it's own independent package shared between multiple projects.

#### [Subscrape](`Subscrape`)

Scrappy, scrape-y [Substack][] API client for reading newsletter stats.

******************************************************************************

[umbrella project]: https://elixirschool.com/en/lessons/advanced/umbrella-projects/
[Elixir API Reference]: api-reference.html
[Substack]: https://substack.com/
