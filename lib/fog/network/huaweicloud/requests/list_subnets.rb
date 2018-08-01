module Fog
  module Network
    class HuaweiCloud
      class Real
        def list_subnets(filters = {}, openstack_compatible = true)
          overwrite_version = openstack_compatible ? {} : {'v2.0'=> 'v1'}
          request(
            {:expects => 200, :method => 'GET', :path => 'subnets', :query => filters},
            true, overwrite_version
          )
        end
      end

      class Mock
        def list_subnets(_filters = {}, openstack_compatible = true)
          Excon::Response.new(
            :body   => {'subnets' => data[:subnets].values},
            :status => 200
          )
        end
      end
    end
  end
end
