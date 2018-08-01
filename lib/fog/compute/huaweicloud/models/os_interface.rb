require 'fog/huaweicloud/models/model'

module Fog
  module Compute
    class HuaweiCloud
      class OsInterface < Fog::HuaweiCloud::Model
        identity  :port_id
        attribute :fixed_ips, :type => :array
        attribute :mac_addr
        attribute :subnet_id
        attribute :port_state
      end
    end
  end
end
