require 'fog/huaweicloud/models/model'

module Fog
  module Monitoring
    class HuaweiCloud
      class Metric < Fog::HuaweiCloud::Model
        identity :id

        attribute :name
        attribute :dimensions
        attribute :timestamp
        attribute :value
        attribute :value_meta

        def to_s
          name
        end

        def create
          requires :name, :timestamp, :value
          service.create_metric(attributes).body['metric']
          self
        end
      end
    end
  end
end
