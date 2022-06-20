# Copyright (C) 2020 HiddenVM <https://github.com/aforensics/HiddenVM>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

COUNT=100000

enforce_amnesia

# Checking if the storage pool exists by looking for the keyword active
get_active_pool_count() 
{
    COUNT=$(virsh pool-list --all | sed -n 's/.*\(active\).*/\1/p'| grep -c "active")

    log "Currently there are ${COUNT} storage pool(s) which exist"

    return "${COUNT}"
}

# Makes the Virtual Machine Manager application's config persistent
setup_vmanager_persistent_config() {
    log "Set up Virtual Machine Manager persistent configuration, prog-id=17"

    # Ensure that the persistent Virtual Machine Manager application config and VM dirs exist
    local VMANAGER_CONFIG_CACHE_DIR="${HVM_HOME}/cache/config-vmanager"
    local HVM_HOME_VMANAGER_VM_LOCATION="${HVM_HOME}/Virtual Machine Manager VMs"
    mkdir -p "${VMANAGER_CONFIG_CACHE_DIR}"
    mkdir -p "${HVM_HOME_VMANAGER_VM_LOCATION}"

    # Make the Virtual Machine Manager application persist its configs
    local HOME_CLEARNET_CONFIG="/etc"
    local HOME_CLEARNET_CONFIG_VMANAGER="${HOME_CLEARNET_CONFIG}/libvirt"
    local VMANAGER_CONFIG_FILE_NAME="qemu.conf"
    local VMANAGER_CONFIG_CACHE_FILE="${VMANAGER_CONFIG_CACHE_DIR}/${VMANAGER_CONFIG_FILE_NAME}"

    #sudo rm -rf "${HOME_CLEARNET_CONFIG_VMANAGER}"
    #sudo -u clearnet mkdir -p "${HOME_CLEARNET_CONFIG}"

    # If we have a cached vmanager config, copy it to the right location for updating
    if [ -f "${VMANAGER_CONFIG_CACHE_FILE}" ]; then
        log "Found existing Virtual Machine Manager config: ${VMANAGER_CONFIG_CACHE_FILE}"
        sudo -u clearnet mkdir "${HOME_CLEARNET_CONFIG_VMANAGER}"
        sudo cp "${VMANAGER_CONFIG_CACHE_DIR}" "${HOME_CLEARNET_CONFIG_VMANAGER}/"
        sudo chown -R clearnet:clearnet "${HOME_CLEARNET_CONFIG_VMANAGER}"
    fi

    log "reached storage pool"

    # Check if the storage pool exists
    log "Checking if storage pool exists"
    if ( get_active_pool_count === 0 ); then
    {
    # Create a storage pool if it doesn't exist as by default the installation doesn't create one
    log "Storage pool is about to be created."
    virsh pool-define-as --name default --type dir --target \
        "${HVM_HOME_VMANAGER_VM_LOCATION}"

    log "Storage pool has been created."

    # Now we start the default storage pool
    virsh pool-start default

    #Setting the default storga eto autoatically start on system boot
    virsh pool-autostart default


    }
    else
    {
    log "Storage pool exists." 
    }
    fi    

    # Restart the libvirtd service
    sudo systemctl restart libvirtd
    
    #sudo killall libvirtd
    
    #sudo -u clearnet libvirtd
    
    pushd / >/dev/null
    
    log "pushd to launch directory"

    # Copy the updated config file back to the cache
    sudo cp -r "${HOME_CLEARNET_CONFIG_VMANAGER}" "${VMANAGER_CONFIG_CACHE_DIR}/"
    sudo chown -R amnesia:amnesia "${VMANAGER_CONFIG_CACHE_DIR}/"
    #sudo chmod -R 777 /etc/libvirt 
    sudo rm -rf "${HOME_CLEARNET_CONFIG_VMANAGER}"

    # Create a symlink to the cached vmanager config directory within the "HiddenVM"
    # mount. Because the mount isn't live yet, this symlink will remain broken
    # until the mount is established by the launcher.
    sudo ln -s "${CLEARNET_HVM_MOUNT}/cache/config-vmanager/libvirt" "${HOME_CLEARNET_CONFIG_VMANAGER}"

    popd > /dev/null
    
    # for testing purposes
    #sudo apt-get update
}





