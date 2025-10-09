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

#check what’s ignored by running:
system("git status --ignored")

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
system("git commit -m 'add new csv datasets from daily pull- deleted older'")
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

#to delete files from github
setwd("/cloud/project/GarminHealthAPP_JM/myGarminHealth_JM")
#remove files from the repo
system("git rm -r figure") # Delete the folder and its contents
# Commit the change
system("git commit -m 'Delete the figure folder and its contents'")
# Push the change to GitHub
system("git push")


######## align everything in github with the local changes i made in this posit folder
#get the status
system("git status")

# remove tracked files that were moved into /archive
system("git rm --cached HR_anomaly_251003BETA.html HR_anomaly_251006BETA.html anom-tabl.html heartRate250926.html hrv251003.html hrv251006.html kruskall.html kruskall_250106_hrv.html kruskall_bpm_comparison.html read_HR250926.Rhtml read_HR250926.html read_HR250929.Rhtml read_HR250929.html read_HR251001.Rhtml read_HR251001.html test.Rhtml")

# stage the modified .gitignore file
system("git add .gitignore")

# commit the removal of tracked files and the updated .gitignore
system('git commit -m "Remove archived files from tracking and update .gitignore to ignore /archive"')

# push committed changes to GitHub
system("git push origin main")

####### i deleted a number of files from clean_data; i need to sync the repo with these changes
# Stage the deleted files and the modified script
system("git add -u")  # This stages modifications and deletions (but not new untracked files)

# Optional: double-check what's staged
system("git status")

# Commit the changes
system("git commit -m 'Deleted outdated health CSVs and updated connection script'")

# Push to GitHub
system("git push origin main")

#########################################################
################## Version Controlling ##################
#########################################################

# Step 1: Stage all changes — including new files, modified files, and deletions.
# This ensures your daily CSV updates (even with new filenames) are tracked.
system("git add .")

# Step 2: Commit the staged changes with a descriptive message.
# This records a snapshot of today's update in your Git history.
system("git commit -m 'Daily update of Garmin CSVs'")

# Step 3: Push the commit to the remote GitHub repository.
# This syncs your local changes with the GitHub version of your project.
system("git push origin main")  # Without this, your updates stay local and aren't visible on GitHub.

# Step 4: Create a version tag for today's update.
# This marks a specific point in history so you can easily refer back to this exact version later.
system("git tag v2025-10-08")   # Without tagging, you lose the ability to track daily versions precisely.

# Step 5: Push the tag to GitHub.
# This makes the version tag available remotely, so you (or collaborators) can access it anytime.
system("git push origin v2025-10-08")  # Without this, the tag only exists locally and isn't backed up.



