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

# Confirm R now sees the SSH agent socket
system("echo $SSH_AUTH_SOCK")

# Add your SSH private key to the agent so git commands can authenticate
system("ssh-add /cloud/project/GarminHealthAPP_JM/myGarminHealth_JM/.ssh/sas_key")

# Test the SSH connection to GitHub from inside R
system("ssh -T git@github.com")
# Hi mahoneyjustinnj! You've successfully authenticated, but GitHub does not provide shell access.

# Check the remote URL to ensure it’s using SSH instead of HTTPS
system("git remote -v")
# origin	git@github.com:mahoneyjustinnj/myGarminHealth_JM.git (fetch)
# origin	git@github.com:mahoneyjustinnj/myGarminHealth_JM.git (push)

###########################################################################
# Step 0: Make sure your local branch is up to date with GitHub
system("git pull origin main")



 