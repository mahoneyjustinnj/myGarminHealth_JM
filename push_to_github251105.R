gc() #garbage collection, to clear the memory
setwd("/cloud/project/GarminHealthAPP_JM/myGarminHealth_JM")
# Check if R’s process can see the SSH agent socket; if empty, system() won’t use your SSH key
#system("echo $SSH_AUTH_SOCK")

# Start a new ssh-agent process and print its environment variables
system("ssh-agent -s")
# > system("ssh-agent -s")
# SSH_AUTH_SOCK=/tmp/ssh-vjzPlQp5qnvL/agent.1239; export SSH_AUTH_SOCK;
# SSH_AGENT_PID=1240; export SSH_AGENT_PID;
# echo Agent pid 1240;

# Export the SSH agent variables into R’s environment so system() can use them
Sys.setenv(SSH_AUTH_SOCK="/tmp/ssh-vjzPlQp5qnvL/agent.1239", SSH_AGENT_PID="1240")

#######TROUBLESHOOTING#######TROUBLESHOOTING#######TROUBLESHOOTING
system("echo $SSH_AUTH_SOCK")  # 'system()' runs a shell command; here it prints the value of SSH_AUTH_SOCK
# Check if ssh-agent process is running
system("ps -e | grep ssh-agent")
# Check if the socket file path is valid
system("ls -l /tmp/ssh-XVsPZigLfQ1T/agent.767")
cat("\014")
# 1. Start a new ssh-agent process; this prints out environment variables like SSH_AUTH_SOCK and SSH_AGENT_PID
system("ssh-agent -s")

# 2. After running the above, copy the real values it prints (e.g., SSH_AUTH_SOCK=/tmp/...; SSH_AGENT_PID=2029)
#    Export those values into R’s environment so subsequent system() calls can use them
Sys.setenv(SSH_AUTH_SOCK="/tmp/ssh-rIhDlcsw8n6p/agent.2029", SSH_AGENT_PID="2030")  # replace with actual values shown

# 3. Confirm R now sees the correct socket path
system("echo $SSH_AUTH_SOCK")

# 4. Add your private SSH key to the agent so Git commands can authenticate
system("ssh-add /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM/.ssh/sas_key")



#######TROUBLESHOOTING#######TROUBLESHOOTING#######TROUBLESHOOTING


# Add your SSH private key to the agent so git commands can authenticate
system("ssh-add /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM/.ssh/sas_key")
#system("ssh-add /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM/.ssh/sas_key")
getwd()

# Test the SSH connection to GitHub from inside R
system("ssh -T git@github.com")
# Hi mahoneyjustinnj! You've successfully authenticated, but GitHub does not provide shell access.

# Check the remote URL to ensure it’s using SSH instead of HTTPS
system("git remote -v")
# origin	git@github.com:mahoneyjustinnj/myGarminHealth_JM.git (fetch)
# origin	git@github.com:mahoneyjustinnj/myGarminHealth_JM.git (push)
# Step 2: Commit the staged changes with a descriptive message

system("git status")
###########################################################################
# Daily GitHub Update and Tagging Workflow
# This script:
#   - Pulls the latest changes from GitHub
#   - Stages and commits today’s updates
#   - Pushes the commit to the remote repository
#   - Creates and verifies a daily version tag
#   - Pushes the tag to GitHub for tracking
###########################################################################
# Step 0: Make sure your local branch is up to date with GitHub
system("git pull origin main")
# Step 1: Stage all new, modified, and deleted files for commit
system("git add .")
# Step 2: Commit the staged changes with a descriptive message
system("git commit -m 'Daily update of Garmin CSVs 2025-12-15'")
# Step 3: Push the new commit to the remote GitHub repository
system("git push origin main")
# Step 4: Create a version tag for today's update
system("git tag v2025-12-15")
# Step 4b: Verify that the new tag was created locally
system("git tag")
# Step 5: Push the new tag to GitHub so it’s available remotely
system("git push origin v2025-12-15")



 