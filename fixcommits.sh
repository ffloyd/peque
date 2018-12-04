#!/usr/bin/env bash

git filter-branch -f --env-filter "GIT_AUTHOR_NAME='Roman Kolesnev';    GIT_AUTHOR_EMAIL='rvkolesnev@gmail.com'; \
                                GIT_COMMITTER_NAME='Roman Kolesnev'; GIT_COMMITTER_EMAIL='rvkolesnev@gmail.com';" HEAD

git push origin +master
