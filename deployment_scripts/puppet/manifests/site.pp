notice('Fuel plugin swift: site.pp')

$swift_hash          = hiera('swift_hash')
$swift_master_role   = hiera('swift_master_role', 'primary-controller')
$swift_nodes         = pick(hiera('swift_nodes', undef), hiera('controllers', undef))
$swift_proxies       = pick(hiera('swift_proxies', undef), hiera('controller_internal_addresses', undef))
$primary_swift       = pick(hiera('primary_swift', undef), hiera('primary_controller', undef))
$proxy_port          = hiera('proxy_port', '8080')
$network_scheme      = hiera('network_scheme', {})
$storage_hash        = hiera('storage_hash')
$mp_hash             = hiera('mp')
$management_vip      = hiera('management_vip')
$debug               = hiera('debug', false)
$verbose             = hiera('verbose')
$storage_address     = hiera('storage_address')
$node                = hiera('node')
$ring_min_part_hours = hiera('swift_ring_min_part_hours', 1)

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  if !(hiera('swift_partition', false)) {
    $swift_partition = '/var/lib/glance/node'
  }
  $master_swift_proxy_nodes = filter_nodes(hiera('nodes_hash'),'role',$swift_master_role)
  $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['storage_address']
  if ($primary_swift) {
    $primary_proxy = true
  } else {
    $primary_proxy = false
  }

  class { 'openstack::swift::storage_node':
    storage_type          => false,
    loopback_size         => '5243780',
    storage_mnt_base_dir  => $swift_partition,
    storage_devices       => filter_hash($mp_hash,'point'),
    swift_zone            => $node[0]['swift_zone'],
    swift_local_net_ip    => $storage_address,
    master_swift_proxy_ip => $master_swift_proxy_ip,
    sync_rings            => ! $primary_proxy,
    debug                 => $debug,
    verbose               => $verbose,
    log_facility          => 'LOG_SYSLOG',
  }
  if $primary_proxy {
    ring_devices {'all':
      storages => $swift_nodes,
      require  => Class['swift'],
    }
  }

  if has_key($swift_hash, 'resize_value') {
    $resize_value = $swift_hash['resize_value']
  } else {
    $resize_value = 2
  }

  $ring_part_power = calc_ring_part_power($swift_nodes,$resize_value)
  $sto_net = $network_scheme['endpoints'][$network_scheme['roles']['storage']]['IP']
  $man_net = $network_scheme['endpoints'][$network_scheme['roles']['management']]['IP']

  class { 'openstack::swift::proxy':
    swift_user_password     => $swift_hash['user_password'],
    swift_proxies           => $swift_proxies,
    ring_part_power         => $ring_part_power,
    primary_proxy           => $primary_proxy,
    controller_node_address => $management_vip,
    swift_local_net_ip      => $storage_address,
    master_swift_proxy_ip   => $master_swift_proxy_ip,
    proxy_port              => $proxy_port,
    debug                   => $debug,
    verbose                 => $verbose,
    log_facility            => 'LOG_SYSLOG',
    ceilometer              => hiera('use_ceilometer',false),
    ring_min_part_hours     => $ring_min_part_hours,
  } ->

  class { 'openstack::swift::status':
    endpoint    => "http://${storage_address}:${proxy_port}",
    vip         => $management_vip,
    only_from   => "127.0.0.1 240.0.0.2 ${sto_net} ${man_net}",
    con_timeout => 5
  }

  class { 'swift::keystone::auth':
    password         => $swift_hash['user_password'],
    public_address   => hiera('public_vip'),
    internal_address => $management_vip,
    admin_address    => $management_vip,
  }

}

# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer
class ceilometer {}
include ceilometernotice('MODULAR: swift.pp')

$swift_hash          = hiera('swift_hash')
$swift_master_role   = hiera('swift_master_role', 'primary-controller')
$swift_nodes         = pick(hiera('swift_nodes', undef), hiera('controllers', undef))
$swift_proxies       = pick(hiera('swift_proxies', undef), hiera('controller_internal_addresses', undef))
$primary_swift       = pick(hiera('primary_swift', undef), hiera('primary_controller', undef))
$proxy_port          = hiera('proxy_port', '8080')
$network_scheme      = hiera('network_scheme', {})
$storage_hash        = hiera('storage_hash')
$mp_hash             = hiera('mp')
$management_vip      = hiera('management_vip')
$debug               = hiera('debug', false)
$verbose             = hiera('verbose')
$storage_address     = hiera('storage_address')
$node                = hiera('node')
$ring_min_part_hours = hiera('swift_ring_min_part_hours', 1)

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  if !(hiera('swift_partition', false)) {
    $swift_partition = '/var/lib/glance/node'
  }
  $master_swift_proxy_nodes = filter_nodes(hiera('nodes_hash'),'role',$swift_master_role)
  $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['storage_address']
  if ($primary_swift) {
    $primary_proxy = true
  } else {
    $primary_proxy = false
  }

  class { 'openstack::swift::storage_node':
    storage_type          => false,
    loopback_size         => '5243780',
    storage_mnt_base_dir  => $swift_partition,
    storage_devices       => filter_hash($mp_hash,'point'),
    swift_zone            => $node[0]['swift_zone'],
    swift_local_net_ip    => $storage_address,
    master_swift_proxy_ip => $master_swift_proxy_ip,
    sync_rings            => ! $primary_proxy,
    debug                 => $debug,
    verbose               => $verbose,
    log_facility          => 'LOG_SYSLOG',
  }
  if $primary_proxy {
    ring_devices {'all':
      storages => $swift_nodes,
      require  => Class['swift'],
    }
  }

  if has_key($swift_hash, 'resize_value') {
    $resize_value = $swift_hash['resize_value']
  } else {
    $resize_value = 2
  }

  $ring_part_power = calc_ring_part_power($swift_nodes,$resize_value)
  $sto_net = $network_scheme['endpoints'][$network_scheme['roles']['storage']]['IP']
  $man_net = $network_scheme['endpoints'][$network_scheme['roles']['management']]['IP']

  class { 'openstack::swift::proxy':
    swift_user_password     => $swift_hash['user_password'],
    swift_proxies           => $swift_proxies,
    ring_part_power         => $ring_part_power,
    primary_proxy           => $primary_proxy,
    controller_node_address => $management_vip,
    swift_local_net_ip      => $storage_address,
    master_swift_proxy_ip   => $master_swift_proxy_ip,
    proxy_port              => $proxy_port,
    debug                   => $debug,
    verbose                 => $verbose,
    log_facility            => 'LOG_SYSLOG',
    ceilometer              => hiera('use_ceilometer',false),
    ring_min_part_hours     => $ring_min_part_hours,
  } ->

  class { 'openstack::swift::status':
    endpoint    => "http://${storage_address}:${proxy_port}",
    vip         => $management_vip,
    only_from   => "127.0.0.1 240.0.0.2 ${sto_net} ${man_net}",
    con_timeout => 5
  }

  class { 'swift::keystone::auth':
    password         => $swift_hash['user_password'],
    public_address   => hiera('public_vip'),
    internal_address => $management_vip,
    admin_address    => $management_vip,
  }

}

# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer
class ceilometer {}
include ceilometer