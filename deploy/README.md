Deploying Stats
==============================================================================

We're using Ansible. It is what it is.

Building Releases
------------------------------------------------------------------------------

Before you can deploy the Elixir code, you need to build a release. Head over
to `//rel/README.md` for details, then come back here.

Dependencies
------------------------------------------------------------------------------

You need to install Ansible and the other Python package dependencies. Assuming
you have run `//dev/bin/setup` -- which creates a `virtualenv` for this repo --
you can then:

    pip install -r requirements.txt
    
After that, you should have `ansible` and friends available in the path.

Now you need to install the Ansible collections we're using:

    ansible-galaxy install -r ansible-requirements.yaml

Playbooks
------------------------------------------------------------------------------

As of writing, this repo does **_NOT_** include playbooks to address a freshly
spun-up server. This is an artifact of history -- we've only deployed on 
`pixeldust` as of now (2021-03-04), and the playbooks to take a new instance 
to where this repo expects it is still in `nrser/bogart`. So that needs to be
addressed at some point. Moving on...

### Secrets ###

Pretty much all of the playbooks use variables that contain secrets. Those 
secrets are kept in the organization's `Dev` 1Password vault, and Ansible pulls
them out when asked.

For this to work, you need to have the 1Passwords command line tool available.
I... don't remember how I installed it. It's called `op` and on my macOS it's at
`/usr/local/bin/op`. Maybe I got it from the website?

Anyways, get it, and update this to be better.

After that, **in the terminal you will run `ansible-playbook`**, execute

    eval $(op signin)

> 📢 You might need to do something different the _first_ time. That command is
> what I have to run every time right now.

That command exports a token into the environment that is good to retrieve data
from 1Password for some short period. Once it expires, you'll need to repeat 
the command.

### Storage ###

The `Stats` Elixir app needs PostgreSQL and Kafka. Those are installed with

1.  `playbooks/kafka.yaml`
2.  `playbooks/db.yaml`

which are run like

    ansible-playbook playbooks/kafka.yaml
    
Order should not matter between these.

### BEAM ###

Right now, the version to deploy is hardcoded in

    inventory/group_vars/beam.yaml

as the `STATS_BEAM_VERSION` variable. This needs to be changed, I just haven't
figured out exactly how yet. But you may need to change that if the `version` in
`//mix.exs` has changed (from `0.1.0`).

The playbooks to run are:

1.  `playbooks/beam/setup.yaml` -- only the _first_ time deploying to a server, or if
    the Erlang, Elixir, or NodeJS version changes. Or if Nginx or Docker are 
    not yet on the target. None of these are true for `pixeldust` right now.
    
2.  `playbooks/beam/deploy.yaml` -- copies and extracts the Elixir release
    archive. Always need to run this.
    
3.  `playbooks/beam/config.yaml` -- configures Nginx virtual server and Systemd
    service. Always need to run this.

That... should do it. Good luck.
