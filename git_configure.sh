#!/bin/bash
#----------------------------------------
# RELEASED BY SATHISH S, OVT
# DATE - 29.04.2024
#----------------------------------------

# ROOT_DIR=/home/git/
ROOT_DIR="/d/OVT/1000_Office_Internal/GIT_Server/"

# Defined the raw file contain project members
HOOK_FILE="hooks/pre-receive"
HOOK_ACCESS_FILE="/hooks/users_access_list.txt"

# For this for push request to user
membership_setting() {
	current_repo_hook_file="$ROOT_DIR/$selected_dir_name/$HOOK_FILE"
	current_repo_access_file="$ROOT_DIR/$selected_dir_name/$HOOK_ACCESS_FILE"
	
	action="$1"
	case "$action" in
		setup)	# Setup at the time of creating repo
			echo -e "Setup the membership configuration...."
			sleep 1
			# Empty access file create
			touch $current_repo_access_file
			
			# create a new hook file with pre-defined code (refer below)
			echo -e '
			#!/bin/bash
			# Read the authenticated username from environment variable
			AUTHENTICATED_USER="$REMOTE_USER"

			# Path to the file containing the allowed user list
			ALLOWED_USERS_FILE="$(dirname "$0")/users_access_list.txt"

			# Check if the authenticated user is in the allowed user list
			if grep -Fxq "$AUTHENTICATED_USER" "$ALLOWED_USERS_FILE"; then
				echo "Access Granded: You are authorized to push to this project."
				exit 0
			else
				echo "Access Denied: You are not authorized to push to this project...!"
				echo "Please contact your project leader."
				exit 1
			fi' > $current_repo_hook_file
			echo -e "Info: Setup Done - $selected_dir_name"
			sleep 1
			
			;;
		enable)	
			# Set the permission for hook file
			chmod +x $current_repo_hook_file
			echo -e "Info: Membership seting - Enabled - $selected_dir_name"
			sleep 1

			;;
		disable)
			# Revert the Executable permission for hook file
			chmod 664 $current_repo_hook_file
			echo -e "Info: Membership seting - Enabled - $selected_dir_name"
			sleep 1
			;;
		*)
			echo "Invalid input. Please use enable or disable or setup"
			sleep 1
			;;
	esac
	
}
# Repo project Membership enable request...
enable_membership_setting_req() {
	while true; do
		read -p "Do you want to enable repository membership access (Additional security for project)? (yes/no): " answer
		answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
		case "$answer" in
			yes|y)	# If yes means, enabling the membership seting
				membership_setting enable || exit 1
				break
				;;
			no|n)	# If no means, disabling the membership seting
				echo "Ignoring the membership configuration...You can configure later."
				sleep 1
				break
				;;
			*)
				echo "Invalid input. Please enter 'yes' or 'no'."
				sleep 1
				;;
		esac
	done
}

setting_project_repo() {
	current_repo_hook_file="$ROOT_DIR/$selected_dir_name/$HOOK_FILE"
	current_repo_access_file="$ROOT_DIR/$selected_dir_name/$HOOK_ACCESS_FILE"
	
	# Check if the current repository hook file exists and if the access file exists
    if [ -f "$current_repo_hook_file" ] && [ -f "$current_repo_access_file" ]; then 
        if [ -x "$current_repo_hook_file" ]; then
            setting="Enabled"	# Current setting of project repo 
            action="disable"	# Action to change
        else
            setting="Disabled"
            action="enable"
        fi
    else
        setting="Not configured"
        action="setup"
    fi

    echo -e "Info: Repository '$selected_dir_name' Membership setting - $setting"
	sleep 1
    read -p "Do you want to $action membership setting? (yes/no): " answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "yes" ] || [ "$answer" = "y" ]; then
        membership_setting "$action"
    else
        echo -e "Membership Setting Ignored..."
		sleep 1
    fi
}

# Function to Create Project Repository
create_project_repo() {
	# Prompt the user for input
	echo -e "Enter new Project name:"

	# Read input from the user and store it in a variable
	read repo_name
	repo_name="$repo_name.git"	# Added .git file extension
	
	# Check the given project name is not exist
	if [ ! -d "$ROOT_DIR/$repo_name" ]; then
		# Creating new repo directory
		mkdir -p "$ROOT_DIR/$repo_name" || exit
		echo -e "New project repo, directory is created - $repo_name"
		project_dir="$ROOT_DIR/$repo_name"
		
		# Check the newly created project dir is present or not
		if [ -d "$project_dir" ]; then
			cd "$project_dir"
			# Generate bare repository
			git init --bare
			sleep 3

			# Setting file and dir permission
			# Set project directories to rwx (read, write, execute) for owner & grp recursively
			find "$ROOT_DIR/$repo_name" -type d -exec chmod 775 {} +

			# Set files to rw (read, write) for owner & grp recursively
			find "$ROOT_DIR/$repo_name" -type f -exec chmod 664 {} +

			# Change the owner & grp of new repo
			chown -R git:www-data "$ROOT_DIR/$repo_name"
			echo -e "Info: Successfully created New Project - $repo_name"
			sleep 1
			
			# Configure project membership seting (extra security - project level authentication)
			selected_dir_name=$repo_name	# Store the new repo name in selected repo
			echo "$selected_dir_name"
			echo ""
			# Default it configured but not enabled
			membership_setting setup || exit 1
			
			# Use enable membership setting request
			enable_membership_setting_req
			
		else
			echo -e "Error: Newly created Project directory - $project_dir does not exist."
			sleep 1
		fi
	else
		echo -e "Info: Given project name is already there...!"
		sleep 1
	fi
}

# Function to Delete Project Repository
delete_project() {
	# Prompt the user with a yes/no question
	echo -e "Enter Project Name to delete: "
	read delete_project_name
	delete_project_dir="$ROOT_DIR/$delete_project_name.git"

	# Check whether the project directory is present or not
	if [ -d "$delete_project_dir" ]; then
		echo -e "Info: Given project repository is found."
		
		while true; do
			# Prompt for confirmation
			echo -e -n "Do you want to proceed to delete directory - $delete_project_dir \n Are you sure? (yes/no): "
			read answer
			
			# Convert the user's input to lowercase for case-insensitive comparison
			answer=$(echo -e "$answer" | tr '[:upper:]' '[:lower:]')

			# Check the user's response
			case "$answer" in
				yes|y)
					# Delete the project directory
					rm -r "$delete_project_dir" || exit
					
					# Check if the directory still exists after deletion
					if [ ! -d "$delete_project_dir" ]; then
						echo -e "Info: Project Deleted - $delete_project_dir"
						sleep 1
					else
						echo -e "Error: Deleted project is still there...!"
						sleep 1
					fi
					break
					;;
				no|n)
					echo -e "Exiting..."
					sleep 1
					break
					;;
				*)
					echo -e "Invalid input. Please enter 'yes' or 'no'."
					sleep 1
					;;
			esac
		done
	else
		echo -e "Error: Given project repository is not found...!"
		sleep 1
	fi
}

### Functions to User Settings ###
# Display the users list
list_user() {
	echo -e "user list:"
	echo -e "---------------------"
	cd "$ROOT_DIR"
	cat .htpasswd | awk -F ':' '{print $1}'
	echo -e "\n---------------------"
	sleep 1
}

# Getting current user list
get_user_list() {
	found=false  # Reset the found variable to false before each iteration
	for username in $(cat "/$ROOT_DIR/.htpasswd" | awk -F ':' '{print $1}'); do
		if [ "$username" = "$get_user" ]; then
			found=true
			break
		fi
	done
}

# Add a new user
add_user() {
	echo -e ""
	read -p "Enter a new user's Username: " new_username
	get_user=$new_username
	get_user_list
	# Check if the username is found or not. If not, add a new user
	if [ ! "$found" = true ]; then
		htpasswd /$ROOT_DIR/.htpasswd $new_username
		sleep 1
		get_user_list
		if [ "$found" = true ]; then
			echo -e "Username '$new_username' added successfully."
			sleep 1
		fi
	else
		echo -e "Username '$new_username' is already there."
		sleep 1
	fi
	
	
}

# Reseting the user's password
reset_user() {
	read -p "Enter the Username to reset password: " reset_username
	get_user=$reset_username
	get_user_list
	# Check if the username is found or not
	if [ "$found" = true ]; then
		echo -e "Username '$reset_username' is present."
		echo -e ""
		htpasswd /$ROOT_DIR/.htpasswd $reset_username
		sleep 1
	else
		echo -e "Username '$reset_username' is not present."
		sleep 1
	fi
}

# Deleting the existing user
delete_user() {
    read -p "Enter the Username to delete: " delete_user
    get_user=$delete_user
    get_user_list
    
    if [ "$found" = true ]; then
        echo "Username '$delete_user' is in the list."
		sleep 1
		while true; do
			read -p "Do you want to proceed to delete user - $delete_user ? (yes/no): " answer
			answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
			case "$answer" in
				yes|y)
					htpasswd -D "/$ROOT_DIR/.htpasswd" "$delete_user"
					get_user_list
					if [ "$found" = true ]; then
						echo "Error: Username '$delete_user' is still there"
						sleep 1
					else
						echo "User: '$delete_user' is removed"
						sleep 1
					fi
					break
					;;
				no|n)
					echo "Exiting... And back to Sub Menu"
					sleep 1
					break
					;;
				*)
					echo "Invalid input. Please enter 'yes' or 'no'."
					sleep 1
					;;
			esac
		done
    else
        echo "Username '$delete_user' is not in the list."
    fi
}

# Function to add SSH Public Key access
ssh_key_access() {
	ssh_key_file="$ROOT_DIR/.ssh/authorized_keys"
	if [ -f $ssh_key_file ]; then
		echo -e " SSH Authorized key file found. Opening..."
		sleep 1
		nano /$ROOT_DIR/.ssh/authorized_keys
	else
		echo -e " SSH Authorized key file is not found..."
		sleep 1
	fi
}

### Functions to Configure Project Member ###
# List & Select the project repo
select_project_repo() {
	# Collecting All repository names in Root director
	mapfile -t directories < <(find $ROOT_DIR -type d -name "*.git" -exec basename {} \; | sort)
	length_dir=${#directories[@]}
	 
	# Check at least minimum 1 project repository is should there
	if [ $length_dir -ge 1 ]; then
		echo -e "Select the project repository...Below mentioned"
		echo -e ""
		
		# Printing the all repo names in list
		printf "%s\n" "${directories[@]}" | nl
		echo -e ""
		while true; do
			read -p "Enter the repository no. to select repository: " selected_dir_no
			selected_dir_no=$(($selected_dir_no - 1))
			selected_dir_name=${directories[$selected_dir_no]}
			length_dir_idx=$(($length_dir - 1))		# Get max index of array
			case $selected_dir_no in
				[0-$length_dir_idx])
					echo -e "You've selected the repository - $selected_dir_name "
					sleep 1
					break
					;;
				 *)
					echo "Invalid input. Please enter a value between 1 to $length_dir"
					sleep 1
					;;
			esac
		done
	else
		echo -e "No one repository projects(Not found)...!"
		sleep 1
	fi
	echo -e ""
}

# Listing members access list (from repo)
list_members() {	# Note: This function should run after the function of 'select_project_repo'
	current_repo_hook_file="$ROOT_DIR/$selected_dir_name/$HOOK_FILE"
	current_repo_access_file="$ROOT_DIR/$selected_dir_name/$HOOK_ACCESS_FILE"
	
	#Check the file "users_access_list.txt" in corresponding project repo
	if [ -f $current_repo_access_file ]; then
		# List the users member acces list in corresponding repository project
		echo -e "Current repo -$selected_dir_name access members listed below... "
		echo -e "-----------------------"
		cat $current_repo_access_file
		echo -e "-----------------------"
	else
		# echo -e "Info: Users access member file is not found and there is no accessed to users"
		echo -e "Info: Current Selected project - $selected_dir_name is not configured user membership.
				\n Enable Project Membership in repository settings"
		sleep 1
	fi
}

# Add/remove user from in selected project repo access list
add_remove_user_in_member() {	# Note: This function should run after the function of 'select_project_repo'
	current_repo_hook_file="$ROOT_DIR/$selected_dir_name/$HOOK_FILE"
	current_repo_access_file="$ROOT_DIR/$selected_dir_name/$HOOK_ACCESS_FILE"
	action=$1
	
	# Function to add/remove user from selected repo member list
	add_remove_action() {
		echo -e "Enter the username to $action access to current selected - '$selected_dir_name' project repo..."
		read -p "Enter the username: " username_action	
		case $action in
			add)
				# Verify the given username in users list (To confirm authorized user or not)
				get_user=$username_action
				get_user_list
				# Check if the username is found or not
				if [ "$found" = true ]; then
					echo "$username_action" >> "$current_repo_access_file"
					echo -e "\n User: $username_action '"$action"ed' in access list successfully. \n"
					sleep 1
					list_members
				else
					echo -e "\n Error: Given username - $username_action is not found in users list. Please enter the valid username... \n"
					sleep 1
				fi
				;;
			remove)
				# Verify and print the current_repo_access_file
				if grep -q "$username_action" "$current_repo_access_file"; then
					sed -i "/$username_action/d" "$current_repo_access_file"
					echo -e "\n User: $username_action '"$action"ed' in access list successfully. \n"
					sleep 1
					list_members
				else
					echo -e "\n Error: Given username - $username_action is not found in member access list of selected repo project...! \n"
					sleep 1
				fi
				;;
		esac
	}
	
	# Function to Request add/remove another user
	add_remove_another_user_req() {
		while true; do
			read -p "Do you want to proceed to $action another user in access list? (yes/no): " answer
			answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

			case "$answer" in
				yes|y)
					add_remove_action $action
					;;
				no|n)
					echo "Back to SUB Menu"
					sleep 1
					break
					;;
				*)
					echo "Invalid input. Please enter 'yes' or 'no'."
					;;
			esac
		done
	}
	
	# Check the current selected repo is enabled membership setting.
	if [ -f $current_repo_hook_file ]; then
		# echo -e "Info: Current Selected project - $selected_dir_name is configured user membership."
		if [ -x $current_repo_hook_file ]; then
			# If the repo hook file is enabled (Executable).
			list_members
			add_remove_action $action
			add_remove_another_user_req
		else
			# If not - the repo hook file is Disabled (Not Executable)
			echo -e "Info: Current Selected project - $selected_dir_name user membership setting is disabled."
			enable_membership_setting_req
		fi
	else
		echo -e "Info: Current Selected project - $selected_dir_name is not configured user membership.
				\n Setup Project Membership in repository settings"
		sleep 1
		
	fi
}

### Main Script starting from here ###
# Check wheather the Root directory is present or not
if [ ! -d "$ROOT_DIR" ]; then
    echo "Error: Root directory not found!"
    exit 1
fi

## Main menu
while true; do
	echo -e "=============================="	
	echo -e "----------Main Menu-----------"
	echo -e "=============================="
	echo -e "What do you want to do?"
	echo -e "------------------------------"
	echo -e "1. Create a New Repository"
	echo -e "2. User Settings"
	echo -e "3. Configure Project member"
	echo -e "4. Repository Setting"
	echo -e "5. Exit"
	echo -e ""
	read -p "Enter your choice to select configuration: " main_menu_choice

	case $main_menu_choice in
		1)
			echo -e "Info: You've selected - 1. Create a New Project"
			echo -e ""
			sleep 1
			create_project_repo
			echo -e "1. Create a New Project - Done."
			;;
		2)
			echo -e "Info: You've selected - 2. User Settings"
			echo -e ""
			sleep 1
			# Sub menu-1
			while true; do
				echo -e ""
				echo -e "=============================="	
				echo -e "----------Sub Menu-----------"
				echo -e "=============================="
				echo -e "From - 3. User Settings,\n What do you want to do?"
				echo -e "------------------------------"
				echo -e "1. List users"
				echo -e "2. Add a new user"
				echo -e "3. Reset user password"
				echo -e "4. Delete Existing user"
				echo -e "5. SSH Public Key access"
				echo -e "6. Back to Main Menu"
				echo -e "7. Exit"
				echo -e ""
				read -p "Enter your choice: " user_settings_choice
				case $user_settings_choice in
					1)
						echo -e "Info You've selected - 1. List users"
						sleep 1
						list_user
						echo -e "1. List users - Done."
						;;
					2)
						echo -e "Info You've selected - 2. Add a new user"
						sleep 1
						add_user
						;;
					3)
						echo -e "Info You've selected - 3. Reset user password"
						sleep 1
						reset_user
						;;
					4)
						echo -e "Info You've selected - 4. Delete Existing user"
						sleep 1
						delete_user
						;;
					5)
						echo -e "Info You've selected - 5. SSH Public Key access"
						sleep 1
						ssh_key_access
						;;
					6)
						echo -e "Exiting Sub menu, and back to main menu..."
						sleep 1
						break
						;;
					7)
						echo -e "Exiting..."
						sleep 1
						exit 0
						;;
					*)
						echo -e "Invalid option. Please choose again."
						sleep 1
						;;
				esac
			done
			;;
		3)
			echo -e "Info: You've selected - 4. Configure Project member"
			echo -e ""
			sleep 1
			# Sub menu-2
			while true; do
				echo -e "=============================="	
				echo -e "----------Sub Menu-----------"
				echo -e "=============================="
				echo -e "From - 4. Configure Project member,\n What do you want to do?"
				echo -e "------------------------------"
				echo -e "1. List members"
				echo -e "2. Add member"
				echo -e "3. Remove member"
				echo -e "4. Back to Main Menu"
				echo -e "5. Exit"
				echo -e ""
				read -p "Enter your choice: " project_member_choice
				case $project_member_choice in
					1)
						echo -e "Info: You've selected - 1. List members"
						echo -e ""
						sleep 1
						# list_members and select the project repo
						select_project_repo
						list_members
						;;
					2)
						echo -e "Info: You've selected - 2. Add member"
						echo -e ""
						sleep 1
						select_project_repo
						add_remove_user_in_member add	# Refer defined function
						;;
					3)
						echo -e "Info: You've selected - 3. Remove member"
						echo -e ""
						sleep 1
						select_project_repo
						add_remove_user_in_member remove	# Refer defined function
						;;
					
					4)
						echo -e "Exiting Sub menu, and back to main menu..."
						sleep 1
						break
						;;
					5)
						# echo -e "Exiting sub menu, and back to main menu..."
						echo -e "Exiting..."
						sleep 1
						exit 0
						;;
					*)
						echo -e "Invalid option. Please choose again."
						sleep 2
						;;
				esac
			done
			;;
			
		4)
			echo -e "Info: You've selected - 4. Repository settings"
			sleep 1
			# Sub menu-2
			while true; do
				echo -e "=============================="	
				echo -e "----------Sub Menu-----------"
				echo -e "=============================="
				echo -e "From - 4. Repository settings,\n What do you want to do?"
				echo -e "------------------------------"
				echo -e "1. Enable/disable repo member acces"
				echo -e "2. Delete existing repo project"
				echo -e "3. Back to Main Menu"
				echo -e "4. Exit"
				echo -e ""
				read -p "Enter your choice: " repo_setting_choice
				case $repo_setting_choice in
					1)
						echo -e "Info: You've selected - 1. Enable/disable repo member access"
						echo -e ""
						select_project_repo
						setting_project_repo
						sleep 1
						;;
					2)
						echo -e "Info: You've selected - 2. Delete existing repo project"
						echo -e ""
						delete_project
						sleep 1
						;;
					3)
						echo -e "Exiting Sub menu, and back to main menu..."
						sleep 1
						break
						;;
						
					4)
						echo -e "Exiting..."
						sleep 1
						exit 0
						;;
					*)
					
						echo -e "Invalid option. Please choose again."
						sleep 2
						;;
				esac
			done
			;;	
			# delete_project
			
		5)
			echo -e "Exiting..."
			sleep 1
			exit 0
			;;
		*)
			echo -e "Invalid option. Please choose again."
			sleep 2
			;;
	esac
done
