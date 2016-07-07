# Oldest Changeset

## Setup

    export GERRITDOMAIN='gerrit.YOUR-COMPANY.com'
    export GERRITUSER='abc...'
    export GERRITHTTPPASSWORD='xyz...'

Note: Your Gerrit http password is generated for you in gerrit's
settings

## Run it

    ruby runner.rb project_name1,project_name1 group_name

Note: project names and group name are case-sensitive!

Creates a `open_changesets.html` file.

