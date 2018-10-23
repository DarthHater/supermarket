#
# Cookbook Name:: supermarket
# Recipe:: config
#
# Copyright 2014 Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Get and/or create config and secrets.
#
# This creates the config_directory if it does not exist as well as the files
# in it.
Supermarket::Config.load_or_create!(
  "#{node['supermarket']['config_directory']}/supermarket.rb",
  node,
)
Supermarket::Config.load_from_json!(
  "#{node['supermarket']['config_directory']}/supermarket.json",
  node,
)
Supermarket::Config.load_or_create_secrets!(
  "#{node['supermarket']['config_directory']}/secrets.json",
  node,
)

Supermarket::Config.audit_config(node['supermarket'])

# Copy things we need from the supermarket namespace to the top level. This is
# necessary for some community cookbooks.
node.consume_attributes('runit' => node['supermarket']['runit'])

case node['supermarket']['fips_enabled']
when nil
  # the default value, set fips mode based on whether it is enabled in the kernel
  fips_path = "/proc/sys/crypto/fips_enabled"
  enabled_in_kernel = (File.exist?(fips_path) && File.read(fips_path).chomp != "0")
  node.normal['supermarket']['fips_enabled'] = enabled_in_kernel
  if enabled_in_kernel
    Chef::Log.info('Detected FIPS-enabled kernel; enabling FIPS 140-2 for Supermarket services.')
  end
when false
  Chef::Log.warn('Overriding FIPS detection: FIPS 140-2 mode is OFF.')
when true
  Chef::Log.warn('Overriding FIPS detection: FIPS 140-2 mode is ON.')
else
  node.normal['supermarket']['fips_enabled'] = true
  Chef::Log.warn('fips_enabled is set to something other than boolean true/false; assuming FIPS mode should be enabled.')
  Chef::Log.warn('Overriding FIPS detection: FIPS 140-2 mode is ON.')
end

# set chef_oauth2_url from chef_server_url after this value has been loaded from config
if node['supermarket']['chef_server_url'] && node['supermarket']['chef_oauth2_url'].nil?
  node.normal['supermarket']['chef_oauth2_url'] = node['supermarket']['chef_server_url']
end

user node['supermarket']['user']

group node['supermarket']['group'] do
  members [node['supermarket']['user']]
end

directory node['supermarket']['config_directory'] do
  owner node['supermarket']['user']
  group node['supermarket']['group']
end

directory node['supermarket']['var_directory'] do
  owner node['supermarket']['user']
  group node['supermarket']['group']
  mode '0700'
  recursive true
end

directory node['supermarket']['log_directory'] do
  owner node['supermarket']['user']
  group node['supermarket']['group']
  mode '0700'
  recursive true
end

directory "#{node['supermarket']['var_directory']}/etc" do
  owner node['supermarket']['user']
  group node['supermarket']['group']
  mode '0700'
end

file "#{node['supermarket']['config_directory']}/supermarket.rb" do
  owner node['supermarket']['user']
  group node['supermarket']['group']
  mode '0600'
end

file "#{node['supermarket']['config_directory']}/secrets.json" do
  owner node['supermarket']['user']
  group node['supermarket']['group']
  mode '0600'
end
