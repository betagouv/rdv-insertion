module AgentSession
  class ThroughAgentConnect < Base
    def max_duration
      7.days
    end

    def agent_connect_token_id
      @params[:agent_connect_id_token]
    end
  end
end
