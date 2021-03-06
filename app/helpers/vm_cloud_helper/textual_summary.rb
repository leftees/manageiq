module VmCloudHelper::TextualSummary
  # TODO: Determine if DoNav + url_for + :title is the right way to do links, or should it be link_to with :title

  #
  # Groups
  #

  def textual_group_properties
    %i(name region server description ipaddress custom_1 container tools_status osinfo architecture advanced_settings resources guid virtualization_type root_device_type)
  end

  def textual_group_vm_cloud_relationships
    %i(ems ems_infra cluster host availability_zone cloud_tenant flavor drift scan_history security_groups
       service cloud_network cloud_subnet orchestration_stack)
  end

  def textual_group_template_cloud_relationships
    %i(ems drift scan_history)
  end

  def textual_group_security
    %i(users groups patches key_pairs)
  end

  def textual_group_configuration
    %i(guest_applications init_processes win32_services kernel_drivers filesystem_drivers filesystems registry_items)
  end

  def textual_group_diagnostics
    %i(processes event_logs)
  end

  def textual_group_vmsafe
    %i(vmsafe_enable vmsafe_agent_address vmsafe_agent_port vmsafe_fail_open vmsafe_immutable_vm vmsafe_timeout)
  end

  def textual_group_miq_custom_attributes
    textual_miq_custom_attributes
  end

  def textual_group_ems_custom_attributes
    textual_ems_custom_attributes
  end

  def textual_group_compliance
    %i(compliance_status compliance_history)
  end

  def textual_group_power_management
    %i(power_state boot_time state_changed_on)
  end

  def textual_group_tags
    %i(tags)
  end

  #
  # Items
  #

  def textual_region
    return nil if @record.region_number == MiqRegion.my_region_number
    h = {:label => "Region"}
    reg = @record.miq_region
    url = reg.remote_ui_url
    h[:value] = if url
      # TODO: Why is this link different than the others?
      link_to(reg.description, url_for(:host => url, :action => 'show', :id => @record), :title => "Connect to this VM in its Region", :onclick => "return miqClickAndPop(this);")
    else
      reg.description
    end
    h
  end

  def textual_name
    @record.name
  end

  def textual_server
    @record.miq_server && "#{@record.miq_server.name} [#{@record.miq_server.id}]"
  end

  def textual_description
    @record.description
  end

  def textual_ipaddress
    ips = @record.ipaddresses
    {:label => (ips.size > 1 ? "IP Address".pluralize : "IP Address"), :value => ips.join(", ")}
  end

  def textual_custom_1
    return nil if @record.custom_1.blank?
    {:label => "Custom Identifier", :value => @record.custom_1}
  end

  def textual_tools_status
    {:label => "Platform Tools", :value => (@record.tools_status.nil? ? "N/A" : @record.tools_status)}
  end

  def textual_osinfo
    h = {:label => "Operating System"}
    os = @record.operating_system.nil? ? nil : @record.operating_system.product_name
    if os.blank?
      h[:value] = "Unknown"
    else
      h[:image] = "os-#{@record.os_image_name.downcase}"
      h[:value] = os
      h[:title] = "Show OS container information"
      h[:explorer] = true
      h[:link]  = url_for(:action => 'show', :id => @record, :display => 'os_info')
    end
    h
  end

  def textual_architecture
    return nil if @record.kind_of?(ManageIQ::Providers::Openstack::CloudManager::Vm) || @record.kind_of?(ManageIQ::Providers::Openstack::CloudManager::Template)
    bitness = @record.hardware.try(:bitness)
    {:label => "Architecture ", :value => bitness.nil? ? "" : "#{bitness} bit"}
  end

  def textual_advanced_settings
    num = @record.number_of(:advanced_settings)
    h = {:label => "Advanced Settings", :image => "advancedsetting", :value => num}
    if num > 0
      h[:title] = "Show the advanced settings on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:action => 'advanced_settings', :id => @record, :db => controller.controller_name)
    end
    h
  end

  def textual_resources
    {:label => "Resources", :value => "Available", :title => "Show resources of this VM", :explorer => true,
      :link => url_for(:action => 'show', :id => @record, :display => 'resources_info')}
  end

  def textual_guid
    {:label => "Management Engine GUID", :value => @record.guid}
  end

  def textual_ems
    textual_link(@record.ext_management_system, :as => EmsCloud)
  end

  def textual_ems_infra
    textual_link(@record.ext_management_system.try(:provider).try(:infra_ems), :as => EmsInfra)
  end

  def textual_cluster
    cluster = @record.host.try(:ems_cluster)
    return nil if cluster.nil?
    h = {:label => title_for_cluster, :image => "ems_cluster", :value => (cluster.nil? ? "None" : cluster.name)}
    if cluster && role_allows(:feature => "ems_cluster_show")
      h[:title] = "Show this VM's #{title_for_cluster}"
      h[:link]  = url_for(:controller => 'ems_cluster', :action => 'show', :id => cluster)
    end
    h
  end

  def textual_host
    host = @record.host
    return nil if host.nil?
    h = {:label => title_for_host, :image => "host", :value => (host.nil? ? "None" : host.name)}
    if host && role_allows(:feature => "host_show")
      h[:title] = "Show this VM's #{title_for_host}"
      h[:link]  = url_for(:controller => 'host', :action => 'show', :id => host)
    end
    h
  end

  def textual_availability_zone
    availability_zone = @record.availability_zone
    label = ui_lookup(:table => "availability_zone")
    h = {:label => label, :image => "availability_zone", :value => (availability_zone.nil? ? "None" : availability_zone.name)}
    if availability_zone && role_allows(:feature => "availability_zone_show")
      h[:title] = "Show this VM's #{label}"
      h[:link]  = url_for(:controller => 'availability_zone', :action => 'show', :id => availability_zone)
    end
    h
  end

  def textual_flavor
    flavor = @record.flavor
    label = ui_lookup(:table => "flavor")
    h = {:label => label, :image => "flavor", :value => (flavor.nil? ? "None" : flavor.name)}
    if flavor && role_allows(:feature => "flavor_show")
      h[:title] = "Show this VM's #{label}"
      h[:link]  = url_for(:controller => 'flavor', :action => 'show', :id => flavor)
    end
    h
  end

  def textual_orchestration_stack
    stack = @record.orchestration_stack
    label = ui_lookup(:table => "orchestration_stack")
    h = {:label => label, :image => "orchestration_stack", :value => (stack.nil? ? "None" : stack.name)}
    if stack && role_allows(:feature => "orchestration_stack_show")
      h[:title] = "Show this VM's #{label} '#{stack.name}'"
      h[:link]  = url_for(:controller => 'orchestration_stack', :action => 'show', :id => stack)
    end
    h
  end

  def textual_service
    h = {:label => "Service", :image => "service"}
    service = @record.service
    if service.nil?
      h[:value] = "None"
    else
      h[:value] = service.name
      h[:title] = "Show this Service"
      h[:link]  = url_for(:controller => 'service', :action => 'show', :id => service)
    end
    h
  end

  def textual_drift
    return nil unless role_allows(:feature => "vm_drift")
    h = {:label => "Drift History", :image => "drift"}
    num = @record.number_of(:drift_states)
    if num == 0
      h[:value] = "None"
    else
      h[:value] = num
      h[:title] = "Show virtual machine drift history"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'drift_history', :id => @record)
    end
    h
  end

  def textual_scan_history
    h = {:label => "Analysis History", :image => "scan"}
    num = @record.number_of(:scan_histories)
    if num == 0
      h[:value] = "None"
    else
      h[:value] = num
      h[:title] = "Show virtual machine analysis history"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'scan_histories', :id => @record)
    end
    h
  end

  def textual_users
    num = @record.number_of(:users)
    h = {:label => "Users", :image => "user", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, 'user')} defined on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:action => 'users', :id => @record, :db => controller.controller_name)
    end
    h
  end

  def textual_groups
    num = @record.number_of(:groups)
    h = {:label => "Groups", :image => "group", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, 'group')} defined on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:action => 'groups', :id => @record, :db => controller.controller_name)
    end
    h
  end

  def textual_patches
    os = @record.os_image_name.downcase
    return nil if os == "unknown" || os =~ /linux/
    num = @record.number_of(:patches)
    h = {:label => "Patches", :image => "patch", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, 'Patch')} defined on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:action => 'patches', :id => @record, :db => controller.controller_name)
    end
    h
  end

  def textual_key_pairs
    return nil if @record.kind_of?(ManageIQ::Providers::CloudManager::Template)
    h = {:label => "Key Pairs"}
    key_pairs = @record.key_pairs
    h[:value] = key_pairs.blank? ? "N/A" : key_pairs.collect(&:name).join(", ")
    h
  end

  def textual_guest_applications
    os = @record.os_image_name.downcase
    return nil if os == "unknown"
    label = (os =~ /linux/) ? "Package" : "Application"
    num = @record.number_of(:guest_applications)
    h = {:label => label.pluralize, :image => "guest_application", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, label)} installed on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'guest_applications', :id => @record)
    end
    h
  end

  def textual_init_processes
    os = @record.os_image_name.downcase
    return nil unless os =~ /linux/
    num = @record.number_of(:linux_initprocesses)
    # TODO: Why is this image different than graphical?
    h = {:label => "Init Processes", :image => "gears", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, 'Init Process')} installed on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'linux_initprocesses', :id => @record)
    end
    h
  end

  def textual_win32_services
    os = @record.os_image_name.downcase
    return nil if os == "unknown" || os =~ /linux/
    num = @record.number_of(:win32_services)
    h = {:label => "Win32 Services", :image => "win32service", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, 'Win32 Service')} installed on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'win32_services', :id => @record)
    end
    h
  end

  def textual_kernel_drivers
    os = @record.os_image_name.downcase
    return nil if os == "unknown" || os =~ /linux/
    num = @record.number_of(:kernel_drivers)
    # TODO: Why is this image different than graphical?
    h = {:label => "Kernel Drivers", :image => "gears", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, 'Kernel Driver')} installed on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'kernel_drivers', :id => @record)
    end
    h
  end

  def textual_filesystem_drivers
    os = @record.os_image_name.downcase
    return nil if os == "unknown" || os =~ /linux/
    num = @record.number_of(:filesystem_drivers)
    # TODO: Why is this image different than graphical?
    h = {:label => "File System Drivers", :image => "gears", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, 'File System Driver')} installed on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'filesystem_drivers', :id => @record)
    end
    h
  end

  def textual_filesystems
    num = @record.number_of(:filesystems)
    h = {:label => "Files", :image => "filesystems", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, 'File')} installed on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'filesystems', :id => @record)
    end
    h
  end

  def textual_registry_items
    os = @record.os_image_name.downcase
    return nil if os == "unknown" || os =~ /linux/
    num = @record.number_of(:registry_items)
    # TODO: Why is this label different from the link title text?
    h = {:label => "Registry Entries", :image => "registry_item", :value => num}
    if num > 0
      h[:title] = "Show the #{pluralize(num, 'Registry Item')} installed on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'registry_items', :id => @record)
    end
    h
  end

  def textual_processes
    h = {:label => "Running Processes", :image => "processes"}
    date = last_date(:processes)
    if date.nil?
      h[:value] = "Not Available"
    else
      # TODO: Why does this date differ in style from the compliance one?
      h[:value] = "From #{time_ago_in_words(date.in_time_zone(Time.zone)).titleize} Ago"
      h[:title] = "Show Running Processes on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'processes', :id => @record)
    end
    h
  end

  def textual_event_logs
    num = @record.operating_system.nil? ? 0 : @record.operating_system.number_of(:event_logs)
    h = {:label => "Event Logs", :image => "event_logs", :value => (num == 0 ? "Not Available" : "Available")}
    if num > 0
      h[:title] = "Show Event Logs on this VM"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'event_logs', :id => @record)
    end
    h
  end

  def textual_vmsafe_enable
    return nil if @record.vmsafe_enable
    {:label => "Enable", :value => "false"}
  end

  def textual_vmsafe_agent_address
    return nil unless @record.vmsafe_enable
    {:label => "Agent Address", :value => @record.vmsafe_agent_address}
  end

  def textual_vmsafe_agent_port
    return nil unless @record.vmsafe_enable
    {:label => "Agent Port", :value => @record.vmsafe_agent_port}
  end

  def textual_vmsafe_fail_open
    return nil unless @record.vmsafe_enable
    {:label => "Fail Open", :value => @record.vmsafe_fail_open}
  end

  def textual_vmsafe_immutable_vm
    return nil unless @record.vmsafe_enable
    {:label => "Immutable VM", :value => @record.vmsafe_immutable_vm}
  end

  def textual_vmsafe_timeout
    return nil unless @record.vmsafe_enable
    {:label => "Timeout (ms)", :value => @record.vmsafe_timeout_ms}
  end

  def textual_miq_custom_attributes
    attrs = @record.miq_custom_attributes
    return nil if attrs.blank?
    attrs.collect { |a| {:label => a.name, :value => a.value} }
  end

  def textual_ems_custom_attributes
    attrs = @record.ems_custom_attributes
    return nil if attrs.blank?
    attrs.collect { |a| {:label => a.name, :value => a.value} }
  end

  def textual_compliance_status
    h = {:label => "Status"}
    if @record.number_of(:compliances) == 0
      h[:value] = "Never Verified"
    else
      compliant = @record.last_compliance_status
      date      = @record.last_compliance_timestamp
      h[:image] = compliant ? "check" : "x"
      h[:value] = "#{"Non-" unless compliant}Compliant as of #{time_ago_in_words(date.in_time_zone(Time.zone)).titleize} Ago"
      h[:title] = "Show Details of Compliance Check on #{format_timezone(date)}"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'show', :id => @record, :display => 'compliance_history', :count => 1)
    end
    h
  end

  def textual_compliance_history
    h = {:label => "History"}
    if @record.number_of(:compliances) == 0
      h[:value] = "Not Available"
    else
      h[:image] = "compliance"
      h[:value] = "Available"
      h[:title] = "Show Compliance History of this VM (Last 10 Checks)"
      h[:explorer] = true
      h[:link]  = url_for(:controller => controller.controller_name, :action => 'show', :id => @record, :display => 'compliance_history')
    end
    h
  end

  def textual_power_state
    state = @record.current_state.downcase
    state = "unknown" if state.blank?
    h = {:label => "Power State", :value => state}
    h[:image] = "currentstate-#{@record.template? ? (@record.host ? "template" : "template-no-host") : state}"
    h
  end

  def textual_boot_time
    date = @record.boot_time
    {:label => "Last Boot Time", :value => (date.nil? ? "N/A" : format_timezone(date))}
  end

  def textual_state_changed_on
    date = @record.state_changed_on
    {:label => "State Changed On", :value => (date.nil? ? "N/A" : format_timezone(date))}
  end

  def textual_security_groups
    label = ui_lookup(:tables => "security_group")
    num   = @record.number_of(:security_groups)
    h     = {:label => label, :image => "security_group", :value => num}
    if num > 0 && role_allows(:feature => "security_group_show_list")
      h[:title] = "Show all #{label}"
      h[:explorer] = true
      h[:link]  = url_for(:action => 'security_groups', :id => @record, :display => "security_groups")
    end
    h
  end

  def textual_virtualization_type
    return nil if @record.kind_of?(ManageIQ::Providers::Openstack::CloudManager::Vm) || @record.kind_of?(ManageIQ::Providers::Openstack::CloudManager::Template)
    v_type = @record.hardware.try(:virtualization_type)
    {:label => "Virtualization Type", :value => v_type.to_s}
  end

  def textual_root_device_type
    return nil if @record.kind_of?(ManageIQ::Providers::Openstack::CloudManager::Vm) || @record.kind_of?(ManageIQ::Providers::Openstack::CloudManager::Template)
    rd_type = @record.hardware.try(:root_device_type)
    {:label => "Root Device Type", :value => rd_type.to_s}
  end

  def textual_cloud_tenant
    cloud_tenant = @record.cloud_tenant if @record.respond_to?(:cloud_tenant)
    label = ui_lookup(:table => "cloud_tenants")
    h = {:label => label, :image => "cloud_tenant", :value => (cloud_tenant.nil? ? "None" : cloud_tenant.name)}
    if cloud_tenant && role_allows(:feature => "cloud_tenant_show")
      h[:title] = "Show this VM's #{label}"
      h[:link]  = url_for(:controller => 'cloud_tenant', :action => 'show', :id => cloud_tenant)
    end
    h
  end
end
