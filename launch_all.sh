#!/bin/bash

source colors.sh

# This script will run regression tests for many earlier OpenStudio versions
# For a single & more interactive version use the CLI ./launch_docker.sh

# AUTHOR: Julien Marrec, julien@effibem.com, 2018


#######################################################################################
#                           H A R D C O D E D    A R G U M E N T S
########################################################################################

# All versions you want to run
declare -a  all_versions=("2.0.4" "2.0.5" "2.1.0" "2.1.1" "2.1.2" "2.2.0" "2.2.1" "2.2.2" "2.3.0" "2.3.1" "2.4.0" "2.4.1")

# Do you want to ask the user to set these arguments?
# If false, will just use the hardcoded ones
ask_user=true

# If image custom/openstudio:$os_version already exists, do you want to force rebuild?
# Otherwise will use this one
force_rebuild=true

# Test filter: passed as model_tests -n /$filter/
filter=""
# Run only osms tests: filter="/_osm/"

# Delete custom/openstudio:$os_version image after having used it?
delete_custom_image=false

# Delete the base image? nrel/openstudio:$os_version
delete_base_image=false


#######################################################################################
#                       G L O B A L    U S E R    A R G U M E N T S
########################################################################################

if [ "$ask_user" = true ]; then

  echo -e -n "Do you want to force rebuild for the ${BRed}custom/openstudio${Color_Off} images? [y/${URed}N${Color_Off}] "
  read -n 1 -r
  echo    # (optional) move to a new line
  # Default is No
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    force_rebuild=true
  fi

  echo -e "Do you want to pass a ${BCyan}filter 'pattern'${Color_Off} passed to 'model_tests.rb -n /pattern/'"
  echo "Leave empty for all tests, or input a pattern. Follow by [ENTER] in both cases"
  read filter

  echo -e -n "Do you want to delete the ${BRed}custom/openstudio${Color_Off} images after use? [y/${URed}N${Color_Off}] "
  read -n 1 -r
  echo    # (optional) move to a new line
  # Default is No
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    delete_custom_image=true
  fi

  echo -e -n "Do you want to delete the base ${BPurple}nrel/openstudio${Color_Off} images after use? [y/${URed}N${Color_Off}] "
  read -n 1 -r
  echo    # (optional) move to a new line
  # Default is No
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    delete_base_image=true
  fi

  echo "Global options have been set as follows:"
  echo "-----------------------------------------"
  echo "force_rebuild=$force_rebuild"
  if [ -z $filter ]; then
    echo "filter=NONE"
  else
    echo "filter=$filter"
  fi
  echo "delete_custom_image=$delete_custom_image"
  echo "delete_base_image=$delete_base_image"

fi


########################################################################################
#                              S E T U P
########################################################################################

# Source the file that has the colors
source colors.sh

# Image/Container names
mongo_image_name=mongo
mongo_container_name=openstudio-mongo

os_container_name=my_openstudio

# String representation with colors
mongo_image_str="${BPurple}image${Color_Off} ${UPurple}$mongo_image_name${Color_Off}"
mongo_container_str="${BCyan}container${Color_Off} ${UCyan}$mongo_container_name${Color_Off}"
os_container_str="${BBlue}container${Color_Off} ${UBlue}$os_container_name${Color_Off}"


########################################################################################
#                               M O N G O
########################################################################################

if [ ! "$(docker ps -q -f name=$mongo_container_name)" ]; then
  if [ "$(docker ps -aq -f status=exited -f name=$mongo_container_name)" ]; then
    # cleanup
    echo -e "* Deleting existing mongo $mongo_container_str"
    docker rm $mongo_container_name &> /dev/null
  fi
  # run your container
  # Have the mongo docker write to the local directory with -v
  echo -e "* Running mongo $mongo_container_str"
  docker run --name $mongo_container_name -v "$(pwd)/database":/data/db -d $mongo_image_name &> /dev/null
fi


# Place the mongo container ip into a file, that'll get added to the openstudio container via the dockerfile
# Actually we will set an environment variable in the dockerfile named MONGOIP too
mongo_ip=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $mongo_container_name`
echo $mongo_ip > mongo_ip


for os_version in "${all_versions[@]}"; do

  base_os_image_name=nrel/openstudio:$os_version
  os_image_name=custom/openstudio:$os_version
  os_image_str="${BRed}image${Color_Off} ${URed}$os_image_name${Color_Off}"
  base_os_image_str="${BRed}image${Color_Off} ${URed}$base_os_image_name${Color_Off}"

  echo
  echo -e "${On_Red}---------------------------------------------------------------"
  echo -e "            ${On_Red}STARTING WITH A NEW VERSION $os_version${Color_Off} "
  echo -e "${On_Red}---------------------------------------------------------------${Color_Off}"
  echo

  ########################################################################################
  #          B U I L D    O P E N S T U D I O    C U S T O M    I M A G E
  ########################################################################################

  # We are going to use a Dockerfile to load the tagged nrel/openstudio image, then add some files, etc


  # Prepare the dockerfile (string substitution in the template file)
  sed -e "s/\${os_version}/$os_version/" -e "s/\${mongo_ip}/$mongo_ip/" Dockerfile.in > Dockerfile

  echo ""
  # If the docker image doesn't already exists
  if [ -z $(docker images -q $os_image_name) ]; then
    echo -e "* Building the $os_image_str from Dockerfile"
    docker build -t $os_image_name .
  else
    if [ "$force_rebuild" = true ];
    then
      echo -e "* Rebuilding the image $os_image_str from Dockerfile"
      docker rmi $os_image_name
      docker build -t $os_image_name .
    fi
    echo
  fi


  # Execute a container in detached mode
  # Check first if there is an existing one, and tell user what to do
  if [ "$(docker ps -aq -f name=$os_container_name)" ]; then
    echo -e "Warning: The $os_container_str is already running... Stopping"
    docker stop $os_container_name
  fi
  # Launch, with link to the mongo one
  echo -e "* Launching the $os_container_str"
  docker run --name $os_container_name --link openstudio-mongo:mongo -v `pwd`/test:/root/test -d -it --rm $os_image_name /bin/bash # &> /dev/null

  # Chmod execute the script
  docker exec $os_container_name chmod +x docker_container_script.sh

  if [ "$os_version" = 2.0.4 ]; then
    echo -e "${On_Red}CUSTOM WORKAROUND FOR BROKEN 2.0.4${Color_Off}"
    # This one has missing dependencies
    docker exec $os_container_name sudo apt update
    docker exec $os_container_name sudo apt install -y libglu1 libjpeg8 libfreetype6 libdbus-glib-1-2 libfontconfig1 libSM6 libXi6
    # Need to specifically require /usr/Ruby/openstudio instead of just openstudio
    docker exec $os_container_name sed -i "s:require 'openstudio':require '/usr/Ruby/openstudio':" model_tests.rb
    # Etc.nprocessor unknown, replace with bash nproc
    docker exec $os_container_name sed -i "s/Etc.nprocessors/$(nproc)/" model_tests.rb
  fi
  # Execute it
  # Launch the regression tests
  docker exec $os_container_name /bin/bash ./docker_container_script.sh $filter


  # Clean up

  # Stop the os container, which is needed because I don't use run -rm, nor I attach to it
  if [ "$(docker ps -q -f name=$os_container_name)" ]; then
    docker stop $os_container_name &> /dev/null
    echo -e "* Stopped the $os_container_str"
  fi
  # if the container still exists but it is stopped, delete
  if [ ! "$(docker ps -q -f name=$1)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=$1)" ]; then
      docker rm $os_container_name &> /dev/null
      echo -e "* Deleted the $os_container_str"
    fi
  fi

  # Delete custom/openstudio:$os_version image?
  if [ "$delete_custom_image" = true ]; then
    docker rmi $os_image_name &> /dev/null
    echo -e "* Deleted the $os_image_str"
  fi

  # Delete base nrel/openstudio:$os_version image?
  if [ "$delete_base_image" = true ]; then
    docker rm $base_os_image_name &> /dev/null
    echo -e "* Deleted the $base_os_image_str"
  fi


done

echo
echo -e "${On_Blue}Fixing ownership: setting it to user=$USER and chmod=664 (requires sudo)${Color_Off}"
sudo chown -R $USER *
sudo find ./test/ -type f -exec chmod 664 {} \;

# Stop the mongo one
docker stop $mongo_container_name &> /dev/null
echo -e "* Stopped the $mongo_container_str"