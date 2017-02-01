module Travis::API::V3
  class Queries::Config < Query
    params :id, prefix: :job

    def find
      Models::Config.new(Models::Job.find(id))
    end
  end
end
