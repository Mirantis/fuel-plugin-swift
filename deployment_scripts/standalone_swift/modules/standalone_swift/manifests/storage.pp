class standalone_swift::storage {

  notice('MODULAR: standalone_swift/storage.pp')

  # Configure networking on a node, during a stage prior to main
  prepare_network_config(hiera('network_scheme'))
  $stub = generate_network_config()

  #Some includes
  include ceilometer
  include memcached

  #Collecting data from hiera
  $swift_hash            = hiera('swift_hash', {})
  $network_metadata      = hiera('network_metadata', {})
  $network_scheme        = hiera('network_scheme', {})
  $mp_hash               = hiera('mp')
  $debug                 = hiera('debug', false)
  $verbose               = hiera('verbose')
  $node                  = hiera('node')
  $nodes_hash            = hiera('nodes')
  $node_role             = hiera('role')
  $ring_min_part_hours   = hiera('swift_ring_min_part_hours', 1)
  $loopback_size         = pick($swift_hash['loopback_size'], '5243780')
  $storage_type          = pick($swift_hash['storage_type'], false)

  # Getting data from plugin
  $swift_account_device   = pick($swift_hash['swift_account_device'], '/srv/node')
  $swift_container_device = pick($swift_hash['swift_container_device'], '/srv/node')
  $swift_object_device    = pick($swift_hash['swift_object_device'], '/var/lib/glance/node')
  $swift_device_list      = unique([ $swift_account_device, $swift_container_device, $swift_object_device ])

  # Collecting ip-addresses
  $master_swift_proxy_nodes      = get_nodes_hash_by_roles($network_metadata, ['primary-swift-proxy'])
  $master_swift_proxy_nodes_list = values($master_swift_proxy_nodes)
  $master_swift_proxy_ip         = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', '')
  $master_swift_replication_ip   = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', '')
  $swift_zone                    = pick($master_swift_proxy_nodes_list[0]['swift_zone'],'1')
  $swift_storage_local_ipaddr      = pick($node['network_roles']['swift/api'], '1.1.1.1')
  $swift_replication_local_ipaddr  = pick($node['network_roles']['swift/replication'], '2.2.2.2')

  $primary_proxy            = $node_role ? { 'primary-swift-proxy' => true, default =>false }

  file { $swift_device_list:
    ensure => 'directory',
    owner  => 'swift',
    group  => 'swift',
    mode   => '0750',
  } ->

  class { 'openstack::swift::storage_node':
    swift_zone                   => $swift_zone,
    storage_type                 => $storage_type,
    loopback_size                => $loopback_size,
    storage_mnt_base_dir         => $swift_object_device,
    storage_devices              => filter_hash($mp_hash,'point'),
    sync_rings                   => ! $primary_proxy,
    debug                        => $debug,
    verbose                      => $verbose,
    log_facility                 => 'LOG_SYSLOG',
    master_swift_replication_ip  => $master_swift_replication_ip,
    master_swift_proxy_ip        => $master_swift_proxy_ip,
    swift_local_net_ip           => $swift_replication_local_ipaddr,
  }

  # Setup a cronjob to rebalance and repush rings periodically
  class { 'openstack::swift::rebalance_cronjob':
    ring_rebalance_period             => min($ring_min_part_hours * 2, 23),
    primary_proxy                     => $primary_proxy,
    master_swift_replication_ip       => $master_swift_replication_ip,
  }
}

# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer

  class ceilometer {}

# Class[Swift::Proxy::Cache] requires Class[Memcached] if memcache_servers
# contains 127.0.0.1. But we're deploying memcached in another task. So we
# need to add this stub here.

  class memcached {}

