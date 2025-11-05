gc() #garbage collection, to clear the memory
setwd("/cloud/project/GarminHealthAPP_JM/myGarminHealth_JM")

# system("mkdir -p /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM.ssh")
system("cd ~ ; pwd")
system("mv sas_key /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM/.ssh/")
system("ls /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM/.ssh/ ")
system("chmod 600 /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM/.ssh/sas_key")
system("ssh-agent -s")
system("export SSH_AUTH_SOCK;export SSH_AGENT_PID")
system("ssh-add /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM/.ssh/sas_key")

#RUN IN TERMINAL DIRECTLY
# 1#eval "$(ssh-agent -s)"
# 2#ssh-add /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM/.ssh/sas_key
# 3#ssh -T git@github.com
#CHECKS:
system("git remote -v")


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

# This command updates your Git repository's remote URL to use SSH instead of HTTPS.
# It tells Git to connect to GitHub using your SSH key for authentication,
# which avoids the need for a username/password or personal access token (PAT).
system("git remote set-url origin git@github.com:mahoneyjustinnj/myGarminHealth_JM.git")

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
# This will:
# Remove the old CSVs from your local repo (but keep them on GitHub history)
# Add the new CSVs
# Create a clean version snapshot (v2025-10-09) you can refer back to anytime
# Step 1: Stage all changes — including new files, modified files, and deletions.
# This ensures your daily CSV updates (even with new filenames) are tracked.
system("git add .")
# Step 2: Commit the staged changes with a descriptive message.
# This records a snapshot of today's update in your Git history.
system("git commit -m 'Daily update of Garmin CSVs 251031' ")
# Step 3: Push the commit to the remote GitHub repository.
# This syncs your local changes with the GitHub version of your project.
system("git push origin main")  # Without this, your updates stay local and aren't visible on GitHub.
# Step 4: Create a version tag for today's update.
# This marks a specific point in history so you can easily refer back to this exact version later.
system("git tag v2025-10-24")   # Without tagging, you lose the ability to track daily versions precisely.
# Step 5: Push the tag to GitHub.
# This makes the version tag available remotely, so you (or collaborators) can access it anytime.
system("git push origin v2025-10-24")  # Without this, the tag only exists locally and isn't backed up.

#######################check local tag
# Check if the tag exists locally
system("git tag")

########################### Receover yesterday's csv's to test recovery of files
# Step 1: This lists all commits in reverse chronological order. 
# Look for the one from October 8 that likely contains the old CSVs.
system("git log --oneline")
# Step 2: This shows the details of commit 6c5c826, including which files were added or modified.
# This helps confirm that the old CSVs are in this commit.
system("git show 2bdf1c7")
# Step 3: This restores the old CSV from the October 8 commit (2bdf1c7) into your working directory.
# It pulls the file without switching branches.
system("git checkout 2bdf1c7 -- clean_data/hrv_bytime2025-10-08.csv")
system("git checkout 2bdf1c7 -- clean_data/heartrate_bytime2025-10-08.csv")
system("git checkout 2bdf1c7 -- clean_data/RemLevelStatsByTime2025-10-08.csv")
system("git checkout 2bdf1c7 -- clean_data/sleepQualStatsDate2025-10-08.csv")
system("git checkout 2bdf1c7 -- clean_data/respirStatsDate2025-10-08.csv")
system("git checkout 2bdf1c7 -- clean_data/heartrateStatsDate2025-10-08.csv")
#create a tagged snapshot of yesterdays csv's

# Step 4: This commits the restored October 8 CSVs to your local Git repo.
# The `-a` flag tells Git to automatically stage all tracked files that have been modified or deleted.
# The `-m` flag lets you include a commit message directly in the command.
# So `-am` means: "Stage all changes to tracked files and commit them with this message."
system("git commit -am 'Restore October 8 CSVs'")
# Step 5: This creates a tag named v2025-10-08 pointing to the current commit.
system("git tag v2025-10-08")
# Step 6: This pushes both the commit and the tag to your GitHub repository.
system("git push origin main --tags")

#######restore the files from today 251009 into 'main'
# This restores the October 9 CSVs from the commit where they were last present.
system("git checkout 6c5c826 -- clean_data/hrv_bytime2025-10-09.csv")
system("git checkout 6c5c826 -- clean_data/heartrate_bytime2025-10-09.csv")
system("git checkout 6c5c826 -- clean_data/RemLevelStatsByTime2025-10-09.csv")
system("git checkout 6c5c826 -- clean_data/sleepQualStatsDate2025-10-09.csv")
system("git checkout 6c5c826 -- clean_data/respirStatsDate2025-10-09.csv")
system("git checkout 6c5c826 -- clean_data/heartrateStatsDate2025-10-09.csv")
# This commits the October 9 files back into your main branch.
system("git commit -am 'Restore October 9 CSVs after tag snapshot'")
# This pushes the updated main branch to GitHub.
system("git push origin main")
