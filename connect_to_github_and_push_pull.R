gc() #garbage collection, to clear the memory
setwd("/cloud/project/GarminHealthAPP_JM/myGarminHealth_JM")

# this system command is same as running from the command line
# gives list of remote repositories connected to your local Git project,
system("git remote -v")
# result:
# origin	https://github.com/mahoneyjustinnj/myGarminHealth_JM.git (fetch)
# origin	https://github.com/mahoneyjustinnj/myGarminHealth_JM.git (push)

#check that the github repo is the 'master' (or main) branch
system("git branch")
# result:
#   * main

#show the latest commit
system("git log -1")
# commit 3ae5dd646eb8ccb36e3614cd9f897244db42a713
# Author: mahoneyjustinnj <mahoneyjustin@hotmail.com>
#   Date:   Wed Sep 24 19:55:09 2025 +0000
# 
# Initial commit (cleaned)

# This will fetch and merge any new commits from your GitHub repo (cleaned_contracts) into your Posit Cloud workspace.
system("git pull origin main")
# From https://github.com/mahoneyjustinnj/myGarminHealth_JM
# * branch            main       -> FETCH_HEAD
# Already up to date.

# the following gives the log of that just happened
system("git log --oneline")
#3ae5dd6 Initial commit (cleaned)

#this gives the status of the pushes and pulls
system("git status")
# On branch main
# Your branch is up to date with 'origin/main'.
# Changes not staged for commit:
#   (use "git add/rm <file>..." to update what will be committed)
# (use "git restore <file>..." to discard changes in working directory)
# deleted:    .gitigore
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
# .gitignore
# connect_to_github_and_push_pull.R
# no changes added to commit (use "git add" and/or "git commit -a")

#########second addition to github
#first, i want to add the untracted files to github 
#all at once using:
system("git add .")

#2nd - i will commit the changes using:
system("git commit -m 'added the simulated heart rate dataset that is compiled and joined'  ")
# [main 068ee51] adding latest updates to my health repo
# 3 files changed, 85 insertions(+), 1 deletion(-)
# create mode 100644 .gitignore
# delete mode 100644 .gitigore
# create mode 100644 connect_to_github_and_push_pull.R

# 3rd - i will push the changes to github
system("git push origin main")
# To https://github.com/mahoneyjustinnj/myGarminHealth_JM.git
# 3ae5dd6..068ee51  main -> main

#get the status
system("git status")
# On branch main
# Your branch is up to date with 'origin/main'.
# Changes not staged for commit:
#   (use "git add <file>..." to update what will be committed)
# (use "git restore <file>..." to discard changes in working directory)
# modified:   connect_to_github_and_push_pull.R
# 
# no changes added to commit (use "git add" and/or "git commit -a")





