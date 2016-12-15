# Simple Credential Store
Some items in DevOps Weekly (<https://github.com/sorah/envchain>) & SRE Weekly and a poke by [electrofelic](https://github.com/electrofelix) recently prompted me to write up how we handle user-focussed access credentials. This is Part 1 of a 2 part series, we'll build on this post to show how we share a set of credentials among a team, but for now I'll cover how I store & switch between credentials sets (in this example, for AWS credentials, but I've used the same technique OpenStack credentials and many other tools & services that can consume sensitive data from environment variables, removing the need to have them written to disk un-encrypted.

Assumptions - you have a working local gpg setup, on my MacBook I'm using [GPG Suite](https://gpgtools.org/), but this has also been used with [homebrew](http://brew.sh/) based gpg & stock gpg on Ubuntu.

## Overview - what do we want?

I want to be able to switch between credential sets easily & not leave unencrypted secrets on disk, here's an example:

    $ env | grep AWS
    $ source ~/.aws-personal
    Agent started: GPG_AGENT_INFO=/tmp/gpg-w557gr/S.gpg-agent:86086:1
    $ env | grep ^AWS
    AWS_DEFAULT_KEYPAIR=simonm
    AWS_SSH_KEY_ID=jobdoneright
    AWS=jdr
    AWS_DEFAULT_REGION=eu-west-1
    AWS_SECRET_ACCESS_KEY=supersecretaccesskey
    AWS_ACCESS_KEY_ID=accesskey1234
    AWS=jdr $

I have multiple `.aws-XXX` files for various environments, I switch between them by sourcing the appropiate file - the primary file being sourced shouldn't contain any secrets, it's in plain text after all, but it does trigger using gpg to decrypt a secret and store it in an environment variable.

Here's what `~/.aws-personal` looks like:

    export AWS=jdr
    export EC2_URL=https://eu-west-1.ec2.amazonaws.com
    export AWS_ACCESS_KEY_ID='madeupaccesskey'
    export AWS_SSH_KEY_ID='namedkeypair'
    export AWS_DEFAULT_KEYPAIR='namedkeypair'
    export AWS_DEFAULT_REGION='eu-west-1'

    export EXPORT_SECRET_AS="AWS_SECRET_ACCESS_KEY"

    # export the name of this file and call the common decrypt logic
    OPENRC=${BASH_SOURCE[0]:-$0}
    KIT_HOME="$( cd "$( dirname "${OPENRC}" )" && pwd )"
    . ${KIT_HOME}/decrypt-secrets.sh

So we can setup any environment variables we need (`AWS_SSH_KEY_ID` for example is used in the Chef tooling, but `AWS_DEFAULT_KEYPAIR` is used by some of the older EC2 tools, I think...)  The clever bit is in the last few lines, where we setup to call [decrypt-secrets.sh](https://github.com/simonmcc/simple-credential-store/blob/master/decrypt-secrets.sh) by setting OPENRC to the name of the current file being sourced.

TODO: Explain what decrypt-secrets.sh does

Here's how I create a secret file:

    echo thisissomethingimadeup | gpg --encrypt --armour -r simon@mccartney.ie -o .aws-personal.secret.gpg -

## Why this approach, tool x already does this?

Build on existing simple tools, provide a minimal amount of glue & don't incur any new dependencies, to this end, we use gpg & bash, 2 tools either on or available to any modern *nix based system (I've used this on Ubuntu & OSX of various flavours).


# Room for improvement?

Of course!  There are a few areas where this could be improved:

* Make creating credential sets easier, in particular the secret creation
* Improve the "do we have a working gpg setup" validation.
