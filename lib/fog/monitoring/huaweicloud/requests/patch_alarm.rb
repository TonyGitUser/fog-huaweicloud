module Fog
  module Monitoring
    class HuaweiCloud
      class Real
        def patch_alarm(id, options)
          request(
            :expects => [200],
            :method  => 'PATCH',
            :path    => "alarms/#{id}",
            :body    => Fog::JSON.encode(options)
          )
        end
      end

      class Mock
      end
    end
  end
end
