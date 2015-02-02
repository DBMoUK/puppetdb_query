Used to find numbers of nodes from PuppetDB that match an OS Family and a given fact.

Usage: do_it.rb [options]

Specific options:
        --server SERVER              PuppetDB server which to use
        --ssl-confdir LOCATION       Location of the SSL directory for REST operation usage.
                                     Directories under this must be: certs, private_keys and public_keys
        --cert NAME                  Name of certificate to use in REST operations.(do not include the pem extension)
    -o, --os OSFAMILY                OS Family to test against
    -f, --fact FACT                  Fact to query
    -v, --value VALUE                Value for which fact is tested against
    -h, --help                       Show this message

Example:
/opt/puppet/bin/ruby puppetdb_query.rb --cert m0.puppetlabs.vm --ssl-confdir /etc/puppetlabs/puppet/ssl/ --server m0.puppetlabs.vm --os RedHat --fact operatingsystemrelease --value 6.5
