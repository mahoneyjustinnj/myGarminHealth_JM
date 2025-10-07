# Step 1: Set your working directory to the folder where you want to clone the repo
# This folder should contain your .gitignore file with sensitive tokens listed
setwd("/path/to/your/local/folder")  # Replace with your actual path

# Step 2: Initialize a new Git repo in this folder
# This creates a .git folder and prepares Git to track changes
system("git init")

# Step 3: Add the remote GitHub repository
# Replace the URL with your actual GitHub repo URL
system("git remote add origin https://github.com/your-username/your-repo-name.git")

# Step 4: Pull the latest content from GitHub
# This brings in all files from the main branch of your GitHub repo
system("git pull origin main")

# ⚠️ Caution: If your local folder has files that conflict with GitHub,
# Git may warn you or reject the pull. Make sure your local folder is clean
# or matches GitHub before pulling.

# Step 5: Check the status of your repo
# This shows which files are tracked, untracked, or modified
system("git status")

# Step 6: Add all files to staging (except those ignored by .gitignore)
# This prepares files for commit
system("git add .")

# Step 7: Commit your changes with a message
# This saves your staged changes locally
system("git commit -m 'Initial commit with .gitignore and setup files'")

# Step 8: Push your commit to GitHub
# This syncs your local repo with GitHub
system("git push origin main")

# ✅ At this point, your local folder is fully connected to GitHub.
# Your .gitignore is protecting sensitive files, and your repo is ready to use.



#################################################################
#first i ran in the command line
git clone https://github.com/mahoneyjustinnj/myGarminHealth_JM.git
cd myGarminHealth_JM

#then
git commit -m "Initial commit"

# then
git push https://mahoneyjustinnj:etc@github.com/mahoneyjustinnj/myGarminHealth_JM.git
