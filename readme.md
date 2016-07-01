# Oldest Changeset

## Setup

    export GERRITDOMAIN='gerrit.YOUR-COMPANY.com'
    export GERRITUSER='abc...'
    export GERRITHTTPPASSWORD='xyz..."

Note: Your Gerrit http password is generated for you in gerrit's
settings

## Run it

    ruby runner.rb project_name

Creates a `open_changesets.html` file.
