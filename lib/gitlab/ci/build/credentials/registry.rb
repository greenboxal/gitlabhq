module Gitlab
  module Ci
    module Build
      module Credentials
        class Registry < Base
          attr_reader :username, :password

          def initialize(build)
            @username = 'doggohub-ci-token'
            @password = build.token
          end

          def url
            Gitlab.config.registry.host_port
          end

          def valid?
            Gitlab.config.registry.enabled
          end
        end
      end
    end
  end
end
