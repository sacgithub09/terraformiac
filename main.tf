variable "location" {
    default = "Central India"
    type = string
    description = "location of resources"
}

variable "rgname" {
    default = "sacterraform-rg"
    type = string
    description = "location of resources"
}

resource "azurerm_resource_group" "rg" {
    location = var.location
    name     = var.rgname
}

resource "azurerm_network_security_group" "nsg" {
    location = var.location
    resource_group_name = var.rgname
    name = "sacterraform-nsg"
}

resource "azurerm_virtual_network" "vnet" {
    location = var.location
    resource_group_name = var.rgname
    address_space = ["10.0.0.0/16"]
    name = "sacterraform-vnet"
}

resource "azurerm_subnet" "subnet1" {
    resource_group_name = var.rgname
    address_prefixes = ["10.0.1.0/24"]
    virtual_network_name = azurerm_virtual_network.vnet.name
    name = "sac-terra-subnet1"
}

resource "azurerm_subnet" "subnet2" {
    resource_group_name = var.rgname
    address_prefixes = ["10.0.2.0/24"]
    virtual_network_name = azurerm_virtual_network.vnet.name
    name = "sac-terra-subnet2"
}

resource "azurerm_network_interface" "nic" {
    resource_group_name = var.rgname
    location = var.location
    name = "sacterraform-nic"

    ip_configuration {
        name = "testconfiguration1"
        subnet_id = azurerm_subnet.subnet1.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_virtual_machine" "vm" {
    resource_group_name = var.rgname
    location = var.location
    name = "sacterraform-vm"
    network_interface_ids = [azurerm_network_interface.nic.id]
    vm_size = "Standard_DS1_V2"

    delete_data_disks_on_termination = true
    delete_os_disk_on_termination = true

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "16.04-LTS"
        version = "latest"
    }

    storage_os_disk {
        name = "sac-terra-osdisk"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name = "hostname"
        admin_username = "sac-user"
        admin_password = "sacpassword1234!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        environment = "Staging"
        owner = "SacShi"
    }
}

resource "azurerm_network_security_rule" "sac-nsg-rule" {
    name = "sac-nsg-rule-1"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "TCP"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = var.rgname
    network_security_group_name = azurerm_network_security_group.nsg.name 
}