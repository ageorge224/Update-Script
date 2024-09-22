#!/bin/bash

# Replace "Your commit message here" with your desired message
commit_message="Automated commit"

# Add all changes to the staging area
git add .

# Commit the changes with the specified message
git commit -m "$commit_message"

# Push the changes to the remote repository
(replace "origin" with your remote name)
git push origin master
