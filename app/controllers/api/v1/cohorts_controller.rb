class Api::V1::CohortsController < Api::V1::ApiController
  before_action :doorkeeper_authorize!

  def index
    render json: Cohort.all, root_url: root_url, status: 200 
  end
end
